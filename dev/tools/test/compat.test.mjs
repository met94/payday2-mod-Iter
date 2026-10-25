// Cross-mod compatibility contract (AI suite phase 1).
//
// Useful Bots 2.4.3 checks `Iter.settings.streamline_path` at load time. Iter
// nils that legacy key in `Iter:load()` and then republishes it as a runtime
// mirror of the effective pathing state, so UB's guard stays alive. `save()`
// recomputes the mirror from the live switches and persists the effective
// boolean, while `load()` drops and rebuilds it on every boot. These checks are
// text-based on purpose: they must run without the game.

import assert from 'node:assert/strict';
import fs from 'node:fs';
import path from 'node:path';
import test from 'node:test';
import { fileURLToPath } from 'node:url';

const repoRoot = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..', '..', '..');
const modTxt = JSON.parse(fs.readFileSync(path.join(repoRoot, 'mod.txt'), 'utf8'));
const version = String(modTxt.version);
const corecode = fs.readFileSync(path.join(repoRoot, 'lua', 'corecode.lua'), 'utf8');
const changelog = fs.readFileSync(path.join(repoRoot, 'changelog.txt'), 'utf8');
const readme = fs.readFileSync(path.join(repoRoot, 'README.md'), 'utf8');
const menuOptions = fs.readFileSync(path.join(repoRoot, 'MENU_OPTIONS.md'), 'utf8');

const ALIAS = /Iter\.settings\.streamline_path\s*=\s*\(?\s*Iter\.settings\.nav_overlay\s+and\s+Iter\.settings\.nav_streamline\s*\)?\s*or\s+nil/;

// Strip Lua comments and long-bracket strings so a commented-out statement or a
// string literal cannot satisfy a check. Short strings are preserved; long
// comments (`--[[ ]]`, `--[==[ ]==]`) and line comments are removed, and
// `[[...]]` / `[=[...]=]` literals are blanked out like comments.
function stripLuaComments(source) {
  let out = '';
  let i = 0;
  while (i < source.length) {
    const c = source[i];

    if (c === '"' || c === "'") {
      const quote = c;
      out += c;
      i++;
      while (i < source.length) {
        const ch = source[i];
        out += ch;
        i++;
        if (ch === '\\') {
          if (i < source.length) out += source[i];
          i++;
          continue;
        }
        if (ch === quote) break;
      }
      continue;
    }

    if (c === '-' && source[i + 1] === '-') {
      const long = /^--(\[(=*)\[)/.exec(source.slice(i));
      if (long) {
        const close = ']' + long[2] + ']';
        const end = source.indexOf(close, i + long[0].length);
        i = end === -1 ? source.length : end + close.length;
      } else {
        const nl = source.indexOf('\n', i + 2);
        i = nl === -1 ? source.length : nl;
      }
      out += '\n';
      continue;
    }

    const longString = c === '[' && /^\[(=*)\[/.exec(source.slice(i));
    if (longString) {
      const close = ']' + longString[1] + ']';
      const end = source.indexOf(close, i + longString[0].length);
      i = end === -1 ? source.length : end + close.length;
      out += '\n';
      continue;
    }

    out += c;
    i++;
  }
  return out;
}

function functionBody(code, name) {
  const start = code.indexOf(`function ${name}(`);
  assert.ok(start >= 0, `${name} missing from corecode.lua`);
  const end = code.indexOf('\nend', start);
  assert.ok(end > start, `${name} body is not terminated`);
  return code.slice(start, end);
}

// The mirror assignment inside `save()`. Lua `and`/`or` on booleans map onto
// `&&`/`||`, so the expression can be evaluated in JS to prove the toggle
// cases without the game.
const SAVE_MIRROR = /self\.settings\.streamline_path\s*=\s*([^\n;]+)/;

function evaluateMirror(expression) {
  // `nil` stays an identifier so it can be passed in as null.
  const js = expression
    .replace(/self\.settings\./g, '')
    .replace(/\band\b/g, '&&')
    .replace(/\bor\b/g, '||');
  // eslint-disable-next-line no-new-func
  return new Function('nav_overlay', 'nav_streamline', 'nil', `return (${js});`);
}

const code = stripLuaComments(corecode);

test('release version and priority agree in mod.txt, README and changelog', () => {
  assert.match(version, /^\d+\.\d+$/, 'mod.txt version must be <upstream revision>.<fork release>');
  assert.equal(modTxt.priority, 40);

  const readmeVersion = readme.match(/^- Version: `([^`]+)`$/m);
  assert.ok(readmeVersion, 'README must declare `- Version: `');
  assert.equal(readmeVersion[1], version, 'README version must match mod.txt');

  const revision = changelog.match(/^Revision (\S+) \(/m);
  assert.ok(revision, 'changelog must open with a Revision block');
  assert.equal(revision[1], version, 'newest changelog revision must match mod.txt');
});

test('corecode publishes the legacy mirror after Iter:load()', () => {
  assert.match(code, ALIAS, 'legacy streamline_path mirror missing (or only present in a comment)');

  const loadCall = code.search(/\nIter:load\(\)\r?\n/);
  assert.ok(loadCall > 0, 'corecode must call Iter:load()');

  const alias = code.search(ALIAS);
  assert.ok(
    alias > loadCall,
    'the mirror must be published after Iter:load() so load() cannot nil it again'
  );
});

test('the mirror is derived from effective state, not from nav_streamline alone', () => {
  const aliasStatement = code.match(ALIAS);
  assert.ok(aliasStatement, 'mirror statement missing');
  assert.match(aliasStatement[0], /nav_overlay/, 'mirror must respect the master switch');
  assert.match(aliasStatement[0], /or nil/, 'mirror must be nil when pathing is off');
});

test('load() still clears the persisted legacy key before the mirror is set', () => {
  const loadBody = functionBody(code, 'Iter:load');
  const nilInLoad = loadBody.indexOf('self.settings.streamline_path = nil');
  assert.ok(nilInLoad > 0, 'load() must nil the persisted legacy key');

  const migration = loadBody.indexOf('data.nav_overlay == nil and data.streamline_path == false');
  assert.ok(migration > 0, 'load() must keep the pre-port migration');
  assert.ok(migration < nilInLoad, 'migration must run before the legacy key is cleared');

  const alias = code.search(ALIAS);
  const loadEnd = code.indexOf('\nend', code.indexOf('function Iter:load('));
  assert.ok(loadEnd > 0, 'load() body is not terminated');
  assert.ok(alias > loadEnd, 'load() must run before the mirror is published');
});

test('long-bracket strings are stripped, so a literal cannot satisfy the alias check', () => {
  const sample = [
    'local before = true',
    'local text = [==[ Iter.settings.streamline_path = (Iter.settings.nav_overlay and Iter.settings.nav_streamline) or nil ]==]',
    'local after = true',
    ''
  ].join('\n');
  const stripped = stripLuaComments(sample);
  assert.doesNotMatch(stripped, /streamline_path/, 'a long-bracket string must not survive stripping');
  assert.match(stripped, /local before = true/);
  assert.match(stripped, /local after = true/);
});

test('save() recomputes the runtime mirror from the live switches', () => {
  const saveBody = functionBody(code, 'Iter:save');
  const assignment = SAVE_MIRROR.exec(saveBody);
  assert.ok(assignment, 'save() must assign streamline_path instead of hiding it');
  assert.match(assignment[1], /nav_overlay/, 'save() mirror must read the master switch');
  assert.match(assignment[1], /nav_streamline/, 'save() mirror must read nav_streamline');
  assert.doesNotMatch(
    saveBody,
    /self\.settings\.streamline_path\s*=\s*nil|local mirror\s*=/,
    'save() must not hide the mirror behind nil or restore a stale local copy'
  );

  const encode = saveBody.indexOf('json.encode');
  assert.ok(encode > assignment.index, 'save() must recompute the mirror before json.encode');
});

test('a toggle then save persists the effective mirror (both switches off cases)', () => {
  const saveBody = functionBody(code, 'Iter:save');
  const assignment = SAVE_MIRROR.exec(saveBody);
  assert.ok(assignment, 'save() mirror assignment missing');
  const evaluate = evaluateMirror(assignment[1]);

  assert.equal(evaluate(true, true, null), true, 'both switches on must persist a truthy mirror');

  for (const [overlay, streamline] of [[false, true], [true, false], [false, false]]) {
    const value = evaluate(overlay, streamline, null);
    assert.equal(
      value,
      false,
      `mirror must persist false (not nil) for nav_overlay=${overlay}, nav_streamline=${streamline} (got ${String(value)})`
    );
    assert.ok(!value, 'reason: a falsy mirror is what Useful Bots and upstream r200 both read as off');
  }
});

test(`changelog has a Revision ${version} block with player notes`, () => {
  const escaped = version.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
  const block = changelog.match(new RegExp(`^Revision ${escaped} \\([^)]*\\):([\\s\\S]*?)(?=\\r?\\nRevision )`, 'm'));
  assert.ok(block, `Revision ${version} block missing`);
  assert.match(block[1], /^Player notes: .+/m, `Revision ${version} needs a Player notes line`);
  assert.match(block[1], /streamline_path/, `Revision ${version} must name the legacy mirror`);
  assert.match(
    block[1],
    /off before launch/,
    `Revision ${version} player notes must say Useful Bots needs pathing off before launch`
  );
});

test('README documents the Useful Bots legacy-key compatibility', () => {
  const compat = readme.match(/## Compatibility([\s\S]*?)## Options/);
  assert.ok(compat, 'README Compatibility section missing');
  assert.match(compat[1], /Useful Bots/, 'Useful Bots bullet missing');
  assert.match(compat[1], /streamline_path/, 'legacy streamline_path note missing');
  assert.match(compat[1], /mirror/i, 'README must explain the mirror, not just name the key');
  assert.match(compat[1], /recomput/i, 'README must say the mirror is recomputed from the live switches');
  assert.match(compat[1], /saved|persist/i, 'README must say the mirror is persisted');
  assert.match(compat[1], /restart/i, 'README must say a toggle reaches Useful Bots only after a restart');
  assert.doesNotMatch(
    compat[1],
    /Iter never fills LIES's `\[4\]`/,
    'README must not credit Iter for the dead LIES [4] branch'
  );
});

test('MENU_OPTIONS documents the runtime mirror', () => {
  assert.match(menuOptions, /`streamline_path`[^]*runtime mirror/, 'MENU_OPTIONS must describe the runtime mirror');
  assert.match(menuOptions, /do not stick/, 'MENU_OPTIONS must say manual edits do not stick');
  assert.match(menuOptions, /persists|saved/i, 'MENU_OPTIONS must say save() persists the mirror');
  assert.match(menuOptions, /restart/i, 'MENU_OPTIONS must say Useful Bots needs a restart');
});
