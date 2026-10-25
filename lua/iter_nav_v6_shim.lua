-- Iter v6 navigation geometry shim.
-- Diesel 3 (247+) stopped building the runtime nav geometry tables on
-- NavigationManager, but the v5 -> v6 converter still forwards the v5 arrays.
-- This module rebuilds _rooms, _room_doors and _visibility_groups from that
-- load data so the ported streamline/flood/proxy code has a geometry source.
-- Scope: geometry tables only. No AI behaviour lives here (N-01 card).
-- Owner: lua/navigationmanager.lua (nav_overlay gate), decisions.md R4.
-- The v5 table names are allowlisted for this file in dev/tools/api-allowlist.json.

local IterNavShim = {}

local Vector3_new = Vector3
local t_ins = table.insert
local K_STATS = 'itr_shim'

local function diag()
	return Iter and Iter.diag
end

local function diag_event(name, fields)
	local d = diag()

	if not d or not d.event then
		return
	end

	d.event(name, fields)
end

local function diag_count(name, amount)
	local d = diag()

	if not d or not d.count then
		return
	end

	d.count(name, amount)
end

-- Optional load-data lists may be missing or malformed on odd data.
local function as_list(value)
	if type(value) ~= 'table' then
		return {}
	end

	return value
end

-- A native v6 payload carries no v5 arrays and can arrive outside a level load
-- (delete_nav_segment, build_complete_clbk). It keeps whatever geometry is
-- already built; every other failure means the data is missing or corrupt, so
-- stale tables are dropped. Level changes clear through the _clear hook first.
local KEEP_TABLES = {
	v6_only_data = true
}

local function report_fallback(nav, reason, msg)
	local keep = KEEP_TABLES[reason] == true
	local previous = nav[K_STATS] or {}

	if not keep then
		nav._rooms = {}
		nav._room_doors = {}
		nav._visibility_groups = {}
	end

	nav[K_STATS] = {
		rooms = keep and #(nav._rooms or {}) or 0,
		room_doors = keep and #(nav._room_doors or {}) or 0,
		vis_groups = keep and #(nav._visibility_groups or {}) or 0,
		doors_skipped = keep and (previous.doors_skipped or 0) or 0,
		groups_without_seg = keep and (previous.groups_without_seg or 0) or 0,
		segments = keep and (previous.segments or 0) or 0,
		grid = keep and (previous.grid or 0) or 0,
		fallback = 1,
		reason = reason
	}

	local payload = {
		subsystem = 'shim',
		reason = reason
	}

	if msg then
		payload.msg = msg
	end

	diag_count('fallback')
	diag_event('fallback', payload)

	return false
end

local function build(nav, load_data)
	if type(load_data) ~= 'table' then
		return {
			ok = false,
			reason = 'no_load_data'
		}
	end

	-- The post-hook also runs when the vanilla function early-returns.
	if type(load_data.segments) ~= 'table' or not next(load_data.segments) then
		return {
			ok = false,
			reason = 'no_segments'
		}
	end

	local borders_x_pos = load_data.quad_borders_x_pos
	local borders_x_neg = load_data.quad_borders_x_neg
	local borders_y_pos = load_data.quad_borders_y_pos
	local borders_y_neg = load_data.quad_borders_y_neg
	local heights_xp_yp = load_data.quad_heights_xp_yp
	local heights_xp_yn = load_data.quad_heights_xp_yn
	local heights_xn_yp = load_data.quad_heights_xn_yp
	local heights_xn_yn = load_data.quad_heights_xn_yn

	if not (type(borders_x_pos) == 'table'
		and type(borders_x_neg) == 'table' and type(borders_y_pos) == 'table' and type(borders_y_neg) == 'table'
		and type(heights_xp_yp) == 'table' and type(heights_xp_yn) == 'table'
		and type(heights_xn_yp) == 'table' and type(heights_xn_yn) == 'table') then
		return {
			ok = false,
			reason = 'v6_only_data'
		}
	end

	local vis_groups_in = load_data.visibility_groups

	if type(vis_groups_in) ~= 'table' or not next(vis_groups_in) then
		return {
			ok = false,
			reason = 'no_vis_groups'
		}
	end

	local door_low_pos = load_data.door_low_pos
	local door_high_pos = load_data.door_high_pos
	local door_low_quads = load_data.door_low_quads
	local door_high_quads = load_data.door_high_quads

	if type(door_low_quads) ~= 'table' or type(door_high_quads) ~= 'table' then
		return {
			ok = false,
			reason = 'no_door_quads'
		}
	end

	-- v5 load data stores x/y in grid units; z and heights are absolute.
	-- The grid size is the only scale source, so never invent one.
	local grid_size = tonumber(nav._grid_size)

	if not grid_size or grid_size <= 0 then
		return {
			ok = false,
			reason = 'no_grid_size'
		}
	end

	local nr_rooms = #borders_x_pos
	local rooms = {}

	for i_room = 1, nr_rooms do
		t_ins(rooms, {
			borders = {
				x_pos = borders_x_pos[i_room] * grid_size,
				x_neg = borders_x_neg[i_room] * grid_size,
				y_pos = borders_y_pos[i_room] * grid_size,
				y_neg = borders_y_neg[i_room] * grid_size
			},
			height = {
				xp_yp = heights_xp_yp[i_room],
				xp_yn = heights_xp_yn[i_room],
				xn_yp = heights_xn_yp[i_room],
				xn_yn = heights_xn_yn[i_room]
			},
			vis_group = nil
		})
	end

	-- The converter drops quad_vis_groups; the owner is recovered from the
	-- visibility groups' quad lists (v5 room_vis_groups is the inverse map).
	local quad_to_vis_group = {}
	local visibility_groups = {}

	for i_vis_group = 1, #vis_groups_in do
		local source = vis_groups_in[i_vis_group]
		local source_pos = source and source.pos
		local visible_groups = {}
		local group = {
			quads = {},
			rooms = {},
			-- r200 reads .vis_groups, v6 data calls it .visible_groups: alias.
			vis_groups = visible_groups,
			visible_groups = visible_groups,
			pos = source_pos and Vector3_new(source_pos.x, source_pos.y, source_pos.z) or Vector3_new(0, 0, 0),
			seg = nil
		}

		for _, quad_key in ipairs(as_list(source and source.quads)) do
			local i_quad = tonumber(quad_key)

			if i_quad and rooms[i_quad] and not quad_to_vis_group[i_quad] then
				quad_to_vis_group[i_quad] = i_vis_group
				t_ins(group.quads, i_quad)
				group.rooms[i_quad] = true
			end
		end

		for _, visible_key in ipairs(as_list(source and source.visible_groups)) do
			local i_visible = tonumber(visible_key)

			if i_visible and i_visible ~= i_vis_group then
				visible_groups[i_visible] = true
			end
		end

		t_ins(visibility_groups, group)
	end

	for i_room = 1, nr_rooms do
		local room = rooms[i_room]
		room.vis_group = quad_to_vis_group[i_room]
	end

	local nr_doors = type(door_low_pos) == 'table' and #door_low_pos or 0
	local room_doors = {}
	local doors_skipped = 0

	for i_door = 1, nr_doors do
		local low_pos = door_low_pos[i_door]
		local high_pos = door_high_pos and door_high_pos[i_door]
		local low_quad = tonumber(door_low_quads[i_door])
		local high_quad = tonumber(door_high_quads[i_door])

		if low_pos and high_pos and rooms[low_quad] and rooms[high_quad] then
			local pos = Vector3_new(low_pos.x * grid_size, low_pos.y * grid_size, low_pos.z)
			local pos1 = Vector3_new(high_pos.x * grid_size, high_pos.y * grid_size, high_pos.z)

			t_ins(room_doors, {
				pos = pos,
				pos1 = pos1,
				-- r200 gameplay shape: itr_get_door_in_alignment reads .center.
				center = Vector3_new(
					(pos.x + pos1.x) * 0.5,
					(pos.y + pos1.y) * 0.5,
					(pos.z + pos1.z) * 0.5
				),
				rooms = {
					low_quad,
					high_quad
				}
			})
		else
			doors_skipped = doors_skipped + 1
		end
	end

	-- Segment ids are string keys in _nav_segments at 248.2; the owning
	-- segment is the one that lists the visibility group.
	local segments_seen = 0

	for key, nav_seg in pairs(load_data.segments) do
		local unique_id

		if nav_seg.id ~= nil then
			unique_id = tostring(nav_seg.id)
		elseif type(key) == 'string' then
			unique_id = key
		end

		if unique_id then
			segments_seen = segments_seen + 1

			for _, group_key in ipairs(as_list(nav_seg.vis_groups)) do
				local i_vis_group = tonumber(group_key)
				local group = i_vis_group and visibility_groups[i_vis_group]

				if group and not group.seg then
					group.seg = unique_id
				end
			end
		end
	end

	local groups_without_seg = 0

	for i_vis_group = 1, #visibility_groups do
		if not visibility_groups[i_vis_group].seg then
			groups_without_seg = groups_without_seg + 1
		end
	end

	-- Map physical doors to the segment pair they connect. 248.2 stores
	-- neighbour entries as engine positions, not door ids, so the ported
	-- flood/proxy code needs this topology index to recover door ids.
	local function seg_of_quad(i_quad)
		local room = i_quad and rooms[i_quad]
		local i_vis_group = room and room.vis_group
		local group = i_vis_group and visibility_groups[i_vis_group]

		return group and group.seg
	end

	local door_by_pair = {}
	local doors_without_pair = 0
	local door_pairs = 0

	for i_door, door in ipairs(room_doors) do
		local seg_a = seg_of_quad(door.rooms[1])
		local seg_b = seg_of_quad(door.rooms[2])

		if seg_a and seg_b and seg_a ~= seg_b then
			local forward = door_by_pair[seg_a]

			if not forward then
				forward = {}
				door_by_pair[seg_a] = forward
			end

			local reverse = door_by_pair[seg_b]

			if not reverse then
				reverse = {}
				door_by_pair[seg_b] = reverse
			end

			if not forward[seg_b] then
				forward[seg_b] = {}
				door_pairs = door_pairs + 1
			end

			if not reverse[seg_a] then
				reverse[seg_a] = {}
			end

			t_ins(forward[seg_b], i_door)
			t_ins(reverse[seg_a], i_door)
		else
			doors_without_pair = doors_without_pair + 1
		end
	end

	local stats = {
		rooms = #rooms,
		room_doors = #room_doors,
		vis_groups = #visibility_groups,
		doors_skipped = doors_skipped,
		doors_without_pair = doors_without_pair,
		door_pairs = door_pairs,
		groups_without_seg = groups_without_seg,
		segments = segments_seen,
		grid = grid_size,
		fallback = 0
	}

	return {
		ok = true,
		rooms = rooms,
		room_doors = room_doors,
		visibility_groups = visibility_groups,
		door_by_pair = door_by_pair,
		stats = stats
	}
end

function IterNavShim.rebuild(nav, load_data)
	if type(nav) ~= 'table' then
		return false
	end

	local ok, result = pcall(build, nav, load_data)

	if not ok then
		-- One fallback line carries the short error; no separate err event.
		return report_fallback(nav, 'rebuild_error', tostring(result))
	end

	if not result or not result.ok then
		return report_fallback(nav, result and result.reason or 'unsupported')
	end

	nav._rooms = result.rooms
	nav._room_doors = result.room_doors
	nav._visibility_groups = result.visibility_groups
	nav.itr_shim_door_by_pair = result.door_by_pair
	nav[K_STATS] = result.stats

	diag_event('navdata', result.stats)

	return true
end

function IterNavShim.clear(nav)
	if type(nav) ~= 'table' then
		return
	end

	nav._rooms = {}
	nav._room_doors = {}
	nav._visibility_groups = {}
	nav.itr_shim_door_by_pair = nil
	nav[K_STATS] = nil
end

function IterNavShim.stats(nav)
	if type(nav) ~= 'table' then
		return nil
	end

	return nav[K_STATS]
end

-- navigationmanager.lua hooks reference the module by name.
_G.IterNavShim = IterNavShim

return IterNavShim
