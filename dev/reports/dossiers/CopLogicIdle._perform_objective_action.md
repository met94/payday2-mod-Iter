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

## Port notes (P1)

1. **Wrapper or replacement.** Wrapper. `lua/coplogicidle.lua:8` captures `itr_original_coplogicidle_performobjectiveaction`; `:9-14` rewrites the objective's action variant when it is `e_so_ntl_idle_look3`, then calls the original.
2. **Call sites.** r200: class override. 248.2: `lib/units/enemies/cop/logics/coplogicidle.lua:126` and `:200`; definition `:1608-1632`; also aliased by `coplogicphalanxminion.lua:18` and `coplogicphalanxvip.lua:17`, which call it at `:102`, `:147` / `:99`, `:162`.
3. **Intent.** Cosmetic animation fallback: when an SO hands the unit the `look3` idle action, use `look2` instead — presumably because `look3` was missing or wrong-facing on some heists.
4. **248.2 delta.** None in the function. `pd2diff 246.1 248.2` hunks in `coplogicidle.lua` are at 406 (`data.t` → `t` in `damage_clbk`) and 931 (`on_area_safety` computes `TimerManager:game():time()`); both are unrelated to `_perform_objective_action`, which is identical at `:1608` in 246.1 and 248.2.
5. **Target mechanism.** Port as-is if kept — both variant strings still exist at 248.2 (`elementspecialobjective.lua:854-855`, `copactionact.lua:790-791`), and the swap is a one-line pre-call mutation of `objective.action.variant`.
6. **Decision.** **DEFER** (intent map row, unchanged). It is cosmetic, it silently mutates an SO-owned table, and the phalanx classes alias the function so the swap also applies to units the author never tested. Revisit only with a specific heist report of a broken `look3`.
7. **Acceptance.** T5 on a level with `ntl` idle SOs; log `evt=fallback k=reason=variant_swap,from=e_so_ntl_idle_look3,to=e_so_ntl_idle_look2,heist=<id>` so a heist-specific need is measurable before enabling it.
8. **Cost if wrong.** Visual only: a unit faces the wrong way while idling, or plays a missing animation and T-poses. No pathing, no combat effect.
9. **Evidence gaps.** No record of *which* heist motivated the swap, and no list of SO elements that emit `look3` at 248.2. Without that, the flag has no testable acceptance beyond "no T-pose".
