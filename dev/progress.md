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
- Next: user runs T0/T1; implementation continues with S-01 (segment doors on
  quads) and S-02 (flood/contiguity/choke).

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
