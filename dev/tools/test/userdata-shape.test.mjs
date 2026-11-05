import test from 'node:test';
import assert from 'node:assert/strict';
import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import { createRequire } from 'node:module';

// Guards the "opaque engine userdata treated as a table or a Vector3" mistake
// class (LIES 2026-11-05 taser crash, `mods/LIES/dev/reports/
// watch-settle-attention-unit-type-crash.md`): an Idstring (`unit:key()`,
// `attention_obj.u_key`, nav-link ids) is userdata with no `__index`, so a
// field read raises "attempt to index ... (a userdata value)". `type()` answers
// "userdata" for a Vector3, an Idstring, a unit and a nav link alike.
//
// Rules, over the real Lua AST (luaparse; no comment or string heuristics):
//   1. no `.type_name` read - the field that crashed LIES;
//   2. `type(x) == "userdata"` / `~= "userdata"` is not a shape proof.
//
// Iter keeps five probes on purpose. They are rejection guards, not shape
// proofs: the value domains are pinned in
// `dev/reports/opaque-userdata-shapes.md` (game writers + the readers that
// already index the same values). An allowlist entry matches file + enclosing
// function + comparison direction, so a copied probe, a positive proof added
// inside an allowlisted function, or a stale entry all fail the test.
//
//   dev\tools\gates.ps1 runs this file with the rest of the Node tool tests.

const root = fileURLToPath(new URL('../../../', import.meta.url));
const LUA_ROOT = path.join(root, 'lua');
const workspaceRoot = path.resolve(root, '..', '..');
const require = createRequire(import.meta.url);
const luaparse = require(path.join(workspaceRoot, 'tools', 'lua', 'node_modules', 'luaparse'));

// `file` is repo-relative, `fn` the enclosing declaration, `op` the comparison
// direction. A guard rejects with `~=`; only the nav-link filter is positive.
const ALLOWED = [
  {
    file: 'lua/navigationmanager.lua',
    fn: 'is_vec3',
    op: '~=',
    reason: 'rejection guard over the proven door-list/position domain; see report',
  },
  {
    file: 'lua/navigationmanager.lua',
    fn: 'itr_alive',
    op: '~=',
    reason: 'rejection guard; Vector3 is rejected here, nav links fall through',
  },
  {
    file: 'lua/navigationmanager.lua',
    fn: 'NavigationManager.itr_find_best_navlink',
    op: '==',
    reason: 'filter for nav-link list entries; itr_alive already rejects non-userdata',
  },
  {
    file: 'lua/copactionwalk.lua',
    fn: 'itr_alive_navpoint',
    op: '~=',
    reason: 'rejection guard over the proven nav-point/nav-link domain; see report',
  },
  {
    file: 'lua/coplogictravel.lua',
    fn: 'get_turn_back_index',
    op: '~=',
    reason: 'rejection guard over coarse-path slot 2 (Vector3 or nil); see report',
  },
];

function walk(dir, out = []) {
  for (const entry of fs.readdirSync(dir, { withFileTypes: true })) {
    const full = path.join(dir, entry.name);
    if (entry.isDirectory()) walk(full, out);
    else if (entry.name.endsWith('.lua')) out.push(full);
  }

  return out;
}

function functionName(node) {
  const identifier = node.identifier;

  if (!identifier) return null;
  if (identifier.type === 'Identifier') return identifier.name;

  if (identifier.type === 'MemberExpression') {
    const base = identifier.base && identifier.base.name ? identifier.base.name : '?';
    const member = identifier.identifier || identifier.index;
    let index = '?';

    if (member) {
      if (member.type === 'Identifier') {
        index = member.name;
      } else if (member.type === 'StringLiteral') {
        index = member.value || (member.raw || '').replace(/^['"]|['"]$/g, '');
      }
    }

    return base + '.' + index;
  }

  return null;
}

function isTypeCall(node) {
  return node
    && node.type === 'CallExpression'
    && node.base
    && node.base.type === 'Identifier'
    && node.base.name === 'type'
    && node.arguments
    && node.arguments.length === 1;
}

function isUserdataLiteral(node) {
  if (!node || node.type !== 'StringLiteral') return false;
  if (node.value === 'userdata') return true;
  return /^(['"])userdata\1$/.test(node.raw || '');
}

function visit(node, scope, onNode) {
  if (!node || typeof node !== 'object') return;

  if (Array.isArray(node)) {
    for (const child of node) visit(child, scope, onNode);
    return;
  }

  if (!node.type) return;

  let current = scope;

  if (node.type === 'FunctionDeclaration') {
    current = functionName(node) || scope;
  }

  onNode(node, current);

  for (const key of Object.keys(node)) {
    if (key === 'loc') continue;
    visit(node[key], current, onNode);
  }
}

function findingsFor(file) {
  const rel = path.relative(root, file).replaceAll('\\', '/');
  const source = fs.readFileSync(file, 'utf8');
  const ast = luaparse.parse(source, { locations: true });
  const findings = [];

  visit(ast, null, (node, scope) => {
    if (node.type === 'MemberExpression' && node.index
      && node.index.type === 'Identifier' && node.index.name === 'type_name') {
      findings.push({
        rel,
        fn: scope,
        op: null,
        line: node.loc.start.line,
        id: 'type_name read',
      });
      return;
    }

    if (node.type !== 'BinaryExpression' || (node.operator !== '==' && node.operator !== '~=')) return;

    const typeLeft = isTypeCall(node.left) && isUserdataLiteral(node.right);
    const typeRight = isUserdataLiteral(node.left) && isTypeCall(node.right);

    if (!typeLeft && !typeRight) return;

    findings.push({
      rel,
      fn: scope,
      op: node.operator,
      line: node.loc.start.line,
      id: 'type() used as a shape proof',
    });
  });

  return findings;
}

test('no code treats a possibly-opaque userdata as a table or a Vector3', () => {
  const used = new Set();
  const unresolved = [];

  for (const file of walk(LUA_ROOT)) {
    for (const finding of findingsFor(file)) {
      const allow = ALLOWED.find((entry) => entry.file === finding.rel
        && entry.fn === finding.fn
        && entry.op === finding.op);

      if (allow) {
        used.add(allow);
        continue;
      }

      unresolved.push(
        `${finding.rel}:${finding.line}: ${finding.id} in ${finding.fn || '<chunk>'}`
        + ` (${finding.op || 'field read'}): an opaque userdata has no __index;`
        + ' read a field of a shape you know, or prove the value domain'
      );
    }
  }

  assert.deepEqual(unresolved, [], `elidable userdata shape assumptions:\n${unresolved.join('\n')}`);

  const stale = ALLOWED.filter((entry) => !used.has(entry));
  assert.deepEqual(
    stale.map((entry) => `${entry.file}: ${entry.fn} (${entry.reason})`),
    [],
    'stale allowlist entries (the probe moved, changed direction or disappeared)'
  );
});

test('the allowlisted guards keep their rejection shape', () => {
  const read = (rel) => fs.readFileSync(path.join(root, rel), 'utf8');

  const nav = read('lua/navigationmanager.lua');
  assert.match(
    nav,
    /local function is_vec3\(value\)\s*\n\s*if type\(value\) ~= 'userdata' then\s*\n\s*return false\s*\n\s*end/
  );
  assert.match(
    nav,
    /local function itr_alive\(obj\)[\s\S]*?if type\(obj\) ~= 'userdata' or is_vec3\(obj\) then\s*\n\s*return false\s*\n\s*end/
  );
  assert.match(
    nav,
    /type\(navlink\) == 'userdata' and itr_alive\(navlink\) and not navlink:is_obstructed\(\) and navlink:check_access\(access_pos, 0\)/
  );

  const walk = read('lua/copactionwalk.lua');
  assert.match(
    walk,
    /local function itr_alive_navpoint\(obj\)\s*\n\s*if not obj or type\(obj\) ~= 'userdata' then\s*\n\s*return false\s*\n\s*end/
  );

  const travel = read('lua/coplogictravel.lua');
  assert.match(
    travel,
    /if type\(coarse_path\[j\]\[2\]\) ~= 'userdata' then\s*\n\s*return\s*\n\s*end/
  );
});
