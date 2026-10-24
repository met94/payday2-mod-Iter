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
