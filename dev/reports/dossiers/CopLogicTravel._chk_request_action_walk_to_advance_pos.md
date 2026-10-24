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

## Port notes (P1)

1. **Wrapper or replacement.** Wrapper with varargs. `lua/coplogictravel.lua:330` captures `itr_original_coplogictravel_chkrequestactionwalktoadvancepos`; `:331` declares `(data, my_data, ...)`, prepends a start position at `:334` when the advance path is a single point, calls the original at `:338` with `...`, then flags the action at `:341`.
2. **Call sites.** r200: class override. 248.2: `coplogictravel.lua:1609` (from `_chk_start_advance_action`) and `lib/units/enemies/cop/logics/coplogicsniper.lua:298` (`objective.haste or "walk"`, `objective.rot`); definition `:751-781`.
3. **Intent.** In stealth (`not _is_loud`), guarantee the walk action receives at least two nav points; a one-point path makes `CopActionWalk` read `_simplified_path[2]` as nil later. Then mark the started action so `_advance_simplified_path` knows it may be appended to.
4. **248.2 delta.** Signature **extended** between the r200 target and 248.2: vanilla is now `(data, my_data, speed, end_rot, no_strafe, pose, end_pose)` (`:751`) versus the 4-arg form r200 was written against; the call site supplies `pose`/`end_pose` at `:1609`. The body also grew a start-point fixer: `CopLogicAttack._correct_path_start_pos(data, my_data.advance_path)` at `:753`, defined at `coplogicattack.lua:550-557` (inserts `data.m_pos` when the first point's xy differs).
5. **Target mechanism.** Port the wrapper as-is (`...` already future-proofs the signature) but narrow the insert: only when `not my_data.advance_path[2]` **and** the existing first point is not already `data.m_pos`, so the two start-point mechanisms cannot both add a point. Keep `my_data.advancing.itr_path_ahead = true` (`:340-342`) unconditionally.
6. **Decision.** **PORT** (P6, F3/A-02). The varargs capture is what makes this safe across the 248.2 signature; do not "tidy" it into named parameters.
7. **Acceptance.** T5, with a stealth heist in the set. Log `evt=path_extend k=prepended=0|1,points=<n>,loud=0|1`.
8. **Cost if wrong.** A duplicate first point gives a zero-length segment; `CopActionWalk:_chk_start_anim` then has a zero direction and the unit can spin or refuse to start. In loud, r200 skips the insert entirely, so a one-point path there relies on vanilla `_correct_path_start_pos` alone.
9. **Evidence gaps.** `_is_loud` is a file-local flag set by an `enemy_weapons_hot` listener registered in a `DelayedCalls` (`:14-18`); if the listener is registered after a level starts, the first heist segment behaves as stealth. No log field currently exposes `_is_loud` at this call site — the proposed `loud=` field closes that.
