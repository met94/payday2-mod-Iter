# Function dossier: lua/copactionwalk.lua :: CopActionWalk._init

Category: **MOD_EDIT_CLEAN**

- ITER: 23 lines, params `()`
- 246.1: 160 lines, params `()`
- 248.2: 160 lines, params `()`

Normalized signature: `self` is omitted for methods; the body is the porting surface.

## ITER body (V8.57)

```lua
function CopActionWalk._init()
local nav_path = self._nav_path
	if nav_path and not nav_path[2] then
		local expand_nav_path
		local action_desc = self._action_desc
		if action_desc.path_simplified and action_desc.persistent then
			expand_nav_path = true
		elseif not managers.groupai:state():enemy_weapons_hot() then
			expand_nav_path = true
		end
		if expand_nav_path then
			table.insert(nav_path, 1, mvector3.copy(self._common_data.pos))
		end
	end

	local result = itr_original_copactionwalk_init(self)

	if result and self._sync then
		self:itr_prepare_for_upcoming_navlink()
	end

	return result
end
```

## 246.1 vanilla (a3180fc)

```lua
function CopActionWalk._init()
if not self:_sanitize() then
		return
	end

	self._init_called = true

	local action_desc = self._action_desc
	local common_data = self._common_data

	if self._is_civilian then
		print("common_data ", inspect(common_data))
	end

	if self._sync then
		if managers.groupai:state():all_AI_criminals()[common_data.unit:key()] then
			self._nav_link_invul = true
		end

		local nav_path = {}

		for i, nav_point in ipairs(self._nav_path) do
			if nav_point.x then
				table.insert(nav_path, nav_point)
			elseif alive(nav_point) then
				table.insert(nav_path, {
					element = nav_point:script_data().element,
					c_class = nav_point
				})
			else
				debug_pause_unit(self._unit, "dead nav_link", self._unit)

				return false
			end
		end

		self._nav_path = nav_path
	else
		local t_ins = table.insert
		local new_nav_points = self._simplified_path

		if new_nav_points then
			for _, nav_point in ipairs(new_nav_points) do
				t_ins(self._nav_path, nav_point.x and mvec3_cpy(nav_point) or nav_point)
			end
		end

		if not action_desc.interrupted or not self._nav_path or not self._nav_path[1].x then
			t_ins(self._nav_path, 1, mvec3_cpy(common_data.pos))
		else
			self._nav_path[1] = mvec3_cpy(common_data.pos)
		end

		for i, nav_point in ipairs(self._nav_path) do
			if not nav_point.x then
				function nav_point.element.value(element, name)
					return element[name]
				end

				function nav_point.element.nav_link_wants_align_pos(element)
					return element.from_idle
				end
			end
		end

		if not action_desc.host_stop_pos_ahead and self._nav_path[2] then
			local ray_params = {
				tracker_from = common_data.nav_tracker,
				pos_to = self._nav_point_pos(self._nav_path[2])
			}

			if managers.navigation:raycast(ray_params) then
				t_ins(self._nav_path, 2, mvec3_cpy(self._ext_movement:m_host_stop_pos()))

				self._host_stop_pos_ahead = true
			end
		end
	end

	if action_desc.path_simplified and action_desc.persistent then
		self._simplified_path = self._nav_path
	elseif not managers.groupai:state():enemy_weapons_hot() then
		self._simplified_path = self._nav_path
	else
		local good_pos = mvector3.copy(common_data.pos)

		self._simplified_path = self._calculate_simplified_path(good_pos, self._nav_path, (not self._sync or self._common_data.stance.name == "ntl") and 2 or 1, self._sync, true)
	end

	if not self._simplified_path[2].x then
		self._next_is_nav_link = self._simplified_path[2]
	end

	self._curve_path_index = 1

	self:_chk_start_anim(CopActionWalk._nav_point_pos(self._simplified_path[2]))

	if self._start_run then
		self:_set_updator("_upd_start_anim_first_frame")
	end

	if not self._start_run_turn and mvec3_dis(self._nav_point_pos(self._simplified_path[2]), self._simplified_path[1]) > 400 and self._ext_base:lod_stage() == 1 then
		self._curve_path = self:_calculate_curved_path(self._simplified_path, 1, 1)
	else
		self._curve_path = {
			self._simplified_path[1],
			mvec3_cpy(self._nav_point_pos(self._simplified_path[2]))
		}
	end

	if #self._simplified_path == 2 and not self._was_interrupted and not self._NO_RUN_STOP and not self._no_walk and self._haste ~= "walk" and not (mvec3_dis(self._curve_path[2], self._curve_path[1]) < 210) then
		self._chk_stop_dis = 210
	end

	if Network:is_server() then
		local sync_yaw = 0

		if self._end_rot then
			local yaw = self._end_rot:yaw()

			if yaw < 0 then
				yaw = 360 + yaw
			end

			sync_yaw = 1 + math.ceil(yaw * 254 / 360)
		end

		local sync_haste = self._haste == "walk" and 1 or 2
		local next_nav_point = self._nav_point_pos(self._simplified_path[2])
		local pose_code

		pose_code = not action_desc.pose and 0 or action_desc.pose == "stand" and 1 or 2

		local end_pose_code

		end_pose_code = not action_desc.end_pose and 0 or action_desc.end_pose == "stand" and 1 or 2

		self._ext_network:send("action_walk_start", self._nav_point_pos(next_nav_point), 1, 0, false, sync_haste, sync_yaw, self._no_walk and true or false, self._no_strafe and true or false, pose_code, end_pose_code)
	else
		local pose = action_desc.pose

		if pose and not self._unit:anim_data()[pose] then
			if pose == "stand" then
				local action, success = CopActionStand:new(action_desc, self._common_data)
			else
				local action, success = CopActionCrouch:new(action_desc, self._common_data)
			end
		end
	end

	if Network:is_server() then
		self._unit:brain():rem_pos_rsrv("stand")
		self._unit:brain():add_pos_rsrv("move_dest", {
			radius = 30,
			position = mvector3.copy(self._simplified_path[#self._simplified_path])
		})
	end

	return true
end
```

## 248.2 vanilla (e3a8b616)

```lua
function CopActionWalk._init()
if not self:_sanitize() then
		return
	end

	self._init_called = true

	local action_desc = self._action_desc
	local common_data = self._common_data

	if self._is_civilian then
		print("common_data ", inspect(common_data))
	end

	if self._sync then
		if managers.groupai:state():all_AI_criminals()[common_data.unit:key()] then
			self._nav_link_invul = true
		end

		local nav_path = {}

		for i, nav_point in ipairs(self._nav_path) do
			if nav_point.x then
				table.insert(nav_path, nav_point)
			elseif alive(nav_point) then
				table.insert(nav_path, {
					element = nav_point:script_data().element,
					c_class = nav_point
				})
			else
				debug_pause_unit(self._unit, "dead nav_link", self._unit)

				return false
			end
		end

		self._nav_path = nav_path
	else
		local t_ins = table.insert
		local new_nav_points = self._simplified_path

		if new_nav_points then
			for _, nav_point in ipairs(new_nav_points) do
				t_ins(self._nav_path, nav_point.x and mvec3_cpy(nav_point) or nav_point)
			end
		end

		if not action_desc.interrupted or not self._nav_path or not self._nav_path[1].x then
			t_ins(self._nav_path, 1, mvec3_cpy(common_data.pos))
		else
			self._nav_path[1] = mvec3_cpy(common_data.pos)
		end

		for i, nav_point in ipairs(self._nav_path) do
			if not nav_point.x then
				function nav_point.element.value(element, name)
					return element[name]
				end

				function nav_point.element.nav_link_wants_align_pos(element)
					return element.from_idle
				end
			end
		end

		if not action_desc.host_stop_pos_ahead and self._nav_path[2] then
			local ray_params = {
				tracker_from = common_data.nav_tracker,
				pos_to = self._nav_point_pos(self._nav_path[2])
			}

			if managers.navigation:raycast(ray_params) then
				t_ins(self._nav_path, 2, mvec3_cpy(self._ext_movement:m_host_stop_pos()))

				self._host_stop_pos_ahead = true
			end
		end
	end

	if action_desc.path_simplified and action_desc.persistent then
		self._simplified_path = self._nav_path
	elseif not managers.groupai:state():enemy_weapons_hot() then
		self._simplified_path = self._nav_path
	else
		local good_pos = mvector3.copy(common_data.pos)

		self._simplified_path = self._calculate_simplified_path(good_pos, self._nav_path, (not self._sync or self._common_data.stance.name == "ntl") and 2 or 1, self._sync, true)
	end

	if not self._simplified_path[2].x then
		self._next_is_nav_link = self._simplified_path[2]
	end

	self._curve_path_index = 1

	self:_chk_start_anim(CopActionWalk._nav_point_pos(self._simplified_path[2]))

	if self._start_run then
		self:_set_updator("_upd_start_anim_first_frame")
	end

	if not self._start_run_turn and mvec3_dis(self._nav_point_pos(self._simplified_path[2]), self._simplified_path[1]) > 400 and self._ext_base:lod_stage() == 1 then
		self._curve_path = self:_calculate_curved_path(self._simplified_path, 1, 1)
	else
		self._curve_path = {
			self._simplified_path[1],
			mvec3_cpy(self._nav_point_pos(self._simplified_path[2]))
		}
	end

	if #self._simplified_path == 2 and not self._was_interrupted and not self._NO_RUN_STOP and not self._no_walk and self._haste ~= "walk" and not (mvec3_dis(self._curve_path[2], self._curve_path[1]) < 210) then
		self._chk_stop_dis = 210
	end

	if Network:is_server() then
		local sync_yaw = 0

		if self._end_rot then
			local yaw = self._end_rot:yaw()

			if yaw < 0 then
				yaw = 360 + yaw
			end

			sync_yaw = 1 + math.ceil(yaw * 254 / 360)
		end

		local sync_haste = self._haste == "walk" and 1 or 2
		local next_nav_point = self._nav_point_pos(self._simplified_path[2])
		local pose_code

		pose_code = not action_desc.pose and 0 or action_desc.pose == "stand" and 1 or 2

		local end_pose_code

		end_pose_code = not action_desc.end_pose and 0 or action_desc.end_pose == "stand" and 1 or 2

		self._ext_network:send("action_walk_start", self._nav_point_pos(next_nav_point), 1, 0, false, sync_haste, sync_yaw, self._no_walk and true or false, self._no_strafe and true or false, pose_code, end_pose_code)
	else
		local pose = action_desc.pose

		if pose and not self._unit:anim_data()[pose] then
			if pose == "stand" then
				local action, success = CopActionStand:new(action_desc, self._common_data)
			else
				local action, success = CopActionCrouch:new(action_desc, self._common_data)
			end
		end
	end

	if Network:is_server() then
		self._unit:brain():rem_pos_rsrv("stand")
		self._unit:brain():add_pos_rsrv("move_dest", {
			radius = 30,
			position = mvector3.copy(self._simplified_path[#self._simplified_path])
		})
	end

	return true
end
```

## Diff 246.1 -> ITER

```diff
--- 246.1 vanilla
+++ ITER
@@ -1,159 +1,22 @@
-if not self:_sanitize() then
-		return
-	end
-
-	self._init_called = true
-
-	local action_desc = self._action_desc
-	local common_data = self._common_data
-
-	if self._is_civilian then
-		print("common_data ", inspect(common_data))
-	end
-
-	if self._sync then
-		if managers.groupai:state():all_AI_criminals()[common_data.unit:key()] then
-			self._nav_link_invul = true
-		end
-
-		local nav_path = {}
-
-		for i, nav_point in ipairs(self._nav_path) do
-			if nav_point.x then
-				table.insert(nav_path, nav_point)
-			elseif alive(nav_point) then
-				table.insert(nav_path, {
-					element = nav_point:script_data().element,
-					c_class = nav_point
-				})
-			else
-				debug_pause_unit(self._unit, "dead nav_link", self._unit)
-
-				return false
-			end
-		end
-
-		self._nav_path = nav_path
-	else
-		local t_ins = table.insert
-		local new_nav_points = self._simplified_path
-
-		if new_nav_points then
-			for _, nav_point in ipairs(new_nav_points) do
-				t_ins(self._nav_path, nav_point.x and mvec3_cpy(nav_point) or nav_point)
-			end
-		end
-
-		if not action_desc.interrupted or not self._nav_path or not self._nav_path[1].x then
-			t_ins(self._nav_path, 1, mvec3_cpy(common_data.pos))
-		else
-			self._nav_path[1] = mvec3_cpy(common_data.pos)
-		end
-
-		for i, nav_point in ipairs(self._nav_path) do
-			if not nav_point.x then
-				function nav_point.element.value(element, name)
-					return element[name]
-				end
-
-				function nav_point.element.nav_link_wants_align_pos(element)
-					return element.from_idle
-				end
-			end
-		end
-
-		if not action_desc.host_stop_pos_ahead and self._nav_path[2] then
-			local ray_params = {
-				tracker_from = common_data.nav_tracker,
-				pos_to = self._nav_point_pos(self._nav_path[2])
-			}
-
-			if managers.navigation:raycast(ray_params) then
-				t_ins(self._nav_path, 2, mvec3_cpy(self._ext_movement:m_host_stop_pos()))
-
-				self._host_stop_pos_ahead = true
-			end
-		end
-	end
-
-	if action_desc.path_simplified and action_desc.persistent then
-		self._simplified_path = self._nav_path
-	elseif not managers.groupai:state():enemy_weapons_hot() then
-		self._simplified_path = self._nav_path
-	else
-		local good_pos = mvector3.copy(common_data.pos)
-
-		self._simplified_path = self._calculate_simplified_path(good_pos, self._nav_path, (not self._sync or self._common_data.stance.name == "ntl") and 2 or 1, self._sync, true)
-	end
-
-	if not self._simplified_path[2].x then
-		self._next_is_nav_link = self._simplified_path[2]
-	end
-
-	self._curve_path_index = 1
-
-	self:_chk_start_anim(CopActionWalk._nav_point_pos(self._simplified_path[2]))
-
-	if self._start_run then
-		self:_set_updator("_upd_start_anim_first_frame")
-	end
-
-	if not self._start_run_turn and mvec3_dis(self._nav_point_pos(self._simplified_path[2]), self._simplified_path[1]) > 400 and self._ext_base:lod_stage() == 1 then
-		self._curve_path = self:_calculate_curved_path(self._simplified_path, 1, 1)
-	else
-		self._curve_path = {
-			self._simplified_path[1],
-			mvec3_cpy(self._nav_point_pos(self._simplified_path[2]))
-		}
-	end
-
-	if #self._simplified_path == 2 and not self._was_interrupted and not self._NO_RUN_STOP and not self._no_walk and self._haste ~= "walk" and not (mvec3_dis(self._curve_path[2], self._curve_path[1]) < 210) then
-		self._chk_stop_dis = 210
-	end
-
-	if Network:is_server() then
-		local sync_yaw = 0
-
-		if self._end_rot then
-			local yaw = self._end_rot:yaw()
-
-			if yaw < 0 then
-				yaw = 360 + yaw
-			end
-
-			sync_yaw = 1 + math.ceil(yaw * 254 / 360)
-		end
-
-		local sync_haste = self._haste == "walk" and 1 or 2
-		local next_nav_point = self._nav_point_pos(self._simplified_path[2])
-		local pose_code
-
-		pose_code = not action_desc.pose and 0 or action_desc.pose == "stand" and 1 or 2
-
-		local end_pose_code
-
-		end_pose_code = not action_desc.end_pose and 0 or action_desc.end_pose == "stand" and 1 or 2
-
-		self._ext_network:send("action_walk_start", self._nav_point_pos(next_nav_point), 1, 0, false, sync_haste, sync_yaw, self._no_walk and true or false, self._no_strafe and true or false, pose_code, end_pose_code)
-	else
-		local pose = action_desc.pose
-
-		if pose and not self._unit:anim_data()[pose] then
-			if pose == "stand" then
-				local action, success = CopActionStand:new(action_desc, self._common_data)
-			else
-				local action, success = CopActionCrouch:new(action_desc, self._common_data)
-			end
-		end
-	end
-
-	if Network:is_server() then
-		self._unit:brain():rem_pos_rsrv("stand")
-		self._unit:brain():add_pos_rsrv("move_dest", {
-			radius = 30,
-			position = mvector3.copy(self._simplified_path[#self._simplified_path])
-		})
-	end
-
-	return true
+local nav_path = self._nav_path
+	if nav_path and not nav_path[2] then
+		local expand_nav_path
+		local action_desc = self._action_desc
+		if action_desc.path_simplified and action_desc.persistent then
+			expand_nav_path = true
+		elseif not managers.groupai:state():enemy_weapons_hot() then
+			expand_nav_path = true
+		end
+		if expand_nav_path then
+			table.insert(nav_path, 1, mvector3.copy(self._common_data.pos))
+		end
+	end
+
+	local result = itr_original_copactionwalk_init(self)
+
+	if result and self._sync then
+		self:itr_prepare_for_upcoming_navlink()
+	end
+
+	return result
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

1. **Wrapper or replacement.** Wrapper. `lua/copactionwalk.lua:15` captures `itr_original_copactionwalk_init = CopActionWalk._init`; the body `:16-38` pre-expands `self._nav_path`, calls the original at `:31`, then calls `self:itr_prepare_for_upcoming_navlink()` at `:34`.
2. **Call sites.** r200: the class override applies wherever vanilla calls `_init`. 248.2: `lib/units/enemies/cop/actions/lower_body/copactionwalk.lua:371` (`elseif not self:_init() then`) and `:962` (both inside `CopActionWalk:init`).
3. **Intent.** A one-point `_nav_path` (a single nav-link element or a single position) must still become a two-point path, or `_simplified_path[2]` is nil and the action cannot compute its first step; then pre-reserve the upcoming nav link so the unit does not stop at the link.
4. **248.2 delta.** None inside `_init` (248.2 `:413-572`, 160 lines == 246.1). The 246.1→248.2 hunks in this file are at 677 (`_chk_start_anim`), 894 (`on_exit`, adds `self._root_blend_disabled = nil`), 1227 (`_upd_start_anim`) and 1385 (`get_husk_interrupt_desc`, adds `_init_called` nav_path handling) — none touch `_init`.
5. **Target mechanism.** Port as-is. The pre-expansion is still required because 248.2 assigns `self._simplified_path = self._nav_path` unsimplified in exactly the two branches r200 pre-expands (`:492-495`), and then reads `_simplified_path[2]` at `:502` and `:508`. Fields: `self._nav_path`, `self._action_desc.path_simplified/persistent`, `managers.groupai:state():enemy_weapons_hot()`.
6. **Decision.** **PORT** (P6, F3/A-02) with two fixes: (a) `itr_prepare_for_upcoming_navlink` is defined inside `if Network:is_server()` (`:40-334`) but r200 calls it precisely when `self._sync` (client) — move the call behind `Network:is_server()`; (b) `get_husk_interrupt_desc` at 248.2 now branches on `self._init_called` (`:1403-1414`), so the husk interrupt path inherits the expanded `_nav_path` — verify the husk re-serialisation does not duplicate the inserted point.
7. **Acceptance.** T5. Log `evt=path_extend k=init_expanded=0|1,points=<n>,sync=0|1` and `evt=fallback k=reason=navlink_helper_missing`.
8. **Cost if wrong.** Inserting a start point where the nav path already starts at the unit ⇒ a zero-length first segment ⇒ `_chk_start_anim` (`:508`) computes a zero-direction and the unit turns in place or stalls. Calling the client-only-missing helper ⇒ `attempt to call method 'itr_prepare_for_upcoming_navlink' (a nil value)` on the client, every walk action.
9. **Evidence gaps.** No client-side (husk) test exists in the current cards; T5 as written is server-only. The `_sync` + `_init_called` interaction is unverified against a real client.
