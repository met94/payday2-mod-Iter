// Cross-mod compatibility contract (AI suite phase 1).
//
// Useful Bots 2.4.3 checks `Iter.settings.streamline_path` at load time. Iter
// nils that legacy key in `Iter:load()`, so the alias published right after
// the load call is the only thing keeping UB's guard alive. These checks are
// text-based on purpose: they must run without the game.

import assert from 'node:assert/strict';
import fs from 'node:fs';
import path from 'node:path';
import test from 'node:test';
import { fileURLToPath } from 'node:url';

const repoRoot = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..', '..', '..');
const modTxt = JSON.parse(fs.readFileSync(path.join(repoRoot, 'mod.txt'), 'utf8'));
const corecode = fs.readFileSync(path.join(repoRoot, 'lua', 'corecode.lua'), 'utf8');
const changelog = fs.readFileSync(path.join(repoRoot, 'changelog.txt'), 'utf8');
const readme = fs.readFileSync(path.join(repoRoot, 'README.md'), 'utf8');

test('release version is 200.2 with priority 40', () => {
  assert.equal(modTxt.version, '200.2');
  assert.equal(modTxt.priority, 40);
});

test('corecode publishes the legacy alias after Iter:load()', () => {
  assert.match(
    corecode,
    /Iter\.settings\.streamline_path = Iter\.settings\.nav_streamline/,
    'legacy streamline_path alias missing'
  );

  const loadCall = corecode.search(/\nIter:load\(\)\r?\n/);
  assert.ok(loadCall > 0, 'corecode must call Iter:load()');

  const alias = corecode.indexOf('Iter.settings.streamline_path = Iter.settings.nav_streamline');
  assert.ok(
    alias > loadCall,
    'the alias must be published after Iter:load() so load() cannot nil it again'
  );
});

test('load() still clears the persisted legacy key before the alias is set', () => {
  const nilInLoad = corecode.indexOf('self.settings.streamline_path = nil');
  const alias = corecode.indexOf('Iter.settings.streamline_path = Iter.settings.nav_streamline');
  assert.ok(nilInLoad > 0, 'load() must nil the persisted legacy key');
  assert.ok(nilInLoad < alias, 'load() must run before the alias is published');
});

test('changelog has a Revision 200.2 block with player notes', () => {
  const block = changelog.match(/^Revision 200\.2 \([^)]*\):([\s\S]*?)(?=\r?\nRevision )/m);
  assert.ok(block, 'Revision 200.2 block missing');
  assert.match(block[1], /^Player notes: .+/m, 'Revision 200.2 needs a Player notes line');
  assert.match(block[1], /streamline_path/, 'Revision 200.2 must name the legacy alias');
});

test('README documents the Useful Bots legacy-key compatibility', () => {
  const compat = readme.match(/## Compatibility([\s\S]*?)## Options/);
  assert.ok(compat, 'README Compatibility section missing');
  assert.match(compat[1], /Useful Bots/, 'Useful Bots bullet missing');
  assert.match(compat[1], /streamline_path/, 'legacy streamline_path note missing');
  assert.match(compat[1], /alias/i, 'README must explain the alias, not just name the key');
});
