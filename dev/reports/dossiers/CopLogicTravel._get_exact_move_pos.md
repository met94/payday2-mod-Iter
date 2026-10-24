# Function dossier: lua/coplogictravel.lua :: CopLogicTravel._get_exact_move_pos

Category: **MOD_EDIT_CLEAN**

- ITER: 40 lines, params `(data, nav_index)`
- 246.1: 98 lines, params `(data, nav_index)`
- 248.2: 98 lines, params `(data, nav_index)`

Normalized signature: `self` is omitted for methods; the body is the porting surface.

## ITER body (V8.57)

```lua
function CopLogicTravel._get_exact_move_pos(data, nav_index)
local my_data = data.internal_data
	local coarse_path = my_data.coarse_path
	local nr = #coarse_path

	if nr > 2 and nav_index == 2 and my_data.itr_direct_to_pos then
		if my_data.moving_to_cover then
			managers.navigation:release_cover(my_data.moving_to_cover[1])
			my_data.moving_to_cover = nil
		end

		local nav_segs = {}
		for i = 1, nr do
			nav_segs[i] = coarse_path[i][1]
		end
		my_data.itr_nav_segs = nav_segs

		my_data.coarse_path = {
			coarse_path[1],
			coarse_path[nr]
		}

		return my_data.itr_direct_to_pos
	end

	if nav_index < nr then
		if data.is_converted or data.team and data.team.id == 'criminal1' then
			if my_data.moving_to_cover then
				managers.navigation:release_cover(my_data.moving_to_cover[1])
				my_data.moving_to_cover = nil
			end
			return coarse_path[nav_index][2]

		elseif data.objective and data.objective.type == 'phalanx' then
			return coarse_path[nav_index][2]
		end
	end

	return itr_original_coplogictravel_getexactmovepos(data, nav_index)
end
```

## 246.1 vanilla (a3180fc)

```lua
function CopLogicTravel._get_exact_move_pos(data, nav_index)
local my_data = data.internal_data
	local objective = data.objective
	local to_pos
	local coarse_path = my_data.coarse_path
	local total_nav_points = #coarse_path
	local reservation, wants_reservation

	if total_nav_points <= nav_index then
		local new_occupation = data.logic._determine_destination_occupation(data, objective)

		if new_occupation then
			if new_occupation.type == "guard" then
				local guard_door = new_occupation.door
				local guard_pos = CopLogicTravel._get_pos_accross_door(guard_door, objective.nav_seg)

				if guard_pos then
					reservation = CopLogicTravel._reserve_pos_along_vec(guard_door.center, guard_pos)

					if reservation then
						local guard_object = {
							type = "door",
							door = guard_door,
							from_seg = new_occupation.from_seg
						}

						objective.guard_obj = guard_object
						to_pos = reservation.pos
					end
				end
			elseif new_occupation.type == "defend" then
				if new_occupation.cover then
					to_pos = new_occupation.cover[1][1]

					if data.char_tweak.wall_fwd_offset then
						to_pos = CopLogicTravel.apply_wall_offset_to_cover(data, my_data, new_occupation.cover[1], data.char_tweak.wall_fwd_offset)
					end

					local new_cover = new_occupation.cover

					managers.navigation:reserve_cover(new_cover[1], data.pos_rsrv_id)

					my_data.moving_to_cover = new_cover
				elseif new_occupation.pos then
					to_pos = new_occupation.pos
				end

				wants_reservation = true
			elseif new_occupation.type == "act" then
				to_pos = new_occupation.pos
				wants_reservation = true
			elseif new_occupation.type == "revive" then
				to_pos = new_occupation.pos
				objective.rot = new_occupation.rot
				wants_reservation = true
			else
				to_pos = new_occupation.pos
				wants_reservation = true
			end
		end

		if not to_pos then
			to_pos = managers.navigation:find_random_position_in_segment(objective.nav_seg)
			to_pos = CopLogicTravel._get_pos_on_wall(to_pos)
			wants_reservation = true
		end
	else
		local nav_seg = coarse_path[nav_index][1]
		local area = managers.groupai:state():get_area_from_nav_seg_id(nav_seg)
		local cover = managers.navigation:find_cover_in_nav_seg_1(area.nav_segs)

		if my_data.moving_to_cover then
			managers.navigation:release_cover(my_data.moving_to_cover[1])

			my_data.moving_to_cover = nil
		end

		if cover then
			managers.navigation:reserve_cover(cover, data.pos_rsrv_id)

			my_data.moving_to_cover = {
				cover
			}
			to_pos = cover[1]
		else
			to_pos = coarse_path[nav_index][2]
		end
	end

	if not reservation and wants_reservation then
		data.brain:add_pos_rsrv("path", {
			radius = 60,
			position = mvector3.copy(to_pos)
		})
	end

	return to_pos
end
```

## 248.2 vanilla (e3a8b616)

```lua
function CopLogicTravel._get_exact_move_pos(data, nav_index)
local my_data = data.internal_data
	local objective = data.objective
	local to_pos
	local coarse_path = my_data.coarse_path
	local total_nav_points = #coarse_path
	local reservation, wants_reservation

	if total_nav_points <= nav_index then
		local new_occupation = data.logic._determine_destination_occupation(data, objective)

		if new_occupation then
			if new_occupation.type == "guard" then
				local guard_door = new_occupation.door
				local guard_pos = CopLogicTravel._get_pos_accross_door(guard_door, objective.nav_seg)

				if guard_pos then
					reservation = CopLogicTravel._reserve_pos_along_vec(guard_door.center, guard_pos)

					if reservation then
						local guard_object = {
							type = "door",
							door = guard_door,
							from_seg = new_occupation.from_seg
						}

						objective.guard_obj = guard_object
						to_pos = reservation.pos
					end
				end
			elseif new_occupation.type == "defend" then
				if new_occupation.cover then
					to_pos = new_occupation.cover[1][1]

					if data.char_tweak.wall_fwd_offset then
						to_pos = CopLogicTravel.apply_wall_offset_to_cover(data, my_data, new_occupation.cover[1], data.char_tweak.wall_fwd_offset)
					end

					local new_cover = new_occupation.cover

					managers.navigation:reserve_cover(new_cover[1], data.pos_rsrv_id)

					my_data.moving_to_cover = new_cover
				elseif new_occupation.pos then
					to_pos = new_occupation.pos
				end

				wants_reservation = true
			elseif new_occupation.type == "act" then
				to_pos = new_occupation.pos
				wants_reservation = true
			elseif new_occupation.type == "revive" then
				to_pos = new_occupation.pos
				objective.rot = new_occupation.rot
				wants_reservation = true
			else
				to_pos = new_occupation.pos
				wants_reservation = true
			end
		end

		if not to_pos then
			to_pos = managers.navigation:find_random_position_in_segment(objective.nav_seg)
			to_pos = CopLogicTravel._get_pos_on_wall(to_pos)
			wants_reservation = true
		end
	else
		local nav_seg = coarse_path[nav_index][1]
		local area = managers.groupai:state():get_area_from_nav_seg_id(nav_seg)
		local cover = managers.navigation:find_cover_in_nav_seg_1(area.nav_segs)

		if my_data.moving_to_cover then
			managers.navigation:release_cover(my_data.moving_to_cover[1])

			my_data.moving_to_cover = nil
		end

		if cover then
			managers.navigation:reserve_cover(cover, data.pos_rsrv_id)

			my_data.moving_to_cover = {
				cover
			}
			to_pos = cover[1]
		else
			to_pos = coarse_path[nav_index][2]
		end
	end

	if not reservation and wants_reservation then
		data.brain:add_pos_rsrv("path", {
			radius = 60,
			position = mvector3.copy(to_pos)
		})
	end

	return to_pos
end
```

## Diff 246.1 -> ITER

```diff
--- 246.1 vanilla
+++ ITER
@@ -1,97 +1,39 @@
-local my_data = data.internal_data
-	local objective = data.objective
-	local to_pos
-	local coarse_path = my_data.coarse_path
-	local total_nav_points = #coarse_path
-	local reservation, wants_reservation
-
-	if total_nav_points <= nav_index then
-		local new_occupation = data.logic._determine_destination_occupation(data, objective)
-
-		if new_occupation then
-			if new_occupation.type == "guard" then
-				local guard_door = new_occupation.door
-				local guard_pos = CopLogicTravel._get_pos_accross_door(guard_door, objective.nav_seg)
-
-				if guard_pos then
-					reservation = CopLogicTravel._reserve_pos_along_vec(guard_door.center, guard_pos)
-
-					if reservation then
-						local guard_object = {
-							type = "door",
-							door = guard_door,
-							from_seg = new_occupation.from_seg
-						}
-
-						objective.guard_obj = guard_object
-						to_pos = reservation.pos
-					end
-				end
-			elseif new_occupation.type == "defend" then
-				if new_occupation.cover then
-					to_pos = new_occupation.cover[1][1]
-
-					if data.char_tweak.wall_fwd_offset then
-						to_pos = CopLogicTravel.apply_wall_offset_to_cover(data, my_data, new_occupation.cover[1], data.char_tweak.wall_fwd_offset)
-					end
-
-					local new_cover = new_occupation.cover
-
-					managers.navigation:reserve_cover(new_cover[1], data.pos_rsrv_id)
-
-					my_data.moving_to_cover = new_cover
-				elseif new_occupation.pos then
-					to_pos = new_occupation.pos
-				end
-
-				wants_reservation = true
-			elseif new_occupation.type == "act" then
-				to_pos = new_occupation.pos
-				wants_reservation = true
-			elseif new_occupation.type == "revive" then
-				to_pos = new_occupation.pos
-				objective.rot = new_occupation.rot
-				wants_reservation = true
-			else
-				to_pos = new_occupation.pos
-				wants_reservation = true
-			end
-		end
-
-		if not to_pos then
-			to_pos = managers.navigation:find_random_position_in_segment(objective.nav_seg)
-			to_pos = CopLogicTravel._get_pos_on_wall(to_pos)
-			wants_reservation = true
-		end
-	else
-		local nav_seg = coarse_path[nav_index][1]
-		local area = managers.groupai:state():get_area_from_nav_seg_id(nav_seg)
-		local cover = managers.navigation:find_cover_in_nav_seg_1(area.nav_segs)
-
-		if my_data.moving_to_cover then
-			managers.navigation:release_cover(my_data.moving_to_cover[1])
-
-			my_data.moving_to_cover = nil
-		end
-
-		if cover then
-			managers.navigation:reserve_cover(cover, data.pos_rsrv_id)
-
-			my_data.moving_to_cover = {
-				cover
-			}
-			to_pos = cover[1]
-		else
-			to_pos = coarse_path[nav_index][2]
-		end
-	end
-
-	if not reservation and wants_reservation then
-		data.brain:add_pos_rsrv("path", {
-			radius = 60,
-			position = mvector3.copy(to_pos)
-		})
-	end
-
-	return to_pos
+local my_data = data.internal_data
+	local coarse_path = my_data.coarse_path
+	local nr = #coarse_path
+
+	if nr > 2 and nav_index == 2 and my_data.itr_direct_to_pos then
+		if my_data.moving_to_cover then
+			managers.navigation:release_cover(my_data.moving_to_cover[1])
+			my_data.moving_to_cover = nil
+		end
+
+		local nav_segs = {}
+		for i = 1, nr do
+			nav_segs[i] = coarse_path[i][1]
+		end
+		my_data.itr_nav_segs = nav_segs
+
+		my_data.coarse_path = {
+			coarse_path[1],
+			coarse_path[nr]
+		}
+
+		return my_data.itr_direct_to_pos
+	end
+
+	if nav_index < nr then
+		if data.is_converted or data.team and data.team.id == 'criminal1' then
+			if my_data.moving_to_cover then
+				managers.navigation:release_cover(my_data.moving_to_cover[1])
+				my_data.moving_to_cover = nil
+			end
+			return coarse_path[nav_index][2]
+
+		elseif data.objective and data.objective.type == 'phalanx' then
+			return coarse_path[nav_index][2]
+		end
+	end
+
+	return itr_original_coplogictravel_getexactmovepos(data, nav_index)
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
