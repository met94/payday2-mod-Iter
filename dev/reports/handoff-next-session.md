# Handoff — Iter full-nav port (next session)

Branch: `feat/iter-full-nav`
Worktree: `.worktrees/Iter-iter-full-nav`
Build: `dist/Iter` at `662834d` (`202-dev`)

## Where the port stands

Glossary and the Bomb id mapping: `dev/reports/p7-terminology.md`.
Short version: Dockyard = job `crojob1` / level `crojob2` (patched);
Forest = job `crojob2` / level `crojob3` (no patch).

Core navigation/AI port is **release-candidate complete**:

| Area | Status |
|---|---|
| v6 geometry shim | T1 PASS |
| Path streamline | T2/T2b PASS |
| Nav-link queue/reservations | T3 PASS |
| Iter coarse search + cache | T4 PASS |
| Direct-to-pos | T4 PASS |
| Path extender | implemented; **T5 pending** (no converted/chase run yet) |
| Map patches | 16 levels survive; 4 need rewrites; 1 dead |
| LIES compatibility | tested together during T1-T4; no Iter errors |

Static gates PASS; API audit baseline 12 expected errors, 12 scoped
suppressions, 0 unused. RC defaults: overlay/streamline/search/AI/navlink
queue/direct on; path extender and map patches off.

## What changed this session

- `!iter navpath <from> <to>` added to the dev harness: logs `level`,
  live `patches` setting, `ok`, `steps`, `length`, `direct` (door count on the
  link) and the segment `ids`. This is the P7 A/B tool from
  `dev/reports/p7-validation.md`.
- Path-extender observability: `path_extend_ok` / `path_extend_skip` counters
  in `CopBrain:clbk_pathing_results`; `!iter ai` prints them.
- T5 human card: `dev/test/cards/T5-extender.md` + `.json`.
- P7 card rewritten to a combined dump + A/B run:
  `dev/test/cards/P7-dumps.md`.
- P7 dead-write cleanup: the 16 `SURVIVES_AS_IS` blocks no longer carry the
  `nav_segments.neighbours` writes that 248.2 discards. The four partials and
  Mallcrasher keep theirs until rewrite. Guard:
  `dev/tools/test/p7-dead-writes.test.mjs`.
- Release docs refreshed to 16/4/1 and current RC defaults: `README.md`,
  `MENU_OPTIONS.md`, `dev/reports/compatibility-iter.md`,
  `dev/reports/workspace-investigation-draft.md`.

## Remaining work

### 1. P7 dumps + A/B for the last five levels

Card: `dev/test/cards/P7-dumps.md`.

Levels: `escape_street`, `jolly`, `moon`, `peta` (dumps + navpath A/B),
`skm_mallcrasher` (dumps only; patch is `skip_dead`).

Method and confidence levels: `dev/reports/p7-validation.md`.
Applying a patch is not proof of intent: verify topology from the dumps, then
compare `navpath` with patches on/off before calling P7 complete.

### 2. T5 path extender

Card: `dev/test/cards/T5-extender.md`.

Needs a run with a converted cop (Joker), an `is_important` unit, or chase
mode. Acceptance: `summary.path_extend_ok > 0`, no sliding, no stuck action.
Path extender is OFF by default; enable **Dev: path extender** and restart the
heist.

### 3. Release/merge

- Review docs: `MENU_OPTIONS.md`, `README.md`,
  `dev/reports/compatibility-iter.md`, P7 audit.
- Compatibility matrix: NavFixes must not run with Iter; The Fixes replaces
  `CopActionWalk._init` (path extender is off by default, so the conflict is
  dormant until T5); Keepers direct-to-pos smoke.
- Workspace doc draft: `dev/reports/workspace-investigation-draft.md`.
- Merge only on explicit user approval, then copy the investigation draft to
  `docs/investigations/iter-full-nav-port.md` and refresh
  `workspace.lock.json` + `CHANGELOG.md`.

## Open issues / risks

1. Probe `avg_len` was 0 despite 3 steps/path. `raw_positions`/
   `stream_positions` were added; the next probe run should explain it.
   AI movement was fine.
2. `[ITER-NAV] evt=patch` uses `applied`/`applied_partial`/`skip_dead`;
   `!iter patch` shows stats.
3. `map_patches` remains off by default; 16 levels are safe, 4 partial.
4. `nav_event` heartbeat every 30 s; `_clear` resets shim/cache/navlink maps.
5. LIES: Iter loads later and owns `_execute_coarce_search`; LIES cover
   search still runs. Re-check after a LIES update.
6. `skm_mallcrasher` still has dead neighbour writes and a `skip_dead` entry.
   Decide from the dump whether to retire it (`drop-log.md`) or rewrite as a
   door/quad edit.

## Session protocol

Start:

```powershell
cd D:\Programowanie\payday\2\v2\.worktrees\Iter-iter-full-nav
powershell -NoProfile -ExecutionPolicy Bypass -File dev\tools\gates.ps1
```

Then read `dev/progress.md` and this file. Pick P7 or T5. End: update
`dev/progress.md`, commit docs, write a new handoff if the session is long.

## Key commits

```
662834d chore: harness deploy hint
c6a8204 docs: refresh P7 status and release defaults
9cfaf38 P7: drop discarded neighbour writes from surviving blocks
c2b2fae feat: add navpath A/B command and path-extender counters
fca3be8 docs: record P7 validation method and confidence
d7c2f12 docs: explain P7 terms and confirm Bomb level ids
ca22c4a P7: confirm Dockyard survives via transfers
4d970c1 P7: correct Bomb mapping (Dockyard crojob2)
```
