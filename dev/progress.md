# SDD ledger — plan: dev/plans/full-nav-port.md

Worktree: `.worktrees/Iter-iter-full-nav` (branch `feat/iter-full-nav`).
Source: `98940fb` (Iter r200). Old baseline: `a3180fc` (246.1).
Target: `e3a8b616` (248.2).

## 2026-10-24 — session 1

- H-01 complete: worktree + r200 restore. Commit `7a8ccc5`.
  Ten files restored, nine hooks re-added. Master untouched.
- H-02 complete: LIES dev harness copied and adapted.
  - `dev/tools/*` labels and prefixes converted to Iter.
  - `log-scan` rewritten: `[ITER-NAV]` events, `[ITER-ERR]`, `Iter` setup,
    `--card` expectations.
  - `test-harness` rewritten: `!iter nav|patch|probe|path|ai|links|alarm|assault|state|setting|dump|reset`.
  - `build.ps1` rewritten for Iter runtime items.
  - `gates.ps1` report/ledger names adapted.
- Static checks:
  - `node --test dev/tools/test/log-scan.test.mjs`: 13/13 PASS.
  - `luajit dev/test-harness/test/test_commands.lua`: PASS.
  - `fn-ledger --old a3180fc --new e3a8b616`: 95 functions, 0 parse errors,
    33 clean mod edits, 54 mod-only, 7 vanilla-changed, 1 vanished.
  - `api-audit --new e3a8b616`: 17/17 hooks, 11 errors, 32 review.
- Safety: overlay gated off (`streamline_path=false`, `nav_core_dev=false`);
  `groupaistatebase` and nav overlay return before installing anything.
- H-03 complete: `Iter.diag` added (`lua/iter_diag.lua`), loaded from the
  corecode pre-hook. Events are `[ITER-NAV] v=1 sid=... evt=... k=v`;
  `[ITER-ERR]` is always emitted and fails log scans. `debug_log` defaults to
  1 on this dev branch.
- H-04 pending: baseline log card T0. Build `dbbd103` in `dist/Iter`, handoff
  written to `dev/reports/handoff-2026-10-24.md`.
- H-05 complete: `gates.ps1` PASS (45 Node tests, LuaJIT syntax, freevars,
  ledger, audit). API audit baseline 11 errors (unported nav).
- P1 started: 39 three-way dossiers generated in `dev/reports/dossiers/`.
- N-01 complete (commit `a7977f3`): v6 geometry shim (`lua/iter_nav_v6_shim.lua`),
  rebuild/clear hooks, offline Lua tests (137 checks), scoped api-audit
  allowlist with used-entry enforcement. Review PASS after one fix round.
- N-02 complete: string-key bookkeeping and guards in the nav overlay;
  feature split `nav_overlay` / `nav_streamline` / `nav_ai`; `evt=heist`
  post-hook. Gates PASS; audit errors still 11.
- S-01/S-02 implemented (awaiting runtime): shim door→segment-pair index;
  `itr_find_proxies` uses it; `itr_copy_door_data` from the shim;
  `itr_prepare_nav_data` after `_resolve_segment_neighbours` (host only) with
  `evt=proxy`; Vector3 door branches in door lookup/accessibility;
  `nav_search` split from `nav_streamline`.
  - Offline shim tests: 144 checks / 11 tests PASS.
  - Audit baseline 11 -> 12 (R6, one expected shim-backed `_room_doors` line).
- S-05 implemented: streamline-only CopBrain wrapper behind `nav_streamline`;
  `evt=heist` now carries string keys/missing neighbours; dev menu toggles for
  streamline/search/AI; probe emits `evt=probe`.
- L-01/L-02 implemented: nav-link element map registration/cleanup, interval
  derivation, interval buckets, `evt=navlink` end-of-simulation summary,
  nav-link queue dev toggle. Diagnostics only.
- S-04 implemented: Vector3-aware door alignment/closest-door selection,
  nav-link `alive()`/map guards, undefined `dis` removed.
- T1 PASS (Jewelry 40 seg / Big Bank 108 / Golden Grin 160): string keys,
  no missing neighbours, rooms/doors/vis groups rebuilt, fallback 0.
  Report: `dev/reports/smoke-t1-t2-2026-10-24.md`.
- T2 PASS (Jewelry): proxy choke=27 in=12 out=24; 37/37 streamline successes,
  0 streamline failures; avg path length -16.2% / -13.0%. One random
  unreachable pair in 20 accepted (probe now logs fail_from/fail_to).
- P4/P6 implemented (awaiting T3): nav-link reservation/queue/alternate
  methods, path extender, CopBrain/AI wrappers with sub-gates; dropped
  civilian/team-AI functions and `_optimize_path` (files inert, hooks
  removed, hook count 17 -> 14). `evt=summary` at simulation end.
- T3 first AI run: no Iter errors, navdata/proxy good on Hotline D1 and
  Biker D1; nav-link intervals derived. Card failed only because the harness
  AI diagnostic read the wrong enemy table and no heartbeat existed.
  Fixes: unit:brain diagnostic, 30 s heartbeat, boot flag logging, search
  and nav-link counters, cache clears.
- Combined T3/T4 run: Hotline D1 PASS (47 cops, 20 travelling, 27 coarse,
  prepare=514, reserve=2, search 133 ok/2 fail, cache 33); Jewelry stealth
  PASS (direct_to_pos=2, search 3/4). Big Bank `!iter probe 20` crashed:
  nav-link userdata passed to `mvector3` in `itr_get_closest_door_to_pos`.
  Fixed with `is_vec3` numeric x/y/z validation and position guards.
  Harness global `ITER` -> `Iter` fixed (`!iter dump/setting`).
- Big Bank probe verified: no crash; search 29/29, direct_to_pos 6. The 24
  streamline failures were probe double-streamlining; `itr_streamline` is now
  idempotent.
- T3 PASS, T4 PASS. Hotline D1: 47 cops, 20 travelling, 27 coarse paths,
  `navlink_prepare=514`, `reserve_ok=2`, search 133 ok / 2 fail, cache 33.
  Jewelry: `direct_to_pos=2`, search 3/4. Big Bank: crash fixed; probe
  search 29/29, direct_to_pos=6; streamline double-call fixed by making
  `itr_streamline` idempotent.
- P7 map patches deferred to the next session: per-call level selection and
  69 dead neighbour writes need a dedicated audit. Design card written.
- Session state: core nav/AI port is functional. Next: P7, then release
  candidate hardening.

## Rulings

- R1: use `a3180fc` as the old baseline for parsing; `b36f5fbb` restyle text
  fails luaparse in `coremissionmanager` and `groupaistatebase`. Content is
  identical. Cost if wrong: restyled body text in dossiers; no semantic drift.
- R2: harness copied from LIES is allowed (same author); provenance recorded in
  `dev/README.md`. Cost if wrong: none.

## Open

- H-03 `Iter.diag` logger.
- H-04 baseline log scan (Iter Lite, current live log).
- H-05 gates baseline (`gates.ps1` full run).
- P1 dossiers (nav first).
