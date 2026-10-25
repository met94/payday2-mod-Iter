// Cross-mod compatibility contract (AI suite phase 1).
//
// Useful Bots 2.4.3 checks `Iter.settings.streamline_path` at load time. Iter
// nils that legacy key in `Iter:load()` and then republishes it as a runtime
// mirror of the effective pathing state, so UB's guard stays alive without the
// key ever reaching the save file. These checks are text-based on purpose: they
// must run without the game.

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

// Strip Lua comments so a commented-out statement cannot satisfy a check.
// Strings are preserved; long comments (`--[[ ]]`, `--[==[ ]==]`) and line
// comments are removed.
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

test('save() keeps the runtime mirror out of the saved settings', () => {
  const saveBody = functionBody(code, 'Iter:save');
  const hide = saveBody.indexOf('self.settings.streamline_path = nil');
  const encode = saveBody.indexOf('json.encode');
  const restore = saveBody.indexOf('self.settings.streamline_path = mirror');
  assert.ok(hide > 0, 'save() must hide the mirror before writing');
  assert.ok(encode > hide, 'save() must clear the mirror before json.encode');
  assert.ok(restore > encode, 'save() must restore the mirror after writing');
});

test(`changelog has a Revision ${version} block with player notes`, () => {
  const escaped = version.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
  const block = changelog.match(new RegExp(`^Revision ${escaped} \\([^)]*\\):([\\s\\S]*?)(?=\\r?\\nRevision )`, 'm'));
  assert.ok(block, `Revision ${version} block missing`);
  assert.match(block[1], /^Player notes: .+/m, `Revision ${version} needs a Player notes line`);
  assert.match(block[1], /streamline_path/, `Revision ${version} must name the legacy mirror`);
});

test('README documents the Useful Bots legacy-key compatibility', () => {
  const compat = readme.match(/## Compatibility([\s\S]*?)## Options/);
  assert.ok(compat, 'README Compatibility section missing');
  assert.match(compat[1], /Useful Bots/, 'Useful Bots bullet missing');
  assert.match(compat[1], /streamline_path/, 'legacy streamline_path note missing');
  assert.match(compat[1], /mirror/i, 'README must explain the mirror, not just name the key');
  assert.match(compat[1], /never saved|not saved/i, 'README must say the mirror is not persisted');
  assert.doesNotMatch(
    compat[1],
    /Iter never fills LIES's `\[4\]`/,
    'README must not credit Iter for the dead LIES [4] branch'
  );
});

test('MENU_OPTIONS documents the runtime mirror', () => {
  assert.match(menuOptions, /`streamline_path`[^]*runtime mirror/, 'MENU_OPTIONS must describe the runtime mirror');
  assert.match(menuOptions, /do not stick/, 'MENU_OPTIONS must say manual edits do not stick');
});
