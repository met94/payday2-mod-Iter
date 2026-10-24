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
- P7 wrapper implemented: per-call `select_patch(level_id)`, v5/CVR gate,
  helper prep, `evt=patch` with applied/mismatch/skip. Offline wrapper test
  (12 checks). Runtime CRC/apply status still to sample on Big Bank/Golden
  Grin.
- RC batch PASS: Biker D1 (`born` patch applied, 42 cops/16 travelling/23
  coarse, probe 13/13, no heist-end error) and Golden Grin (`kenaz` patch
  applied, 160 segments). No Iter errors.
- RC defaults set: overlay/streamline/search/AI/navlink-queue/direct on;
  path extender and map patches off. `202-dev`.
- P7 dumps resolved arm_for and crojob2 (Dockyard) as SURVIVES_AS_IS;
  dead neighbour writes removed. 16 levels now survive, 4 need rewrites
  (escape_street, jolly, moon, peta), Mallcrasher is dead-only.
- Session handoff for next context window:
  `dev/reports/handoff-next-session.md`.
- Next: collect remaining five P7 dumps, T5 path extender, release/merge.

## 2026-10-24 — session 2 (offline)

- P7 A/B tool added: `!iter navpath <from> <to>` logs level, live patch
  setting, ok/steps/length, direct door count and segment ids. Harness test
  covers success/fail/error/missing-segment (LuaJIT, PASS).
- P7 collection made automatic: the harness post-hooks
  `NavigationManager:on_simulation_started` and dumps the pending level's
  segments/doors/paths (plus a seal alternative) with `p7auto`. `!iter p7`
  forces a run, `!iter p7 auto off` disables it. Harness test covers the plan,
  header, seal alternative and the off switch.
- Runtime check found two blockers, both fixed: the harness loads before
  `NavigationManager` exists, so the first hook registration silently skipped
  (now retried from `LocalizationManagerPostInit` / `GameSetupUpdate`); and
  the standard Mallcrasher job reports level id `mallcrasher`, not
  `skm_mallcrasher` (alias added in `_navdatapatches.lua`, still `skip_dead`).
- First runtime pass (jolly/moon/peta/mallcrasher) produced patch/heist events
  but no dumps; needs a rerun with the redeployed harness.
- Manual `!iter p7` run on all five levels (patch on). Results:
  `dev/reports/p7-runtime-2026-10-24.md`. `escape_street` and `jolly` survive
  as-is (63<->48 is 2 navlinks; door 9410 links 87<->141 and 87's seal is
  inherent); dead writes removed, both now log `applied`. `moon` (23 isolated)
  and `peta` (53 isolated) need rewrites. `skm_mallcrasher` alias works, block
  is `skip_dead`; door 1526 carries 8<->11.
- Harness fix: Mallcrasher's plan has no `paths`, so `ipairs(nil)` ended the
  block with `p7auto ERROR nil`; defaults added.
- Peta/mallcrasher geometry checked: both doors sit exactly on the shared
  quad edge. Visibility cross-link tested on moon/peta: `see_fwd=1 see_rev=1`
  but the engine still does not derive the link, so visibility is **not** the
  gate. Moon/peta moved to accepted losses (`drop-log.md`).
- Mallcrasher id audit: the standard Vlad job (`mallcrasher`,
  `narratives/vlad/mallcrasher`, CRC `75811735`) and the skirmish stage
  (`skm_mallcrasher`, `narratives/skm/skm_mallcrasher`, CRC `598935744`) are
  **different heists**. The alias was reverted; the standard job logs
  `skip_nopatch`. The skirmish block keeps `transfer_room(943, 8, 11)` as an
  untested rewrite (`applied_partial`). Audit:
  `dev/reports/p7-level-id-audit.md`.
- Level-id audit found no other conflation: all patch/setting ids map to real
  level keys; `gallery` is a valid `deep_clone` of `framing_frame_1` with its
  own CRC; `_day`/`_night` stripping is intentional.
- Escape: Street is a random escape, not selectable in Crime.net. Added
  host-only `!iter force <level_id>` (tweak-data world name via
  `session():load_level`) so `escape_street` can be loaded from any heist.
- Path-extender observability: `path_extend_ok` / `path_extend_skip` counters
  in `CopBrain:clbk_pathing_results`; `!iter ai` prints `extend(ok, skip)`.
- Cards: new `dev/test/cards/T5-extender.{md,json}`; `P7-dumps.md` rewritten
  as dump + navpath A/B run with an explicit on/off reload order.
- P7 dead-write cleanup: all 16 `SURVIVES_AS_IS` blocks had their discarded
  `nav_segments.neighbours` writes removed (the four partials and Mallcrasher
  keep theirs until rewrite). New guard: `dev/tools/test/p7-dead-writes.test.mjs`.
- Release docs refreshed to the real P7 counts (16 survive / 4 rewrite / 1
  dead) and the RC defaults: README, MENU_OPTIONS, compatibility matrix,
  workspace investigation draft, changelog 202-dev bullet.
- Gates PASS (49 Node tests, harness test, 12+144 Lua checks, syntax,
  freevars, ledger 100 functions, audit 12/12 baseline, 0 unused).
- Ruling: navpath belongs to the dev harness only; no runtime cost, and the
  line records the live `map_patches` value so an A/B pair is self-describing.
  Cost if wrong: none (dev-only file, excluded from `dist/Iter`).
- Next: run the combined P7 card and the T5 card in one game session, then
  release/merge.

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
