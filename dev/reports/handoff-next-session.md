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
| Path extender | T5 PASS on counters; no visible slide/stuck |
| Map patches | 21 clean blocks (22 level ids), 2 accepted losses, 1 dead, 2 no-op |
| LIES compatibility | tested together during T1-T4; no Iter errors |

Static gates PASS; API audit baseline 12 expected errors, 12 scoped
suppressions, 0 unused. Release defaults: overlay/streamline/search/AI/
navlink queue/direct/path extender/map patches and `cop_idle_fix` on.

## What changed this session

- **P7 collection is automatic.** The harness post-hooks
  `NavigationManager:on_simulation_started`; loading one of the five pending
  levels logs `p7auto` + `navdump`/`navdoors`/`navpath` with the live
  `map_patches` state. `!iter p7` forces a re-run; `!iter p7 auto off`
  disables it. Hook registration is deferred to
  `LocalizationManagerPostInit`/`GameSetupUpdate` because the harness loads
  before `NavigationManager` exists.
- Mallcrasher id: the Vlad job reports `mallcrasher`; it is a **different
  heist** from `skm_mallcrasher` (different world/CRC) and stays unpatched
  (`skip_setting`). The skirmish block is `skip_dead`.
- `!iter force <level_id>` added for levels not in Crime.net:
  `!iter force escape_street` from any heist loads the escape narrative and
  the auto dump fires on simulation start.
- `!iter navpath <from> <to>` added to the dev harness: logs `level`,
  live `patches` setting, `ok`, `steps`, `length`, `direct` (door count on the
  link) and the segment `ids`. This is the P7 A/B tool from
  `dev/reports/p7-validation.md`.
- Path-extender observability: `path_extend_ok` / `path_extend_skip` counters
  in `CopBrain:clbk_pathing_results`; `!iter ai` prints them.
- T5 human card: `dev/test/cards/T5-extender.md` + `.json`.
- P7 card rewritten to a combined dump + A/B run:
  `dev/test/cards/P7-dumps.md`.
- P7 dead-write cleanup: the 21 clean blocks (22 level ids) no longer carry
  the `nav_segments.neighbours` writes that 248.2 discards. `moon`/`peta` keep
  theirs as accepted losses; `skm_mallcrasher` is `skip_dead`. Guard:
  `dev/tools/test/p7-dead-writes.test.mjs`.
- Release docs refreshed to 21 clean blocks / 2 accepted losses / 1 dead /
  2 no-op and current RC defaults: `README.md`, `MENU_OPTIONS.md`,
  `dev/reports/compatibility-iter.md`,
  `dev/reports/workspace-investigation-draft.md`.

## Remaining work

### 1. P7 rewrites (dumps collected)

Runtime report: `dev/reports/p7-runtime-2026-10-24.md`.
Patch-on dumps are done for all five pending levels:

- `escape_street`, `jolly`: verified, dead writes removed, now log `applied`.
- `moon`: appended door 4983 does not link segment 23; it stays isolated.
  Geometry is exactly on the shared edge; visibility cross-link tested
  (`see=1/1`) and did not help. **Accepted loss** (`drop-log.md`).
- `peta`: the new 47<->91 door works and segment 91's seal is inherent, but
  segment 53 (hat shop) stays isolated. Door 201 geometry is correct;
  visibility `see=1/1` did not help. **Accepted loss**; the working door is
  kept.
- `skm_mallcrasher`: **skirmish only** (Crime Spree, world
  `narratives/skm/skm_mallcrasher`, CRC `598935744`). Dump proved 8<->11 is
  2 navlinks, not a door; door 1343 uses quads 844/61 and quad 943 belongs to
  segment 37. Transfer reverted; block is `skip_dead`. Forced skirmish load
  crashed on exit (`NavigationManager:destroy` access violation, LIES
  `register_cover_units` nil, missing skirmish package); `!iter force` now
  refuses skirmish levels. The standard Vlad job (`mallcrasher`, world
  `narratives/vlad/mallcrasher`, CRC `75811735`) is a different heist and
  stays unpatched (`skip_setting`).
- Level-id audit: `dev/reports/p7-level-id-audit.md` — no other conflation;
  `gallery` is a valid clone of `framing_frame_1` with its own CRC.

Still useful: the patch-off baseline for `moon`/`peta` (confirms the patch is
the only attempted link, not a vanilla topology change). Optional for
`jolly`/`escape_street`.

### 2. T5 path extender — PASS on counters

Card: `dev/test/cards/T5-extender.md`.
Hoxton Breakout D1: `path_ahead=1`, `extend(ok=1)` → `ok=4 skip=0`,
`summary path_extend_ok=4`, no Iter errors. Log scan:
`dev/reports/smoke-t5-2026-10-24.md`. Remaining: player confirmation that no
cop visibly slid or stuck at the append point.

### 3. Release/merge

- Review docs: `MENU_OPTIONS.md`, `README.md`,
  `dev/reports/compatibility-iter.md`, P7 audit.
- Compatibility matrix: NavFixes must not run with Iter; The Fixes replaces
  `CopActionWalk._init` (The Fixes owns it; Iter re-wraps it after load and
  T5 passed with The Fixes installed); Keepers direct-to-pos smoke.
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
3. `map_patches` is on by default; 21 clean blocks (22 level ids),
   2 accepted losses, 1 dead, 2 no-op.
4. `nav_event` heartbeat every 30 s; `_clear` resets shim/cache/navlink maps.
5. LIES: Iter loads later and owns `_execute_coarce_search`; LIES cover
   search still runs. Re-check after a LIES update.
6. `skm_mallcrasher` is resolved as `skip_dead` (navlink-only seal); the
   standard `mallcrasher` is out of scope. No P7 testing remains.

## Session protocol

Start:

```powershell
cd D:\Programowanie\payday\2\v2\.worktrees\Iter-iter-full-nav
powershell -NoProfile -ExecutionPolicy Bypass -File dev\tools\gates.ps1
```

Then read `dev/progress.md` and this file. P7/T5 are done; next is the final
branch review and merge prep. End: update `dev/progress.md`, commit docs,
write a new handoff if the session is long.

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
