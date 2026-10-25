# Function dossier: lua/coplogictravel.lua :: CopLogicTravel._check_start_path_ahead

Category: **MOD_EDIT_CLEAN**

- ITER: 41 lines, params `(data)`
- 246.1: 26 lines, params `(data)`
- 248.2: 26 lines, params `(data)`

Normalized signature: `self` is omitted for methods; the body is the porting surface.

## ITER body (V8.57)

```lua
function CopLogicTravel._check_start_path_ahead(data)
local my_data = data.internal_data

	if my_data.processing_advance_path then
		return
	end

	local objective = data.objective
	local coarse_path = my_data.coarse_path
	if not coarse_path then
		return
	end

	local walk_action = my_data.advancing
	if not walk_action then
		return
	end

	local s_path = walk_action._simplified_path
	if not s_path then
		return
	end

	local from_pos = CopActionWalk._nav_point_pos(s_path[#s_path])

	local next_index = my_data.coarse_path_index + 2
	if next_index > #coarse_path then
		return
	end

	local to_pos = data.logic._get_exact_move_pos(data, next_index)
	if not to_pos then
		return
	end

	my_data.processing_advance_path = true
	local prio = data.logic.get_pathing_prio(data)
	local nav_segs = CopLogicTravel._get_allowed_travel_nav_segs(data, my_data, to_pos)

	data.brain:search_for_path_from_pos(my_data.advance_path_search_id, from_pos, to_pos, prio, nil, nav_segs)
end
```

## 246.1 vanilla (a3180fc)

```lua
function CopLogicTravel._check_start_path_ahead(data)
local my_data = data.internal_data

	if my_data.processing_advance_path then
		return
	end

	local objective = data.objective
	local coarse_path = my_data.coarse_path
	local next_index = my_data.coarse_path_index + 2
	local total_nav_points = #coarse_path

	if total_nav_points < next_index then
		return
	end

	local to_pos = data.logic._get_exact_move_pos(data, next_index)

	my_data.processing_advance_path = true

	local prio = data.logic.get_pathing_prio(data)
	local from_pos = data.pos_rsrv.move_dest.position
	local nav_segs = CopLogicTravel._get_allowed_travel_nav_segs(data, my_data, to_pos)

	data.unit:brain():search_for_path_from_pos(my_data.advance_path_search_id, from_pos, to_pos, prio, nil, nav_segs)
end
```

## 248.2 vanilla (e3a8b616)

```lua
function CopLogicTravel._check_start_path_ahead(data)
local my_data = data.internal_data

	if my_data.processing_advance_path then
		return
	end

	local objective = data.objective
	local coarse_path = my_data.coarse_path
	local next_index = my_data.coarse_path_index + 2
	local total_nav_points = #coarse_path

	if total_nav_points < next_index then
		return
	end

	local to_pos = data.logic._get_exact_move_pos(data, next_index)

	my_data.processing_advance_path = true

	local prio = data.logic.get_pathing_prio(data)
	local from_pos = data.pos_rsrv.move_dest.position
	local nav_segs = CopLogicTravel._get_allowed_travel_nav_segs(data, my_data, to_pos)

	data.unit:brain():search_for_path_from_pos(my_data.advance_path_search_id, from_pos, to_pos, prio, nil, nav_segs)
end
```

## Diff 246.1 -> ITER

```diff
--- 246.1 vanilla
+++ ITER
@@ -1,25 +1,40 @@
-local my_data = data.internal_data
-
-	if my_data.processing_advance_path then
-		return
-	end
-
-	local objective = data.objective
-	local coarse_path = my_data.coarse_path
-	local next_index = my_data.coarse_path_index + 2
-	local total_nav_points = #coarse_path
-
-	if total_nav_points < next_index then
-		return
-	end
-
-	local to_pos = data.logic._get_exact_move_pos(data, next_index)
-
-	my_data.processing_advance_path = true
-
-	local prio = data.logic.get_pathing_prio(data)
-	local from_pos = data.pos_rsrv.move_dest.position
-	local nav_segs = CopLogicTravel._get_allowed_travel_nav_segs(data, my_data, to_pos)
-
-	data.unit:brain():search_for_path_from_pos(my_data.advance_path_search_id, from_pos, to_pos, prio, nil, nav_segs)
+local my_data = data.internal_data
+
+	if my_data.processing_advance_path then
+		return
+	end
+
+	local objective = data.objective
+	local coarse_path = my_data.coarse_path
+	if not coarse_path then
+		return
+	end
+
+	local walk_action = my_data.advancing
+	if not walk_action then
+		return
+	end
+
+	local s_path = walk_action._simplified_path
+	if not s_path then
+		return
+	end
+
+	local from_pos = CopActionWalk._nav_point_pos(s_path[#s_path])
+
+	local next_index = my_data.coarse_path_index + 2
+	if next_index > #coarse_path then
+		return
+	end
+
+	local to_pos = data.logic._get_exact_move_pos(data, next_index)
+	if not to_pos then
+		return
+	end
+
+	my_data.processing_advance_path = true
+	local prio = data.logic.get_pathing_prio(data)
+	local nav_segs = CopLogicTravel._get_allowed_travel_nav_segs(data, my_data, to_pos)
+
+	data.brain:search_for_path_from_pos(my_data.advance_path_search_id, from_pos, to_pos, prio, nil, nav_segs)
 end
\ No newline at end of file
```

## Diff 246.1 -> 248.2

```diff
No differences.
```

## Porter checklist

- [ ] Decision: keep ITER body, adopt 248.2 vanilla, or merge.
- [ ] If merge: re-apply the ITER intent onto the 248.2 body, not the 246.1 body.
- [ ] Check removed/changed APIs (`_room_doors`, numeric `_nav_segments`, `no_dispose`, `session():send_to_peers_synched`, ...).
- [ ] Check new 248.2 fields/callbacks this function must preserve.
- [ ] Run `luajit -bl` and `api-audit` on the file.

## Port notes (P1)

1. **Wrapper or replacement.** **Replacement** — the only full replacement besides `_chk_stop_for_follow_unit` in this file. `lua/coplogictravel.lua:345-385` defines it with no captured `itr_original_*` and never calls one; 41 lines replace the vanilla 26.
2. **Call sites.** r200: called from the mod's `upd_advance` at `:395`. 248.2: `lib/units/enemies/cop/logics/coplogictravel.lua:252` (`CopLogicTravel._check_start_path_ahead(data)`, inside the `my_data.advancing and my_data.path_ahead` branch); definition `:1369-1394`.
3. **Intent.** Start the *next* detailed path while the current walk action is still running, from the current tail of the live simplified path rather than from the original reservation, so the appended path continues where the walk will actually be.
4. **248.2 delta.** None in the vanilla body — the file is byte-identical 246.1↔248.2, so the 248.2 body *is* the 246.1 body (`:1369-1394`). The functional difference is Iter's: vanilla takes `from_pos = data.pos_rsrv.move_dest.position` (`:1390`, the position reserved once at `CopActionWalk._init` `:565-568`), r200 takes `from_pos = CopActionWalk._nav_point_pos(s_path[#s_path])` (`:368`) — the live tail after appended steps.
5. **Target mechanism.** REIMPLEMENT the delta, not the body: keep the 26-line vanilla function and wrap it with a temporary swap of `data.pos_rsrv.move_dest.position` to the simplified-path tail (or better, patch the `from_pos` local by calling a 3-line helper), restoring it afterwards. Hook point: the `walk_action._simplified_path` tail; fields `my_data.processing_advance_path`, `my_data.advance_path_search_id`.
6. **Decision.** **REIMPLEMENT** (P6, F3/A-01). Replacing 26 lines to change one variable re-couples the whole function to future 248.x drift, which is exactly what the plan's "re-apply intent onto the 248.2 body" rule forbids.
7. **Acceptance.** T5. Log `evt=path_extend k=start=1,from=tail|move_dest,gap=<units>`; a large `gap` (tail far from `move_dest`) confirms the swap is doing work.
8. **Cost if wrong.** If `from_pos` is the stale `move_dest`, the appended path starts behind the unit; the walk action then walks backwards on the first appended step — visible sliding, and it is indistinguishable from a bad append in the logs unless `from=` is logged.
9. **Evidence gaps.** r200 also requires `my_data.advancing` and `walk_action._simplified_path` to exist (`:358-366`), which vanilla does not; whether 248.2 ever calls this with `advancing` nil (the `path_ahead` flag is set in `enter`, `:157`) is unverified. Also: `data.pos_rsrv` may be nil for units without a move_dest reservation — r200 never touches it, a wrapper must nil-check.
