// P7 dead-write invariant.
//
// 248.2 `_convert_nav_data_v5_to_v6` always builds v6 segments with an empty
// `neighbours` table, so every explicit `nav_segments[..].neighbours` write is
// discarded. Blocks whose topology survives through doors/quads must not carry
// those writes; the two accepted-loss blocks (moon, peta) keep theirs because
// the intended link is still missing and the applied_partial marker documents
// it. Mallcrasher is rewritten as a quad transfer, not a neighbour write.
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
  'watchdogs_1',
  'dinner',
  'flat'
];

const PENDING = ['moon', 'peta', 'skm_mallcrasher'];

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

const deadSource = source.match(/local dead_patches = \{([\s\S]*?)\n\}/);
const partialSource = source.match(/local partial_patches = \{([\s\S]*?)\n\}/);

assert.ok(deadSource, 'dead_patches table not found');
assert.ok(partialSource, 'partial_patches table not found');

const marked = (table, level) => new RegExp(`\\b${level}\\s*=\\s*true`).test(table);
const writeRe = /data\.nav_segments\[[^\]]+\]\.neighbours/;

test('surviving blocks carry no discarded neighbour writes', () => {
  for (const level of CLEAN) {
    const block = blockFor(level);
    assert.ok(
      !writeRe.test(block),
      `${level}: dead nav_segments.neighbours write is back; v6 discards it`
    );
    assert.ok(
      !marked(deadSource[1], level) && !marked(partialSource[1], level),
      `${level}: CLEAN block must not be in dead_patches/partial_patches`
    );
  }
});

test('dead/partial blocks keep their writes and their log marker', () => {
  for (const level of PENDING) {
    const block = blockFor(level);
    assert.ok(
      writeRe.test(block),
      `${level}: no nav_segments.neighbours write left; update PENDING and the P7 docs if the rewrite landed`
    );
    assert.ok(
      marked(deadSource[1], level) || marked(partialSource[1], level),
      `${level}: must be listed in dead_patches or partial_patches so the log status matches`
    );
  }
});
