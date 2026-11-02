// Upstream r204 map-data resync, adopted in 205.1.
//
// The shipped v5 nav data of four levels changed with the U247+ updates, so the
// r200 CRC signatures and the room/door ids inside those blocks no longer match
// the data the game hands to `set_load_data`. The CRC gate then logs `mismatch`
// and the block is skipped - silently, because a mismatch is a normal outcome.
//
// Upstream Iter r204 (BangL) republished those four blocks against the current
// data: new signatures plus remapped ids. This test pins the adopted values so a
// future merge cannot quietly restore the r200 ones.
//
// The signatures cannot be recomputed offline (the .nav bundles are binary), so
// the in-game confirmation is the `patch result=applied` event per level:
// branchbank, firestarter_1, gallery/framing_frame_1, mex.
//
// Second half: `append_vis_group` wrote nav segment ids into `vis_groups`. The
// 248.2 converter copies those keys into the v6 `visible_groups` array, where
// the engine reads them as indices into `data.vis_groups` - a segment id (63,
// 100, 150) is an out-of-range index. r204 switched to the group index.

import assert from 'node:assert/strict';
import fs from 'node:fs';
import path from 'node:path';
import test from 'node:test';
import { fileURLToPath } from 'node:url';

const repoRoot = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..', '..', '..');
const source = fs.readFileSync(path.join(repoRoot, 'lua', '_navdatapatches.lua'), 'utf8');

function block(level) {
  const marker = `level_id == '${level}'`;
  const start = source.indexOf(marker);
  assert.ok(start >= 0, `patch block for ${level} missing`);
  const next = source.indexOf('elseif level_id ==', start + marker.length);
  return source.slice(start, next < 0 ? source.length : next);
}

function sig(level) {
  const match = new RegExp(`^\\t${level} = (-?\\d+),$`, 'm').exec(source);
  assert.ok(match, `nav_data_sigs entry for ${level} missing`);
  return Number(match[1]);
}

function has(haystack, needle, label) {
  assert.ok(haystack.includes(needle), `${label}: expected \`${needle}\``);
}

function hasNot(haystack, needle, label) {
  assert.ok(!haystack.includes(needle), `${label}: stale \`${needle}\``);
}

test('the four resynced levels carry the r204 signatures', () => {
  assert.equal(sig('branchbank'), -1119519727, 'branchbank signature');
  assert.equal(sig('firestarter_1'), -1378527392, 'firestarter_1 signature');
  assert.equal(sig('gallery'), 697226673, 'gallery signature');
  assert.equal(sig('mex'), 59608889, 'mex signature');
});

test('the r200 signatures are gone', () => {
  // A stale signature is indistinguishable from a legitimate mismatch at
  // runtime, so the old numbers must not survive the adoption.
  for (const stale of ['-115776117', '952805177', '1380658305', '-415457450']) {
    assert.ok(
      !new RegExp(`^\\t\\w+ = ${stale},$`, 'm').test(source),
      `stale signature ${stale} still in the table`,
    );
  }
});

test('branchbank uses the remapped room and door ids', () => {
  const body = block('branchbank');

  has(body, 'local rid = 470', 'branchbank');
  has(body, 'local did = 863', 'branchbank');
  has(body, 'room_borders_x_pos[427] = -130', 'branchbank');

  for (const id of [423, 472, 427, 294, 333]) {
    has(body, `, ${id}, rid)`, `branchbank door ${id}`);
  }

  for (const stale of ['local rid = 551', 'local did = 999', 'room_borders_x_pos[508]', ', 504, rid)', ', 553, rid)', ', 375, rid)', ', 414, rid)']) {
    hasNot(body, stale, 'branchbank');
  }
});

test('firestarter_1 uses the remapped quad ids', () => {
  const body = block('firestarter_1');

  has(body, 'room_borders_x_pos[572] = -12', 'firestarter_1');
  has(body, 'room_borders_y_neg[572] = 159', 'firestarter_1');
  has(body, 'append_door(Vector3(-13, 159, 21.98), Vector3(-12, 159, 21.98), 572, 1120)', 'firestarter_1');

  hasNot(body, '576', 'firestarter_1');
  hasNot(body, '1124', 'firestarter_1');
});

test('gallery moves the nine quads to their current ids', () => {
  const body = block('gallery');

  for (const id of [807, 808, 819, 820, 821, 822, 830, 832, 833]) {
    has(body, `[${id}] = true`, `gallery quad ${id}`);
  }

  for (const stale of [858, 859, 870, 871, 872, 873, 881, 883, 884]) {
    hasNot(body, `[${stale}] = true`, 'gallery');
  }
});

test('mex transfers the current rooms', () => {
  const body = block('mex');

  for (const id of [3883, 3891, 3882, 3871, 3880, 3874, 3864, 3873]) {
    has(body, `transfer_room(${id}, 235, 192)`, `mex room ${id}`);
  }
  has(body, 'transfer_room(2602, 214, 192)', 'mex room 2602');

  for (const stale of [3908, 3916, 3907, 3896, 3906, 3899, 3889, 3898, 2627]) {
    hasNot(body, `transfer_room(${stale},`, 'mex');
  }
});

test('append_vis_group registers the new group by index, not by segment id', () => {
  const start = source.indexOf('append_vis_group = function');
  assert.ok(start >= 0, 'append_vis_group missing');
  const body = source.slice(start, source.indexOf('\n\tend,', start));

  // Index of the group being appended: #data.vis_groups + 1.
  has(body, 'local i_vg = #data.vis_groups + 1', 'append_vis_group');
  // Existing groups must learn about the new group by index.
  has(body, 'v.vis_groups[i_vg] = true', 'append_vis_group');
  // The new group lists the existing groups by their own indices.
  has(body, 'vg.vis_groups[k] = true', 'append_vis_group');
  // Deliberate deviation from r204: no self-reference. The game's own builder
  // never lists a group in its own list (navfieldbuilder.lua:283, 442, 3293).
  hasNot(body, 'vg.vis_groups[i_vg] = true', 'append_vis_group');
  // The segment id must not leak into the visibility table.
  hasNot(body, 'vis_groups[navseg_id]', 'append_vis_group');
});
