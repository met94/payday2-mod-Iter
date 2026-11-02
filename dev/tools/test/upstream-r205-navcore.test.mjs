// Upstream r201-r205 nav-core fixes, adopted in 205.1.
//
// Each item below is a fix BangL published in Iter r201-r205 that applies to our
// own 248.2 port unchanged. They are pinned here because the affected functions
// are engine-facing and cannot be exercised offline; the in-game checks are the
// watch digest, the `navdoors`/`navpath` harness probes and the T1-T5 smoke
// cards.
//
// A4  cached coarse paths must answer with the *current* search destination and
//     streamline with the current access position.
// A5  nav links make the neighbourhood asymmetric, so a segment state change
//     must rebuild every list that points at the changed segment.
// A6  the nav link itself knows the two segments it joins; a nav tracker at the
//     element position guessed them.
// A7  a nav link whose c_class is gone must not freeze the cop forever, and the
//     wait stamp must be dropped when the animation actually plays.
// A9  nav-link accounting must never compare a nil timestamp.
// A10 the congestion risk must stay a local.
// A11 nav-link access checks take the negative filter explicitly.

import assert from 'node:assert/strict';
import fs from 'node:fs';
import path from 'node:path';
import test from 'node:test';
import { fileURLToPath } from 'node:url';

const repoRoot = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..', '..', '..');
const nav = fs.readFileSync(path.join(repoRoot, 'lua', 'navigationmanager.lua'), 'utf8');
const walk = fs.readFileSync(path.join(repoRoot, 'lua', 'copactionwalk.lua'), 'utf8');

// Slice one top-level function body: from its header to the next top-level
// `function`/`Hooks:`/`local function` line.
function fn(source, header) {
  const start = source.indexOf(header);
  assert.ok(start >= 0, `\`${header}\` missing`);
  const rest = source.slice(start + header.length);
  const match = /\n(function |Hooks:|local function |end\n)/.exec(rest);
  return rest.slice(0, match ? match.index : rest.length);
}

function has(haystack, needle, label) {
  assert.ok(haystack.includes(needle), `${label}: expected \`${needle}\``);
}

function hasNot(haystack, needle, label) {
  assert.ok(!haystack.includes(needle), `${label}: unexpected \`${needle}\``);
}

function cacheHitBranch() {
  const header = 'if t - cached_result.t < self.itr_coarse_cache_lifetime then';
  const start = nav.indexOf(header);
  assert.ok(start >= 0, 'coarse cache hit branch missing');
  const end = nav.indexOf('\n\t\tend', start);
  assert.ok(end > start, 'cache hit branch unterminated');
  return nav.slice(start, end);
}

test('A4: the cached path takes the destination of the current search', () => {
  const hit = cacheHitBranch();

  has(hit, 'local end_pos = search_data.to_pos or (self._nav_segments[end_i_seg] and self._nav_segments[end_i_seg].pos)', 'A4 cache');
  // A cache entry without a usable destination must not answer with the stale
  // endpoint: the branch falls through to a real search instead.
  has(hit, 'if end_pos then', 'A4 cache');
  has(hit, 'result[#result][2] = end_pos', 'A4 cache');
  has(hit, 'search_cache_unusable', 'A4 cache');
  has(hit, 'self:itr_streamline(result, access_pos)', 'A4 cache');
});

test('A4: the computed path is streamlined with the access position', () => {
  const search = fn(nav, 'function NavigationManager:itr_execute_coarce_search(search_data)');

  has(search, 'self:itr_streamline(result, access_pos)', 'A4 search');
  hasNot(search, 'self:itr_streamline(result)', 'A4 search');
});

test('A5: a segment state change refreshes every referencing segment', () => {
  const body = fn(nav, 'function NavigationManager:set_nav_segment_state(id, ...)');

  has(body, 'for navseg_id, navseg in pairs(self._nav_segments) do', 'A5');
  has(body, 'if navseg_id == unique_id or (navseg.neighbours and navseg.neighbours[unique_id]) then', 'A5');
  has(body, 'self:itr_make_neighbours_list(navseg_id)', 'A5');
});

test('A6: register_anim_nav_link reads the segments from the nav link', () => {
  const body = fn(nav, 'function NavigationManager:register_anim_nav_link(element)');

  has(body, 'nav_link:start_nav_segment()', 'A6');
  has(body, 'nav_link:end_nav_segment()', 'A6');
  has(body, 'values.itr_from_navseg = from_seg', 'A6');
  has(body, 'values.itr_to_navseg = to_seg', 'A6');
  // The tracker guess is gone.
  hasNot(body, 'create_nav_tracker', 'A6');
});

test('A7: a dead nav link no longer blocks the animation', () => {
  const body = fn(walk, 'function CopActionWalk:itr_check_navlink_delay(t)');

  has(body, 'if itr_alive_navpoint(navlink) then', 'A7 delay');
  assert.ok(
    /else\s*\n\s*--[\s\S]*?\n\s*return true/.test(body),
    'A7 delay: missing `else return true` for a dead nav link',
  );
  // Observe when this path is taken: vanilla `_upd_nav_link` touches c_class in
  // the branch taken only when the animation never started.
  has(body, "Iter.diag.count('navlink_play_dead')", 'A7 delay');
});

test('A7: the wait stamp is dropped when the animation plays', () => {
  const body = fn(walk, 'function CopActionWalk:_play_nav_link_anim(t)');

  const clearAt = body.indexOf('self.itr_wait_for_navlink_availability_t = nil');
  const playAt = body.indexOf('itr_original_copactionwalk_playnavlinkanim(self, t)', clearAt);
  assert.ok(clearAt >= 0, 'A7 play: the wait stamp is never cleared before playing');
  // The early "queue off" return calls the same function, so look after the clear.
  assert.ok(playAt > clearAt, 'A7 play: the stamp must be cleared before the animation starts');
});

test('A9: nav-link accounting falls back to the game clock', () => {
  const body = fn(nav, 'function NavigationManager:itr_get_closest_door_to_pos(all_doors, door_list, pos_from, pos_to, access_pos, navlink_accounting)');

  has(body, 'itr_log_navlink_usage(through_navlink, t or TimerManager:game():time())', 'A9');
});

test('A10: the congestion risk is a local', () => {
  const body = fn(nav, 'function NavigationManager:itr_get_accessibility(door_list, access_pos, access_neg)');

  has(body, 'local congestion_risk = math_max(0, i_door:delay_time() - t)', 'A10');
});

test('A11: nav-link access checks pass the negative filter explicitly', () => {
  const doors = fn(nav, 'function NavigationManager:itr_get_closest_door_to_pos(all_doors, door_list, pos_from, pos_to, access_pos, navlink_accounting)');
  const navlinks = fn(nav, 'function NavigationManager:itr_find_best_navlink(segment1_id, segment2_id, access_pos, near_pos, current_navlink_element)');

  has(doors, 'i_door:check_access(access_pos, 0)', 'A11 door');
  has(navlinks, 'navlink:check_access(access_pos, 0)', 'A11 navlink');
});
