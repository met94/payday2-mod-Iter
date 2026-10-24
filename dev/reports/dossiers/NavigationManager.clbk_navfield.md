# Function dossier: lua/navigationmanager.lua :: NavigationManager.clbk_navfield

Category: **MOD_EDIT_VANILLA_CHANGED**

- ITER: 32 lines, params `(event_name, args, args2, args3)`
- 246.1: 163 lines, params `(event_name, args, args2, args3)`
- 248.2: 176 lines, params `(event_name, args, args2, args3)`

Normalized signature: `self` is omitted for methods; the body is the porting surface.

## ITER body (V8.57)

```lua
function NavigationManager.clbk_navfield(event_name, args, args2, args3)
local fuckery
	if event_name == 'add_nav_seg_neighbours' then
		for nav_seg_id in pairs(args) do
			local nav_seg = self._nav_segments[nav_seg_id]
			if not nav_seg.disabled_neighbours then
				nav_seg.disabled_neighbours = {}
				fuckery = true
			end
		end
	end

	itr_original_navigationmanager_clbknavfield(self, event_name, args, args2, args3)

	if fuckery then
		for nav_seg_id in pairs(args) do
			local nav_seg = self._nav_segments[nav_seg_id]
			if nav_seg.disabled_neighbours and not next(nav_seg.disabled_neighbours) then
				nav_seg.disabled_neighbours = nil
			end
		end
	end

	if event_name == 'add_nav_seg_neighbours' or event_name == 'remove_nav_seg_neighbours' then
		for nav_seg_id, neighbours in pairs(args) do
			self:itr_make_neighbours_list(nav_seg_id)
			for _, dfghjkrezt in ipairs(neighbours) do
				self:itr_make_neighbours_list(dfghjkrezt)
			end
		end
	end
end
```

## 246.1 vanilla (a3180fc)

```lua
function NavigationManager.clbk_navfield(event_name, args, args2, args3)
if event_name == "add_nav_seg_neighbours" then
		for nav_seg_id, add_neighbours in pairs(args) do
			local nav_seg = self._nav_segments[nav_seg_id]

			for _, other_nav_seg_id in ipairs(add_neighbours) do
				if nav_seg.disabled_neighbours[other_nav_seg_id] then
					nav_seg.neighbours[other_nav_seg_id] = nav_seg.neighbours[other_nav_seg_id] or {}

					local i_door = 1

					while i_door <= #nav_seg.disabled_neighbours[other_nav_seg_id] do
						local door_id = table.remove(nav_seg.disabled_neighbours[other_nav_seg_id], i_door)

						if type(door_id) == "number" then
							table.insert(nav_seg.neighbours[other_nav_seg_id], door_id)
						else
							i_door = i_door + 1
						end
					end

					if not next(nav_seg.disabled_neighbours[other_nav_seg_id]) then
						nav_seg.disabled_neighbours[other_nav_seg_id] = nil
					end

					if not next(nav_seg.disabled_neighbours) then
						nav_seg.disabled_neighbours = nil
					end
				end
			end
		end

		for nav_seg_id, add_neighbours in pairs(args) do
			managers.groupai:state():on_nav_seg_neighbours_state(nav_seg_id, args, true)
		end
	elseif event_name == "remove_nav_seg_neighbours" then
		for nav_seg_id, rem_neighbours in pairs(args) do
			local nav_seg = self._nav_segments[nav_seg_id]

			for _, other_nav_seg_id in ipairs(rem_neighbours) do
				local other_nav_seg = self._nav_segments[other_nav_seg_id]

				nav_seg.disabled_neighbours = nav_seg.disabled_neighbours or {}
				nav_seg.disabled_neighbours[other_nav_seg_id] = nav_seg.disabled_neighbours[other_nav_seg_id] or {}

				local i_door = 1

				while i_door <= #nav_seg.neighbours[other_nav_seg_id] do
					if type(nav_seg.neighbours[other_nav_seg_id][i_door]) == "number" then
						local door_id = table.remove(nav_seg.neighbours[other_nav_seg_id], i_door)

						table.insert(nav_seg.disabled_neighbours[other_nav_seg_id], door_id)
					else
						i_door = i_door + 1
					end
				end

				if not next(nav_seg.neighbours[other_nav_seg_id]) then
					nav_seg.neighbours[other_nav_seg_id] = nil
				end
			end
		end

		for nav_seg_id, rem_neighbours in pairs(args) do
			managers.groupai:state():on_nav_seg_neighbours_state(nav_seg_id, args, false)
		end
	elseif event_name == "invalidated_script_data" then
		if args.covers then
			for i_cover, cover in ipairs(args.covers) do
				cover[3]:move(cover[1])

				local location_script_data = self._quad_field:get_script_data(cover[3], true)

				if not location_script_data.covers then
					location_script_data.covers = {}
				end

				table.insert(location_script_data.covers, cover)
			end
		end
	elseif event_name == "unobstruct_nav_link" then
		local nav_seg_from_id = args
		local nav_seg_to_id = args2
		local nav_link_id = args3
		local nav_seg_from = self._nav_segments[nav_seg_from_id]

		if nav_seg_from.disabled_neighbours and nav_seg_from.disabled_neighbours[nav_seg_to_id] then
			for i_door, door in pairs(nav_seg_from.disabled_neighbours[nav_seg_to_id]) do
				if type(door) == "userdata" and door:script_data().element:id() == nav_link_id then
					local is_first_door = not nav_seg_from.neighbours[nav_seg_to_id]

					nav_seg_from.neighbours[nav_seg_to_id] = nav_seg_from.neighbours[nav_seg_to_id] or {}

					table.insert(nav_seg_from.neighbours[nav_seg_to_id], table.remove(nav_seg_from.disabled_neighbours[nav_seg_to_id], i_door))

					if not next(nav_seg_from.disabled_neighbours[nav_seg_to_id]) then
						nav_seg_from.disabled_neighbours[nav_seg_to_id] = nil
					end

					if is_first_door then
						managers.groupai:state():on_nav_seg_neighbour_state(nav_seg_from_id, nav_seg_to_id, true)
					end

					return
				end
			end
		end
	elseif event_name == "obstruct_nav_link" then
		local nav_seg_from_id = args
		local nav_seg_to_id = args2
		local nav_link_id = args3
		local nav_seg_from = self._nav_segments[nav_seg_from_id]

		if not nav_seg_from.neighbours[nav_seg_to_id] then
			debug_pause("[NavigationManager:clbk_navfield] did not have such neighbour", event_name, args, args2, args3)

			return
		end

		for i_door, door in pairs(nav_seg_from.neighbours[nav_seg_to_id]) do
			if type(door) ~= "number" and door:script_data().element:id() == nav_link_id then
				nav_seg_from.disabled_neighbours = nav_seg_from.disabled_neighbours or {}
				nav_seg_from.disabled_neighbours[nav_seg_to_id] = nav_seg_from.disabled_neighbours[nav_seg_to_id] or {}

				table.insert(nav_seg_from.disabled_neighbours[nav_seg_to_id], table.remove(nav_seg_from.neighbours[nav_seg_to_id], i_door))

				if not next(nav_seg_from.neighbours[nav_seg_to_id]) then
					nav_seg_from.neighbours[nav_seg_to_id] = nil

					managers.groupai:state():on_nav_seg_neighbour_state(nav_seg_from_id, nav_seg_to_id, false)
				end

				managers.groupai:state():on_nav_link_unregistered(nav_link_id)

				return
			end
		end

		debug_pause("[NavigationManager:clbk_navfield] did not find nav_link", event_name, args, args2, args3)
	elseif event_name == "add_quads" then
		if not self._debug then
			return
		end

		for i, k in pairs(args) do
			self:_add_quad_by_data(k)
		end
	elseif event_name == "obstruct_quads" then
		if not self._debug then
			return
		end

		for i, k in pairs(args) do
			self:_set_quad_obstructed_by_data(k, args2)
		end
	elseif event_name == "alter_quad" then
		if not self._debug then
			return
		end

		self:_alter_quad_by_data(args)
	end
end
```

## 248.2 vanilla (e3a8b616)

```lua
function NavigationManager.clbk_navfield(event_name, args, args2, args3)
if event_name == "add_nav_seg_neighbours" then
		local update_in_group_ai = {}

		for nav_seg_id, add_neighbours in pairs(args) do
			local nav_seg = self._nav_segments[nav_seg_id]

			if nav_seg then
				update_in_group_ai[nav_seg_id] = add_neighbours

				if not nav_seg.disabled_neighbours then
					debug_pause("[NavigationManager] clbk_navfield() - add_nav_seg_neighbours - no disabled neighbours to enable. Something went wrong, possibly in mission script.", nav_seg_id, inspect(nav_seg))
				else
					for _, other_nav_seg_id in ipairs(add_neighbours) do
						if nav_seg.disabled_neighbours[other_nav_seg_id] then
							nav_seg.neighbours[other_nav_seg_id] = nav_seg.neighbours[other_nav_seg_id] or {}

							local i_door = 1

							while i_door <= #nav_seg.disabled_neighbours[other_nav_seg_id] do
								local door = table.remove(nav_seg.disabled_neighbours[other_nav_seg_id], i_door)

								if door.x then
									table.insert(nav_seg.neighbours[other_nav_seg_id], door)
								else
									i_door = i_door + 1
								end
							end

							if not next(nav_seg.disabled_neighbours[other_nav_seg_id]) then
								nav_seg.disabled_neighbours[other_nav_seg_id] = nil
							end

							if not next(nav_seg.disabled_neighbours) then
								nav_seg.disabled_neighbours = nil
							end
						end
					end
				end
			end
		end

		local groupai_state = managers.groupai:state()

		for nav_seg_id, add_neighbours in pairs(update_in_group_ai) do
			groupai_state:on_nav_seg_neighbours_state(nav_seg_id, add_neighbours, true)
		end
	elseif event_name == "remove_nav_seg_neighbours" then
		local update_in_group_ai = {}

		for nav_seg_id, rem_neighbours in pairs(args) do
			local nav_seg = self._nav_segments[nav_seg_id]

			if nav_seg then
				update_in_group_ai[nav_seg_id] = rem_neighbours

				for _, other_nav_seg_id in ipairs(rem_neighbours) do
					local other_nav_seg = self._nav_segments[other_nav_seg_id]

					nav_seg.disabled_neighbours = nav_seg.disabled_neighbours or {}
					nav_seg.disabled_neighbours[other_nav_seg_id] = nav_seg.disabled_neighbours[other_nav_seg_id] or {}

					local i_door = 1

					while i_door <= #nav_seg.neighbours[other_nav_seg_id] do
						if nav_seg.neighbours[other_nav_seg_id][i_door].x then
							local door = table.remove(nav_seg.neighbours[other_nav_seg_id], i_door)

							table.insert(nav_seg.disabled_neighbours[other_nav_seg_id], door)
						else
							i_door = i_door + 1
						end
					end

					if not next(nav_seg.neighbours[other_nav_seg_id]) then
						nav_seg.neighbours[other_nav_seg_id] = nil
					end
				end
			end
		end

		local groupai_state = managers.groupai:state()

		for nav_seg_id, rem_neighbours in pairs(update_in_group_ai) do
			groupai_state:on_nav_seg_neighbours_state(nav_seg_id, rem_neighbours, false)
		end
	elseif event_name == "invalidated_script_data" then
		if args.covers then
			for i_cover, cover in ipairs(args.covers) do
				cover[NavigationManager.COVER_TRACKER]:move(cover[NavigationManager.COVER_POSITION])

				local location_script_data = self._quad_field:get_script_data(cover[NavigationManager.COVER_TRACKER], true)

				if not location_script_data.covers then
					location_script_data.covers = {}
				end

				table.insert(location_script_data.covers, cover)
			end
		end
	elseif event_name == "unobstruct_nav_link" then
		local nav_seg_from_id = args
		local nav_seg_to_id = args2
		local nav_link_id = args3
		local nav_seg_from = self._nav_segments[nav_seg_from_id]

		if not nav_seg_from then
			return
		end

		if nav_seg_from.disabled_neighbours and nav_seg_from.disabled_neighbours[nav_seg_to_id] then
			for i_door, door in pairs(nav_seg_from.disabled_neighbours[nav_seg_to_id]) do
				if not door.x and door:script_data().element:id() == nav_link_id then
					local is_first_door = not nav_seg_from.neighbours[nav_seg_to_id]
					local new_neighbour = table.remove(nav_seg_from.disabled_neighbours[nav_seg_to_id], i_door)

					nav_seg_from.neighbours[nav_seg_to_id] = nav_seg_from.neighbours[nav_seg_to_id] or {}

					table.insert(nav_seg_from.neighbours[nav_seg_to_id], new_neighbour)

					if not next(nav_seg_from.disabled_neighbours[nav_seg_to_id]) then
						nav_seg_from.disabled_neighbours[nav_seg_to_id] = nil
					end

					if is_first_door then
						managers.groupai:state():on_nav_seg_neighbour_state(nav_seg_from_id, nav_seg_to_id, true)
					end

					return
				end
			end
		end

		debug_pause("[NavigationManager] clbk_navfield() - unobstruct_nav_link - couldn't find nav_link", args, args2, args3)
	elseif event_name == "obstruct_nav_link" then
		local nav_seg_from_id = args
		local nav_seg_to_id = args2
		local nav_link_id = args3
		local nav_seg_from = self._nav_segments[nav_seg_from_id]

		if not nav_seg_from then
			debug_pause("[NavigationManager] clbk_navfield() - obstruct_nav_link - nav segment not found", args, args2, args3)

			return
		end

		if not nav_seg_from.neighbours[nav_seg_to_id] then
			debug_pause("[NavigationManager] clbk_navfield() - obstruct_nav_link - neighbour of nav segment not found", args, args2, args3, inspect(nav_seg_from.neighbours))

			return
		end

		for i_door, door in pairs(nav_seg_from.neighbours[nav_seg_to_id]) do
			if not door.x and door:script_data().element:id() == nav_link_id then
				local neighbour = table.remove(nav_seg_from.neighbours[nav_seg_to_id], i_door)

				nav_seg_from.disabled_neighbours = nav_seg_from.disabled_neighbours or {}
				nav_seg_from.disabled_neighbours[nav_seg_to_id] = nav_seg_from.disabled_neighbours[nav_seg_to_id] or {}

				table.insert(nav_seg_from.disabled_neighbours[nav_seg_to_id], neighbour)

				if not next(nav_seg_from.neighbours[nav_seg_to_id]) then
					nav_seg_from.neighbours[nav_seg_to_id] = nil

					managers.groupai:state():on_nav_seg_neighbour_state(nav_seg_from_id, nav_seg_to_id, false)
				end

				managers.groupai:state():on_nav_link_unregistered(nav_link_id)

				return
			end
		end

		debug_pause("[NavigationManager] clbk_navfield() - obstruct_nav_link - couldn't find nav_link", args, args2, args3)
	end
end
```

## Diff 246.1 -> ITER

```diff
--- 246.1 vanilla
+++ ITER
@@ -1,162 +1,31 @@
-if event_name == "add_nav_seg_neighbours" then
-		for nav_seg_id, add_neighbours in pairs(args) do
-			local nav_seg = self._nav_segments[nav_seg_id]
-
-			for _, other_nav_seg_id in ipairs(add_neighbours) do
-				if nav_seg.disabled_neighbours[other_nav_seg_id] then
-					nav_seg.neighbours[other_nav_seg_id] = nav_seg.neighbours[other_nav_seg_id] or {}
-
-					local i_door = 1
-
-					while i_door <= #nav_seg.disabled_neighbours[other_nav_seg_id] do
-						local door_id = table.remove(nav_seg.disabled_neighbours[other_nav_seg_id], i_door)
-
-						if type(door_id) == "number" then
-							table.insert(nav_seg.neighbours[other_nav_seg_id], door_id)
-						else
-							i_door = i_door + 1
-						end
-					end
-
-					if not next(nav_seg.disabled_neighbours[other_nav_seg_id]) then
-						nav_seg.disabled_neighbours[other_nav_seg_id] = nil
-					end
-
-					if not next(nav_seg.disabled_neighbours) then
-						nav_seg.disabled_neighbours = nil
-					end
-				end
-			end
-		end
-
-		for nav_seg_id, add_neighbours in pairs(args) do
-			managers.groupai:state():on_nav_seg_neighbours_state(nav_seg_id, args, true)
-		end
-	elseif event_name == "remove_nav_seg_neighbours" then
-		for nav_seg_id, rem_neighbours in pairs(args) do
-			local nav_seg = self._nav_segments[nav_seg_id]
-
-			for _, other_nav_seg_id in ipairs(rem_neighbours) do
-				local other_nav_seg = self._nav_segments[other_nav_seg_id]
-
-				nav_seg.disabled_neighbours = nav_seg.disabled_neighbours or {}
-				nav_seg.disabled_neighbours[other_nav_seg_id] = nav_seg.disabled_neighbours[other_nav_seg_id] or {}
-
-				local i_door = 1
-
-				while i_door <= #nav_seg.neighbours[other_nav_seg_id] do
-					if type(nav_seg.neighbours[other_nav_seg_id][i_door]) == "number" then
-						local door_id = table.remove(nav_seg.neighbours[other_nav_seg_id], i_door)
-
-						table.insert(nav_seg.disabled_neighbours[other_nav_seg_id], door_id)
-					else
-						i_door = i_door + 1
-					end
-				end
-
-				if not next(nav_seg.neighbours[other_nav_seg_id]) then
-					nav_seg.neighbours[other_nav_seg_id] = nil
-				end
-			end
-		end
-
-		for nav_seg_id, rem_neighbours in pairs(args) do
-			managers.groupai:state():on_nav_seg_neighbours_state(nav_seg_id, args, false)
-		end
-	elseif event_name == "invalidated_script_data" then
-		if args.covers then
-			for i_cover, cover in ipairs(args.covers) do
-				cover[3]:move(cover[1])
-
-				local location_script_data = self._quad_field:get_script_data(cover[3], true)
-
-				if not location_script_data.covers then
-					location_script_data.covers = {}
-				end
-
-				table.insert(location_script_data.covers, cover)
-			end
-		end
-	elseif event_name == "unobstruct_nav_link" then
-		local nav_seg_from_id = args
-		local nav_seg_to_id = args2
-		local nav_link_id = args3
-		local nav_seg_from = self._nav_segments[nav_seg_from_id]
-
-		if nav_seg_from.disabled_neighbours and nav_seg_from.disabled_neighbours[nav_seg_to_id] then
-			for i_door, door in pairs(nav_seg_from.disabled_neighbours[nav_seg_to_id]) do
-				if type(door) == "userdata" and door:script_data().element:id() == nav_link_id then
-					local is_first_door = not nav_seg_from.neighbours[nav_seg_to_id]
-
-					nav_seg_from.neighbours[nav_seg_to_id] = nav_seg_from.neighbours[nav_seg_to_id] or {}
-
-					table.insert(nav_seg_from.neighbours[nav_seg_to_id], table.remove(nav_seg_from.disabled_neighbours[nav_seg_to_id], i_door))
-
-					if not next(nav_seg_from.disabled_neighbours[nav_seg_to_id]) then
-						nav_seg_from.disabled_neighbours[nav_seg_to_id] = nil
-					end
-
-					if is_first_door then
-						managers.groupai:state():on_nav_seg_neighbour_state(nav_seg_from_id, nav_seg_to_id, true)
-					end
-
-					return
-				end
-			end
-		end
-	elseif event_name == "obstruct_nav_link" then
-		local nav_seg_from_id = args
-		local nav_seg_to_id = args2
-		local nav_link_id = args3
-		local nav_seg_from = self._nav_segments[nav_seg_from_id]
-
-		if not nav_seg_from.neighbours[nav_seg_to_id] then
-			debug_pause("[NavigationManager:clbk_navfield] did not have such neighbour", event_name, args, args2, args3)
-
-			return
-		end
-
-		for i_door, door in pairs(nav_seg_from.neighbours[nav_seg_to_id]) do
-			if type(door) ~= "number" and door:script_data().element:id() == nav_link_id then
-				nav_seg_from.disabled_neighbours = nav_seg_from.disabled_neighbours or {}
-				nav_seg_from.disabled_neighbours[nav_seg_to_id] = nav_seg_from.disabled_neighbours[nav_seg_to_id] or {}
-
-				table.insert(nav_seg_from.disabled_neighbours[nav_seg_to_id], table.remove(nav_seg_from.neighbours[nav_seg_to_id], i_door))
-
-				if not next(nav_seg_from.neighbours[nav_seg_to_id]) then
-					nav_seg_from.neighbours[nav_seg_to_id] = nil
-
-					managers.groupai:state():on_nav_seg_neighbour_state(nav_seg_from_id, nav_seg_to_id, false)
-				end
-
-				managers.groupai:state():on_nav_link_unregistered(nav_link_id)
-
-				return
-			end
-		end
-
-		debug_pause("[NavigationManager:clbk_navfield] did not find nav_link", event_name, args, args2, args3)
-	elseif event_name == "add_quads" then
-		if not self._debug then
-			return
-		end
-
-		for i, k in pairs(args) do
-			self:_add_quad_by_data(k)
-		end
-	elseif event_name == "obstruct_quads" then
-		if not self._debug then
-			return
-		end
-
-		for i, k in pairs(args) do
-			self:_set_quad_obstructed_by_data(k, args2)
-		end
-	elseif event_name == "alter_quad" then
-		if not self._debug then
-			return
-		end
-
-		self:_alter_quad_by_data(args)
-	end
+local fuckery
+	if event_name == 'add_nav_seg_neighbours' then
+		for nav_seg_id in pairs(args) do
+			local nav_seg = self._nav_segments[nav_seg_id]
+			if not nav_seg.disabled_neighbours then
+				nav_seg.disabled_neighbours = {}
+				fuckery = true
+			end
+		end
+	end
+
+	itr_original_navigationmanager_clbknavfield(self, event_name, args, args2, args3)
+
+	if fuckery then
+		for nav_seg_id in pairs(args) do
+			local nav_seg = self._nav_segments[nav_seg_id]
+			if nav_seg.disabled_neighbours and not next(nav_seg.disabled_neighbours) then
+				nav_seg.disabled_neighbours = nil
+			end
+		end
+	end
+
+	if event_name == 'add_nav_seg_neighbours' or event_name == 'remove_nav_seg_neighbours' then
+		for nav_seg_id, neighbours in pairs(args) do
+			self:itr_make_neighbours_list(nav_seg_id)
+			for _, dfghjkrezt in ipairs(neighbours) do
+				self:itr_make_neighbours_list(dfghjkrezt)
+			end
+		end
+	end
 end
\ No newline at end of file
```

## Diff 246.1 -> 248.2

```diff
--- 246.1 vanilla
+++ 248.2 vanilla
@@ -1,74 +1,94 @@
 if event_name == "add_nav_seg_neighbours" then
+		local update_in_group_ai = {}
+
 		for nav_seg_id, add_neighbours in pairs(args) do
 			local nav_seg = self._nav_segments[nav_seg_id]
 
-			for _, other_nav_seg_id in ipairs(add_neighbours) do
-				if nav_seg.disabled_neighbours[other_nav_seg_id] then
-					nav_seg.neighbours[other_nav_seg_id] = nav_seg.neighbours[other_nav_seg_id] or {}
+			if nav_seg then
+				update_in_group_ai[nav_seg_id] = add_neighbours
 
-					local i_door = 1
+				if not nav_seg.disabled_neighbours then
+					debug_pause("[NavigationManager] clbk_navfield() - add_nav_seg_neighbours - no disabled neighbours to enable. Something went wrong, possibly in mission script.", nav_seg_id, inspect(nav_seg))
+				else
+					for _, other_nav_seg_id in ipairs(add_neighbours) do
+						if nav_seg.disabled_neighbours[other_nav_seg_id] then
+							nav_seg.neighbours[other_nav_seg_id] = nav_seg.neighbours[other_nav_seg_id] or {}
 
-					while i_door <= #nav_seg.disabled_neighbours[other_nav_seg_id] do
-						local door_id = table.remove(nav_seg.disabled_neighbours[other_nav_seg_id], i_door)
+							local i_door = 1
 
-						if type(door_id) == "number" then
-							table.insert(nav_seg.neighbours[other_nav_seg_id], door_id)
-						else
-							i_door = i_door + 1
-						end
-					end
+							while i_door <= #nav_seg.disabled_neighbours[other_nav_seg_id] do
+								local door = table.remove(nav_seg.disabled_neighbours[other_nav_seg_id], i_door)
 
-					if not next(nav_seg.disabled_neighbours[other_nav_seg_id]) then
-						nav_seg.disabled_neighbours[other_nav_seg_id] = nil
-					end
+								if door.x then
+									table.insert(nav_seg.neighbours[other_nav_seg_id], door)
+								else
+									i_door = i_door + 1
+								end
+							end
+
+							if not next(nav_seg.disabled_neighbours[other_nav_seg_id]) then
+								nav_seg.disabled_neighbours[other_nav_seg_id] = nil
+							end
 
-					if not next(nav_seg.disabled_neighbours) then
-						nav_seg.disabled_neighbours = nil
+							if not next(nav_seg.disabled_neighbours) then
+								nav_seg.disabled_neighbours = nil
+							end
+						end
 					end
 				end
 			end
 		end
 
-		for nav_seg_id, add_neighbours in pairs(args) do
-			managers.groupai:state():on_nav_seg_neighbours_state(nav_seg_id, args, true)
+		local groupai_state = managers.groupai:state()
+
+		for nav_seg_id, add_neighbours in pairs(update_in_group_ai) do
+			groupai_state:on_nav_seg_neighbours_state(nav_seg_id, add_neighbours, true)
 		end
 	elseif event_name == "remove_nav_seg_neighbours" then
+		local update_in_group_ai = {}
+
 		for nav_seg_id, rem_neighbours in pairs(args) do
 			local nav_seg = self._nav_segments[nav_seg_id]
 
-			for _, other_nav_seg_id in ipairs(rem_neighbours) do
-				local other_nav_seg = self._nav_segments[other_nav_seg_id]
+			if nav_seg then
+				update_in_group_ai[nav_seg_id] = rem_neighbours
+
+				for _, other_nav_seg_id in ipairs(rem_neighbours) do
+					local other_nav_seg = self._nav_segments[other_nav_seg_id]
 
-				nav_seg.disabled_neighbours = nav_seg.disabled_neighbours or {}
-				nav_seg.disabled_neighbours[other_nav_seg_id] = nav_seg.disabled_neighbours[other_nav_seg_id] or {}
+					nav_seg.disabled_neighbours = nav_seg.disabled_neighbours or {}
+					nav_seg.disabled_neighbours[other_nav_seg_id] = nav_seg.disabled_neighbours[other_nav_seg_id] or {}
 
-				local i_door = 1
+					local i_door = 1
 
-				while i_door <= #nav_seg.neighbours[other_nav_seg_id] do
-					if type(nav_seg.neighbours[other_nav_seg_id][i_door]) == "number" then
-						local door_id = table.remove(nav_seg.neighbours[other_nav_seg_id], i_door)
+					while i_door <= #nav_seg.neighbours[other_nav_seg_id] do
+						if nav_seg.neighbours[other_nav_seg_id][i_door].x then
+							local door = table.remove(nav_seg.neighbours[other_nav_seg_id], i_door)
 
-						table.insert(nav_seg.disabled_neighbours[other_nav_seg_id], door_id)
-					else
-						i_door = i_door + 1
+							table.insert(nav_seg.disabled_neighbours[other_nav_seg_id], door)
+						else
+							i_door = i_door + 1
+						end
 					end
-				end
 
-				if not next(nav_seg.neighbours[other_nav_seg_id]) then
-					nav_seg.neighbours[other_nav_seg_id] = nil
+					if not next(nav_seg.neighbours[other_nav_seg_id]) then
+						nav_seg.neighbours[other_nav_seg_id] = nil
+					end
 				end
 			end
 		end
 
-		for nav_seg_id, rem_neighbours in pairs(args) do
-			managers.groupai:state():on_nav_seg_neighbours_state(nav_seg_id, args, false)
+		local groupai_state = managers.groupai:state()
+
+		for nav_seg_id, rem_neighbours in pairs(update_in_group_ai) do
+			groupai_state:on_nav_seg_neighbours_state(nav_seg_id, rem_neighbours, false)
 		end
 	elseif event_name == "invalidated_script_data" then
 		if args.covers then
 			for i_cover, cover in ipairs(args.covers) do
-				cover[3]:move(cover[1])
+				cover[NavigationManager.COVER_TRACKER]:move(cover[NavigationManager.COVER_POSITION])
 
-				local location_script_data = self._quad_field:get_script_data(cover[3], true)
+				local location_script_data = self._quad_field:get_script_data(cover[NavigationManager.COVER_TRACKER], true)
 
 				if not location_script_data.covers then
 					location_script_data.covers = {}
@@ -83,14 +103,19 @@ if event_name == "add_nav_seg_neighbours" then
 		local nav_link_id = args3
 		local nav_seg_from = self._nav_segments[nav_seg_from_id]
 
+		if not nav_seg_from then
+			return
+		end
+
 		if nav_seg_from.disabled_neighbours and nav_seg_from.disabled_neighbours[nav_seg_to_id] then
 			for i_door, door in pairs(nav_seg_from.disabled_neighbours[nav_seg_to_id]) do
-				if type(door) == "userdata" and door:script_data().element:id() == nav_link_id then
+				if not door.x and door:script_data().element:id() == nav_link_id then
 					local is_first_door = not nav_seg_from.neighbours[nav_seg_to_id]
+					local new_neighbour = table.remove(nav_seg_from.disabled_neighbours[nav_seg_to_id], i_door)
 
 					nav_seg_from.neighbours[nav_seg_to_id] = nav_seg_from.neighbours[nav_seg_to_id] or {}
 
-					table.insert(nav_seg_from.neighbours[nav_seg_to_id], table.remove(nav_seg_from.disabled_neighbours[nav_seg_to_id], i_door))
+					table.insert(nav_seg_from.neighbours[nav_seg_to_id], new_neighbour)
 
 					if not next(nav_seg_from.disabled_neighbours[nav_seg_to_id]) then
 						nav_seg_from.disabled_neighbours[nav_seg_to_id] = nil
@@ -104,24 +129,34 @@ if event_name == "add_nav_seg_neighbours" then
 				end
 			end
 		end
+
+		debug_pause("[NavigationManager] clbk_navfield() - unobstruct_nav_link - couldn't find nav_link", args, args2, args3)
 	elseif event_name == "obstruct_nav_link" then
 		local nav_seg_from_id = args
 		local nav_seg_to_id = args2
 		local nav_link_id = args3
 		local nav_seg_from = self._nav_segments[nav_seg_from_id]
 
+		if not nav_seg_from then
+			debug_pause("[NavigationManager] clbk_navfield() - obstruct_nav_link - nav segment not found", args, args2, args3)
+
+			return
+		end
+
 		if not nav_seg_from.neighbours[nav_seg_to_id] then
-			debug_pause("[NavigationManager:clbk_navfield] did not have such neighbour", event_name, args, args2, args3)
+			debug_pause("[NavigationManager] clbk_navfield() - obstruct_nav_link - neighbour of nav segment not found", args, args2, args3, inspect(nav_seg_from.neighbours))
 
 			return
 		end
 
 		for i_door, door in pairs(nav_seg_from.neighbours[nav_seg_to_id]) do
-			if type(door) ~= "number" and door:script_data().element:id() == nav_link_id then
+			if not door.x and door:script_data().element:id() == nav_link_id then
+				local neighbour = table.remove(nav_seg_from.neighbours[nav_seg_to_id], i_door)
+
 				nav_seg_from.disabled_neighbours = nav_seg_from.disabled_neighbours or {}
 				nav_seg_from.disabled_neighbours[nav_seg_to_id] = nav_seg_from.disabled_neighbours[nav_seg_to_id] or {}
 
-				table.insert(nav_seg_from.disabled_neighbours[nav_seg_to_id], table.remove(nav_seg_from.neighbours[nav_seg_to_id], i_door))
+				table.insert(nav_seg_from.disabled_neighbours[nav_seg_to_id], neighbour)
 
 				if not next(nav_seg_from.neighbours[nav_seg_to_id]) then
 					nav_seg_from.neighbours[nav_seg_to_id] = nil
@@ -135,28 +170,6 @@ if event_name == "add_nav_seg_neighbours" then
 			end
 		end
 
-		debug_pause("[NavigationManager:clbk_navfield] did not find nav_link", event_name, args, args2, args3)
-	elseif event_name == "add_quads" then
-		if not self._debug then
-			return
-		end
-
-		for i, k in pairs(args) do
-			self:_add_quad_by_data(k)
-		end
-	elseif event_name == "obstruct_quads" then
-		if not self._debug then
-			return
-		end
-
-		for i, k in pairs(args) do
-			self:_set_quad_obstructed_by_data(k, args2)
-		end
-	elseif event_name == "alter_quad" then
-		if not self._debug then
-			return
-		end
-
-		self:_alter_quad_by_data(args)
+		debug_pause("[NavigationManager] clbk_navfield() - obstruct_nav_link - couldn't find nav_link", args, args2, args3)
 	end
 end
\ No newline at end of file
```

## Porter checklist

- [ ] Decision: keep ITER body, adopt 248.2 vanilla, or merge.
- [ ] If merge: re-apply the ITER intent onto the 248.2 body, not the 246.1 body.
- [ ] Check removed/changed APIs (`_room_doors`, numeric `_nav_segments`, `no_dispose`, `session():send_to_peers_synched`, ...).
- [ ] Check new 248.2 fields/callbacks this function must preserve.
- [ ] Run `luajit -bl` and `api-audit` on the file.
