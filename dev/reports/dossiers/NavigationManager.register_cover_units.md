# Function dossier: lua/navigationmanager.lua :: NavigationManager.register_cover_units

Category: **MOD_EDIT_VANILLA_CHANGED**

- ITER: 19 lines, params `()`
- 246.1: 80 lines, params `()`
- 248.2: 75 lines, params `()`

Normalized signature: `self` is omitted for methods; the body is the porting surface.

## ITER body (V8.57)

```lua
function NavigationManager.register_cover_units()
local _debug = self._debug
	self._debug = true
	itr_original_navigationmanager_registercoverunits(self)
	local covers = {}
	for i = #self._covers, 1, -1 do
		local cover = self._covers[i]
		local nav_tracker = cover[3]
		if mvector3.distance(cover[1], nav_tracker:position()) < 60 then
			table.insert(covers, nav_tracker:position())
		else
			table.remove(self._covers, i)
			local location_script_data = self._quad_field:get_script_data(nav_tracker)
			table.delete(location_script_data.covers, cover)
			self._quad_field:destroy_nav_tracker(nav_tracker)
		end
	end
	self._debug = _debug
end
```

## 246.1 vanilla (a3180fc)

```lua
function NavigationManager.register_cover_units()
if not self:is_data_ready() then
		return
	end

	local rooms = self._rooms
	local covers = {}
	local cover_data = managers.worlddefinition:get_cover_data()
	local t_ins = table.insert

	if cover_data then
		local function _register_cover(pos, fwd)
			local nav_tracker = self._quad_field:create_nav_tracker(pos, true)
			local cover = {
				nav_tracker:field_position(),
				fwd,
				nav_tracker
			}

			if self._debug then
				t_ins(covers, cover)
			end

			local location_script_data = self._quad_field:get_script_data(nav_tracker, true)

			if not location_script_data.covers then
				location_script_data.covers = {}
			end

			t_ins(location_script_data.covers, cover)
		end

		local tmp_rot = Rotation(0, 0, 0)

		if cover_data.rotations then
			local rotations = cover_data.rotations

			for i, yaw in ipairs(cover_data.rotations) do
				mrotation.set_yaw_pitch_roll(tmp_rot, yaw, 0, 0)
				mrotation.y(tmp_rot, temp_vec1)
				_register_cover(cover_data.positions[i], mvector3.copy(temp_vec1))
			end
		else
			for _, cover_desc in ipairs(cover_data) do
				mrotation.set_yaw_pitch_roll(tmp_rot, cover_desc[2], 0, 0)
				mrotation.y(tmp_rot, temp_vec1)
				_register_cover(cover_desc[1], mvector3.copy(temp_vec1))
			end
		end
	else
		local all_cover_units = World:find_units_quick("all", managers.slot:get_mask("cover"))

		for i, unit in ipairs(all_cover_units) do
			local pos = unit:position()
			local fwd = unit:rotation():y()
			local nav_tracker = self._quad_field:create_nav_tracker(pos, true)
			local cover = {
				nav_tracker:field_position(),
				fwd,
				nav_tracker,
				true
			}

			if self._debug then
				t_ins(covers, cover)
			end

			local location_script_data = self._quad_field:get_script_data(nav_tracker)

			if not location_script_data.covers then
				location_script_data.covers = {}
			end

			t_ins(location_script_data.covers, cover)
			self:_safe_remove_unit(unit)
		end
	end

	self._covers = covers
end
```

## 248.2 vanilla (e3a8b616)

```lua
function NavigationManager.register_cover_units()
if not self:is_data_ready() then
		return
	end

	local covers = {}
	local cover_data = managers.worlddefinition:get_cover_data()
	local t_ins = table.insert

	if cover_data then
		local function _register_cover(pos, fwd)
			local nav_tracker = self._quad_field:create_nav_tracker(pos, true)
			local cover = {
				nav_tracker:field_position(),
				fwd,
				nav_tracker
			}

			t_ins(covers, cover)

			local location_script_data = self._quad_field:get_script_data(nav_tracker, true)

			if not location_script_data.covers then
				location_script_data.covers = {}
			end

			t_ins(location_script_data.covers, cover)
		end

		local tmp_rot = Rotation(0, 0, 0)

		if cover_data.rotations then
			local rotations = cover_data.rotations

			for i, yaw in ipairs(cover_data.rotations) do
				mrotation.set_yaw_pitch_roll(tmp_rot, yaw, 0, 0)
				mrotation.y(tmp_rot, temp_vec1)
				_register_cover(cover_data.positions[i], mvec3_copy(temp_vec1))
			end
		else
			for _, cover_desc in ipairs(cover_data) do
				mrotation.set_yaw_pitch_roll(tmp_rot, cover_desc[2], 0, 0)
				mrotation.y(tmp_rot, temp_vec1)
				_register_cover(cover_desc[1], mvec3_copy(temp_vec1))
			end
		end
	else
		local all_cover_units = World:find_units_quick("all", managers.slot:get_mask("cover"))

		for i, unit in ipairs(all_cover_units) do
			local pos = unit:position()
			local fwd = unit:rotation():y()
			local nav_tracker = self._quad_field:create_nav_tracker(pos, true)
			local cover = {
				nav_tracker:field_position(),
				fwd,
				nav_tracker,
				true
			}

			t_ins(covers, cover)

			local location_script_data = self._quad_field:get_script_data(nav_tracker, true)

			if not location_script_data.covers then
				location_script_data.covers = {}
			end

			t_ins(location_script_data.covers, cover)
			self:_safe_remove_unit(unit)
		end
	end

	self._covers = covers
end
```

## Diff 246.1 -> ITER

```diff
--- 246.1 vanilla
+++ ITER
@@ -1,79 +1,18 @@
-if not self:is_data_ready() then
-		return
-	end
-
-	local rooms = self._rooms
-	local covers = {}
-	local cover_data = managers.worlddefinition:get_cover_data()
-	local t_ins = table.insert
-
-	if cover_data then
-		local function _register_cover(pos, fwd)
-			local nav_tracker = self._quad_field:create_nav_tracker(pos, true)
-			local cover = {
-				nav_tracker:field_position(),
-				fwd,
-				nav_tracker
-			}
-
-			if self._debug then
-				t_ins(covers, cover)
-			end
-
-			local location_script_data = self._quad_field:get_script_data(nav_tracker, true)
-
-			if not location_script_data.covers then
-				location_script_data.covers = {}
-			end
-
-			t_ins(location_script_data.covers, cover)
-		end
-
-		local tmp_rot = Rotation(0, 0, 0)
-
-		if cover_data.rotations then
-			local rotations = cover_data.rotations
-
-			for i, yaw in ipairs(cover_data.rotations) do
-				mrotation.set_yaw_pitch_roll(tmp_rot, yaw, 0, 0)
-				mrotation.y(tmp_rot, temp_vec1)
-				_register_cover(cover_data.positions[i], mvector3.copy(temp_vec1))
-			end
-		else
-			for _, cover_desc in ipairs(cover_data) do
-				mrotation.set_yaw_pitch_roll(tmp_rot, cover_desc[2], 0, 0)
-				mrotation.y(tmp_rot, temp_vec1)
-				_register_cover(cover_desc[1], mvector3.copy(temp_vec1))
-			end
-		end
-	else
-		local all_cover_units = World:find_units_quick("all", managers.slot:get_mask("cover"))
-
-		for i, unit in ipairs(all_cover_units) do
-			local pos = unit:position()
-			local fwd = unit:rotation():y()
-			local nav_tracker = self._quad_field:create_nav_tracker(pos, true)
-			local cover = {
-				nav_tracker:field_position(),
-				fwd,
-				nav_tracker,
-				true
-			}
-
-			if self._debug then
-				t_ins(covers, cover)
-			end
-
-			local location_script_data = self._quad_field:get_script_data(nav_tracker)
-
-			if not location_script_data.covers then
-				location_script_data.covers = {}
-			end
-
-			t_ins(location_script_data.covers, cover)
-			self:_safe_remove_unit(unit)
-		end
-	end
-
-	self._covers = covers
+local _debug = self._debug
+	self._debug = true
+	itr_original_navigationmanager_registercoverunits(self)
+	local covers = {}
+	for i = #self._covers, 1, -1 do
+		local cover = self._covers[i]
+		local nav_tracker = cover[3]
+		if mvector3.distance(cover[1], nav_tracker:position()) < 60 then
+			table.insert(covers, nav_tracker:position())
+		else
+			table.remove(self._covers, i)
+			local location_script_data = self._quad_field:get_script_data(nav_tracker)
+			table.delete(location_script_data.covers, cover)
+			self._quad_field:destroy_nav_tracker(nav_tracker)
+		end
+	end
+	self._debug = _debug
 end
\ No newline at end of file
```

## Diff 246.1 -> 248.2

```diff
--- 246.1 vanilla
+++ 248.2 vanilla
@@ -2,7 +2,6 @@ if not self:is_data_ready() then
 		return
 	end
 
-	local rooms = self._rooms
 	local covers = {}
 	local cover_data = managers.worlddefinition:get_cover_data()
 	local t_ins = table.insert
@@ -16,9 +15,7 @@ if not self:is_data_ready() then
 				nav_tracker
 			}
 
-			if self._debug then
-				t_ins(covers, cover)
-			end
+			t_ins(covers, cover)
 
 			local location_script_data = self._quad_field:get_script_data(nav_tracker, true)
 
@@ -37,13 +34,13 @@ if not self:is_data_ready() then
 			for i, yaw in ipairs(cover_data.rotations) do
 				mrotation.set_yaw_pitch_roll(tmp_rot, yaw, 0, 0)
 				mrotation.y(tmp_rot, temp_vec1)
-				_register_cover(cover_data.positions[i], mvector3.copy(temp_vec1))
+				_register_cover(cover_data.positions[i], mvec3_copy(temp_vec1))
 			end
 		else
 			for _, cover_desc in ipairs(cover_data) do
 				mrotation.set_yaw_pitch_roll(tmp_rot, cover_desc[2], 0, 0)
 				mrotation.y(tmp_rot, temp_vec1)
-				_register_cover(cover_desc[1], mvector3.copy(temp_vec1))
+				_register_cover(cover_desc[1], mvec3_copy(temp_vec1))
 			end
 		end
 	else
@@ -60,11 +57,9 @@ if not self:is_data_ready() then
 				true
 			}
 
-			if self._debug then
-				t_ins(covers, cover)
-			end
+			t_ins(covers, cover)
 
-			local location_script_data = self._quad_field:get_script_data(nav_tracker)
+			local location_script_data = self._quad_field:get_script_data(nav_tracker, true)
 
 			if not location_script_data.covers then
 				location_script_data.covers = {}
```

## Porter checklist

- [ ] Decision: keep ITER body, adopt 248.2 vanilla, or merge.
- [ ] If merge: re-apply the ITER intent onto the 248.2 body, not the 246.1 body.
- [ ] Check removed/changed APIs (`_room_doors`, numeric `_nav_segments`, `no_dispose`, `session():send_to_peers_synched`, ...).
- [ ] Check new 248.2 fields/callbacks this function must preserve.
- [ ] Run `luajit -bl` and `api-audit` on the file.
