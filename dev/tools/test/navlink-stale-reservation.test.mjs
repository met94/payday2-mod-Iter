// Stale nav-link reservation sweep (live owner, never uses the link).
//
// Counterfeit (`pal`), Iter 200.4, harness 0.3, 2026-10-26 (sid 991e):
//
//   07:52:30 [ITER-TEST] diag cop key=... id=1151 logic=travel obj=defend_area
//            action=walk wait=iter=table: ... age=0.5 coarse=2/1   <- 1151 waits
//   07:52:32 [ITER-TEST] diag link ... action=e_nl_up_1_down_3m from=288 to=287
//            interval=2.00 queue=1 reserved=1151 wait=2.9           <- 1151 holds
//   ... 51 consecutive samples with reserved=1151, wait growing to 201.4
//   07:53:24 [ITER-NAV] evt=navlink_dead action=e_nl_up_1_down_3m from=288
//            to=287 wait=204.78963525391                           <- 1151 died
//
// 1151 was alive the whole time and never played the link: it took the
// reservation while it was itself blocked behind the same link (coarse=2/1,
// itr_wait_for_navlink set), then stopped engaging with it. 200.4 only clears
// reservations whose owner is dead, so the link stayed busy for ~205 s of sim
// time and every cop behind it waited. Same session: 191 distinct cops waited
// at links, mean 58.1 s, max 268 s, and only 2 of 1405 sampled cops were ever
// in the basement.
//
// Fix: a reservation is a token to pass the link, not a lock to park on. The
// holder refreshes `itr_reserved_t` only while it is actually at the link
// (CopActionWalk:_play_nav_link_anim runs every frame the walk action holds
// it), and the once-per-second sweep clears a live reservation that has not
// been refreshed for longer than ITR_RESERVED_STALE_T. The owner re-reserves
// when it arrives, in queue order, so nothing deadlocks.
//
// Static checks only: Node cannot execute Lua and the engine userdata types
// only exist in-game. Runtime proof is the Counterfeit (`pal`) card: no
// `[ITER-NAV] evt=navlink_stale`, no link with `reserved=<id>` and a
// monotonically growing `wait` past ~15 s, and cops reaching the basement.

import assert from 'node:assert/strict';
import fs from 'node:fs';
import path from 'node:path';
import test from 'node:test';
import { fileURLToPath } from 'node:url';

const repoRoot = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..', '..', '..');
const read = (...parts) => fs.readFileSync(path.join(repoRoot, ...parts), 'utf8');

// Strip line comments and long comments/strings so a commented-out clear or a
// quoted snippet cannot satisfy a check. Mirrors navlink-dead-reservation.test.mjs.
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

function sliceFrom(code, startNeedle, endNeedle) {
  const start = code.indexOf(startNeedle);
  assert.ok(start >= 0, `missing: ${startNeedle}`);
  const end = code.indexOf(endNeedle, start + startNeedle.length);
  assert.ok(end > start, `unterminated block: ${startNeedle}`);
  return code.slice(start, end);
}

const navCode = stripLuaComments(read('lua', 'navigationmanager.lua'));
const walkCode = stripLuaComments(read('lua', 'copactionwalk.lua'));

test('both grant sites stamp the reservation time', () => {
  const reserve = sliceFrom(walkCode, 'function CopActionWalk:itr_reserve_navlink(', '\n\tend');
  assert.match(
    reserve,
    /navlink_element\.itr_reserved_by_unit = self\._unit\s*\n\s*navlink_element\.itr_reserved_t = /,
    'itr_reserve_navlink must stamp itr_reserved_t when it grants'
  );

  const switchBody = sliceFrom(
    walkCode,
    'function CopActionWalk:itr_switch_to_sibling_navlink(',
    '\n\tend'
  );
  assert.match(
    switchBody,
    /alt_navlink_element\.itr_reserved_by_unit = self\._unit\s*\n\s*alt_navlink_element\.itr_reserved_t = /,
    'itr_switch_to_sibling_navlink must stamp itr_reserved_t when it grants'
  );
});

test('the holder refreshes the stamp only while it is at the link', () => {
  // _play_nav_link_anim runs every frame the walk action holds the nav link.
  const play = sliceFrom(walkCode, 'function CopActionWalk:_play_nav_link_anim(', '\n\tend');
  assert.match(
    play,
    /itr_reserved_by_unit[\s\S]{0,120}key\(\) == self\._unit:key\(\)/,
    'the refresh must only happen for the owning unit'
  );
  assert.match(play, /itr_reserved_t = self\._last_upd_t/, 'the holder must refresh itr_reserved_t');
});

test('the sweep clears a live reservation that stopped being used', () => {
  const body = sliceFrom(
    navCode,
    "Hooks:PostHook(NavigationManager, 'update', 'Iter_navlink_dead_sweep'",
    '\nend)'
  );

  // One predicate, one clear site: dead owner OR stale live owner.
  assert.match(body, /local dead = /, 'dead predicate missing');
  assert.match(body, /itr_reserved_by_unit/, 'the sweep must read the owner');
  assert.match(body, /itr_reserved_t/, 'the sweep must read the stamp');
  assert.match(body, /ITR_RESERVED_STALE_T/, 'the stale limit must be a named constant');
  assert.match(body, /navlink_stale_reservation_cleared/, 'stale counter missing');
  assert.match(body, /Iter\.diag\.event\('navlink_stale'/, 'stale event missing');
  assert.match(body, /Iter\.diag\.count\('navlink_dead_reservation_cleared'\)/, 'dead counter lost');

  // Every cleared reservation drops the stamp as well, so the next grant starts
  // from a clean element.
  assert.equal(
    (body.match(/itr_reserved_t = nil/g) || []).length,
    1,
    'the stamp must be cleared exactly once, at the single clear site'
  );

  // A nil stamp (reservation made before this build, or a level reload) is
  // adopted, never cleared on sight.
  assert.match(body, /if not stamp then/, 'missing stamp must be adopted');
});

test('stale limit is a named file-local constant', () => {
  assert.match(navCode, /local ITR_RESERVED_STALE_T = \d+/, 'ITR_RESERVED_STALE_T missing');
  const value = Number(/local ITR_RESERVED_STALE_T = (\d+)/.exec(navCode)[1]);
  // Longer than any single nav-link interval (menu max is a few seconds) and
  // short enough that a parked cop cannot own a link for minutes.
  assert.ok(value >= 10 && value <= 30, `unexpected stale limit: ${value}`);
});

test('stale-reservation predicate truth table', () => {
  // JS mirror of the sweep decision.
  const STALE_T = Number(/local ITR_RESERVED_STALE_T = (\d+)/.exec(navCode)[1]);
  const shouldClear = (user, stamp, t) => {
    if (!user) return false;
    if (!user.alive() || user.id() === -1) return true;
    if (stamp == null) return false;
    return t - stamp > STALE_T;
  };

  const live = { alive: () => true, id: () => 1151 };
  const deadUnit = { alive: () => false, id: () => 1099 };

  assert.equal(shouldClear(null, 100, 200), false, 'a free link stays free');
  assert.equal(shouldClear(live, 100, 110), false, 'a refreshed live hold survives');
  assert.equal(shouldClear(live, 100, 100 + STALE_T), false, 'exactly at the limit is still in use');
  assert.equal(shouldClear(live, 100, 100 + STALE_T + 1), true, 'a parked live cop loses the link');
  assert.equal(shouldClear(live, null, 1000), false, 'a missing stamp is adopted, not cleared');
  assert.equal(shouldClear(deadUnit, 100, 101), true, 'a dead owner is still cleared at once');
});
