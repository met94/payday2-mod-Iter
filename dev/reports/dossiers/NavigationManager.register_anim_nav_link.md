# Function dossier: lua/navigationmanager.lua :: NavigationManager.register_anim_nav_link

Category: **MOD_EDIT_CLEAN**

- ITER: 49 lines, params `(element)`
- 246.1: 45 lines, params `(element)`
- 248.2: 45 lines, params `(element)`

Normalized signature: `self` is omitted for methods; the body is the porting surface.

## ITER body (V8.57)

```lua
function NavigationManager.register_anim_nav_link(element)
local values = element._values
	if not values.itr_from_navseg then
		local intervals = {
			e_nl_fwd_2m = 0,
			e_nl_fwd_4m = 1,
		}

		local tracker = managers.navigation:create_nav_tracker(values.position, true)
		values.itr_from_navseg = tracker:nav_segment()
		tracker:move(values.search_position)
		values.itr_to_navseg = tracker:nav_segment()
		self:destroy_nav_tracker(tracker)

		local so_action = values.so_action
		if type(so_action) == 'string' then
			local interval = math.max(values.interval or 1000, 0)
			if intervals[so_action] then
				values.interval = math.min(interval, intervals[so_action])
			elseif so_action:find('rappel') or so_action:find('rapel') then
				values.interval = math.min(interval, 2)
			elseif so_action:find('jump') then
				values.interval = math.min(interval, 1)
			elseif so_action:find('ladder') then
				values.interval = math.min(interval, 1)
			elseif so_action:find('_clim') then -- climb/climd
				values.interval = math.min(interval, 2)
			elseif so_action:find('e_nl_down_') then
				values.interval = math.min(interval, 1.5)
			elseif so_action:find('e_nl_over_') then
				values.interval = math.min(interval, 1)
			elseif so_action:find('e_nl_up_') then
				values.interval = math.min(interval, 2)
			elseif so_action:find('through') then
				values.interval = math.min(interval, 1)
			end
		end

		values.itr_interval = values.interval or 0
	end
	values.interval = Iter.settings.streamline_path and 0 or values.itr_interval

	itr_original_navigationmanager_registeranimnavlink(self, element)

	local nav_link = element:nav_link()
	if nav_link then
		_navlink_elements[nav_link:key()] = element
	end
end
```

## 246.1 vanilla (a3180fc)

```lua
function NavigationManager.register_anim_nav_link(element)
if element:nav_link() then
		if Application:editor() then
			managers.editor:output_error("[NavigationManager:register_anim_nav_link] Navigation link is already registered id: " .. tostring(element._id))
		else
			Application:error("[NavigationManager:register_anim_nav_link] Navigation link is already registered", element._id)
		end

		return
	end

	if self._nav_links then
		self._nav_links[element] = true
	end

	local nav_link = self._quad_field:add_nav_link(element:value("position"), element:nav_link_end_pos(), {
		element = element
	}, element:nav_link_access(), element:chance(), element._id)
	local is_obstructed = nav_link:is_obstructed()

	element:set_nav_link(nav_link)

	local start_nav_seg_id = nav_link:start_nav_segment()
	local end_nav_seg_id = nav_link:end_nav_segment()

	if start_nav_seg_id ~= end_nav_seg_id then
		local start_nav_seg = self._nav_segments[start_nav_seg_id]
		local new_neighbour

		if not is_obstructed and (not start_nav_seg.neighbours[end_nav_seg_id] or not next(start_nav_seg.neighbours[end_nav_seg_id])) then
			new_neighbour = true
		end

		local neighbours_list_name = is_obstructed and "disabled_neighbours" or "neighbours"

		start_nav_seg[neighbours_list_name] = start_nav_seg[neighbours_list_name] or {}
		start_nav_seg[neighbours_list_name][end_nav_seg_id] = start_nav_seg[neighbours_list_name][end_nav_seg_id] or {}

		table.insert(start_nav_seg[neighbours_list_name][end_nav_seg_id], nav_link)

		if new_neighbour then
			managers.groupai:state():on_nav_seg_neighbour_state(start_nav_seg_id, end_nav_seg_id, true)
		end
	end
end
```

## 248.2 vanilla (e3a8b616)

```lua
function NavigationManager.register_anim_nav_link(element)
if element:nav_link() then
		if Application:editor() then
			managers.editor:output_error("[NavigationManager:register_anim_nav_link] Navigation link is already registered id: " .. tostring(element._id))
		else
			Application:error("[NavigationManager:register_anim_nav_link] Navigation link is already registered", element._id)
		end

		return
	end

	if self._nav_links then
		self._nav_links[element] = true
	end

	local nav_link = self._quad_field:add_nav_link(element:value("position"), element:nav_link_end_pos(), {
		element = element
	}, element:nav_link_access(), element:chance(), element._id)
	local is_obstructed = nav_link:is_obstructed()

	element:set_nav_link(nav_link)

	local start_nav_seg_id = nav_link:start_nav_segment()
	local end_nav_seg_id = nav_link:end_nav_segment()

	if start_nav_seg_id ~= end_nav_seg_id then
		local start_nav_seg = self._nav_segments[start_nav_seg_id]
		local new_neighbour

		if not is_obstructed and (not start_nav_seg.neighbours[end_nav_seg_id] or not next(start_nav_seg.neighbours[end_nav_seg_id])) then
			new_neighbour = true
		end

		local neighbours_list_name = is_obstructed and "disabled_neighbours" or "neighbours"

		start_nav_seg[neighbours_list_name] = start_nav_seg[neighbours_list_name] or {}
		start_nav_seg[neighbours_list_name][end_nav_seg_id] = start_nav_seg[neighbours_list_name][end_nav_seg_id] or {}

		table.insert(start_nav_seg[neighbours_list_name][end_nav_seg_id], nav_link)

		if new_neighbour then
			managers.groupai:state():on_nav_seg_neighbour_state(start_nav_seg_id, end_nav_seg_id, true)
		end
	end
end
```

## Diff 246.1 -> ITER

```diff
--- 246.1 vanilla
+++ ITER
@@ -1,44 +1,48 @@
-if element:nav_link() then
-		if Application:editor() then
-			managers.editor:output_error("[NavigationManager:register_anim_nav_link] Navigation link is already registered id: " .. tostring(element._id))
-		else
-			Application:error("[NavigationManager:register_anim_nav_link] Navigation link is already registered", element._id)
-		end
-
-		return
-	end
-
-	if self._nav_links then
-		self._nav_links[element] = true
-	end
-
-	local nav_link = self._quad_field:add_nav_link(element:value("position"), element:nav_link_end_pos(), {
-		element = element
-	}, element:nav_link_access(), element:chance(), element._id)
-	local is_obstructed = nav_link:is_obstructed()
-
-	element:set_nav_link(nav_link)
-
-	local start_nav_seg_id = nav_link:start_nav_segment()
-	local end_nav_seg_id = nav_link:end_nav_segment()
-
-	if start_nav_seg_id ~= end_nav_seg_id then
-		local start_nav_seg = self._nav_segments[start_nav_seg_id]
-		local new_neighbour
-
-		if not is_obstructed and (not start_nav_seg.neighbours[end_nav_seg_id] or not next(start_nav_seg.neighbours[end_nav_seg_id])) then
-			new_neighbour = true
-		end
-
-		local neighbours_list_name = is_obstructed and "disabled_neighbours" or "neighbours"
-
-		start_nav_seg[neighbours_list_name] = start_nav_seg[neighbours_list_name] or {}
-		start_nav_seg[neighbours_list_name][end_nav_seg_id] = start_nav_seg[neighbours_list_name][end_nav_seg_id] or {}
-
-		table.insert(start_nav_seg[neighbours_list_name][end_nav_seg_id], nav_link)
-
-		if new_neighbour then
-			managers.groupai:state():on_nav_seg_neighbour_state(start_nav_seg_id, end_nav_seg_id, true)
-		end
-	end
+local values = element._values
+	if not values.itr_from_navseg then
+		local intervals = {
+			e_nl_fwd_2m = 0,
+			e_nl_fwd_4m = 1,
+		}
+
+		local tracker = managers.navigation:create_nav_tracker(values.position, true)
+		values.itr_from_navseg = tracker:nav_segment()
+		tracker:move(values.search_position)
+		values.itr_to_navseg = tracker:nav_segment()
+		self:destroy_nav_tracker(tracker)
+
+		local so_action = values.so_action
+		if type(so_action) == 'string' then
+			local interval = math.max(values.interval or 1000, 0)
+			if intervals[so_action] then
+				values.interval = math.min(interval, intervals[so_action])
+			elseif so_action:find('rappel') or so_action:find('rapel') then
+				values.interval = math.min(interval, 2)
+			elseif so_action:find('jump') then
+				values.interval = math.min(interval, 1)
+			elseif so_action:find('ladder') then
+				values.interval = math.min(interval, 1)
+			elseif so_action:find('_clim') then -- climb/climd
+				values.interval = math.min(interval, 2)
+			elseif so_action:find('e_nl_down_') then
+				values.interval = math.min(interval, 1.5)
+			elseif so_action:find('e_nl_over_') then
+				values.interval = math.min(interval, 1)
+			elseif so_action:find('e_nl_up_') then
+				values.interval = math.min(interval, 2)
+			elseif so_action:find('through') then
+				values.interval = math.min(interval, 1)
+			end
+		end
+
+		values.itr_interval = values.interval or 0
+	end
+	values.interval = Iter.settings.streamline_path and 0 or values.itr_interval
+
+	itr_original_navigationmanager_registeranimnavlink(self, element)
+
+	local nav_link = element:nav_link()
+	if nav_link then
+		_navlink_elements[nav_link:key()] = element
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
