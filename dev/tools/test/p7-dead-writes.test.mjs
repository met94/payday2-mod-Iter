// P7 dead-write invariant.
//
// 248.2 `_convert_nav_data_v5_to_v6` always builds v6 segments with an empty
// `neighbours` table, so every explicit `nav_segments[..].neighbours` write is
// discarded. Blocks whose topology survives through doors/quads must not carry
// those writes; the four partial blocks and the dead Mallcrasher block keep
// theirs until they are rewritten (they are logged as applied_partial /
// skip_dead, so the log continues to tell the truth).
//
// This test fails when a cleaned block reintroduces a dead write, or when a
// pending block is cleaned without updating the lists below.

import assert from 'node:assert/strict';
import fs from 'node:fs';
import path from 'node:path';
import test from 'node:test';
import { fileURLToPath } from 'node:url';

const repoRoot = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..', '..', '..');
const sourcePath = path.join(repoRoot, 'lua', '_navdatapatches.lua');
const source = fs.readFileSync(sourcePath, 'utf8');
const lines = source.split(/\r?\n/);

const CLEAN = [
  'alex_2',
  'arm_fac',
  'arm_for',
  'big',
  'born',
  'branchbank',
  'chas',
  'crojob2',
  'escape_park',
  'escape_street',
  'firestarter_1',
  'framing_frame_1',
  'gallery',
  'jewelry_store',
  'jolly',
  'kenaz',
  'kosugi',
  'mex',
  'mia_1',
  'pbr',
  'roberts',
  'skm_mallcrasher',
  'watchdogs_1',
  'dinner',
  'flat'
];

const PENDING = ['moon', 'peta'];

function blockFor(level) {
  const start = lines.findIndex(line => line.includes(`level_id == '${level}'`));

  assert.notEqual(start, -1, `no patch block for ${level}`);

  let end = lines.length;

  for (let i = start + 1; i < lines.length; i++) {
    if (/^\s*elseif level_id ==/.test(lines[i]) || /^end\s*$/.test(lines[i])) {
      end = i;
      break;
    }
  }

  return lines.slice(start, end).join('\n');
}

test('surviving blocks carry no discarded neighbour writes', () => {
  for (const level of CLEAN) {
    const block = blockFor(level);
    assert.ok(
      !block.includes('neighbours'),
      `${level}: dead nav_segments.neighbours write is back; v6 discards it`
    );
  }
});

test('pending blocks still carry the dead writes that mark the rewrite work', () => {
  for (const level of PENDING) {
    const block = blockFor(level);
    assert.ok(
      block.includes('neighbours'),
      `${level}: no neighbour writes left; update PENDING and the P7 docs if the rewrite landed`
    );
  }
});
