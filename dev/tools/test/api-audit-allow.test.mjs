import test from 'node:test';
import assert from 'node:assert/strict';
import { auditText, renderReport } from '../api-audit.mjs';

const SYMBOLS = [
  { symbol: '_room_doors', severity: 'error', reason: 'removed in nav v6' }
];

test('auditText marks allowlisted findings as suppressed', () => {
  const source = 'local doors = self._room_doors[1]\n';
  const findings = auditText(source, {
    file: 'lua/shim.lua',
    symbols: SYMBOLS,
    allow: { 'lua/shim.lua': { _room_doors: 'sanctioned rebuild point' } }
  });
  assert.equal(findings.length, 1);
  assert.equal(findings[0].suppressed, true);
});

test('renderReport excludes suppressed findings from error counts', () => {
  const md = renderReport({
    targetRev: 'e3a8b616',
    hookChecks: [],
    hookMethodChecks: [],
    findings: [
      {
        file: 'lua/shim.lua',
        line: 1,
        symbol: '_room_doors',
        severity: 'error',
        reason: 'gone',
        text: 'self._room_doors',
        suppressed: true
      }
    ],
    allowUsage: [{ file: 'lua/shim.lua', symbol: '_room_doors', used: true }]
  });
  assert.match(md, /errors: 0/i);
  assert.match(md, /suppressed \(allowlisted\): 1/i);
  assert.match(md, /used .*lua\/shim\.lua/);
});
