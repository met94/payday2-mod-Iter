# Function dossier: lua/coplogictravel.lua :: CopLogicTravel.upd_advance

Category: **MOD_EDIT_CLEAN**

- ITER: 14 lines, params `(data)`
- 246.1: 71 lines, params `(data)`
- 248.2: 71 lines, params `(data)`

Normalized signature: `self` is omitted for methods; the body is the porting surface.

## ITER body (V8.57)

```lua
function CopLogicTravel.upd_advance(data)
local my_data = data.internal_data
	if my_data.has_old_action then
		CopLogicAttack._upd_stop_old_action(data, my_data)
	elseif my_data.itr_want_path_ahead then
		if my_data.itr_want_path_ahead.itr_path_ahead then -- if interrupted
			my_data.advancing = my_data.itr_want_path_ahead
			CopLogicTravel._check_start_path_ahead(data)
		end
		my_data.itr_want_path_ahead = nil
	else
		itr_original_coplogictravel_updadvance(data)
	end
end
```

## 246.1 vanilla (a3180fc)

```lua
function CopLogicTravel.upd_advance(data)
local unit = data.unit
	local my_data = data.internal_data
	local objective = data.objective
	local t = TimerManager:game():time()

	data.t = t

	if my_data.has_old_action then
		CopLogicAttack._upd_stop_old_action(data, my_data)
	elseif my_data.warp_pos then
		local action_desc = {
			body_part = 1,
			type = "warp",
			position = mvector3.copy(objective.pos),
			rotation = objective.rot
		}

		if unit:movement():action_request(action_desc) then
			CopLogicTravel._on_destination_reached(data)
		end
	elseif my_data.advancing then
		if my_data.coarse_path then
			if my_data.announce_t and t > my_data.announce_t then
				CopLogicTravel._try_anounce(data, my_data)
			end

			CopLogicTravel._chk_stop_for_follow_unit(data, my_data)

			if my_data ~= data.internal_data then
				return
			end
		end
	elseif my_data.advance_path then
		CopLogicTravel._chk_begin_advance(data, my_data)

		if my_data.advancing and my_data.path_ahead then
			CopLogicTravel._check_start_path_ahead(data)
		end
	elseif my_data.processing_advance_path or my_data.processing_coarse_path then
		CopLogicTravel._upd_pathing(data, my_data)

		if my_data ~= data.internal_data then
			return
		end
	elseif my_data.cover_leave_t then
		if not my_data.turning and not unit:movement():chk_action_forbidden("walk") and not data.unit:anim_data().reload then
			if t > my_data.cover_leave_t then
				my_data.cover_leave_t = nil
			elseif data.attention_obj and data.attention_obj.reaction >= AIAttentionObject.REACT_SCARED and (not my_data.best_cover or not my_data.best_cover[4]) and not unit:anim_data().crouch and (not data.char_tweak.allowed_poses or data.char_tweak.allowed_poses.crouch) then
				CopLogicAttack._chk_request_action_crouch(data)
			end
		end
	elseif objective and (objective.nav_seg or objective.type == "follow") then
		if my_data.coarse_path then
			if my_data.coarse_path_index == #my_data.coarse_path then
				CopLogicTravel._on_destination_reached(data)

				return
			else
				CopLogicTravel._chk_start_pathing_to_next_nav_point(data, my_data)
			end
		else
			CopLogicTravel._begin_coarse_pathing(data, my_data)
		end
	else
		CopLogicBase._exit(data.unit, "idle")

		return
	end
end
```

## 248.2 vanilla (e3a8b616)

```lua
function CopLogicTravel.upd_advance(data)
local unit = data.unit
	local my_data = data.internal_data
	local objective = data.objective
	local t = TimerManager:game():time()

	data.t = t

	if my_data.has_old_action then
		CopLogicAttack._upd_stop_old_action(data, my_data)
	elseif my_data.warp_pos then
		local action_desc = {
			body_part = 1,
			type = "warp",
			position = mvector3.copy(objective.pos),
			rotation = objective.rot
		}

		if unit:movement():action_request(action_desc) then
			CopLogicTravel._on_destination_reached(data)
		end
	elseif my_data.advancing then
		if my_data.coarse_path then
			if my_data.announce_t and t > my_data.announce_t then
				CopLogicTravel._try_anounce(data, my_data)
			end

			CopLogicTravel._chk_stop_for_follow_unit(data, my_data)

			if my_data ~= data.internal_data then
				return
			end
		end
	elseif my_data.advance_path then
		CopLogicTravel._chk_begin_advance(data, my_data)

		if my_data.advancing and my_data.path_ahead then
			CopLogicTravel._check_start_path_ahead(data)
		end
	elseif my_data.processing_advance_path or my_data.processing_coarse_path then
		CopLogicTravel._upd_pathing(data, my_data)

		if my_data ~= data.internal_data then
			return
		end
	elseif my_data.cover_leave_t then
		if not my_data.turning and not unit:movement():chk_action_forbidden("walk") and not data.unit:anim_data().reload then
			if t > my_data.cover_leave_t then
				my_data.cover_leave_t = nil
			elseif data.attention_obj and data.attention_obj.reaction >= AIAttentionObject.REACT_SCARED and (not my_data.best_cover or not my_data.best_cover[4]) and not unit:anim_data().crouch and (not data.char_tweak.allowed_poses or data.char_tweak.allowed_poses.crouch) then
				CopLogicAttack._chk_request_action_crouch(data)
			end
		end
	elseif objective and (objective.nav_seg or objective.type == "follow") then
		if my_data.coarse_path then
			if my_data.coarse_path_index == #my_data.coarse_path then
				CopLogicTravel._on_destination_reached(data)

				return
			else
				CopLogicTravel._chk_start_pathing_to_next_nav_point(data, my_data)
			end
		else
			CopLogicTravel._begin_coarse_pathing(data, my_data)
		end
	else
		CopLogicBase._exit(data.unit, "idle")

		return
	end
end
```

## Diff 246.1 -> ITER

```diff
--- 246.1 vanilla
+++ ITER
@@ -1,70 +1,13 @@
-local unit = data.unit
-	local my_data = data.internal_data
-	local objective = data.objective
-	local t = TimerManager:game():time()
-
-	data.t = t
-
-	if my_data.has_old_action then
-		CopLogicAttack._upd_stop_old_action(data, my_data)
-	elseif my_data.warp_pos then
-		local action_desc = {
-			body_part = 1,
-			type = "warp",
-			position = mvector3.copy(objective.pos),
-			rotation = objective.rot
-		}
-
-		if unit:movement():action_request(action_desc) then
-			CopLogicTravel._on_destination_reached(data)
-		end
-	elseif my_data.advancing then
-		if my_data.coarse_path then
-			if my_data.announce_t and t > my_data.announce_t then
-				CopLogicTravel._try_anounce(data, my_data)
-			end
-
-			CopLogicTravel._chk_stop_for_follow_unit(data, my_data)
-
-			if my_data ~= data.internal_data then
-				return
-			end
-		end
-	elseif my_data.advance_path then
-		CopLogicTravel._chk_begin_advance(data, my_data)
-
-		if my_data.advancing and my_data.path_ahead then
-			CopLogicTravel._check_start_path_ahead(data)
-		end
-	elseif my_data.processing_advance_path or my_data.processing_coarse_path then
-		CopLogicTravel._upd_pathing(data, my_data)
-
-		if my_data ~= data.internal_data then
-			return
-		end
-	elseif my_data.cover_leave_t then
-		if not my_data.turning and not unit:movement():chk_action_forbidden("walk") and not data.unit:anim_data().reload then
-			if t > my_data.cover_leave_t then
-				my_data.cover_leave_t = nil
-			elseif data.attention_obj and data.attention_obj.reaction >= AIAttentionObject.REACT_SCARED and (not my_data.best_cover or not my_data.best_cover[4]) and not unit:anim_data().crouch and (not data.char_tweak.allowed_poses or data.char_tweak.allowed_poses.crouch) then
-				CopLogicAttack._chk_request_action_crouch(data)
-			end
-		end
-	elseif objective and (objective.nav_seg or objective.type == "follow") then
-		if my_data.coarse_path then
-			if my_data.coarse_path_index == #my_data.coarse_path then
-				CopLogicTravel._on_destination_reached(data)
-
-				return
-			else
-				CopLogicTravel._chk_start_pathing_to_next_nav_point(data, my_data)
-			end
-		else
-			CopLogicTravel._begin_coarse_pathing(data, my_data)
-		end
-	else
-		CopLogicBase._exit(data.unit, "idle")
-
-		return
-	end
+local my_data = data.internal_data
+	if my_data.has_old_action then
+		CopLogicAttack._upd_stop_old_action(data, my_data)
+	elseif my_data.itr_want_path_ahead then
+		if my_data.itr_want_path_ahead.itr_path_ahead then -- if interrupted
+			my_data.advancing = my_data.itr_want_path_ahead
+			CopLogicTravel._check_start_path_ahead(data)
+		end
+		my_data.itr_want_path_ahead = nil
+	else
+		itr_original_coplogictravel_updadvance(data)
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

1. **Wrapper or replacement.** Wrapper. `lua/coplogictravel.lua:387` captures `itr_original_coplogictravel_updadvance`; `:388-401` intercepts `my_data.has_old_action` and `my_data.itr_want_path_ahead`, otherwise calls the original at `:399`.
2. **Call sites.** r200: class override (the logic table calls `CopLogicTravel.upd_advance`). 248.2: `lib/units/enemies/cop/logics/coplogictravel.lua:200` (the `advancing` branch of `CopLogicTravel.update`); definition `:215-285`; also `teamailogictravel.lua:176` (`return CopLogicTravel.upd_advance(data)`).
3. **Intent.** On the tick after a fake-complete, put the stashed walk action back as `my_data.advancing` and immediately start the next path-ahead search, instead of letting vanilla rebuild the action from `advance_path`.
4. **248.2 delta.** None (file byte-identical 246.1↔248.2). The vanilla body is 71 lines (`:215-285`) with branches `has_old_action` (`:223`), `warp_pos` (`:225`), `advancing` (`:236`), `advance_path` (`:248`), `processing_*` (`:254`), `cover_leave_t` (`:260`), objective fallback (`:268`).
5. **Target mechanism.** Port as-is but restructure: call the original unconditionally first, then apply the resume branch. r200 skips vanilla entirely while `itr_want_path_ahead` is set, which also skips `data.t = t` (`:219-221`) and the `_chk_stop_for_follow_unit` call (`:242`); with the original called first, only the resume is added.
6. **Decision.** **PORT** (P6, F3/A-01), with the restructure above. Pure wrapper otherwise; fields `my_data.itr_want_path_ahead`, `my_data.advancing`, `action.itr_path_ahead`.
7. **Acceptance.** T5. Log `evt=path_extend k=resume=1,skipped_vanilla=0|1,t_stale=0`; `t_stale=1` is the failure signature of the r200 shape.
8. **Cost if wrong.** One tick without vanilla `upd_advance` means `data.t`, `cover_leave_t`, `announce_t` and follow-unit checking all lag by one frame per fake-complete; in a fight that is a single frozen step, but repeated fake-completes could starve the branch and look like stuttering AI.
9. **Evidence gaps.** r200's `has_old_action` branch calls `CopLogicAttack._upd_stop_old_action(data, my_data)` directly, duplicating vanilla `:224`; harmless but must not be ported twice after the restructure. No measurement of how often fake-complete fires per minute exists yet (the T5 log would give it).
