# Function dossier: lua/coplogictravel.lua :: CopLogicTravel.action_complete_clbk

Category: **MOD_EDIT_CLEAN**

- ITER: 11 lines, params `(data, action)`
- 246.1: 104 lines, params `(data, action)`
- 248.2: 104 lines, params `(data, action)`

Normalized signature: `self` is omitted for methods; the body is the porting surface.

## ITER body (V8.57)

```lua
function CopLogicTravel.action_complete_clbk(data, action)
if action.itr_fake_complete then
		local original_expired = action._expired
		action._expired = true
		data.internal_data.itr_want_path_ahead = action
		itr_original_coplogictravel_actioncompleteclbk(data, action)
		action._expired = original_expired
	else
		itr_original_coplogictravel_actioncompleteclbk(data, action)
	end
end
```

## 246.1 vanilla (a3180fc)

```lua
function CopLogicTravel.action_complete_clbk(data, action)
local my_data = data.internal_data
	local action_type = action:type()

	if action_type == "walk" then
		if action:expired() and not my_data.starting_advance_action and my_data.coarse_path_index and not my_data.has_old_action and my_data.advancing then
			my_data.coarse_path_index = my_data.coarse_path_index + 1

			if my_data.coarse_path_index > #my_data.coarse_path then
				debug_pause_unit(data.unit, "[CopLogicTravel.action_complete_clbk] invalid coarse path index increment", data.unit, inspect(my_data.coarse_path), my_data.coarse_path_index)

				my_data.coarse_path_index = my_data.coarse_path_index - 1
			end
		end

		my_data.advancing = nil

		if my_data.moving_to_cover then
			if action:expired() then
				if my_data.best_cover then
					managers.navigation:release_cover(my_data.best_cover[1])
				end

				my_data.best_cover = my_data.moving_to_cover

				CopLogicBase.chk_cancel_delayed_clbk(my_data, my_data.cover_update_task_key)

				local high_ray = CopLogicTravel._chk_cover_height(data, my_data.best_cover[1], data.visibility_slotmask)

				my_data.best_cover[4] = high_ray
				my_data.in_cover = true

				local cover_wait_time = my_data.coarse_path_index == #my_data.coarse_path - 1 and 0.3 or 0.6 + 0.4 * math.random()

				if not CopLogicTravel._chk_close_to_criminal(data, my_data) then
					cover_wait_time = 0
				end

				my_data.cover_leave_t = data.t + cover_wait_time
			else
				managers.navigation:release_cover(my_data.moving_to_cover[1])

				if my_data.best_cover then
					local dis = mvector3.distance(my_data.best_cover[1][1], data.unit:movement():m_pos())

					if dis > 100 then
						managers.navigation:release_cover(my_data.best_cover[1])

						my_data.best_cover = nil
					end
				end
			end

			my_data.moving_to_cover = nil
		elseif my_data.best_cover then
			local dis = mvector3.distance(my_data.best_cover[1][1], data.unit:movement():m_pos())

			if dis > 100 then
				managers.navigation:release_cover(my_data.best_cover[1])

				my_data.best_cover = nil
			end
		end

		if not action:expired() then
			if my_data.processing_advance_path then
				local pathing_results = data.pathing_results

				if pathing_results and pathing_results[my_data.advance_path_search_id] then
					data.pathing_results[my_data.advance_path_search_id] = nil
					my_data.processing_advance_path = nil
				end
			elseif my_data.advance_path then
				my_data.advance_path = nil
			end

			data.unit:brain():abort_detailed_pathing(my_data.advance_path_search_id)
		end
	elseif action_type == "turn" then
		data.internal_data.turning = nil
	elseif action_type == "shoot" then
		data.internal_data.shooting = nil
	elseif action_type == "dodge" then
		local objective = data.objective
		local allow_trans, obj_failed = CopLogicBase.is_obstructed(data, objective, nil, nil)

		if allow_trans then
			local wanted_state = data.logic._get_logic_state_from_reaction(data)

			if wanted_state and wanted_state ~= data.name and obj_failed then
				if data.unit:in_slot(managers.slot:get_mask("enemies")) or data.unit:in_slot(17) then
					data.objective_failed_clbk(data.unit, data.objective)
				elseif data.unit:in_slot(managers.slot:get_mask("criminals")) then
					managers.groupai:state():on_criminal_objective_failed(data.unit, data.objective, false)
				end

				if my_data == data.internal_data then
					debug_pause_unit(data.unit, "[CopLogicTravel.action_complete_clbk] exiting without discarding objective", data.unit, inspect(data.objective))
					CopLogicBase._exit(data.unit, wanted_state)
				end
			end
		end
	end
end
```

## 248.2 vanilla (e3a8b616)

```lua
function CopLogicTravel.action_complete_clbk(data, action)
local my_data = data.internal_data
	local action_type = action:type()

	if action_type == "walk" then
		if action:expired() and not my_data.starting_advance_action and my_data.coarse_path_index and not my_data.has_old_action and my_data.advancing then
			my_data.coarse_path_index = my_data.coarse_path_index + 1

			if my_data.coarse_path_index > #my_data.coarse_path then
				debug_pause_unit(data.unit, "[CopLogicTravel.action_complete_clbk] invalid coarse path index increment", data.unit, inspect(my_data.coarse_path), my_data.coarse_path_index)

				my_data.coarse_path_index = my_data.coarse_path_index - 1
			end
		end

		my_data.advancing = nil

		if my_data.moving_to_cover then
			if action:expired() then
				if my_data.best_cover then
					managers.navigation:release_cover(my_data.best_cover[1])
				end

				my_data.best_cover = my_data.moving_to_cover

				CopLogicBase.chk_cancel_delayed_clbk(my_data, my_data.cover_update_task_key)

				local high_ray = CopLogicTravel._chk_cover_height(data, my_data.best_cover[1], data.visibility_slotmask)

				my_data.best_cover[4] = high_ray
				my_data.in_cover = true

				local cover_wait_time = my_data.coarse_path_index == #my_data.coarse_path - 1 and 0.3 or 0.6 + 0.4 * math.random()

				if not CopLogicTravel._chk_close_to_criminal(data, my_data) then
					cover_wait_time = 0
				end

				my_data.cover_leave_t = data.t + cover_wait_time
			else
				managers.navigation:release_cover(my_data.moving_to_cover[1])

				if my_data.best_cover then
					local dis = mvector3.distance(my_data.best_cover[1][1], data.unit:movement():m_pos())

					if dis > 100 then
						managers.navigation:release_cover(my_data.best_cover[1])

						my_data.best_cover = nil
					end
				end
			end

			my_data.moving_to_cover = nil
		elseif my_data.best_cover then
			local dis = mvector3.distance(my_data.best_cover[1][1], data.unit:movement():m_pos())

			if dis > 100 then
				managers.navigation:release_cover(my_data.best_cover[1])

				my_data.best_cover = nil
			end
		end

		if not action:expired() then
			if my_data.processing_advance_path then
				local pathing_results = data.pathing_results

				if pathing_results and pathing_results[my_data.advance_path_search_id] then
					data.pathing_results[my_data.advance_path_search_id] = nil
					my_data.processing_advance_path = nil
				end
			elseif my_data.advance_path then
				my_data.advance_path = nil
			end

			data.unit:brain():abort_detailed_pathing(my_data.advance_path_search_id)
		end
	elseif action_type == "turn" then
		data.internal_data.turning = nil
	elseif action_type == "shoot" then
		data.internal_data.shooting = nil
	elseif action_type == "dodge" then
		local objective = data.objective
		local allow_trans, obj_failed = CopLogicBase.is_obstructed(data, objective, nil, nil)

		if allow_trans then
			local wanted_state = data.logic._get_logic_state_from_reaction(data)

			if wanted_state and wanted_state ~= data.name and obj_failed then
				if data.unit:in_slot(managers.slot:get_mask("enemies")) or data.unit:in_slot(17) then
					data.objective_failed_clbk(data.unit, data.objective)
				elseif data.unit:in_slot(managers.slot:get_mask("criminals")) then
					managers.groupai:state():on_criminal_objective_failed(data.unit, data.objective, false)
				end

				if my_data == data.internal_data then
					debug_pause_unit(data.unit, "[CopLogicTravel.action_complete_clbk] exiting without discarding objective", data.unit, inspect(data.objective))
					CopLogicBase._exit(data.unit, wanted_state)
				end
			end
		end
	end
end
```

## Diff 246.1 -> ITER

```diff
--- 246.1 vanilla
+++ ITER
@@ -1,103 +1,10 @@
-local my_data = data.internal_data
-	local action_type = action:type()
-
-	if action_type == "walk" then
-		if action:expired() and not my_data.starting_advance_action and my_data.coarse_path_index and not my_data.has_old_action and my_data.advancing then
-			my_data.coarse_path_index = my_data.coarse_path_index + 1
-
-			if my_data.coarse_path_index > #my_data.coarse_path then
-				debug_pause_unit(data.unit, "[CopLogicTravel.action_complete_clbk] invalid coarse path index increment", data.unit, inspect(my_data.coarse_path), my_data.coarse_path_index)
-
-				my_data.coarse_path_index = my_data.coarse_path_index - 1
-			end
-		end
-
-		my_data.advancing = nil
-
-		if my_data.moving_to_cover then
-			if action:expired() then
-				if my_data.best_cover then
-					managers.navigation:release_cover(my_data.best_cover[1])
-				end
-
-				my_data.best_cover = my_data.moving_to_cover
-
-				CopLogicBase.chk_cancel_delayed_clbk(my_data, my_data.cover_update_task_key)
-
-				local high_ray = CopLogicTravel._chk_cover_height(data, my_data.best_cover[1], data.visibility_slotmask)
-
-				my_data.best_cover[4] = high_ray
-				my_data.in_cover = true
-
-				local cover_wait_time = my_data.coarse_path_index == #my_data.coarse_path - 1 and 0.3 or 0.6 + 0.4 * math.random()
-
-				if not CopLogicTravel._chk_close_to_criminal(data, my_data) then
-					cover_wait_time = 0
-				end
-
-				my_data.cover_leave_t = data.t + cover_wait_time
-			else
-				managers.navigation:release_cover(my_data.moving_to_cover[1])
-
-				if my_data.best_cover then
-					local dis = mvector3.distance(my_data.best_cover[1][1], data.unit:movement():m_pos())
-
-					if dis > 100 then
-						managers.navigation:release_cover(my_data.best_cover[1])
-
-						my_data.best_cover = nil
-					end
-				end
-			end
-
-			my_data.moving_to_cover = nil
-		elseif my_data.best_cover then
-			local dis = mvector3.distance(my_data.best_cover[1][1], data.unit:movement():m_pos())
-
-			if dis > 100 then
-				managers.navigation:release_cover(my_data.best_cover[1])
-
-				my_data.best_cover = nil
-			end
-		end
-
-		if not action:expired() then
-			if my_data.processing_advance_path then
-				local pathing_results = data.pathing_results
-
-				if pathing_results and pathing_results[my_data.advance_path_search_id] then
-					data.pathing_results[my_data.advance_path_search_id] = nil
-					my_data.processing_advance_path = nil
-				end
-			elseif my_data.advance_path then
-				my_data.advance_path = nil
-			end
-
-			data.unit:brain():abort_detailed_pathing(my_data.advance_path_search_id)
-		end
-	elseif action_type == "turn" then
-		data.internal_data.turning = nil
-	elseif action_type == "shoot" then
-		data.internal_data.shooting = nil
-	elseif action_type == "dodge" then
-		local objective = data.objective
-		local allow_trans, obj_failed = CopLogicBase.is_obstructed(data, objective, nil, nil)
-
-		if allow_trans then
-			local wanted_state = data.logic._get_logic_state_from_reaction(data)
-
-			if wanted_state and wanted_state ~= data.name and obj_failed then
-				if data.unit:in_slot(managers.slot:get_mask("enemies")) or data.unit:in_slot(17) then
-					data.objective_failed_clbk(data.unit, data.objective)
-				elseif data.unit:in_slot(managers.slot:get_mask("criminals")) then
-					managers.groupai:state():on_criminal_objective_failed(data.unit, data.objective, false)
-				end
-
-				if my_data == data.internal_data then
-					debug_pause_unit(data.unit, "[CopLogicTravel.action_complete_clbk] exiting without discarding objective", data.unit, inspect(data.objective))
-					CopLogicBase._exit(data.unit, wanted_state)
-				end
-			end
-		end
-	end
+if action.itr_fake_complete then
+		local original_expired = action._expired
+		action._expired = true
+		data.internal_data.itr_want_path_ahead = action
+		itr_original_coplogictravel_actioncompleteclbk(data, action)
+		action._expired = original_expired
+	else
+		itr_original_coplogictravel_actioncompleteclbk(data, action)
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

1. **Wrapper or replacement.** Wrapper. `lua/coplogictravel.lua:314` captures `itr_original_coplogictravel_actioncompleteclbk`; `:315-325` fakes `action._expired = true` around the original call (`:320`), stashing the action in `my_data.itr_want_path_ahead`, then restores the original `_expired` value. `:326-328` additionally re-points `TeamAILogicTravel.action_complete_clbk` after load.
2. **Call sites.** r200: triggered by the fake-complete path in `_advance_simplified_path` (`lua/copactionwalk.lua:290`, `ext_brain:action_complete_clbk(self)`). 248.2: `lib/units/enemies/cop/copbrain.lua:580-582` (`self._current_logic.action_complete_clbk(...)`); definition `coplogictravel.lua:464-567`; the team alias already exists at `teamailogictravel.lua:20`.
3. **Intent.** When the path extender has appended the next coarse step, the current walk action must be allowed to end *without* the logic treating it as a real destination arrival, then be resumed on the next tick.
4. **248.2 delta.** None (file byte-identical 246.1↔248.2, definition at 464 in both). The field the trick relies on is unchanged: `CopActionWalk:expired()` still returns `self._expired` (`copactionwalk.lua:1431-1433`), and `action_complete_clbk` still branches on `action:expired()` at `:469`, `:482`, `:528`.
5. **Target mechanism.** Port as-is as a wrapper, under `path_extender`. The `DelayedCalls` re-alias at `:326-328` is **required**, not redundant: 248.2 `teamailogictravel.lua:20` binds the *vanilla* function at load, so without the re-alias team AI would bypass the wrapper.
6. **Decision.** **PORT** (P6, F3/A-01). Replace the `DelayedCalls:Add(..., 0)` re-alias with a direct assignment after the wrapper definition (the delayed one only works because nothing calls it in the same frame, which is fragile).
7. **Acceptance.** T5. Log `evt=path_extend k=fake_complete=1,coarse_index=<i>` plus `k=resume=1` on the next `upd_advance`; a missing `resume` after a `fake_complete` is the failure signature.
8. **Cost if wrong.** `_expired` left true leaks out of the wrapper and the action is treated as expired for the rest of its life (r200 restores it in the `else` path only, `:321`), or the wrong action is resumed — a unit walks to a stale coarse index. Both are visible as stuck cops, not crashes.
9. **Evidence gaps.** r200 restores `_expired` *after* the original call returns, so any vanilla code that stores the action during the call sees a fake-expired action. Whether any 248.2 listener does that is unverified; a T5 log with `k=has_old_action=1` would expose it.
