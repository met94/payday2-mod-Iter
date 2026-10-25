import test from 'node:test';
import assert from 'node:assert/strict';
import { scanLog, renderReport, isOk, parseNavEvent, evaluateCard } from '../log-scan.mjs';

const LOG = `08:57:00 AM Lua: [INFO] [BLT] Setting up mod 'Iter Lite'
08:57:01 AM Lua: [INFO] [ITER-NAV] v=1 sid=7f3a evt=navdata segments=42 string_keys=42 missing_neighbours=0 rooms=120 room_doors=48
08:57:02 AM Lua: [INFO] [ITER-TEST] nav segments=42 covers=10
08:57:03 AM Lua: [ERROR] [Updates] Missing meta in provider 'meta_file'
08:57:04 AM Lua: Error: lib/managers/navigationmanager.lua:37: attempt to index a nil value (field '_room_doors')
stack traceback:
	lib/managers/navigationmanager.lua:37: in function 'find_segment_doors'
	lib/managers/navigationmanager.lua:50: in function 'update'
`;

test('scanLog finds setup, nav event, harness, Lua error, and Iter context', () => {
  const result = scanLog(LOG, { file: 'test.log', hookFiles: ['lib/managers/navigationmanager.lua'] });
  assert.equal(result.setup.length, 1);
  assert.equal(result.navEvents.length, 1);
  assert.equal(result.navEvents[0].evt, 'navdata');
  assert.equal(result.navEvents[0].segments, 42);
  assert.equal(result.harness.length, 1);
  assert.equal(result.luaErrors.length, 1);
  assert.equal(result.iterErrors.length, 1);
  assert.equal(result.ok, false);
  assert.equal(result.iterErrors[0].line, 5);
});

test('parseNavEvent numbers and strings', () => {
  const event = parseNavEvent('[ITER-NAV] evt=streamline steps_in=9 fail=none ok=1');
  assert.equal(event.evt, 'streamline');
  assert.equal(event.steps_in, 9);
  assert.equal(event.fail, 'none');
  assert.equal(event.ok, 1);
});

test('scanLog flags [ITER-ERR] as a failure', () => {
  const log = "Lua: [INFO] [BLT] Setting up mod 'Iter'\nLua: [ERROR] [ITER-ERR] where=shim msg=boom\n";
  const result = scanLog(log, { file: 'test.log' });
  assert.equal(result.iterErrors.length, 1);
  assert.equal(result.ok, false);
});

test('scanLog flags FATAL as failure', () => {
  const result = scanLog('Lua: FATAL ERROR: boom\n', { file: 'test.log' });
  assert.equal(result.fatal.length, 1);
  assert.equal(result.ok, false);
});

test('clean log is ok even with unrelated update noise', () => {
  const log = `08:57:00 AM Lua: [INFO] [BLT] Setting up mod 'Iter'
08:57:01 AM Lua: [ERROR] [Updates] Missing meta in provider 'meta_file'
`;
  const result = scanLog(log, { file: 'test.log' });
  assert.equal(result.ok, true);
  assert.equal(isOk(result, { strict: true }), true);
});

test('strict mode fails on non-Iter Lua errors', () => {
  const result = scanLog("Lua: [INFO] [BLT] Setting up mod 'Iter'\nLua: Error: attempt to call a nil value\n", { file: 'test.log' });
  assert.equal(result.ok, true);
  assert.equal(isOk(result, { strict: true }), false);
});

test('setup match does not count other Iter-derived standalone mods', () => {
  const result = scanLog("Lua: [INFO] [BLT] Setting up mod 'Iter''s Joker Tweaks Standalone'\n", { file: 'test.log' });
  assert.equal(result.setup.length, 0);
});

test('scanLog fails when Iter never loaded', () => {
  const result = scanLog("Lua: [INFO] [BLT] Setting up mod 'Other'\n", { file: 'test.log' });
  assert.equal(result.setup.length, 0);
  assert.equal(result.ok, false);
});

test('scanLog fails on harness ERROR lines', () => {
  const result = scanLog("Lua: [INFO] [BLT] Setting up mod 'Iter'\nLua: [INFO] [ITER-TEST] ERROR attempt to call a nil value\n", { file: 'test.log' });
  assert.equal(result.setup.length, 1);
  assert.equal(result.harnessErrors.length, 1);
  assert.equal(result.ok, false);
});

test('setup match does not count the test harness', () => {
  const result = scanLog("Lua: [INFO] [BLT] Setting up mod 'Iter Test Harness'\nLua: [INFO] [BLT] Setting up mod 'Iter'\n", { file: 'test.log' });
  assert.equal(result.setup.length, 1);
  assert.equal(result.ok, true);
});

test('scanLog does not mark errors before Iter setup as Iter errors', () => {
  const log = "Lua: Error: lib/managers/navigationmanager.lua:1: attempt to index a nil value\nLua: [INFO] [BLT] Setting up mod 'Iter'\n";
  const result = scanLog(log, { file: 'test.log', hookFiles: ['lib/managers/navigationmanager.lua'] });
  assert.equal(result.iterErrors.length, 0);
  assert.equal(result.ok, true);
});

test('evaluateCard passes and fails expectations', () => {
  const result = scanLog(LOG, { file: 'test.log', hookFiles: ['lib/managers/navigationmanager.lua'] });

  const pass = evaluateCard(result, {
    expect: {
      setup: true,
      'navdata.segments': 42,
      'navdata.missing_neighbours': 0,
      fallback: 0
    }
  });
  assert.equal(pass.pass, true);

  const fail = evaluateCard(result, {
    expect: {
      'navdata.segments': '>100',
      iterErrors: 0
    }
  });
  assert.equal(fail.pass, false);
});

test('renderReport contains counts, card, and line references', () => {
  const result = scanLog(LOG, { file: 'test.log', hookFiles: ['lib/managers/navigationmanager.lua'] });
  const card = evaluateCard(result, { expect: { 'navdata.segments': 42 } });
  const md = renderReport(result, card);
  assert.match(md, /Iter log scan/);
  assert.match(md, /test\.log/);
  assert.match(md, /setup: 1/i);
  assert.match(md, /Iter errors: 1/i);
  assert.match(md, /navigationmanager\.lua:37/);
  assert.match(md, /ITER-TEST/);
  assert.match(md, /Result: PASS/);
});
