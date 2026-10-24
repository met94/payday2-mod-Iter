# Iter full-navigation port — plan

Status: implementation started 2026-10-24.
Branch: `feat/iter-full-nav` (worktree `.worktrees/Iter-iter-full-nav`).
Source of truth for Iter: `98940fb` (r200). Last-compatible game content:
`a3180fc` (246.1). Target: `e3a8b616` (248.2).

Companion docs:

- `dev/reports/intent-map.md` — feature intent, target mechanism, decision.
- `dev/port-ledger.md` — generated per-function inventory.
- `dev/reports/decisions.md` — rulings, each with "cost if wrong".
- `dev/reports/drop-log.md` — dropped features and reasons.
- `dev/reports/reviews/` — reviewer verdicts.
- `dev/progress.md` — session ledger and handoff pointer.
- `dev/test/cards/` — runtime acceptance cards.

## 1. Goal

Restore Iter's navigation behaviour on PAYDAY 2 248.2 (Diesel 3) by
reimplementing the intent of r200 against the v6 nav model. Port code only
where the underlying game contract still exists; otherwise rebuild the
mechanism and document the decision.

Success means:

1. `streamline_path` can be enabled and a heist runs without Lua errors,
   FATAL, stuck AI, or navlink deadlocks on the target map set.
2. Each Iter feature is either reimplemented with a matching observable
   behaviour or explicitly dropped/deferred with a recorded reason.
3. Nav data that v6 removed from runtime Lua is reconstructed from the v5
   load data, or the subsystem degrades to vanilla with a logged fallback.
4. Every change is traceable: task → ledger row → intent row → decision →
   test card → review verdict → commit.

## 2. Non-goals

- Restoring obsolete v5 mechanisms for their own sake.
- Fixing vanilla 248.2 nav defects (NavFixes owns the general guards).
- Porting Iter's cover-generation hack or unrelated AI changes.
- Touching the user's deployed game copy.

## 3. Hard constraints

- `mods/Iter` master stays Iter Lite until the port passes its gates.
- Every restored subsystem is behind a flag; default off until its card passes.
- No subagent edits more than two files per task; shared nav file edits are serialized.
- Static gates run after every implementation unit.
- Reviewer `FIX-REQUIRED` blocks the phase.
- Runtime claims require a log scan; static-only claims are labeled "static".

## 4. Why a v6 shim is possible

248.2 still converts v5 nav data:

- `NavigationManager:set_load_data` calls `_convert_nav_data_v5_to_v6` when
  `data.version < 6` (`lib/managers/navigationmanager.lua:207-236`).
- The converter passes `quad_borders_*`, `quad_heights_*`, `door_low/high_pos`,
  `door_low/high_quads`, `visibility_groups` through (`:238-304`).
- `NavFieldBuilder._VERSION` is still `5` (`lib/managers/navfieldbuilder.lua:2`).
- `_send_nav_field_to_engine(load_data)` receives that data before
  `_resolve_segment_neighbours` (`:207-232`, `:1760-1791`).
- `_load_nav_data` keys segments by `tostring(id)` (`:306-324`).
- `_resolve_segment_neighbours` fills `segment.neighbours[other]` with engine
  door positions (`Vector3`) or nav-link userdata (`:326-351`).
- `get_nav_seg_from_i_room` remains but reads `_rooms`/`_visibility_groups`,
  which are never built (`:1601-1607`) — the shim fixes this for Iter.

The shim rebuilds `_rooms`, `_room_doors`, `_visibility_groups` from the load
data after `_send_nav_field_to_engine`, then computes proxies after
`_resolve_segment_neighbours`.

## 5. Architecture

| File | Role |
|---|---|
| `lua/navigationmanager.lua` | nav overlay, gated by `streamline_path` |
| `lua/_navdatapatches.lua` | level patches, v5 gate + CRC, gated by `map_patches` |
| `lua/iter_nav_v6_shim.lua` | reconstruct rooms/doors/vis-groups; prep; fallbacks |
| `lua/iter_diag.lua` | `Iter.diag` event/counter logger |
| `lua/copbrain.lua`, `copactionwalk.lua`, `coplogictravel.lua`, `coplogicidle.lua`, `groupaistatebase.lua` | AI wrappers |
| `lua/civilianbrain.lua`, `civilianlogictravel.lua`, `teamaibrain.lua` | drop or defer; see intent map |
| `dev/` | harness, reports, cards; excluded from `dist/Iter` |

Load order:

```
set_load_data (raw v5)
  -> patch hook (version + CRC)
_convert_nav_data_v5_to_v6
_load_nav_data (string keys)
_send_nav_field_to_engine(load_data)  -> shim builds rooms/doors/vis groups
_resolve_segment_neighbours()         -> post-hook: neighbour lists + proxies
first path request                    -> search/streamline/navlink logic
```

## 6. Feature flags

| Flag | Default | Subsystem |
|---|---|---|
| `nav_overlay` | false | internal master gate for the restored overlay |
| `streamline_path` | false | user-facing master toggle, proxies + streamline |
| `navlink_queue` | false | congestion/queue/alternates/reservations |
| `path_extender` | false | live path appending |
| `direct_to_pos` | false | straight-line objective movement |
| `map_patches` | false | `_navdatapatches` |
| `debug_log` | 0 | 0 off, 1 summaries+errors, 2 verbose |

## 7. Diagnostics

Any file may call `Iter.diag`. Events are one line:

```
[ITER-NAV] v=1 sid=<short> evt=<name> k=v k=v ...
```

Required events: `boot`, `heist`, `navdata`, `patch`, `proxy`, `search`,
`streamline`, `navlink`, `path_extend`, `direct`, `fallback`, `err`, `summary`.

Rules:

- `err` is only emitted from a `pcall` boundary; `log-scan` fails on `[ITER-ERR]`.
- `fallback` means a subsystem saw a contract it could not satisfy and used
  vanilla behaviour. Fallbacks are counted, not silently swallowed.
- `debug_log=1` logs summaries and discrete failures; `=2` logs every event.
- Per-heist summaries at start/end and every 60 s in level 1.

## 8. Harness

Copied from LIES dev tooling (same author, reuse approved) and adapted:

| Tool | Purpose |
|---|---|
| `dev/tools/fn-ledger.mjs` | per-function inventory vs 246.1 and 248.2 |
| `dev/tools/fn-workbench.mjs` | three-way function dossier |
| `dev/tools/api-audit.mjs` | hook targets, removed symbols, nav field checks |
| `dev/tools/log-scan.mjs` | `[ITER-NAV]` parsing, card PASS/FAIL |
| `dev/tools/gates.ps1` | Node tests, LuaJIT syntax, freevars, ledger, audit |
| `dev/tools/build.ps1` | `dist/Iter`, never touches the game |
| `dev/test-harness/` | `!iter` chat commands, prefix `[ITER-TEST]` |
| `dev/test/cards/` | acceptance JSON consumed by `log-scan --card` |

Commands: `!iter help | nav | patch | probe [n] | path | ai | links | alarm |
assault | state | setting <key> <value> | dump | reset`.

## 9. Test cards

| Card | Time | Maps | Focus |
|---|---|---|---|
| T0 load | 5 min | Jewelry Store | setup, shim, no errors |
| T1 nav graph | 10 min | Jewelry, Big Bank, Golden Grin, Border Crossing, Hotline D1 | counts, string keys, door types |
| T2 streamline | 5 min | any | `!iter probe 20`, success and length |
| T3 navlink | 10 min | Hotline D1 / Biker D2 | queues, alternates, no stacking |
| T4 search | 10 min | Big Bank / Border Crossing | success, cache, direct-to-pos |
| T5 AI | 15 min | mixed | path extender, followers, no pauses |
| T6 patches | 5 min/level | patch levels | CRC/apply status |
| T7 compat | 10 min | with LIES/NavFixes/Keepers/The Fixes | ownership matrix |

The user runs a card when available; the log is scanned with
`node dev/tools/log-scan.mjs <log> --mod . --card dev/test/cards/<card>.json`.

## 10. Work breakdown

Estimates are focused human-equivalent hours; test waits are separate.

### P0 Harness and baseline — 6-8 h

- H-01 worktree and r200 restore — done.
- H-02 copy/adapt LIES harness — done.
- H-03 `[ITER-NAV]` schema + `Iter.diag` (next).
- H-04 baseline log scan on Iter Lite.
- H-05 gates baseline (ledger, audit, syntax, freevars).
- H-06 first test cards committed.

Gate: gates PASS; T0 card exists; baseline audit errors recorded (11).

### P1 Intent and dossiers — 12-16 h

- I-01 nav feature inventory.
- I-02 nav function dossiers.
- I-03 AI function dossiers.
- I-04 map patch inventory.
- I-05 intent map + decisions.
- I-06 reviewer pass.

Gate: every restored function has an intent row and decision; reviewer PASS.

### P2 v6 data layer — 14-16 h

- N-01 shim: rooms/doors/vis-groups from load data.
- N-02 string keys, door shapes, lifecycle clear.
- N-03 `_send_nav_field_to_engine` / `_resolve_segment_neighbours` hook points.
- N-04 guards + `_navdatapatches` version gate.
- N-05 offline Lua unit tests for the shim.
- N-06 T0 card.

Gate: T0 PASS; `fallback=0`; shim counts non-zero; audit nav errors drop.

### P3 Streamline — 20-24 h

- S-01 segment doors + room-to-doors on quads.
- S-02 flood/contiguity/choke-point port + unit tests.
- S-03 proxy port + unit tests.
- S-04 door selection/alignment.
- S-05 streamline port + integration in `CopBrain.clbk_coarse_pathing_results`.
- S-06 fallback path.
- S-07 probe/T2.
- S-08 review.

Gate: T1/T2 PASS; offline tests green; no stuck AI.

### P4 Navlink subsystem — 24-28 h

- L-01 navlink element map + intervals.
- L-02 congestion/queue counters.
- L-03 reservation + alternates.
- L-04 `CopActionWalk` navlink integration.
- L-05 group-AI neighbour upkeep.
- L-06 T3.
- L-07 review.

Gate: T3 PASS; queue bounded; no deadlock.

### P5 Search and direct-to-pos — 16-20 h

- C-01 search adaptation.
- C-02 cache + invalidation.
- C-03 `CopBrain` params.
- C-04 direct-to-pos.
- C-05 LIES ownership.
- C-06 T4.

Gate: T4 PASS; cache correct after segment state change.

### P6 AI remainder — 10-14 h

- A-01 path extender.
- A-02 `_init`/append/shortcut/pose.
- A-03 follow-unit.
- A-04 drops.
- A-05 T5.

Gate: T5 PASS.

## P7 Map patches — 16-24 h — DEFERRED

- Status: deferred to the next session; design card
  `dev/plans/tasks/P7-map-patches.md`.
- Blocker: the r200 file selects the level at file-load time, and 69 patch
  writes target neighbour lists that v6 discards. Needs a per-call patch table
  and a per-level audit.
- Gate: T6 per level; `evt=patch` status; no errors.


### P8 Hardening and release — 10-14 h

- R-01 compat matrix.
- R-02 performance/ms.
- R-03 error handling/fallbacks.
- R-04 docs/changelog/menu.
- R-05 final gates and release build.
- R-06 workspace investigation doc.

Gate: T0-T7 PASS, docs complete, release build reproducible.

## 11. Orchestration

| Role | Work |
|---|---|
| Main thread | architecture, task cards, integration, gates, decisions, docs, log analysis |
| `cavecrew-investigator` | symbol/caller mapping, read-only |
| `cavecrew-builder` | 1-2 file mechanical edits |
| `general` | one isolated complex unit |
| `cavecrew-reviewer` | diff review, verdict per unit |

Every implementation unit:

1. Write/confirm the task card with exact files and acceptance.
2. Dispatch one implementer with the card and baselines.
3. Run `gates.ps1` on its result.
4. Dispatch `cavecrew-reviewer` with the diff and card.
5. Fix findings; re-review; record verdict in `dev/reports/reviews/<task>.md`.
6. Commit with the task ID.

## 12. Session protocol

Start: read `dev/progress.md` + latest handoff; run `gates.ps1`; pick the next
task. End: update progress, decisions, intent map; write handoff with the next
task and any pending test card. Builds are produced at unit boundaries so the
user can test whenever available.

## 13. Definition of done

- Every restored function classified, reviewed, tested or explicitly deferred.
- T0-T7 pass on the target set.
- Compose or documented exclusion with LIES, NavFixes, Keepers, The Fixes.
- Full docs set regenerated.
- `changelog.txt`, `MENU_OPTIONS.md`, workspace investigation updated.
- Release build with player notes.
