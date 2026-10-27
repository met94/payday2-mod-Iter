// Iter watch channel: opt-in digest + always-on hard-failure alarms.
//
// Why it exists: the Counterfeit nav-link fault of 2026-10-26 was only visible
// because the dev harness was installed (one cop held a link 204.8 s). A release
// build with diag off leaves nothing behind, so this channel adds a bounded,
// self-silencing recorder: one digest line per minute when the player opts in,
// plus alarms that only fire on hard failures.
//
// Runtime proof is a Counterfeit card (see TEST-RESULTS.md): zero WATCH lines
// with watch_log=false on a healthy level, header + digests with it on, and an
// alarm path exercised by the dev harness.

import assert from 'node:assert/strict';
import fs from 'node:fs';
import path from 'node:path';
import test from 'node:test';
import { fileURLToPath } from 'node:url';

const repoRoot = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..', '..', '..');
const read = (...parts) => fs.readFileSync(path.join(repoRoot, ...parts), 'utf8');

const core = read('lua', 'corecode.lua');
const diag = read('lua', 'iter_diag.lua');
const nav = read('lua', 'navigationmanager.lua');

test('heap size is reported and the final is idempotent', () => {
  assert.match(nav, /lua_kb = math\.floor\(collectgarbage\('count'\)\)/, 'lua heap missing from digest');
  assert.match(nav, /if itr_watch_final_done then\s*\n\s*return/, 'final must be idempotent');
  assert.match(nav, /function NavigationManager:itr_watch_final\(\)/, 'menu fallback entry point missing');

  // The menu fallback exists, is hooked, and is registered in mod.txt.
  const menu = fs.readFileSync(path.join(repoRoot, 'lua', 'iter_watch_menu.lua'), 'utf8');
  assert.match(menu, /Hooks:PostHook\(MenuManager, 'open', 'Iter_watch_menu_final'/, 'menu hook missing');
  assert.match(menu, /managers\.navigation\.itr_watch_final/, 'menu hook must call the manager entry point');
  const modTxt = fs.readFileSync(path.join(repoRoot, 'mod.txt'), 'utf8');
  assert.match(modTxt, /"script_path"\s*:\s*"lua\/iter_watch_menu\.lua"/, 'hook not declared in mod.txt');
});

test('frame pacing uses wall clock and detects a time multiplier', () => {
  // Application:time() is scaled by the game's time multiplier, so it cannot
  // measure the multiplier. os.time() is the wall clock.
  assert.match(nav, /wall_s = os\.time\(\) - itr_watch_window_wall_s0/, 'sim ratio must use os.time()');
  assert.match(nav, /fps_real = frames \/ wall_s/, 'real frame rate must be derived from the wall window');
  assert.match(nav, /evt=alarm|diag\.alarm\('sim_timescale'/, 'a time multiplier must raise an alarm');
  assert.match(nav, /sim_timescale/, 'sim_timescale alarm missing');
  assert.match(nav, /ratio > 1\.2 or sim_ratio < 0\.8/, 'alarm threshold missing');
});

test('player speed and timer multipliers are reported', () => {
  // The 2026-10-27 session showed 122-126 fps with zero hitches while the
  // player still felt heavy after a 16x phase, so the digest has to prove
  // whether the local player actually moves slower and whether the player /
  // animation timers kept a multiplier while the game timer was back at 1x.
  assert.match(nav, /pspd_max/, 'player speed missing from the digest');
  assert.match(nav, /timer_multiplier|tmul_player/, 'timer multipliers missing');
  assert.match(nav, /itr_watch_timer_mul\('player'\)/, 'player timer not probed');
  assert.match(nav, /itr_watch_timer_mul\('game_animation'\)/, 'animation timer not probed');
});

test('watch_log is opt-in and off by default', () => {
  assert.match(core, /watch_log = false,/, 'watch_log must default to false');
  assert.match(core, /watch_log = tostring\(Iter\.settings\.watch_log\)/, 'boot event should record the switch');
});

test('the digest is gated, the alarm is not', () => {
  const watch = /function D\.watch\(event_name, fields\)[\s\S]*?\nend/.exec(diag);
  assert.ok(watch, 'D.watch missing');
  assert.match(watch[0], /if not D\.watch_enabled\(\) then\s*\n\s*return/, 'digest must be gated');
  assert.match(watch[0], /\[ITER-WATCH\]/, 'digest prefix missing');

  const alarm = /function D\.alarm\(name, fields, now\)[\s\S]*?\nend/.exec(diag);
  assert.ok(alarm, 'D.alarm missing');
  assert.doesNotMatch(alarm[0], /watch_enabled/, 'alarms must not be gated by the opt-in switch');
  assert.match(alarm[0], /evt=alarm/, 'alarm event missing');
});

test('alarms are rate limited per name and per level', () => {
  const alarm = /function D\.alarm\(name, fields, now\)[\s\S]*?\nend/.exec(diag)[0];
  assert.match(alarm, /D\.alarm_window = 60|D\.alarm_window/, 'window constant missing');
  assert.match(alarm, /if last and now - last < D\.alarm_window then/, 'per-name window missing');
  assert.match(alarm, /D\.alarm_budget_left = D\.alarm_budget_left - 1/, 'per-level budget missing');
  assert.match(alarm, /evt=alarm_budget_exhausted/, 'budget exhaustion must be reported');
  assert.match(diag, /function D\.watch_reset\(\)[\s\S]*?D\.alarm_budget_left = 20/, 'reset must restore the budget');
});

test('the per-frame hook only emits on the digest cadence', () => {
  const hook = nav.slice(nav.indexOf("Hooks:PostHook(NavigationManager, 'update', 'Iter_nav_watch'"));
  const body = hook.slice(0, hook.indexOf('\nend)'));
  assert.match(nav, /local ITR_WATCH_DIGEST_T = 60/, 'digest cadence must be 60 s');
  assert.match(body, /if t < itr_watch_next_t then\s*\n\s*return/, 'cadence gate missing');
  assert.match(body, /itr_watch_next_t = t \+ ITR_WATCH_DIGEST_T/, 'cadence not advanced');
  assert.match(body, /if Iter\.diag\.watch_enabled\(\) then\s*\n\s*itr_watch_digest\(t\)/, 'digest not gated in the hook');
  // Alarms live in the 1 s sweep, never in the per-frame hook.
  assert.doesNotMatch(body, /D\.alarm|diag\.alarm/, 'alarms must not run per frame');
});

test('the sweep raises the three hard-failure alarms', () => {
  for (const name of ['navlink_queue_long', 'navlink_wait_long', 'navlink_stale_burst']) {
    assert.match(nav, new RegExp(`diag\\.alarm\\('${name}'`), `${name} alarm missing`);
  }
  const sweep = nav.slice(nav.indexOf("Hooks:PostHook(NavigationManager, 'update', 'Iter_navlink_dead_sweep'"));
  const body = sweep.slice(0, sweep.indexOf('\nend)'));
  assert.match(body, /if t < itr_next_dead_sweep_t then\s*\n\s*return/, 'alarms must ride the 1 s sweep gate');
  assert.match(body, /queue_len > ITR_WATCH_QUEUE_LONG/, 'queue threshold missing');
  assert.match(body, /queue_len > 0 and wait > ITR_WATCH_WAIT_LONG/, 'wait threshold missing');
  assert.match(body, /itr_watch_stale_in_window > ITR_WATCH_STALE_BURST/, 'stale burst threshold missing');
});

test('the digest reports frame pacing and the simulation ratio', () => {
  // "100-144 fps but the game feels heavy" is frame pacing or a time-scale
  // change, not throughput, so the digest has to carry wall-clock frame data.
  assert.match(nav, /itr_watch_wall_sum/, 'no wall-clock accumulator');
  assert.match(nav, /itr_watch_hitches/, 'no hitch counter');
  assert.match(nav, /itr_watch_sim_ratio|sim_ratio/, 'no simulation-ratio field');
  assert.match(nav, /Application:time\(\)/, 'wall clock must come from Application:time()');
  // Frame data is emitted with the digest.
  assert.match(nav, /fps = /, 'digest must report fps');
  assert.match(nav, /hitch_n = /, 'digest must report the hitch count');
});

test('final digest fires on level teardown too', () => {
  // Forward declaration must precede the _clear posthook, or the call is nil.
  const decl = nav.indexOf('local itr_watch_final');
  const clearHook = nav.indexOf("'Iter_nav_shim_clear'");
  assert.ok(decl >= 0, 'itr_watch_final must be forward-declared');
  assert.ok(clearHook > decl, 'forward declaration must come before the _clear posthook');

  const clear = nav.slice(clearHook);
  const body = clear.slice(0, clear.indexOf('\nend)'));
  assert.match(body, /if itr_watch_final then\s*\n\s*itr_watch_final\(\)/, 'teardown must emit the final digest');
  assert.match(body, /Iter\.diag\.watch_reset\(\)/, 'reset must follow the final digest');

  // The final digest is the same snapshot with a different event name.
  assert.match(nav, /itr_watch_digest\(t, event_name\)/, 'digest must take an event name');
  assert.match(nav, /itr_watch_digest\(itr_watch_window_t0 or 0, 'final'\)/, 'final event name missing');
});

test('header once per level and a final digest on simulation end', () => {
  assert.match(nav, /local itr_watch_header_done = false/, 'header flag missing');
  assert.match(nav, /if not itr_watch_header_done then\s*\n\s*itr_watch_header\(t\)/, 'header not once-per-level');
  assert.match(nav, /Iter\.diag\.watch\('header'/, 'header event missing');

  const ended = nav.slice(nav.indexOf("Hooks:PostHook(NavigationManager, 'on_simulation_ended', 'Iter_nav_summary'"));
  const body = ended.slice(0, ended.indexOf('\nend)'));
  assert.match(body, /itr_watch_final\(\)/, 'final digest missing');
  assert.match(body, /Iter\.diag\.watch_reset\(\)/, 'watch state not reset after the level');

  // A new level resets the channel with the other nav state.
  const clear = nav.slice(nav.indexOf("Hooks:PostHook(NavigationManager, '_clear', 'Iter_nav_shim_clear'"));
  const clearBody = clear.slice(0, clear.indexOf('\nend)'));
  assert.match(clearBody, /itr_watch_header_done = false/, 'header flag not reset on level change');
  assert.match(clearBody, /Iter\.diag\.watch_reset\(\)/, 'alarm budget not reset on level change');
});

test('state is declared before the _clear posthook that resets it', () => {
  const declared = nav.indexOf('local itr_watch_next_t = 0');
  const clearHook = nav.indexOf("'Iter_nav_shim_clear'");
  assert.ok(declared >= 0 && clearHook > declared, 'watch locals must exist before the _clear posthook');
});
