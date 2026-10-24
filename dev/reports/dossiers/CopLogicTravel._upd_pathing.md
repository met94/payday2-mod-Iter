# Function dossier: lua/coplogictravel.lua :: CopLogicTravel._upd_pathing

Category: **MOD_EDIT_CLEAN**

- ITER: 29 lines, params `(data, my_data)`
- 246.1: 44 lines, params `(data, my_data)`
- 248.2: 44 lines, params `(data, my_data)`

Normalized signature: `self` is omitted for methods; the body is the porting surface.

## ITER body (V8.57)

```lua
function CopLogicTravel._upd_pathing(data, my_data)
local pathing_results = data.pathing_results
	if pathing_results then
		if my_data.processing_coarse_path then
			local path = pathing_results[my_data.coarse_path_search_id]
			if path == 'failed' and not my_data.path_safely then
				local current_SO_element = data.objective and data.objective.followup_SO
				if not current_SO_element then
					-- qued
				elseif current_SO_element._events and current_SO_element._events.fail then
					-- qued, don't bypass error handling when it exists!
				else
					local unit = data.unit
					local so_element = current_SO_element:choose_followup_SO(unit)
					if so_element then
						local new_objective = so_element:get_objective(unit)
						if new_objective then
							my_data.processing_coarse_path = nil
							data.brain:set_objective(new_objective)
							return
						end
					end
				end
			end
		end
	end

	itr_original_coplogictravel_updpathing(data, my_data)
end
```

## 246.1 vanilla (a3180fc)

```lua
function CopLogicTravel._upd_pathing(data, my_data)
if data.pathing_results then
		local pathing_results = data.pathing_results

		data.pathing_results = nil

		local path = pathing_results[my_data.advance_path_search_id]

		if path and my_data.processing_advance_path then
			my_data.processing_advance_path = nil

			if path ~= "failed" then
				my_data.advance_path = path
			else
				data.path_fail_t = data.t

				data.objective_failed_clbk(data.unit, data.objective)

				return
			end
		end

		local path = pathing_results[my_data.coarse_path_search_id]

		if path and my_data.processing_coarse_path then
			my_data.processing_coarse_path = nil

			if path ~= "failed" then
				my_data.coarse_path = path
				my_data.coarse_path_index = 1
			elseif my_data.path_safely then
				my_data.path_safely = nil
			else
				print("[CopLogicTravel:_upd_pathing] coarse_path failed unsafe", data.unit, my_data.coarse_path_index)

				data.path_fail_t = data.t

				data.objective_failed_clbk(data.unit, data.objective)

				return
			end
		end
	end
end
```

## 248.2 vanilla (e3a8b616)

```lua
function CopLogicTravel._upd_pathing(data, my_data)
if data.pathing_results then
		local pathing_results = data.pathing_results

		data.pathing_results = nil

		local path = pathing_results[my_data.advance_path_search_id]

		if path and my_data.processing_advance_path then
			my_data.processing_advance_path = nil

			if path ~= "failed" then
				my_data.advance_path = path
			else
				data.path_fail_t = data.t

				data.objective_failed_clbk(data.unit, data.objective)

				return
			end
		end

		local path = pathing_results[my_data.coarse_path_search_id]

		if path and my_data.processing_coarse_path then
			my_data.processing_coarse_path = nil

			if path ~= "failed" then
				my_data.coarse_path = path
				my_data.coarse_path_index = 1
			elseif my_data.path_safely then
				my_data.path_safely = nil
			else
				print("[CopLogicTravel:_upd_pathing] coarse_path failed unsafe", data.unit, my_data.coarse_path_index)

				data.path_fail_t = data.t

				data.objective_failed_clbk(data.unit, data.objective)

				return
			end
		end
	end
end
```

## Diff 246.1 -> ITER

```diff
--- 246.1 vanilla
+++ ITER
@@ -1,43 +1,28 @@
-if data.pathing_results then
-		local pathing_results = data.pathing_results
-
-		data.pathing_results = nil
-
-		local path = pathing_results[my_data.advance_path_search_id]
-
-		if path and my_data.processing_advance_path then
-			my_data.processing_advance_path = nil
-
-			if path ~= "failed" then
-				my_data.advance_path = path
-			else
-				data.path_fail_t = data.t
-
-				data.objective_failed_clbk(data.unit, data.objective)
-
-				return
-			end
-		end
-
-		local path = pathing_results[my_data.coarse_path_search_id]
-
-		if path and my_data.processing_coarse_path then
-			my_data.processing_coarse_path = nil
-
-			if path ~= "failed" then
-				my_data.coarse_path = path
-				my_data.coarse_path_index = 1
-			elseif my_data.path_safely then
-				my_data.path_safely = nil
-			else
-				print("[CopLogicTravel:_upd_pathing] coarse_path failed unsafe", data.unit, my_data.coarse_path_index)
-
-				data.path_fail_t = data.t
-
-				data.objective_failed_clbk(data.unit, data.objective)
-
-				return
-			end
-		end
-	end
+local pathing_results = data.pathing_results
+	if pathing_results then
+		if my_data.processing_coarse_path then
+			local path = pathing_results[my_data.coarse_path_search_id]
+			if path == 'failed' and not my_data.path_safely then
+				local current_SO_element = data.objective and data.objective.followup_SO
+				if not current_SO_element then
+					-- qued
+				elseif current_SO_element._events and current_SO_element._events.fail then
+					-- qued, don't bypass error handling when it exists!
+				else
+					local unit = data.unit
+					local so_element = current_SO_element:choose_followup_SO(unit)
+					if so_element then
+						local new_objective = so_element:get_objective(unit)
+						if new_objective then
+							my_data.processing_coarse_path = nil
+							data.brain:set_objective(new_objective)
+							return
+						end
+					end
+				end
+			end
+		end
+	end
+
+	itr_original_coplogictravel_updpathing(data, my_data)
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

1. **Wrapper or replacement.** Wrapper. `lua/coplogictravel.lua:33` captures `itr_original_coplogictravel_updpathing`; the body `:34-62` inspects `data.pathing_results` first, then calls the original at `:61` — unless it took the followup-SO branch and returned early at `:53`.
2. **Call sites.** r200: class override. 248.2: `lib/units/enemies/cop/logics/coplogictravel.lua:255` (from `upd_advance`, the `processing_advance_path or processing_coarse_path` branch); definition `:350-393`; also aliased as `TeamAILogicTravel._upd_pathing` at `lib/units/player_team/logics/teamailogictravel.lua:13`.
3. **Intent.** A failed coarse search on a safe-path objective should hand over to the current SO's `followup_SO` (choose another objective) instead of failing the whole objective, as long as the SO has no explicit `fail` event to bypass.
4. **248.2 delta.** None. `coplogictravel.lua` is **byte-identical** between `a3180fc` (246.1) and `e3a8b616` (248.2) — `git diff --no-index` on the two blobs is empty and `pd2diff` lists no changes for the file; all definitions sit at the same lines (350, 464, 751, 1331, 1369, 1411, 1554, 1612).
5. **Target mechanism.** Port as-is as a wrapper. The APIs it needs still exist at 248.2: `objective.followup_SO` (`elementspecialobjective.lua:425`), `ElementSpecialObjective:choose_followup_SO(unit, skip_ids)` (`:751`), `element._events` (`:185`, `:293`), `my_data.path_safely` (`coplogictravel.lua:157`, `:380`). Fields: `my_data.processing_coarse_path`, `my_data.coarse_path_search_id`.
6. **Decision.** **PORT** (P6) with two fixes: clear `data.pathing_results` before the early `return` at `:53` (or 248.2's `:354` never runs and a stale table survives), and pass `nil` rather than nothing to `choose_followup_SO` (r200 `:47` already does).
7. **Acceptance.** T5. Log `evt=fallback k=reason=followup_so,so=<id>` on the handover and `evt=search k=ok=0,safely=0` on the failure that triggered it; a heist must not show an objective-failed spike with this branch active.
8. **Cost if wrong.** If a followup SO is chosen where vanilla would have failed the objective, units can be re-tasked into a loop (`set_objective` → path fails → same followup). The `_events.fail` guard only covers SOs that registered a fail handler.
9. **Evidence gaps.** The r200 path only triggers for `path_safely` objectives set in `CopLogicTravel.enter` (`:157`); whether any 248.2 level still builds such objectives with `followup_SO` populated is unverified. If none do, this wrapper is dead weight and should be dropped at the review gate.
