# Function dossier: lua/coplogicidle.lua :: CopLogicIdle._perform_objective_action

Category: **MOD_EDIT_CLEAN**

- ITER: 6 lines, params `(data, my_data, objective)`
- 246.1: 25 lines, params `(data, my_data, objective)`
- 248.2: 25 lines, params `(data, my_data, objective)`

Normalized signature: `self` is omitted for methods; the body is the porting surface.

## ITER body (V8.57)

```lua
function CopLogicIdle._perform_objective_action(data, my_data, objective)
if objective and objective.action and objective.action.variant == 'e_so_ntl_idle_look3' then
		objective.action.variant = 'e_so_ntl_idle_look2'
	end
	itr_original_coplogicidle_performobjectiveaction(data, my_data, objective)
end
```

## 246.1 vanilla (a3180fc)

```lua
function CopLogicIdle._perform_objective_action(data, my_data, objective)
if objective and not my_data.action_started and (data.unit:anim_data().act_idle or not data.unit:movement():chk_action_forbidden("action")) then
		if objective.action then
			my_data.action_started = data.unit:brain():action_request(objective.action)
		else
			my_data.action_started = true
		end

		if my_data.action_started then
			if objective.action_duration or objective.action_timeout_t then
				my_data.action_timeout_clbk_id = "CopLogicIdle_action_timeout" .. tostring(data.key)

				local action_timeout_t = objective.action_timeout_t or data.t + objective.action_duration

				objective.action_timeout_t = action_timeout_t

				CopLogicBase.add_delayed_clbk(my_data, my_data.action_timeout_clbk_id, callback(CopLogicIdle, CopLogicIdle, "clbk_action_timeout", data), action_timeout_t)
			end

			if objective.action_start_clbk then
				objective.action_start_clbk(data.unit)
			end
		end
	end
end
```

## 248.2 vanilla (e3a8b616)

```lua
function CopLogicIdle._perform_objective_action(data, my_data, objective)
if objective and not my_data.action_started and (data.unit:anim_data().act_idle or not data.unit:movement():chk_action_forbidden("action")) then
		if objective.action then
			my_data.action_started = data.unit:brain():action_request(objective.action)
		else
			my_data.action_started = true
		end

		if my_data.action_started then
			if objective.action_duration or objective.action_timeout_t then
				my_data.action_timeout_clbk_id = "CopLogicIdle_action_timeout" .. tostring(data.key)

				local action_timeout_t = objective.action_timeout_t or data.t + objective.action_duration

				objective.action_timeout_t = action_timeout_t

				CopLogicBase.add_delayed_clbk(my_data, my_data.action_timeout_clbk_id, callback(CopLogicIdle, CopLogicIdle, "clbk_action_timeout", data), action_timeout_t)
			end

			if objective.action_start_clbk then
				objective.action_start_clbk(data.unit)
			end
		end
	end
end
```

## Diff 246.1 -> ITER

```diff
--- 246.1 vanilla
+++ ITER
@@ -1,24 +1,5 @@
-if objective and not my_data.action_started and (data.unit:anim_data().act_idle or not data.unit:movement():chk_action_forbidden("action")) then
-		if objective.action then
-			my_data.action_started = data.unit:brain():action_request(objective.action)
-		else
-			my_data.action_started = true
-		end
-
-		if my_data.action_started then
-			if objective.action_duration or objective.action_timeout_t then
-				my_data.action_timeout_clbk_id = "CopLogicIdle_action_timeout" .. tostring(data.key)
-
-				local action_timeout_t = objective.action_timeout_t or data.t + objective.action_duration
-
-				objective.action_timeout_t = action_timeout_t
-
-				CopLogicBase.add_delayed_clbk(my_data, my_data.action_timeout_clbk_id, callback(CopLogicIdle, CopLogicIdle, "clbk_action_timeout", data), action_timeout_t)
-			end
-
-			if objective.action_start_clbk then
-				objective.action_start_clbk(data.unit)
-			end
-		end
+if objective and objective.action and objective.action.variant == 'e_so_ntl_idle_look3' then
+		objective.action.variant = 'e_so_ntl_idle_look2'
 	end
+	itr_original_coplogicidle_performobjectiveaction(data, my_data, objective)
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
