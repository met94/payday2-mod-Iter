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
