# Function dossier: lua/copbrain.lua :: CopBrain.clbk_pathing_results

Category: **MOD_EDIT_CLEAN**

- ITER: 21 lines, params `(search_id, path)`
- 246.1: 41 lines, params `(search_id, path)`
- 248.2: 41 lines, params `(search_id, path)`

Normalized signature: `self` is omitted for methods; the body is the porting surface.

## ITER body (V8.57)

```lua
function CopBrain.clbk_pathing_results(search_id, path)
itr_original_copbrain_clbkpathingresults(self, search_id, path)
	if path then
		local my_data = self._logic_data.internal_data
		if my_data.coarse_path then
			local walk_action = my_data.advancing
			if walk_action and walk_action:itr_append_next_step(path) then
				self._logic_data.pathing_results[search_id] = nil
				my_data.processing_advance_path = nil
				if my_data.coarse_path_index >= #my_data.coarse_path - 2 then
					if self._logic_data.objective then
						local end_rot = self._logic_data.objective.rot
						if end_rot then
							walk_action._end_rot = end_rot
						end
					end
				end
			end
		end
	end
end
```

## 246.1 vanilla (a3180fc)

```lua
function CopBrain.clbk_pathing_results(search_id, path)
local dead_nav_link_id = self._nav_links_to_check_on_results and self._nav_links_to_check_on_results[search_id]

	if dead_nav_link_id then
		if path then
			for i, nav_point in ipairs(path) do
				if not nav_point.x and (not alive(nav_point) or nav_point:script_data().element:id() == dead_nav_link_id) then
					path = nil

					break
				end
			end

			self._nav_links_to_check_on_results[search_id] = nil

			if not next(self._nav_links_to_check_on_results) then
				self._nav_links_to_check_on_results = nil
			end
		else
			self._nav_links_to_check_on_results[search_id] = nil

			if not next(self._nav_links_to_check_on_results) then
				self._nav_links_to_check_on_results = nil
			end
		end
	end

	self:_add_pathing_result(search_id, path)

	if path then
		local t

		for i, nav_point in ipairs(path) do
			if not nav_point.x and nav_point:script_data().element:nav_link_delay() > 0 then
				t = t or TimerManager:game():time()

				nav_point:set_delay_time(t + nav_point:script_data().element:nav_link_delay())
			end
		end
	end
end
```

## 248.2 vanilla (e3a8b616)

```lua
function CopBrain.clbk_pathing_results(search_id, path)
local dead_nav_link_id = self._nav_links_to_check_on_results and self._nav_links_to_check_on_results[search_id]

	if dead_nav_link_id then
		if path then
			for i, nav_point in ipairs(path) do
				if not nav_point.x and (not alive(nav_point) or nav_point:script_data().element:id() == dead_nav_link_id) then
					path = nil

					break
				end
			end

			self._nav_links_to_check_on_results[search_id] = nil

			if not next(self._nav_links_to_check_on_results) then
				self._nav_links_to_check_on_results = nil
			end
		else
			self._nav_links_to_check_on_results[search_id] = nil

			if not next(self._nav_links_to_check_on_results) then
				self._nav_links_to_check_on_results = nil
			end
		end
	end

	self:_add_pathing_result(search_id, path)

	if path then
		local t

		for i, nav_point in ipairs(path) do
			if not nav_point.x and nav_point:script_data().element:nav_link_delay() > 0 then
				t = t or TimerManager:game():time()

				nav_point:set_delay_time(t + nav_point:script_data().element:nav_link_delay())
			end
		end
	end
end
```

## Diff 246.1 -> ITER

```diff
--- 246.1 vanilla
+++ ITER
@@ -1,40 +1,20 @@
-local dead_nav_link_id = self._nav_links_to_check_on_results and self._nav_links_to_check_on_results[search_id]
-
-	if dead_nav_link_id then
-		if path then
-			for i, nav_point in ipairs(path) do
-				if not nav_point.x and (not alive(nav_point) or nav_point:script_data().element:id() == dead_nav_link_id) then
-					path = nil
-
-					break
-				end
-			end
-
-			self._nav_links_to_check_on_results[search_id] = nil
-
-			if not next(self._nav_links_to_check_on_results) then
-				self._nav_links_to_check_on_results = nil
-			end
-		else
-			self._nav_links_to_check_on_results[search_id] = nil
-
-			if not next(self._nav_links_to_check_on_results) then
-				self._nav_links_to_check_on_results = nil
-			end
-		end
-	end
-
-	self:_add_pathing_result(search_id, path)
-
-	if path then
-		local t
-
-		for i, nav_point in ipairs(path) do
-			if not nav_point.x and nav_point:script_data().element:nav_link_delay() > 0 then
-				t = t or TimerManager:game():time()
-
-				nav_point:set_delay_time(t + nav_point:script_data().element:nav_link_delay())
-			end
-		end
-	end
+itr_original_copbrain_clbkpathingresults(self, search_id, path)
+	if path then
+		local my_data = self._logic_data.internal_data
+		if my_data.coarse_path then
+			local walk_action = my_data.advancing
+			if walk_action and walk_action:itr_append_next_step(path) then
+				self._logic_data.pathing_results[search_id] = nil
+				my_data.processing_advance_path = nil
+				if my_data.coarse_path_index >= #my_data.coarse_path - 2 then
+					if self._logic_data.objective then
+						local end_rot = self._logic_data.objective.rot
+						if end_rot then
+							walk_action._end_rot = end_rot
+						end
+					end
+				end
+			end
+		end
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

1. **Wrapper or replacement.** Wrapper. `lua/copbrain.lua:89` captures `itr_original_copbrain_clbkpathingresults`; the body `:90-110` calls it first at `:91`, then appends to the live walk action.
2. **Call sites.** r200: registered as `result_clbk` for the four detailed searches — `lua/copbrain.lua` calls `search_for_path_to_unit`/`search_for_path`/`search_for_path_from_pos`/`search_for_path_to_cover`, each building `callback(self, self, 'clbk_pathing_results', search_id)`. 248.2: `lib/units/enemies/cop/copbrain.lua:487`, `:504`, `:523`, `:542` (definition `:588-628`).
3. **Intent.** If a detailed path arrives while the unit is already walking a coarse path, splice it onto the running `CopActionWalk` instead of letting the logic restart the walk action, so the unit never pauses at a coarse-step boundary; also carry the objective's end rotation onto the action.
4. **248.2 delta.** None. `copbrain.lua:588-628` (41 lines) is unchanged from 246.1 — the dead-nav-link re-check, `_add_pathing_result` and the nav-link `set_delay_time` loop are all still there. The 248.2-specific nav-link work is inside `_play_nav_link_anim` (`copactionwalk.lua:2383`), not here.
5. **Target mechanism.** Port as-is as a wrapper, gated on `path_extender`. Hook point: after the original `_add_pathing_result` (`:615`), call `my_data.advancing:itr_append_next_step(path)`; on success clear `self._logic_data.pathing_results[search_id]` and `my_data.processing_advance_path`, and set `walk_action._end_rot` when `my_data.coarse_path_index >= #my_data.coarse_path - 2`. Fields: `my_data.coarse_path`, `my_data.advancing`, `my_data.processing_advance_path`.
6. **Decision.** **PORT** (P6, F3/A-01). Needs one hardening: `itr_append_next_step` is defined inside `if Network:is_server()` (`lua/copactionwalk.lua:40`), so guard the call with `Network:is_server()` or the nil-method call errors on clients.
7. **Acceptance.** T5 (mixed heists, 15 min). Log `evt=path_extend k=appended=1,points=<n>,coarse_index=<i>` and `evt=fallback k=reason=not_server|not_extensible`.
8. **Cost if wrong.** Append with a mismatched path shape ⇒ doubled/short `_simplified_path` ⇒ unit slides, walks backwards, or the action completes early (`itr_fake_complete`, `coplogictravel.lua:316-321`) and the unit stands still until the next logic tick. Recoverable by disabling `path_extender`.
9. **Evidence gaps.** r200 calls `itr_append_next_step` unguarded (`lua/copbrain.lua:96`) yet the method is server-only — either r200 never ran this on a client, or the client path silently errored. A server-only T5 run cannot distinguish the two; the fix above removes the ambiguity.
