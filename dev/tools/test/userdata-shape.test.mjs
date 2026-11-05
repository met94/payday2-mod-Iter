import test from 'node:test';
import assert from 'node:assert/strict';
import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

// Guards the "opaque engine userdata treated as a table or a Vector3" mistake
// class (LIES 2026-11-05 taser crash, `mods/LIES/dev/reports/
// watch-settle-attention-unit-type-crash.md`): an Idstring (`unit:key()`,
// `attention_obj.u_key`, nav-link ids) is userdata with no `__index`, so a
// field read raises "attempt to index ... (a userdata value)". `type()` answers
// "userdata" for a Vector3, an Idstring, a unit and a nav link alike.
//
// Rules, over comment-stripped lua/**/*.lua:
//   1. no `.type_name` read - the field that crashed LIES;
//   2. `type(x) == "userdata"` is not accepted as proof of a Vector3 or a table.
//
// Iter keeps five probes on purpose. They are rejection guards, not shape
// proofs: the value domains are pinned in
// `dev/reports/opaque-userdata-shapes.md` (game writers + the readers that
// already index the same values). The allowlist is scoped to the enclosing
// function, so a copy of the same probe anywhere else is still flagged, and a
// stale entry fails the test.
//
//   dev\tools\gates.ps1 runs this file with the rest of the Node tool tests.

const root = fileURLToPath(new URL('../../../', import.meta.url));
const LUA_ROOT = path.join(root, 'lua');

// `file` is repo-relative, `fn` is the nearest preceding declaration name.
const ALLOWED = [
  {
    file: 'lua/navigationmanager.lua',
    fn: 'is_vec3',
    reason: 'rejection guard over the proven door-list/position domain; see report',
  },
  {
    file: 'lua/navigationmanager.lua',
    fn: 'itr_alive',
    reason: 'rejection guard; Vector3 is rejected here, nav links fall through',
  },
  {
    file: 'lua/navigationmanager.lua',
    fn: 'NavigationManager:itr_find_best_navlink',
    reason: 'rejection guard; itr_alive already rejects non-userdata',
  },
  {
    file: 'lua/copactionwalk.lua',
    fn: 'itr_alive_navpoint',
    reason: 'rejection guard over the proven nav-point/nav-link domain; see report',
  },
  {
    file: 'lua/coplogictravel.lua',
    fn: 'get_turn_back_index',
    reason: 'rejection guard over coarse-path slot 2 (Vector3 or nil); see report',
  },
];

const RULES = [
  {
    id: 'type_name read',
    pattern: /\.type_name\b/,
    why: 'an opaque userdata has no __index; read a field of a shape you know instead',
  },
  {
    id: 'type() used as a shape proof',
    pattern: /type\s*\([^()]*\)\s*[=~]=\s*['"]userdata['"]/,
    why: 'type() answers "userdata" for a Vector3, an Idstring, a unit and a nav link alike',
  },
];

function stripLuaComments(source) {
  let out = '';
  let i = 0;

  while (i < source.length) {
    if (source.startsWith('--[[', i)) {
      const end = source.indexOf(']]', i + 4);
      if (end === -1) break;
      out += source.slice(i, end + 2).replace(/[^\n]/g, ' ');
      i = end + 2;
      continue;
    }

    if (source.startsWith('--', i)) {
      const eol = source.indexOf('\n', i);
      if (eol === -1) break;
      out += source.slice(i, eol).replace(/[^\n]/g, ' ');
      i = eol;
      continue;
    }

    out += source[i];
    i++;
  }

  return out;
}

function walk(dir, out = []) {
  for (const entry of fs.readdirSync(dir, { withFileTypes: true })) {
    const full = path.join(dir, entry.name);
    if (entry.isDirectory()) walk(full, out);
    else if (entry.name.endsWith('.lua')) out.push(full);
  }

  return out;
}

const luaFiles = () => walk(LUA_ROOT).map((file) => ({
  rel: path.relative(root, file).replaceAll('\\', '/'),
  lines: stripLuaComments(fs.readFileSync(file, 'utf8')).split(/\r?\n/),
}));

function declarationBefore(lines, index) {
  for (let i = index; i >= 0; i--) {
    const match = /^\s*(?:local\s+)?function\s+([A-Za-z_][\w.:]*)\s*\(/.exec(lines[i]);
    if (match) return match[1];
  }

  return null;
}

test('no code treats a possibly-opaque userdata as a table or a Vector3', () => {
  const findings = [];
  const used = new Set();

  for (const { rel, lines } of luaFiles()) {
    lines.forEach((line, index) => {
      for (const rule of RULES) {
        if (!rule.pattern.test(line)) continue;

        const fn = declarationBefore(lines, index);
        const allow = ALLOWED.find((entry) => entry.file === rel && entry.fn === fn);

        if (allow) {
          used.add(allow);
          continue;
        }

        findings.push(`${rel}:${index + 1}: ${rule.id}: ${line.trim()} (${rule.why})`);
      }
    });
  }

  assert.deepEqual(findings, [], `elidable userdata shape assumptions:\n${findings.join('\n')}`);

  const stale = ALLOWED.filter((entry) => !used.has(entry));
  assert.deepEqual(
    stale.map((entry) => `${entry.file}: ${entry.fn} (${entry.reason})`),
    [],
    'stale allowlist entries (the probe moved or disappeared)'
  );
});

test('the allowlisted guards keep their rejection shape', () => {
  const byFile = new Map(luaFiles().map((entry) => [entry.rel, entry.lines.join('\n')]));

  const nav = byFile.get('lua/navigationmanager.lua');
  assert.match(nav, /local function is_vec3\(value\)\s*\n\s*if type\(value\) ~= 'userdata' then\s*\n\s*return false/);
  assert.match(nav, /local function itr_alive\(obj\)/);
  assert.match(nav, /type\(navlink\) == 'userdata' and itr_alive\(navlink\)/);

  const walk = byFile.get('lua/copactionwalk.lua');
  assert.match(walk, /local function itr_alive_navpoint\(obj\)/);

  const travel = byFile.get('lua/coplogictravel.lua');
  assert.match(travel, /if type\(coarse_path\[j\]\[2\]\) ~= 'userdata' then/);
});
