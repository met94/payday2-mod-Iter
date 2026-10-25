# Function dossier: lua/navigationmanager.lua :: NavigationManager.itr_find_proxies

Category: **MOD_ONLY**

- ITER: 128 lines, params `(segment_id)`
- 246.1: not found
- 248.2: not found

Normalized signature: `self` is omitted for methods; the body is the porting surface.

## ITER body (V8.57)

```lua
function NavigationManager.itr_find_proxies(segment_id)
local choke_points, choke_point_proxies = {}, {}
	local in_proxies = {}
	local out_proxies = {}
	local all_doors = self._room_doors
	local all_nav_segments = self._nav_segments
	local segment = all_nav_segments[segment_id]
	local all_seg_doors, room_neighbours = self:itr_get_all_doors_of_segment(segment_id)
	local room_to_doors = self:itr_get_room_to_doors(segment_id, all_seg_doors)

	for neighbour_seg_id, door_list in pairs(segment.neighbours) do
		local best_level
		local min_count = 1000
		local level1_contiguous
		local room_flood_levels, door_flood_levels, door_level_counts = self:itr_flood(door_list, room_to_doors)

		local important_rooms = itr_get_rooms_having_access_to_next_level(all_doors, room_to_doors, room_flood_levels, room_neighbours)
		local important_doors = {}
		local room_level_counts = {}
		for room_id, level in pairs(important_rooms) do
			room_level_counts[level] = room_level_counts[level] and room_level_counts[level] + 1 or 1
			if level == 1 then
				for _, door_id in ipairs(room_to_doors[room_id]) do
					if door_flood_levels[door_id] == 1 then
						table_insert(important_doors, door_id)
					end
				end
			end
		end

		for level, count in pairs(door_level_counts) do
			if not self:itr_is_contiguous(level, door_flood_levels, room_to_doors) then
				break
			end
			if count <= min_count then
				best_level = level
				min_count = count
			end
			if level == 1 then
				level1_contiguous = true
			elseif level > 4 then
				break
			end
		end

		if best_level and table.size(all_seg_doors) > 20 then
			local cnt = 0
			local pos = Vector3(0, 0, 0)
			for door_id, level in pairs(door_flood_levels) do
				if level == best_level then
					itr_add_door_pos_to(pos, all_doors, door_id)
					cnt = cnt + 1
				end
			end
			if cnt > 0 and cnt < 5 then
				mvec3_div(pos, cnt)
				out_proxies[neighbour_seg_id] = pos
			end
		end

		local neighbour_in_proxies = all_nav_segments[neighbour_seg_id].in_proxies
		local already_done = neighbour_in_proxies and neighbour_in_proxies[segment_id]
		if already_done ~= nil then
			in_proxies[neighbour_seg_id] = already_done
		elseif level1_contiguous then
			local cnt = 0
			local frontier_center = Vector3(0, 0, 0)
			for _, door_id in ipairs(important_doors) do
				itr_add_door_pos_to(frontier_center, all_doors, door_id)
				cnt = cnt + 1
			end
			if cnt > 2 then
				mvec3_div(frontier_center, cnt)
				local metawidth = 0
				for _, door_id in ipairs(important_doors) do
					local dis
					if type(door_id) == 'number' then
						local door = all_doors[door_id]
						mvec3_lerp(tmp_vec, door.pos, door.pos1, 0.5)
						dis = mvec3_dis_sq(frontier_center, tmp_vec)
					elseif alive(door_id) then
						dis = mvec3_dis_sq(frontier_center, _navlink_elements[door_id:key()]:value('position'))
					end
					if dis and dis > metawidth then
						metawidth = dis
					end
				end
				in_proxies[neighbour_seg_id] = metawidth < (150 * 150) and frontier_center or nil
			end
		end

		if #door_list > 1 then
			local choke_point_pos, lower_levels_contiguity = self:itr_find_choke_point(room_flood_levels, room_level_counts, room_to_doors, door_flood_levels, important_rooms)
			if choke_point_pos then
				local choke_pos = choke_point
				choke_points[neighbour_seg_id] = choke_point_pos

				if lower_levels_contiguity then
					-- pick the closest important door
					local best_pos = Vector3()
					local min_dis = 1000000000
					for _, door_id in ipairs(important_doors) do
						local door = all_doors[door_id]
						if mvec3_dis_sq(door.pos, door.pos1) > 2500 then
							mvec3_lerp(tmp_vec, door.pos, door.pos1, 0.5)
							local dis = mvec3_dis_sq(tmp_vec, choke_point_pos)
							if dis < min_dis then
								min_dis = dis
								mvec3_set(best_pos, tmp_vec)
							end
						else
							for _, pos in ipairs({door.pos, door.pos1}) do
								local dis = mvec3_dis_sq(pos, choke_point_pos)
								if dis < min_dis then
									min_dis = dis
									mvec3_set(best_pos, pos)
								end
							end
						end
					end
					choke_point_proxies[neighbour_seg_id] = best_pos
				end
			end
		end
	end

	return choke_points, choke_point_proxies, in_proxies, out_proxies
end
```

## 246.1 vanilla (a3180fc)

246.1: not found.

## 248.2 vanilla (e3a8b616)

248.2: not found.

## Diff 246.1 -> ITER

Cannot diff: 246.1 function not found.

## Diff 246.1 -> 248.2

Cannot diff: old or new function missing.

## Porter checklist

- [ ] Decision: keep ITER body, adopt 248.2 vanilla, or merge.
- [ ] If merge: re-apply the ITER intent onto the 248.2 body, not the 246.1 body.
- [ ] Check removed/changed APIs (`_room_doors`, numeric `_nav_segments`, `no_dispose`, `session():send_to_peers_synched`, ...).
- [ ] Check new 248.2 fields/callbacks this function must preserve.
- [ ] Run `luajit -bl` and `api-audit` on the file.

## Port notes (P1)

**Call sites.** `lua/navigationmanager.lua:634` inside `itr_prepare_streamline_data`, itself called from `itr_prepare_nav_data` (`:677`) through the `_resolve_segment_neighbours` post-hook (`:700-702`). No game caller.
**Intent.** Per segment/neighbour pair, derive choke points and in/out/through proxies that later route paths through doorway centres.
**248.2 constraint.** `segment.neighbours[neighbour]` holds engine door `Vector3`s or nav-link userdata (`:331-348`); the r200 flood needs numeric door ids plus `_room_doors`, `_rooms`, `_visibility_groups`, none of which v6 builds (`get_nav_seg_from_i_room` at `:1601-1603` reads tables that stay empty).
**Target mechanism.** `nav.itr_shim_door_by_pair` (shim `:306-343`, assigned `:387`) replaces numeric neighbour entries; `_room_doors`/`_rooms`/`_visibility_groups` from shim `:384-386`; `itr_copy_door_data` (`:651-661`) exposes `itr_room_doors`; `proxy_no_doors` counter (`:625-627`).
**Decision.** PORT (F2, S-01/S-02 implemented) — keep the flood/choke intent on shim door ids. Current body is `:479-630`; the dossier body above predates the pair-index block (`:488-508`).
**Acceptance.** T1 `[ITER-NAV] ... evt=heist rooms=>0 room_doors=>0 vis_groups=>0` and `evt=proxy segments=>0 choke=>=0 in_proxies out_proxies ms=<n>`, with `proxy_no_doors` bounded (nav-link-only neighbours expected). The pair index is only visible as `evt=navdata ... door_pairs=<n>` (shim `:390`), not on the proxy line.
**Cost if wrong.** Empty proxies: `itr_get_coarse_pos_between` falls through to the closest-door lookup (`:939`) or returns false, so the Iter search skips neighbours (`:1154`) and streamline degrades to vanilla. No crash path while the flag is off.
**Evidence gaps.** `choke_pos = choke_point` (`:593`) assigns an undefined global — dead but an audit/freevars smell. The shim assigns `room.vis_group` from the first visibility group listing the quad (shim `:204`), whereas 246.1 used `data.room_vis_groups[i_room]` (`a3180fc` `:357`); equality unverified on 248.2 data.
