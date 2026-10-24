# Function dossier: lua/navigationmanager.lua :: NavigationManager.unregister_anim_nav_link

Category: **MOD_EDIT_VANILLA_CHANGED**

- ITER: 7 lines, params `(element)`
- 246.1: 63 lines, params `(element)`
- 248.2: 69 lines, params `(element)`

Normalized signature: `self` is omitted for methods; the body is the porting surface.

## ITER body (V8.57)

```lua
function NavigationManager.unregister_anim_nav_link(element)
local nav_link = element:nav_link()
	if nav_link then
		nav_link:set_delay_time(604800)
		itr_original_navigationmanager_unregisteranimnavlink(self, element)
	end
end
```

## 246.1 vanilla (a3180fc)

```lua
function NavigationManager.unregister_anim_nav_link(element)
local nav_link = element:nav_link()

	if not nav_link then
		return
	end

	if self._nav_links then
		self._nav_links[element] = nil
	end

	local start_nav_seg_id = nav_link:start_nav_segment()
	local end_nav_seg_id = nav_link:end_nav_segment()
	local start_nav_seg = self._nav_segments[start_nav_seg_id]

	if start_nav_seg.disabled_neighbours and start_nav_seg.disabled_neighbours[end_nav_seg_id] then
		for i_door, door_id in pairs(start_nav_seg.disabled_neighbours[end_nav_seg_id]) do
			if door_id == nav_link then
				table.remove(start_nav_seg.disabled_neighbours[end_nav_seg_id], i_door)

				if not next(start_nav_seg.disabled_neighbours[end_nav_seg_id]) then
					start_nav_seg.disabled_neighbours[end_nav_seg_id] = nil
				end

				if not next(start_nav_seg.disabled_neighbours) then
					start_nav_seg.disabled_neighbours = nil
				end

				break
			end
		end
	end

	local was_in_group_ai
	local start_nav_seg_neighbours = start_nav_seg.neighbours

	if start_nav_seg_neighbours and start_nav_seg_neighbours[end_nav_seg_id] then
		for i_door, door_id in pairs(start_nav_seg_neighbours[end_nav_seg_id]) do
			if door_id == nav_link then
				was_in_group_ai = true

				if #start_nav_seg_neighbours[end_nav_seg_id] == 1 then
					start_nav_seg_neighbours[end_nav_seg_id] = nil

					managers.groupai:state():on_nav_seg_neighbour_state(start_nav_seg_id, end_nav_seg_id, false)

					break
				end

				table.remove(start_nav_seg_neighbours[end_nav_seg_id], i_door)

				break
			end
		end
	end

	if was_in_group_ai then
		managers.groupai:state():on_nav_link_unregistered(element:id())
	end

	element:set_nav_link()
	self._quad_field:remove_nav_link(element._id)
end
```

## 248.2 vanilla (e3a8b616)

```lua
function NavigationManager.unregister_anim_nav_link(element)
local nav_link = element:nav_link()

	if not nav_link then
		return
	end

	if self._nav_links then
		self._nav_links[element] = nil
	end

	local start_nav_seg_id = nav_link:start_nav_segment()
	local end_nav_seg_id = nav_link:end_nav_segment()
	local start_nav_seg = self._nav_segments[start_nav_seg_id]

	if not start_nav_seg_id or not end_nav_seg_id or not start_nav_seg then
		Application:error("[NavigationManager] Nav link start or end point is not in the navigation mesh. Element id: ", element._id, " nav_link ", nav_link)

		return
	end

	if start_nav_seg.disabled_neighbours and start_nav_seg.disabled_neighbours[end_nav_seg_id] then
		for i_door, door_id in pairs(start_nav_seg.disabled_neighbours[end_nav_seg_id]) do
			if door_id == nav_link then
				table.remove(start_nav_seg.disabled_neighbours[end_nav_seg_id], i_door)

				if not next(start_nav_seg.disabled_neighbours[end_nav_seg_id]) then
					start_nav_seg.disabled_neighbours[end_nav_seg_id] = nil
				end

				if not next(start_nav_seg.disabled_neighbours) then
					start_nav_seg.disabled_neighbours = nil
				end

				break
			end
		end
	end

	local was_in_group_ai
	local start_nav_seg_neighbours = start_nav_seg.neighbours

	if start_nav_seg_neighbours and start_nav_seg_neighbours[end_nav_seg_id] then
		for i_door, door_id in pairs(start_nav_seg_neighbours[end_nav_seg_id]) do
			if door_id == nav_link then
				was_in_group_ai = true

				if #start_nav_seg_neighbours[end_nav_seg_id] == 1 then
					start_nav_seg_neighbours[end_nav_seg_id] = nil

					managers.groupai:state():on_nav_seg_neighbour_state(start_nav_seg_id, end_nav_seg_id, false)

					break
				end

				table.remove(start_nav_seg_neighbours[end_nav_seg_id], i_door)

				break
			end
		end
	end

	if was_in_group_ai then
		managers.groupai:state():on_nav_link_unregistered(element:id())
	end

	element:set_nav_link()
	self._quad_field:remove_nav_link(element._id)
end
```

## Diff 246.1 -> ITER

```diff
--- 246.1 vanilla
+++ ITER
@@ -1,62 +1,6 @@
-local nav_link = element:nav_link()
-
-	if not nav_link then
-		return
-	end
-
-	if self._nav_links then
-		self._nav_links[element] = nil
-	end
-
-	local start_nav_seg_id = nav_link:start_nav_segment()
-	local end_nav_seg_id = nav_link:end_nav_segment()
-	local start_nav_seg = self._nav_segments[start_nav_seg_id]
-
-	if start_nav_seg.disabled_neighbours and start_nav_seg.disabled_neighbours[end_nav_seg_id] then
-		for i_door, door_id in pairs(start_nav_seg.disabled_neighbours[end_nav_seg_id]) do
-			if door_id == nav_link then
-				table.remove(start_nav_seg.disabled_neighbours[end_nav_seg_id], i_door)
-
-				if not next(start_nav_seg.disabled_neighbours[end_nav_seg_id]) then
-					start_nav_seg.disabled_neighbours[end_nav_seg_id] = nil
-				end
-
-				if not next(start_nav_seg.disabled_neighbours) then
-					start_nav_seg.disabled_neighbours = nil
-				end
-
-				break
-			end
-		end
-	end
-
-	local was_in_group_ai
-	local start_nav_seg_neighbours = start_nav_seg.neighbours
-
-	if start_nav_seg_neighbours and start_nav_seg_neighbours[end_nav_seg_id] then
-		for i_door, door_id in pairs(start_nav_seg_neighbours[end_nav_seg_id]) do
-			if door_id == nav_link then
-				was_in_group_ai = true
-
-				if #start_nav_seg_neighbours[end_nav_seg_id] == 1 then
-					start_nav_seg_neighbours[end_nav_seg_id] = nil
-
-					managers.groupai:state():on_nav_seg_neighbour_state(start_nav_seg_id, end_nav_seg_id, false)
-
-					break
-				end
-
-				table.remove(start_nav_seg_neighbours[end_nav_seg_id], i_door)
-
-				break
-			end
-		end
-	end
-
-	if was_in_group_ai then
-		managers.groupai:state():on_nav_link_unregistered(element:id())
-	end
-
-	element:set_nav_link()
-	self._quad_field:remove_nav_link(element._id)
+local nav_link = element:nav_link()
+	if nav_link then
+		nav_link:set_delay_time(604800)
+		itr_original_navigationmanager_unregisteranimnavlink(self, element)
+	end
 end
\ No newline at end of file
```

## Diff 246.1 -> 248.2

```diff
--- 246.1 vanilla
+++ 248.2 vanilla
@@ -12,6 +12,12 @@ local nav_link = element:nav_link()
 	local end_nav_seg_id = nav_link:end_nav_segment()
 	local start_nav_seg = self._nav_segments[start_nav_seg_id]
 
+	if not start_nav_seg_id or not end_nav_seg_id or not start_nav_seg then
+		Application:error("[NavigationManager] Nav link start or end point is not in the navigation mesh. Element id: ", element._id, " nav_link ", nav_link)
+
+		return
+	end
+
 	if start_nav_seg.disabled_neighbours and start_nav_seg.disabled_neighbours[end_nav_seg_id] then
 		for i_door, door_id in pairs(start_nav_seg.disabled_neighbours[end_nav_seg_id]) do
 			if door_id == nav_link then
```

## Porter checklist

- [ ] Decision: keep ITER body, adopt 248.2 vanilla, or merge.
- [ ] If merge: re-apply the ITER intent onto the 248.2 body, not the 246.1 body.
- [ ] Check removed/changed APIs (`_room_doors`, numeric `_nav_segments`, `no_dispose`, `session():send_to_peers_synched`, ...).
- [ ] Check new 248.2 fields/callbacks this function must preserve.
- [ ] Run `luajit -bl` and `api-audit` on the file.
