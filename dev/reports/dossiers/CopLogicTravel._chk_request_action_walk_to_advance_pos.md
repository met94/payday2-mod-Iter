# Function dossier: lua/coplogictravel.lua :: CopLogicTravel._chk_request_action_walk_to_advance_pos

Category: **MOD_EDIT_CLEAN**

- ITER: 13 lines, params `(data, my_data, ...)`
- 246.1: 31 lines, params `(data, my_data, speed, end_rot, no_strafe, pose, end_pose)`
- 248.2: 31 lines, params `(data, my_data, speed, end_rot, no_strafe, pose, end_pose)`

Normalized signature: `self` is omitted for methods; the body is the porting surface.

## ITER body (V8.57)

```lua
function CopLogicTravel._chk_request_action_walk_to_advance_pos(data, my_data, ...)
if not _is_loud then
		if my_data.advance_path and not my_data.advance_path[2] then
			table.insert(my_data.advance_path, 1, mvector3.copy(data.m_pos)) -- or crash later when checking _simplified_path[2].x in CopActionWalk
		end
	end

	itr_original_coplogictravel_chkrequestactionwalktoadvancepos(data, my_data, ...)

	if my_data.path_ahead and my_data.advancing then
		my_data.advancing.itr_path_ahead = true
	end
end
```

## 246.1 vanilla (a3180fc)

```lua
function CopLogicTravel._chk_request_action_walk_to_advance_pos(data, my_data, speed, end_rot, no_strafe, pose, end_pose)
if not data.unit:movement():chk_action_forbidden("walk") or data.unit:anim_data().act_idle then
		CopLogicAttack._correct_path_start_pos(data, my_data.advance_path)

		local path = my_data.advance_path
		local new_action_data = {
			body_part = 2,
			type = "walk",
			nav_path = path,
			variant = speed or "run",
			end_rot = end_rot,
			path_simplified = my_data.path_is_precise,
			no_strafe = no_strafe,
			pose = pose,
			end_pose = end_pose
		}

		my_data.advance_path = nil
		my_data.starting_advance_action = true
		my_data.advancing = data.unit:brain():action_request(new_action_data)
		my_data.starting_advance_action = false

		if my_data.advancing then
			data.brain:rem_pos_rsrv("path")

			if my_data.nearest_cover and (not my_data.delayed_clbks or not my_data.delayed_clbks[my_data.cover_update_task_key]) then
				CopLogicBase.add_delayed_clbk(my_data, my_data.cover_update_task_key, callback(CopLogicTravel, CopLogicTravel, "_update_cover", data), data.t + 1)
			end
		end
	end
end
```

## 248.2 vanilla (e3a8b616)

```lua
function CopLogicTravel._chk_request_action_walk_to_advance_pos(data, my_data, speed, end_rot, no_strafe, pose, end_pose)
if not data.unit:movement():chk_action_forbidden("walk") or data.unit:anim_data().act_idle then
		CopLogicAttack._correct_path_start_pos(data, my_data.advance_path)

		local path = my_data.advance_path
		local new_action_data = {
			body_part = 2,
			type = "walk",
			nav_path = path,
			variant = speed or "run",
			end_rot = end_rot,
			path_simplified = my_data.path_is_precise,
			no_strafe = no_strafe,
			pose = pose,
			end_pose = end_pose
		}

		my_data.advance_path = nil
		my_data.starting_advance_action = true
		my_data.advancing = data.unit:brain():action_request(new_action_data)
		my_data.starting_advance_action = false

		if my_data.advancing then
			data.brain:rem_pos_rsrv("path")

			if my_data.nearest_cover and (not my_data.delayed_clbks or not my_data.delayed_clbks[my_data.cover_update_task_key]) then
				CopLogicBase.add_delayed_clbk(my_data, my_data.cover_update_task_key, callback(CopLogicTravel, CopLogicTravel, "_update_cover", data), data.t + 1)
			end
		end
	end
end
```

## Diff 246.1 -> ITER

```diff
--- 246.1 vanilla
+++ ITER
@@ -1,30 +1,12 @@
-if not data.unit:movement():chk_action_forbidden("walk") or data.unit:anim_data().act_idle then
-		CopLogicAttack._correct_path_start_pos(data, my_data.advance_path)
-
-		local path = my_data.advance_path
-		local new_action_data = {
-			body_part = 2,
-			type = "walk",
-			nav_path = path,
-			variant = speed or "run",
-			end_rot = end_rot,
-			path_simplified = my_data.path_is_precise,
-			no_strafe = no_strafe,
-			pose = pose,
-			end_pose = end_pose
-		}
-
-		my_data.advance_path = nil
-		my_data.starting_advance_action = true
-		my_data.advancing = data.unit:brain():action_request(new_action_data)
-		my_data.starting_advance_action = false
-
-		if my_data.advancing then
-			data.brain:rem_pos_rsrv("path")
-
-			if my_data.nearest_cover and (not my_data.delayed_clbks or not my_data.delayed_clbks[my_data.cover_update_task_key]) then
-				CopLogicBase.add_delayed_clbk(my_data, my_data.cover_update_task_key, callback(CopLogicTravel, CopLogicTravel, "_update_cover", data), data.t + 1)
-			end
-		end
-	end
+if not _is_loud then
+		if my_data.advance_path and not my_data.advance_path[2] then
+			table.insert(my_data.advance_path, 1, mvector3.copy(data.m_pos)) -- or crash later when checking _simplified_path[2].x in CopActionWalk
+		end
+	end
+
+	itr_original_coplogictravel_chkrequestactionwalktoadvancepos(data, my_data, ...)
+
+	if my_data.path_ahead and my_data.advancing then
+		my_data.advancing.itr_path_ahead = true
+	end
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
