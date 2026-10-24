# Handoff — Iter full-nav port (next session)

Branch: `feat/iter-full-nav`
Worktree: `.worktrees/Iter-iter-full-nav`
Build: `dist/Iter` at `ca22c4a` (`202-dev`)

## Where the port stands

Core navigation/AI port is **release-candidate complete**:

| Area | Status |
|---|---|
| v6 geometry shim | T1 PASS |
| Path streamline | T2/T2b PASS |
| Nav-link queue/reservations | T3 PASS |
| Iter coarse search + cache | T4 PASS |
| Direct-to-pos | T4 PASS |
| Path extender | implemented; **T5 pending** (no converted/chase run yet) |
| Map patches | framework works; 16 levels survive; 4 need rewrites; 1 dead |
| LIES compatibility | tested together during T1-T4; no Iter errors |

Static gates PASS; API audit baseline 12 expected errors, 12 scoped
suppressions, 0 unused. RC defaults: overlay/streamline/search/AI/navlink
queue/direct on; path extender and map patches off.

## P7 progress this session

Dumps proved two "partial" levels actually survive:

- **Train Heist (`arm_for`)**: transfers 2689/2701/2704-2712 leave doors
  5188, 5205/5210, 5195/5206 in place. Dead writes removed.
- **Dockyard (`crojob2`)**: transfers 414/417/418/424 leave doors
  758/764/772/773 between segments 28 and 74; 28↔52 has no doors.
  Dead writes removed.

Both now log `applied`, not `applied_partial`.

Important mapping (cost us a wrong test):

- The Bomb: **Dockyard** = job `crojob1`, **level `crojob2`** (has patch).
- The Bomb: **Forest** = job `crojob2`, **level `crojob3`** (no patch).

## Remaining work

### 1. P7 dumps for the last five levels

Card: `dev/test/cards/P7-dumps.md`.

- Escape: Street (`escape_street`): `navdump 48`, `63`; `navdoors 48 63`
- Aftershock (`jolly`): `navdump 87`, `141`; `navdoors 87 141`
- Stealing Xmas (`moon`): `navdump 22`, `23`; `navdoors 22 23`
- Goat Simulator D1 (`peta`): `navdump 47`, `53`, `91`; `navdoors 47 91`,
  `47 53`
- Mallcrasher (`skm_mallcrasher`): `navdump 8`, `11`; `navdoors 8 11`

Enable **Dev: v6 map patches**, one command per chat line (no semicolons).
The dumps show quads and door ids to replace the dead neighbour-only links.
`jolly`/`moon`/`peta` also lose a neighbour-list seal; that likely needs an
engine-side segment-state expression rather than data edits — decide from
the dumps.

### 2. T5 path extender

Needs a run with a converted cop (Joker), an `is_important` unit, or chase
mode, because `path_ahead=0` in every test so far. Acceptance: no sliding,
no stuck action, `itr_append_next_step` path extends.

### 3. Release/merge

- Review docs: `MENU_OPTIONS.md`, `README.md`,
  `dev/reports/compatibility-iter.md`, P7 audit.
- Compatibility matrix: NavFixes must not run with Iter; The Fixes replaces
  `CopActionWalk._init`; Keepers direct-to-pos smoke.
- Workspace doc draft: `dev/reports/workspace-investigation-draft.md`.
- Merge only on explicit user approval, then copy the investigation draft to
  `docs/investigations/iter-full-nav-port.md` and refresh
  `workspace.lock.json` + `CHANGELOG.md`.

## Open issues / risks

1. Probe `avg_len` was 0 despite 3 steps/path. Added `raw_positions`/
   `stream_positions` to `!iter probe`; next probe run should explain it.
   AI movement was fine.
2. `[ITER-NAV] evt=patch` uses `applied`/`applied_partial`/`skip_dead`;
   `!iter patch` shows stats.
3. `map_patches` remains off by default; 16 levels are safe, 4 partial.
4. `nav_event` heartbeat every 30 s; `_clear` resets shim/cache/navlink maps.
5. LIES: Iter loads later and owns `_execute_coarce_search`; LIES cover
   search still runs. Re-check after a LIES update.

## Session protocol

Start:

```powershell
cd D:\Programowanie\payday\2\v2\.worktrees\Iter-iter-full-nav
powershell -NoProfile -ExecutionPolicy Bypass -File dev\tools\gates.ps1
```

Then read `dev/progress.md` and this file. Pick P7 dumps or T5. End: update
`dev/progress.md`, commit docs, write a new handoff if the session is long.

## Key commits

```
ca22c4a P7: confirm Dockyard survives via transfers
4d970c1 P7: correct Bomb mapping (Dockyard crojob2)
edf9c41 P7: confirm arm_for survives via transfers
6ea2b74 P7: navdoors dump + topology card
6a97f2e fix: harden search results/cap/patch lifecycle
55f7d64 RC defaults + final smoke
```
