// Stale nav-link queue cache on a free link (the 239 s "wait" of 2026-10-26).
//
// Counterfeit (`pal`), Iter 200.7, harness 0.3, session sid `b2d8`:
//
//   12:16:22 diag link action=e_nl_jump_over_1m_var2 from=460 to=247
//            interval=1.00 queue=1 reserved=none wait=3.8
//   ... 38 consecutive samples, reserved=none, queue=1, wait climbing ...
//   12:16:50 ... wait=239.4
//   12:16:51 reserved=1150 wait=2.6      <- one poll later it reserves at once
//
// The alarm tier (`navlink_wait_long`) reported it. But the link had **no
// owner**: `queue=1` is a cached `itr_navlink_queue_length` and `wait` is
// `now - itr_navlink_queue_oldest_t`, both written only when a waiting unit
// polls. When that unit stops polling (repath, action swap, logic change) the
// cache freezes, so the log shows a waiter that is not there - while the cop
// itself never appeared in `diag cop` (no `itr_wait_for_navlink_availability_t`),
// i.e. it was not waiting any more at all.
//
// Fix: the queue fields are per-frame scratch data. When a link has no owner and
// its cache has not been refreshed for ITR_QUEUE_CACHE_TTL seconds, drop it. The
// reservation-order check then never reads a frozen `previous_oldest_t`, and the
// digest/alarm numbers describe reality.
//
// Runtime proof: a Counterfeit card must show no `diag link` sample with
// `reserved=none` and a `wait` older than a few seconds, and no
// `navlink_wait_long` alarm for a free link.

import assert from 'node:assert/strict';
import fs from 'node:fs';
import path from 'node:path';
import test from 'node:test';
import { fileURLToPath } from 'node:url';

const repoRoot = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..', '..', '..');
const nav = fs.readFileSync(path.join(repoRoot, 'lua', 'navigationmanager.lua'), 'utf8');

function sweepBody() {
  const start = nav.indexOf("Hooks:PostHook(NavigationManager, 'update', 'Iter_navlink_dead_sweep'");
  assert.ok(start >= 0, 'sweep posthook missing');
  const end = nav.indexOf('\nend)', start);
  assert.ok(end > start, 'sweep body unterminated');
  return nav.slice(start, end);
}

test('the cache lifetime is a named constant', () => {
  const match = /local ITR_QUEUE_CACHE_TTL = (\d+)/.exec(nav);
  assert.ok(match, 'ITR_QUEUE_CACHE_TTL missing');
  const value = Number(match[1]);
  assert.ok(value >= 1 && value <= 5, `unexpected cache TTL: ${value}`);
});

test('the sweep expires the cache of a free link only', () => {
  const body = sweepBody();

  // The expiry sits in an `elseif not user then` branch: an owned link keeps its
  // cache (that is the live reservation path).
  assert.match(body, /elseif not user then/, 'free-link branch missing');
  assert.match(body, /itr_navlink_queue_frame_t/, 'expiry must read the frame stamp');
  assert.match(body, /t - frame_t > ITR_QUEUE_CACHE_TTL/, 'expiry must compare against the TTL');
  assert.match(body, /navlink_queue_cache_cleared/, 'expiry counter missing');
  assert.match(body, /Iter\.diag\.event\('navlink_queue_cache'/, 'expiry event missing');

  // Every cached field is dropped together; a surviving oldest_t is exactly the
  // frozen value this fixes.
  for (const field of [
    'itr_navlink_queue_length',
    'itr_navlink_queue_length_in_progress',
    'itr_navlink_queue_frame_t',
    'itr_navlink_queue_oldest_t',
    'itr_navlink_queue_previous_oldest_t'
  ]) {
    assert.match(body, new RegExp(`element\\.${field} = nil`), `${field} must be dropped`);
  }
});

test('owned reservations still take the dead/stale path', () => {
  const body = sweepBody();
  assert.match(body, /if user then/, 'owner branch missing');
  // The free-link expiry must not run for an owned link.
  const ownerAt = body.indexOf('if user then');
  const freeAt = body.indexOf('elseif not user then');
  const expiryAt = body.indexOf('ITR_QUEUE_CACHE_TTL');
  assert.ok(ownerAt >= 0 && freeAt > ownerAt, 'branch order changed');
  assert.ok(expiryAt > freeAt, 'expiry must live in the free-link branch');
});

test('cache-expiry predicate truth table', () => {
  const TTL = Number(/local ITR_QUEUE_CACHE_TTL = (\d+)/.exec(nav)[1]);
  // JS mirror of `if not user then local frame_t = element.itr_navlink_queue_frame_t
  // if frame_t and t - frame_t > ITR_QUEUE_CACHE_TTL then clear end end`
  const expires = (user, frameT, t) => !user && frameT != null && t - frameT > TTL;

  assert.equal(expires(null, 100, 100 + TTL), false, 'fresh cache on a free link survives');
  assert.equal(expires(null, 100, 100 + TTL + 1), true, 'frozen cache on a free link expires');
  assert.equal(expires(null, null, 1000), false, 'a link that never queued stays untouched');
  assert.equal(expires({}, 100, 5000), false, 'an owned link keeps its cache');
});
