// Dead nav-link reservation sweep (Counterfeit `pal` release blocker).
//
// Harness v0.2 evidence on 200.3 (Counterfeit `pal`):
//
//   [ITER-TEST] diag link action=e_nl_over_and_fwd_1m from=458 to=365
//     interval=1.00 queue=1 reserved=dead wait=363.7
//   action=e_nl_up_1_75m from=270 to=271 queue=1 reserved=dead wait=15.0
//   action=e_nl_jump_over_1m_var1 from=268 to=265 queue=5 reserved=dead wait=12.2
//   71 dead-link samples, max wait 375.8 s
//   navlink_reserve_busy=282373 navlink_switch_fail=282194
//   navlink_reserve_ok=1283
//
// A destroyed unit never runs CopActionWalk:on_exit, so
// itr_clear_navlink_reservation is never called for it. The stale
// itr_reserved_by_unit keeps the link busy forever, and the stale
// itr_navlink_queue_previous_oldest_t makes the r200 queue-order check
// (`if not oldest_t or wait_since_t <= oldest_t`) reject every later unit, so
// the link stays unreservable instead of merely delayed. That busy-wait storm
// on 200+ cops is the FPS drop.
//
// Fix: clear a dead reservation (unit fields only; nav-link/door userdata is
// not a unit) both where it is consumed (itr_reserve_navlink) and once per
// second in a NavigationManager.update posthook, so links nobody walks up to
// again are cleaned too. The queue-order check itself stays: with the stale
// timestamps gone it either passes immediately or defers to a live waiter that
// really is older.
//
// Static checks only: Node cannot execute Lua and the engine userdata types
// only exist in-game. Runtime proof is the Counterfeit (`pal`) card with
// harness v0.2: `diag link` must show no `reserved=dead`, the ITER-NAV summary
// must log `evt=navlink_dead`, and the basement/stairs queues plus the late
// session FPS drop must be gone.

import assert from 'node:assert/strict';
import fs from 'node:fs';
import path from 'node:path';
import test from 'node:test';
import { fileURLToPath } from 'node:url';

const repoRoot = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..', '..', '..');
const read = (...parts) => fs.readFileSync(path.join(repoRoot, ...parts), 'utf8');

// Strip line comments and long comments/strings so a commented-out clear or a
// quoted snippet cannot satisfy a check. Mirrors navlink-alive.test.mjs.
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

function countMatches(code, pattern) {
  return (code.match(pattern) || []).length;
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

const RESERVATION_FIELDS = [
  'itr_reserved_by_unit',
  'itr_navlink_queue_frame_t',
  'itr_navlink_queue_oldest_t',
  'itr_navlink_queue_previous_oldest_t'
];

// The only condition allowed to drop a reservation: the owning unit is gone.
const DEAD_GUARD = /if user and \(not alive\(user\) or user:id\(\) == -1\) then/;

test('itr_reserve_navlink clears a dead reservation before reserving', () => {
  const body = sliceFrom(walkCode, 'function CopActionWalk:itr_reserve_navlink(', '\n\tend');

  // Dead user only: a live user's reservation is never dropped here.
  assert.match(body, DEAD_GUARD, 'itr_reserve_navlink must gate the clear on a dead unit');

  // The pre-fix shape indexed a nil user through alive(user) and then decided
  // to keep the link busy forever on the stale oldest_t check.
  assert.doesNotMatch(
    body,
    /if not alive\(user\) or user:id\(\) == -1 then/,
    'the unguarded dead-user branch must be gone'
  );

  // The interval-0 fast path and the wait-since setup stay above the change.
  assert.match(body, /if navlink_element\._values\.itr_interval == 0 then/);
  assert.match(body, /local wait_since_t = self\.itr_wait_for_navlink_availability_t/);

  // All four fields are cleared, in the dead branch.
  for (const field of RESERVATION_FIELDS) {
    assert.equal(
      countMatches(body, new RegExp(`navlink_element\\.${field} = nil`, 'g')),
      1,
      `${field} must be cleared exactly once in itr_reserve_navlink`
    );
  }

  // Order: guard -> clear reservation -> (other fields) -> reserve.
  const guardAt = body.search(DEAD_GUARD);
  const clearAt = body.indexOf('navlink_element.itr_reserved_by_unit = nil');
  const reserveAt = body.indexOf('navlink_element.itr_reserved_by_unit = self._unit');
  assert.ok(guardAt >= 0 && clearAt > guardAt, 'the dead reservation must be cleared after the guard');
  assert.ok(reserveAt > clearAt, 'the clear must happen before the new reservation');

  // `user = nil` makes the following `if not user` branch do the reserving.
  assert.match(body, /Iter\.diag\.count\('navlink_dead_reservation_cleared'\)\s*\n\s*user = nil/);
  assert.match(body, /if not user then/);
  assert.match(body, /Iter\.diag\.count\('navlink_reserve_ok'\)/);
  assert.match(body, /Iter\.diag\.count\('navlink_reserve_busy'\)/);

  // The r200 queue-order check survives; the stale oldest_t it reads is gone,
  // so a cleared link is immediately reservable.
  assert.match(body, /local oldest_t = navlink_element\.itr_navlink_queue_previous_oldest_t/);
});

test('NavigationManager.update sweeps dead reservations once per second', () => {
  assert.match(
    navCode,
    /Hooks:PostHook\(NavigationManager, 'update', 'Iter_navlink_dead_sweep', function\(self, t\)/,
    'dead-reservation sweep posthook missing'
  );

  const body = sliceFrom(
    navCode,
    "Hooks:PostHook(NavigationManager, 'update', 'Iter_navlink_dead_sweep'",
    '\nend)'
  );

  // Throttle: at most one pass per second of sim time; the deadline is a
  // file-local reset by the _clear posthook (level timer may restart at 0).
  assert.match(navCode, /local itr_next_dead_sweep_t = 0/);
  assert.match(
    navCode,
    /Hooks:PostHook\(NavigationManager, '_clear', 'Iter_nav_shim_clear'[\s\S]*?itr_next_dead_sweep_t = 0/
  );
  assert.match(body, /if t < itr_next_dead_sweep_t then\s*\n\s*return/);
  assert.match(body, /itr_next_dead_sweep_t = t \+ 1/);

  // Iterates the file-local nav-link map registered by register_anim_nav_link.
  assert.match(body, /for _, element in pairs\(_navlink_elements\) do/);

  // 200.5 supersedes the narrow dead-only guard with one predicate: a dead
  // owner is always cleared, a live owner only when its reservation stamp is
  // stale (see navlink-stale-reservation.test.mjs). The dead half must stay.
  assert.match(body, /local dead = \(not alive\(user\) or user:id\(\) == -1\)/, 'the sweep must clear dead owners');

  // Queue fields are also dropped by the free-link cache expiry (200.8), so they
  // may appear twice: once with the cleared reservation, once with the cache.
  for (const field of RESERVATION_FIELDS) {
    const count = countMatches(body, new RegExp(`element\\.${field} = nil`, 'g'));
    const expected = field === 'itr_reserved_by_unit' ? 1 : 2;
    assert.equal(count, expected, `${field} must be cleared ${expected}x in the sweep`);
  }

  // Diagnostics: counter for the summary, one event per cleared link.
  assert.match(body, /Iter\.diag\.count\('navlink_dead_reservation_cleared'\)/);
  assert.match(body, /Iter\.diag\.event\('navlink_dead', \{/);
  assert.match(body, /action = action/);
  assert.match(body, /from = element\._values and element\._values\.itr_from_navseg/);
  assert.match(body, /to = element\._values and element\._values\.itr_to_navseg/);
  assert.match(body, /wait = wait/);

  // Order: predicate -> clear -> report.
  const deadAt = body.search(/local dead = \(not alive\(user\) or user:id\(\) == -1\)/);
  const clearAt = body.indexOf('element.itr_reserved_by_unit = nil');
  const eventAt = body.search(/Iter\.diag\.event\('navlink_dead'/);
  assert.ok(deadAt >= 0 && clearAt > deadAt, 'the sweep clear must sit behind the liveness predicate');
  assert.ok(eventAt > clearAt, 'the navlink_dead event must be emitted after the clear');

  // No unguarded (live-inclusive) clearing in the sweep.
  assert.equal(
    countMatches(body, /element\.itr_reserved_by_unit = nil/g),
    1,
    'exactly one clear site, behind the dead-or-stale predicate'
  );
});

test('units stay on the game alive() helper (no itr_alive for units)', () => {
  // `user` is always a unit (CopActionWalk sets it from self._unit), so the
  // door/nav-link itr_alive helper does not apply here.
  assert.doesNotMatch(walkCode, /itr_alive\(user\)/);
  assert.doesNotMatch(navCode, /itr_alive\(user\)/);
  assert.doesNotMatch(navCode, /itr_alive\(element\.itr_reserved_by_unit\)/);
});

test('dead-reservation predicate truth table', () => {
  // JS mirror of `user and (not alive(user) or user:id() == -1)`.
  // Documents that a live owner is never swept; the authoritative proof is the
  // in-game Counterfeit (`pal`) card.
  const dead = (user) => Boolean(user) && (!user.alive() || user.id() === -1);

  const live = { alive: () => true, id: () => 100234 };
  const destroyed = { alive: () => false, id: () => 100235 };
  const destroying = { alive: () => true, id: () => -1 };

  assert.equal(dead(null), false, 'a free link stays free');
  assert.equal(dead(undefined), false, 'a free link stays free');
  assert.equal(dead(live), false, 'a live reservation must survive the sweep');
  assert.equal(dead(destroyed), true, 'a destroyed unit loses its reservation');
  assert.equal(dead(destroying), true, 'a unit reporting id -1 is treated as dead');
});
