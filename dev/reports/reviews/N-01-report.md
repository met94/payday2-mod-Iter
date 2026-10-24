# N-01 — v6 nav geometry shim (implementation report)

Status: DONE
Task card: `dev/plans/tasks/N-01-shim.md`
Worktree: `.worktrees/Iter-iter-full-nav` (branch `feat/iter-full-nav`)
Date: 2026-10-24
Round: 2 (review fixes). Not committed; the controller commits and owns the
gate evidence.

## Scope of this round

Review fixes only, in three files:

- `lua/iter_nav_v6_shim.lua`
- `dev/tests/lua/test_shim.lua`
- `dev/reports/reviews/N-01-report.md` (this file)

Controller-owned fixes in the same round (not by the implementer):
`dev/tools/api-audit.mjs` (suppressed findings + allowlist usage),
`dev/tools/gates.ps1` (conditional `--allow`, unused-entry gate, non-empty
unit suite), `dev/tools/api-allowlist.json` (scoped shim allowlist), and
`lua/navigationmanager.lua` (shim hooks, unchanged since round 1).

## What the shim builds

`IterNavShim.rebuild(nav, load_data)` reconstructs the three runtime tables
from the post-converter v5 arrays, then `clear(nav)` resets them and
`stats(nav)` returns `nav.itr_shim`.

- `nav._rooms` — `{ borders = {x_pos, x_neg, y_pos, y_neg}, height =
  {xp_yp, xp_yn, xn_yp, xn_yn}, vis_group }`; borders x/y multiplied by
  `nav._grid_size`, heights absolute.
- `nav._room_doors` — `{ pos, pos1, center, rooms = {low_quad, high_quad} }`;
  x/y scaled by `nav._grid_size`, z unchanged; `pos`, `pos1` and `center`
  (the midpoint, the r200 gameplay shape read by
  `itr_get_door_in_alignment`) are three distinct fresh `Vector3`s.
- `nav._visibility_groups` — `{ quads (array), rooms (map), vis_groups (map),
  visible_groups (same table as vis_groups), pos (Vector3 copy), seg }`.
  `vis_groups`/`visible_groups` are aliases of one table, not copies: r200
  consumers read `.vis_groups`, v6 data names it `.visible_groups`. `seg` is
  the owning segment's string id (`tostring(segment.id)`), matching the 248.2
  `_nav_segments` key space and `get_nav_seg_from_i_room`.
- `nav.itr_shim` stats: `rooms`, `room_doors`, `vis_groups`, `doors_skipped`,
  `groups_without_seg`, `segments`, `grid`, `fallback` (+ `reason` on
  fallback).
- Quad → vis-group ownership is recovered from each visibility group's
  `quads` list, because `_convert_nav_data_v5_to_v6` does not forward
  `room_vis_groups` (it is the inverse map of `vis_group.rooms`).
- Numeric string keys (`"3"` instead of `3`) are accepted via `tonumber`, in
  case `ScriptSerializer` round-trips integer keys as strings.
- Door lists are read from `door_low_quads` / `door_high_quads` only; the v5
  `door_low_rooms` / `door_high_rooms` names are not accepted as aliases,
  because post-converter data never has them. A missing quad list is
  `no_door_quads`.

### Rebuild requirements

Rebuild returns `false` and logs one
`[ITER-NAV] ... evt=fallback subsystem=shim reason=<short>` line when:

| reason | meaning |
|---|---|
| `no_load_data` | payload is not a table |
| `no_segments` | `load_data.segments` missing/empty (the post-hook also runs when vanilla early-returns) |
| `v6_only_data` | no v5 quad arrays (native v6 payload) |
| `no_vis_groups` | visibility groups missing/empty |
| `no_door_quads` | door quad lists missing |
| `no_grid_size` | `nav._grid_size` nil or ≤ 0 — never invent a grid |
| `rebuild_error` | exception inside the single `pcall` boundary; the same fallback line carries `msg=<short error>`, no separate `err` event |

`v6_only_data` keeps the already-built tables and reports the fallback with
the kept counts, because a native v6 payload can arrive outside a level load
(`delete_nav_segment`, `build_complete_clbk`). Every other reason is missing
or corrupt data and drops the tables so stale geometry is never served; level
changes already clear through the `_clear` hook before `set_load_data`.
Success emits one `evt=navdata` event with `rooms`, `room_doors`, `vis_groups`,
`doors_skipped`, `groups_without_seg`, `segments`, `grid`, `fallback=0`.

Wiring (`lua/navigationmanager.lua`, unchanged this round): the shim is
`dofile`d inside the `nav_overlay` gate and driven by
`Hooks:PostHook(NavigationManager, '_send_nav_field_to_engine',
'Iter_nav_shim_rebuild', ...)` and
`Hooks:PostHook(NavigationManager, '_clear', 'Iter_nav_shim_clear', ...)`.
With `nav_overlay=false` none of it runs.

## Tests

`dev/tests/lua/test_shim.lua` — 10 tests, 137 checks, run on bare LuaJIT with
a stubbed `Vector3` and `Iter.diag` against a synthetic post-converter fixture
(4 quads, 3 visibility groups, 2 segments, 1 valid door, 1 door with an
out-of-range quad):

- `rebuilds_tables` — counts, `doors_skipped`, x/y scaling, z and heights
  unscaled, `center` midpoint and that `center`/`pos`/`pos1` are distinct,
  copy isolation in **both** directions (mutating rebuilt data leaves the
  fixture intact and mutating fixture vectors leaves the rebuilt data intact),
  direct `nav._rooms[i].vis_group` / `nav._visibility_groups[i].seg`
  assertions, `.vis_groups == .visible_groups` alias, one `navdata` event and
  no fallback.
- `vanilla_accessor_uses_shim` — separate test for the vanilla
  `get_nav_seg_from_i_room` body returning the string segment ids.
- `respects_grid_size` — grid 50 scaling for borders, doors and center.
- `accepts_numeric_string_keys` — serializer-style string keys for quads,
  door quads and segment vis-group lists.
- `unowned_vis_group_and_missing_pos` — fourth group with no owner segment and
  no `pos`: `groups_without_seg == 1`, `seg == nil`, default vector.
- `clear_resets` — all three tables emptied, stats dropped.
- `rejects_v6_only_data` — non-empty v6 segments but no quad arrays: `false`,
  reason `v6_only_data`, tables and counts kept, accessor still works.
- `rejects_missing_pieces` — `no_load_data`, `no_segments`, `no_vis_groups`,
  `no_door_quads` (with v5 `*_rooms` names present, proving they are not
  aliases), `no_grid_size` for nil and for 0; stale tables dropped; one
  fallback per rejection.
- `rebuild_error_is_one_fallback` — fixture that throws inside the build:
  `false`, reason `rebuild_error`, exactly one `evt=fallback` line carrying
  `msg` with the original error, zero `evt=err` events, stale tables dropped.
- `survives_bad_optional_data` — malformed optional quad list degrades instead
  of raising; no fallback.

## Commands run

| Command | Result |
|---|---|
| `tools\luajit\luajit.exe -bl lua\iter_nav_v6_shim.lua` | exit 0 |
| `tools\luajit\luajit.exe -bl lua\navigationmanager.lua` | exit 0 |
| `tools\luajit\luajit.exe dev\tests\lua\test_shim.lua` | exit 0, `137 checks, 10 tests passed` |
| `node dev\tools\api-audit.mjs --mod . --clone ..\..\game-data\Payday-2-LuaJIT-Complete --new e3a8b616 --allow dev\tools\api-allowlist.json` | `hooks=17/17 methods=2/2 errors=11 review=32` |

`errors=11` equals the recorded baseline, so the audit did not regress. The
allowlist (`dev/tools/api-allowlist.json`, controller-owned) scopes the three
v5 table names to `lua/iter_nav_v6_shim.lua` as the sanctioned rebuild point
(R4); the shim now writes `nav._rooms`, `nav._room_doors` and
`nav._visibility_groups` literally instead of hiding them behind constants.
`methods=2/2` confirms both PostHook targets exist at `e3a8b616`.

Full `gates.ps1` was not run in this round; the controller owns the gate run
and the generated report files (`dev/reports/api-audit.*`,
`dev/reports/static-gates.md`, ledger outputs) are left in the working tree as
they are.

## Concerns

1. **Skipped doors.** Doors whose `door_low_quads`/`door_high_quads` do not
   resolve to a built quad are dropped (`doors_skipped` in stats/navdata).
   `_room_doors` stays internally consistent but its keys no longer match v5
   save-data indices 1:1. No r200 consumer and no `_navdatapatches` code
   depends on that identity (all use `pairs`), but downstream tasks (S-01
   segment doors) must keep treating `_room_doors` keys as opaque.
2. **`vis_group.pos` is not scaled.** v5 `set_load_data` assigned
   `self._visibility_groups = data.vis_groups` untouched, so the shim copies
   `pos` as-is (fresh `Vector3`). No current consumer reads it; if a P3
   consumer expects world units this needs a decision.
3. **Runtime acceptance not run.** The card's T0 log check
   (`rooms>0 room_doors>0 vis_groups>0`, `fallback=0`) is static-only here — no
   game session was started. The `navdata` event is shaped for that scan.
4. **`_clear` post-hook is global.** It empties the tables for every
   manager-level clear/rebuild flow, matching r200 `_clear`. No mod in the T7
   set is known to read these tables (NavFixes guards engine nav, not these
   Lua tables); T7 remains the place to confirm.
5. **Kept geometry on `v6_only_data` relies on `_clear` running first on a
   level change.** That is the vanilla 248.2 order (`_clear` then
   `set_load_data`); if a future game build changes it, the keep policy needs
   re-checking.
