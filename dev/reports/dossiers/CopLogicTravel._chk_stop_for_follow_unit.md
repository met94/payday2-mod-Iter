# Function dossier: lua/coplogictravel.lua :: CopLogicTravel._chk_stop_for_follow_unit

Category: **MOD_EDIT_CLEAN**

- ITER: 49 lines, params `(data, my_data)`
- 246.1: 25 lines, params `(data, my_data)`
- 248.2: 25 lines, params `(data, my_data)`

Normalized signature: `self` is omitted for methods; the body is the porting surface.

## ITER body (V8.57)

```lua
function CopLogicTravel._chk_stop_for_follow_unit(data, my_data)
local objective = data.objective
	if objective.type ~= 'follow' or data.unit:movement():chk_action_forbidden('walk') or data.unit:anim_data().act_idle then
		return
	end
	if not my_data.coarse_path_index then
		return
	end

	local follow_unit = data.objective.follow_unit
	if not alive(follow_unit) then
		return
	end

	local follow_unit_nav_seg = follow_unit:movement():nav_tracker():nav_segment()
	local next_coarse_path_index = my_data.coarse_path_index + 1
	local coarse_path = my_data.coarse_path
	local my_next_seg = coarse_path[next_coarse_path_index] and coarse_path[next_coarse_path_index][1]
	local coarse_path_nr = #coarse_path
	local my_nav_seg = data.unit:movement():nav_tracker():nav_segment()

	if follow_unit_nav_seg == my_nav_seg and follow_unit_nav_seg ~= my_next_seg then
		for i = #coarse_path, next_coarse_path_index, -1 do
			coarse_path[i] = nil
		end
		coarse_path[next_coarse_path_index] = {
			[1] = follow_unit_nav_seg,
			[2] = _update_destination(my_data, follow_unit_nav_seg, data.pos_rsrv_id)
		}
		data.logic.on_new_objective(data)

	elseif data.itr_follow_unit_nav_seg and data.itr_follow_unit_nav_seg ~= follow_unit_nav_seg and coarse_path[coarse_path_nr][1] ~= follow_unit_nav_seg then
		local pos = not managers.navigation._quad_field:is_nav_segment_blocked(follow_unit_nav_seg, data.SO_access) and managers.navigation:itr_get_door_between(data.itr_follow_unit_nav_seg, follow_unit_nav_seg, follow_unit:position())
		if pos then
			coarse_path[coarse_path_nr][1] = follow_unit_nav_seg
			coarse_path[coarse_path_nr][2] = pos

			coarse_path[coarse_path_nr + 1] = {
				[1] = follow_unit_nav_seg,
				[2] = _update_destination(my_data, follow_unit_nav_seg, data.pos_rsrv_id)
			}
			coarse_path_nr = coarse_path_nr + 1

			CopLogicTravel.itr_simplify_coarse_path(data, my_data)
		end
	end

	data.itr_follow_unit_nav_seg = follow_unit_nav_seg
end
```

## 246.1 vanilla (a3180fc)

```lua
function CopLogicTravel._chk_stop_for_follow_unit(data, my_data)
local objective = data.objective

	if objective.type ~= "follow" or data.unit:movement():chk_action_forbidden("walk") or data.unit:anim_data().act_idle then
		return
	end

	if not my_data.coarse_path_index then
		debug_pause_unit(data.unit, "[CopLogicTravel._chk_stop_for_follow_unit]", data.unit, inspect(data), inspect(my_data))

		return
	end

	local follow_unit_nav_seg = data.objective.follow_unit:movement():nav_tracker():nav_segment()

	if follow_unit_nav_seg ~= my_data.coarse_path[my_data.coarse_path_index + 1][1] or my_data.coarse_path_index ~= #my_data.coarse_path - 1 then
		local my_nav_seg = data.unit:movement():nav_tracker():nav_segment()

		if follow_unit_nav_seg == my_nav_seg then
			objective.in_place = true

			data.logic.on_new_objective(data)
		end
	end
end
```

## 248.2 vanilla (e3a8b616)

```lua
function CopLogicTravel._chk_stop_for_follow_unit(data, my_data)
local objective = data.objective

	if objective.type ~= "follow" or data.unit:movement():chk_action_forbidden("walk") or data.unit:anim_data().act_idle then
		return
	end

	if not my_data.coarse_path_index then
		debug_pause_unit(data.unit, "[CopLogicTravel._chk_stop_for_follow_unit]", data.unit, inspect(data), inspect(my_data))

		return
	end

	local follow_unit_nav_seg = data.objective.follow_unit:movement():nav_tracker():nav_segment()

	if follow_unit_nav_seg ~= my_data.coarse_path[my_data.coarse_path_index + 1][1] or my_data.coarse_path_index ~= #my_data.coarse_path - 1 then
		local my_nav_seg = data.unit:movement():nav_tracker():nav_segment()

		if follow_unit_nav_seg == my_nav_seg then
			objective.in_place = true

			data.logic.on_new_objective(data)
		end
	end
end
```

## Diff 246.1 -> ITER

```diff
--- 246.1 vanilla
+++ ITER
@@ -1,24 +1,48 @@
-local objective = data.objective
-
-	if objective.type ~= "follow" or data.unit:movement():chk_action_forbidden("walk") or data.unit:anim_data().act_idle then
-		return
-	end
-
-	if not my_data.coarse_path_index then
-		debug_pause_unit(data.unit, "[CopLogicTravel._chk_stop_for_follow_unit]", data.unit, inspect(data), inspect(my_data))
-
-		return
-	end
-
-	local follow_unit_nav_seg = data.objective.follow_unit:movement():nav_tracker():nav_segment()
-
-	if follow_unit_nav_seg ~= my_data.coarse_path[my_data.coarse_path_index + 1][1] or my_data.coarse_path_index ~= #my_data.coarse_path - 1 then
-		local my_nav_seg = data.unit:movement():nav_tracker():nav_segment()
-
-		if follow_unit_nav_seg == my_nav_seg then
-			objective.in_place = true
-
-			data.logic.on_new_objective(data)
-		end
-	end
+local objective = data.objective
+	if objective.type ~= 'follow' or data.unit:movement():chk_action_forbidden('walk') or data.unit:anim_data().act_idle then
+		return
+	end
+	if not my_data.coarse_path_index then
+		return
+	end
+
+	local follow_unit = data.objective.follow_unit
+	if not alive(follow_unit) then
+		return
+	end
+
+	local follow_unit_nav_seg = follow_unit:movement():nav_tracker():nav_segment()
+	local next_coarse_path_index = my_data.coarse_path_index + 1
+	local coarse_path = my_data.coarse_path
+	local my_next_seg = coarse_path[next_coarse_path_index] and coarse_path[next_coarse_path_index][1]
+	local coarse_path_nr = #coarse_path
+	local my_nav_seg = data.unit:movement():nav_tracker():nav_segment()
+
+	if follow_unit_nav_seg == my_nav_seg and follow_unit_nav_seg ~= my_next_seg then
+		for i = #coarse_path, next_coarse_path_index, -1 do
+			coarse_path[i] = nil
+		end
+		coarse_path[next_coarse_path_index] = {
+			[1] = follow_unit_nav_seg,
+			[2] = _update_destination(my_data, follow_unit_nav_seg, data.pos_rsrv_id)
+		}
+		data.logic.on_new_objective(data)
+
+	elseif data.itr_follow_unit_nav_seg and data.itr_follow_unit_nav_seg ~= follow_unit_nav_seg and coarse_path[coarse_path_nr][1] ~= follow_unit_nav_seg then
+		local pos = not managers.navigation._quad_field:is_nav_segment_blocked(follow_unit_nav_seg, data.SO_access) and managers.navigation:itr_get_door_between(data.itr_follow_unit_nav_seg, follow_unit_nav_seg, follow_unit:position())
+		if pos then
+			coarse_path[coarse_path_nr][1] = follow_unit_nav_seg
+			coarse_path[coarse_path_nr][2] = pos
+
+			coarse_path[coarse_path_nr + 1] = {
+				[1] = follow_unit_nav_seg,
+				[2] = _update_destination(my_data, follow_unit_nav_seg, data.pos_rsrv_id)
+			}
+			coarse_path_nr = coarse_path_nr + 1
+
+			CopLogicTravel.itr_simplify_coarse_path(data, my_data)
+		end
+	end
+
+	data.itr_follow_unit_nav_seg = follow_unit_nav_seg
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

1. **Wrapper or replacement.** **Replacement.** `lua/coplogictravel.lua:264-312` has no captured `itr_original_*` and never calls vanilla; 49 lines replace the 25-line 248.2 body. It uses a file-local helper `_update_destination` (`:117-133`).
2. **Call sites.** r200: class override. 248.2: `lib/units/enemies/cop/logics/coplogictravel.lua:242` (from `upd_advance`, the `advancing and coarse_path` branch); definition `:1612-1636`.
3. **Intent.** When following a unit, keep the coarse path's *destination* glued to the follower: if the follower is now in the unit's own segment, truncate the path and re-target; if the follower changed segment, append a doorway point plus a new destination and re-simplify — instead of stopping in place.
4. **248.2 delta.** None in the file (byte-identical 246.1↔248.2), which means the mechanism clash is with *vanilla*, not with the patch: 248.2 `_chk_stop_for_follow_unit` (`:1612-1636`) sets `objective.in_place = true` and calls `data.logic.on_new_objective(data)` (`:1631-1633`), with a `debug_pause_unit` on a missing `coarse_path_index` (`:1620`). r200 replaces that with coarse-path rewriting and never sets `in_place`.
5. **Target mechanism.** REIMPLEMENT the rewrite on top of the 248.2 body: keep vanilla's `in_place`/`on_new_objective` exit, and add the r200 path-extension only for the second branch (`data.itr_follow_unit_nav_seg ~= follow_unit_nav_seg`, `:295-309`). Hook points: `managers.navigation._quad_field:is_nav_segment_blocked` (still present, used by the ported search), `managers.navigation:itr_get_door_between` (Iter helper; currently the audit's 12th error, R6), `_update_destination` → `find_cover_in_nav_seg_1`/`find_random_position_in_segment`/`CopLogicTravel._get_pos_on_wall`.
6. **Decision.** **REIMPLEMENT** (P6, A-03). Do not port the 49 lines as a replacement: it drops vanilla's `in_place` signal, which 248.2 objectives and `on_new_objective` consumers rely on.
7. **Acceptance.** T5, team-AI follow objectives (e.g. escort/defend with a follow unit). Log `evt=path_extend k=follow_reroute=1,mode=truncate|append,new_seg=<id>` and `k=follow_in_place=1` for the vanilla branch.
8. **Cost if wrong.** A mis-written coarse path entry (numeric v5 seg id instead of a 248.2 string id) makes `_get_exact_move_pos` read `coarse_path[i][1]` as a nil area, return nil `to_pos`, and the next `search_for_path` fails — the follower freezes. That is the single highest-risk write in the AI cluster.
9. **Evidence gaps.** `data.itr_follow_unit_nav_seg` is written only at the end of r200's body (`:311`) and never initialised in `enter`, so the very first call always takes the `nil` path — intended, but unverified against 248.2's objective lifecycle. `itr_get_door_between` is still an audit error (decisions R6), so this branch cannot pass `api-audit` until S-04/P7 lands.
