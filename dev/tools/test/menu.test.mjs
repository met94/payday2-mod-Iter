// Menu + release-default invariants.
//
// The release menu must stay player-facing: master pathing, Rebuild NavLinks,
// then one divider and only per-map toggles. Subsystem flags stay in
// corecode.lua / iter.txt, not between the map toggles.

import assert from 'node:assert/strict';
import fs from 'node:fs';
import path from 'node:path';
import test from 'node:test';
import { fileURLToPath } from 'node:url';

const repoRoot = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..', '..', '..');
const menu = JSON.parse(fs.readFileSync(path.join(repoRoot, 'menu', 'options.txt'), 'utf8'));
const corecode = fs.readFileSync(path.join(repoRoot, 'lua', 'corecode.lua'), 'utf8');

const toggles = menu.items.filter(item => item.type === 'toggle');
const mapIds = toggles.map(item => item.id).filter(id => id.startsWith('map_change_'));
const settingIds = [...corecode.matchAll(/^\s*(map_change_[a-z0-9_]+)\s*=/gm)].map(match => match[1]).sort();

test('menu exposes only the master, Rebuild NavLinks and map toggles', () => {
  assert.deepEqual(toggles.slice(0, 2).map(item => item.id), ['nav_overlay', 'rebuild_navlinks']);
  assert.ok(
    toggles.slice(2).every(item => item.id.startsWith('map_change_')),
    'non-map setting leaked between the map toggles'
  );
  assert.equal(menu.items[2].type, 'divider', 'map toggles must start after a divider');
  assert.equal(toggles[0].title, 'itr_options_streamline_path_title');
});

test('every map_change setting has a menu toggle', () => {
  assert.deepEqual([...mapIds].sort(), settingIds);
});

test('release defaults match original Iter', () => {
  for (const key of ['nav_overlay', 'nav_streamline', 'nav_search', 'nav_ai', 'navlink_queue',
    'path_extender', 'direct_to_pos', 'map_patches', 'cop_idle_fix']) {
    assert.match(corecode, new RegExp(`^\\s*${key} = true`, 'm'), `${key} must default to true`);
  }
  assert.match(corecode, /^\s*debug_log = 0/m, 'debug_log must default to 0');
  assert.match(corecode, /^\s*error_log = true/m, 'error_log must default to true');
  assert.ok(!/^\s*streamline_path\s*=/m.test(corecode), 'legacy streamline_path default must be gone');
});
