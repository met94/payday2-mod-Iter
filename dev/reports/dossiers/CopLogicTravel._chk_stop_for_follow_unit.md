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
