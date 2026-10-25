# Function dossier: lua/navigationmanager.lua :: NavigationManager.send_nav_field_to_engine

Category: **VANISHED_IN_NEW** — function exists in 246.1 but not in 248.2; drop or re-home

- ITER: 10 lines, params `()`
- 246.1: 73 lines, params `()`
- 248.2: not found

Normalized signature: `self` is omitted for methods; the body is the porting surface.

## ITER body (V8.57)

```lua
function NavigationManager.send_nav_field_to_engine()
self:itr_prepare_streamline_data()
	self:itr_copy_door_data()

	for navseg_id in pairs(self._nav_segments) do
		self:itr_make_neighbours_list(navseg_id)
	end

	return itr_original_navigationmanager_sendnavfieldtoengine(self)
end
```

## 246.1 vanilla (a3180fc)

```lua
function NavigationManager.send_nav_field_to_engine()
local t_ins = table.insert
	local send_data = {}

	send_data.rooms = self._rooms

	local nr_rooms = #send_data.rooms

	send_data.doors = self._room_doors
	send_data.nav_segments = self._nav_segments
	send_data.quad_grid_size = self._grid_size
	send_data.sector_grid_offset = self._geog_segment_offset or Vector3()
	send_data.sector_grid_size = self._geog_segment_size
	send_data.sector_max_x = self._nr_geog_segments and self._nr_geog_segments.x or 0
	send_data.sector_max_y = self._nr_geog_segments and self._nr_geog_segments.y or 0

	local vis_groups = {}

	send_data.visibility_groups = vis_groups

	for i_vis_group, vis_group in ipairs(self._visibility_groups) do
		local new_vis_group = {
			seg = vis_group.seg
		}
		local rooms = {}

		for i_room, _ in pairs(vis_group.rooms) do
			if i_room <= nr_rooms then
				t_ins(rooms, i_room)
			else
				Application:error("[NavigationManager:send_nav_field_to_engine] Navgraph needs to be rebuilt!")
			end
		end

		new_vis_group.rooms = rooms

		local visible_groups = {}

		for i_visible_group, _ in pairs(vis_group.vis_groups) do
			t_ins(visible_groups, i_visible_group)
		end

		new_vis_group.vis_groups = visible_groups

		t_ins(vis_groups, new_vis_group)
	end

	local nav_sectors = {}

	send_data.nav_sectors = nav_sectors

	for sector_id, sector in pairs(self._geog_segments) do
		local rooms = {}
		local new_sector = {
			rooms = rooms
		}

		for i_room, _ in pairs(sector.rooms) do
			if i_room <= nr_rooms then
				t_ins(rooms, i_room)
			else
				Application:error("[NavigationManager:send_nav_field_to_engine] Navgraph needs to be rebuilt!")
			end
		end

		nav_sectors[sector_id] = new_sector
	end

	local nav_field = World:quad_field()

	nav_field:set_navfield(send_data, callback(self, self, "clbk_navfield"))
	nav_field:set_nav_link_filter(NavigationManager.ACCESS_FLAGS)
end
```

## 248.2 vanilla (e3a8b616)

248.2: not found.

## Diff 246.1 -> ITER

```diff
--- 246.1 vanilla
+++ ITER
@@ -1,72 +1,9 @@
-local t_ins = table.insert
-	local send_data = {}
-
-	send_data.rooms = self._rooms
-
-	local nr_rooms = #send_data.rooms
-
-	send_data.doors = self._room_doors
-	send_data.nav_segments = self._nav_segments
-	send_data.quad_grid_size = self._grid_size
-	send_data.sector_grid_offset = self._geog_segment_offset or Vector3()
-	send_data.sector_grid_size = self._geog_segment_size
-	send_data.sector_max_x = self._nr_geog_segments and self._nr_geog_segments.x or 0
-	send_data.sector_max_y = self._nr_geog_segments and self._nr_geog_segments.y or 0
-
-	local vis_groups = {}
-
-	send_data.visibility_groups = vis_groups
-
-	for i_vis_group, vis_group in ipairs(self._visibility_groups) do
-		local new_vis_group = {
-			seg = vis_group.seg
-		}
-		local rooms = {}
-
-		for i_room, _ in pairs(vis_group.rooms) do
-			if i_room <= nr_rooms then
-				t_ins(rooms, i_room)
-			else
-				Application:error("[NavigationManager:send_nav_field_to_engine] Navgraph needs to be rebuilt!")
-			end
-		end
-
-		new_vis_group.rooms = rooms
-
-		local visible_groups = {}
-
-		for i_visible_group, _ in pairs(vis_group.vis_groups) do
-			t_ins(visible_groups, i_visible_group)
-		end
-
-		new_vis_group.vis_groups = visible_groups
-
-		t_ins(vis_groups, new_vis_group)
-	end
-
-	local nav_sectors = {}
-
-	send_data.nav_sectors = nav_sectors
-
-	for sector_id, sector in pairs(self._geog_segments) do
-		local rooms = {}
-		local new_sector = {
-			rooms = rooms
-		}
-
-		for i_room, _ in pairs(sector.rooms) do
-			if i_room <= nr_rooms then
-				t_ins(rooms, i_room)
-			else
-				Application:error("[NavigationManager:send_nav_field_to_engine] Navgraph needs to be rebuilt!")
-			end
-		end
-
-		nav_sectors[sector_id] = new_sector
-	end
-
-	local nav_field = World:quad_field()
-
-	nav_field:set_navfield(send_data, callback(self, self, "clbk_navfield"))
-	nav_field:set_nav_link_filter(NavigationManager.ACCESS_FLAGS)
+self:itr_prepare_streamline_data()
+	self:itr_copy_door_data()
+
+	for navseg_id in pairs(self._nav_segments) do
+		self:itr_make_neighbours_list(navseg_id)
+	end
+
+	return itr_original_navigationmanager_sendnavfieldtoengine(self)
 end
\ No newline at end of file
```

## Diff 246.1 -> 248.2

Cannot diff: old or new function missing.

## Porter checklist

- [ ] Decision: keep ITER body, adopt 248.2 vanilla, or merge.
- [ ] If merge: re-apply the ITER intent onto the 248.2 body, not the 246.1 body.
- [ ] Check removed/changed APIs (`_room_doors`, numeric `_nav_segments`, `no_dispose`, `session():send_to_peers_synched`, ...).
- [ ] Check new 248.2 fields/callbacks this function must preserve.
- [ ] Run `luajit -bl` and `api-audit` on the file.
