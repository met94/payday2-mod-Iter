-- Offline unit test for lua/iter_nav_v6_shim.lua.
-- Runs on bare LuaJIT, no game/engine:
--   tools\luajit\luajit.exe dev\tests\lua\test_shim.lua
-- Vector3 and Iter.diag are stubbed; the shim is dofile'd from the mod root.

local script_path = (arg and arg[0]) or 'dev/tests/lua/test_shim.lua'
local test_dir = script_path:match('^(.*)[/\\][^/\\]+$') or '.'

local function resolve_shim()
	local candidates = {
		'lua/iter_nav_v6_shim.lua',
		test_dir .. '/../../../lua/iter_nav_v6_shim.lua'
	}

	for _, candidate in ipairs(candidates) do
		local handle = io.open(candidate, 'r')

		if handle then
			handle:close()
			return candidate
		end
	end

	error('cannot locate lua/iter_nav_v6_shim.lua from ' .. script_path)
end

-- Engine stub: the game exposes Vector3 as a callable global.
local function vector3(x, y, z)
	return {
		x = x or 0,
		y = y or 0,
		z = z or 0
	}
end

Vector3 = vector3

local checks = 0
local events = {}
local counters = {}

local function reset_events()
	events = {}
	counters = {}
end

Iter = {
	settings = {
		debug_log = 1
	},
	diag = {
		event = function(name, fields)
			events[#events + 1] = {
				name = name,
				fields = fields or {}
			}
		end,
		count = function(name, amount)
			counters[name] = (counters[name] or 0) + (amount or 1)
		end,
		err = function(where, message)
			events[#events + 1] = {
				name = 'err',
				fields = {
					where = where,
					msg = message
				}
			}
		end
	}
}

local shim_path = resolve_shim()
local IterNavShim = dofile(shim_path)

local function check(condition, message)
	if not condition then
		error(message, 2)
	end

	checks = checks + 1
end

local function check_equal(actual, expected, message)
	if actual ~= expected then
		error(string.format('%s (expected %s, got %s)', message, tostring(expected), tostring(actual)), 2)
	end

	checks = checks + 1
end

local function find_event(name)
	for i = #events, 1, -1 do
		if events[i].name == name then
			return events[i]
		end
	end

	return nil
end

local function count_events(name)
	local total = 0

	for _, event in ipairs(events) do
		if event.name == name then
			total = total + 1
		end
	end

	return total
end

-- Synthetic v5 load data after _convert_nav_data_v5_to_v6: quad arrays in
-- grid units (x/y), absolute z and heights, four quads, three visibility
-- groups, two segments, one valid door and one door pointing at a bad quad.
local function make_load_data()
	return {
		version = 6,
		quad_borders_x_pos = { 1.5, 3.0, 4.5, 6.0 },
		quad_borders_x_neg = { -1.5, 1.5, 3.0, 4.5 },
		quad_borders_y_pos = { 1.0, 1.0, 1.0, 1.0 },
		quad_borders_y_neg = { -1.0, -1.0, -1.0, -1.0 },
		quad_heights_xp_yp = { 0, 0, 0, 0 },
		quad_heights_xp_yn = { 10, 0, 0, 0 },
		quad_heights_xn_yp = { 20, 0, 0, 0 },
		quad_heights_xn_yn = { 30, 0, 0, 0 },
		door_low_pos = {
			{ x = 1.5, y = -1.0, z = 0.25 },
			{ x = 9.0, y = 9.0, z = 0.0 }
		},
		door_high_pos = {
			{ x = 1.5, y = 1.0, z = 0.25 },
			{ x = 9.0, y = 9.0, z = 0.0 }
		},
		door_low_quads = { 2, 99 },
		door_high_quads = { 3, 99 },
		visibility_groups = {
			{
				quads = { 1, 2 },
				visible_groups = { 2, 3 },
				pos = { x = 0.5, y = 0, z = 0 }
			},
			{
				quads = { 3 },
				visible_groups = { 1 },
				pos = { x = 3.5, y = 0, z = 0 }
			},
			{
				quads = { 4 },
				visible_groups = {},
				pos = { x = 5.5, y = 0, z = 0 }
			}
		},
		segments = {
			{
				id = 1,
				pos = { x = 0, y = 0, z = 0 },
				vis_groups = { 1, 2 },
				location_id = 1
			},
			{
				id = 2,
				pos = { x = 5, y = 0, z = 0 },
				vis_groups = { 3 },
				location_id = 2
			}
		}
	}
end

local function make_nav(grid_size)
	local nav = {
		_grid_size = grid_size == nil and 100 or grid_size
	}

	-- Vanilla accessor shape at 248.2: vis group index -> segment string id.
	function nav.get_nav_seg_from_i_room(self, i_room)
		return self._visibility_groups[self._rooms[i_room].vis_group].seg
	end

	return nav
end

local tests = {}

function tests.rebuilds_tables()
	reset_events()

	local nav = make_nav(100)
	local load_data = make_load_data()

	check(IterNavShim.rebuild(nav, load_data) == true, 'rebuild must succeed on v5-shaped data')

	local stats = IterNavShim.stats(nav)
	check(stats ~= nil, 'stats must be stored on the nav object')
	check_equal(stats.rooms, 4, 'room count')
	check_equal(stats.room_doors, 1, 'door count (invalid quad door skipped)')
	check_equal(stats.doors_skipped, 1, 'skipped door count')
	check_equal(stats.vis_groups, 3, 'visibility group count')
	check_equal(stats.segments, 2, 'segment count')
	check_equal(stats.groups_without_seg, 0, 'every vis group owned by a segment')
	check_equal(stats.fallback, 0, 'fallback flag')

	check(nav._rooms ~= load_data.quad_borders_x_pos, 'rooms must be a fresh table')
	check(nav._room_doors ~= nil and nav._visibility_groups ~= nil, 'all three tables built')

	-- x/y scaled by grid size, z and heights untouched.
	check_equal(nav._rooms[1].borders.x_pos, 150, 'border x_pos scaling')
	check_equal(nav._rooms[1].borders.x_neg, -150, 'border x_neg scaling')
	check_equal(nav._rooms[1].borders.y_pos, 100, 'border y_pos scaling')
	check_equal(nav._rooms[1].borders.y_neg, -100, 'border y_neg scaling')
	check_equal(nav._rooms[1].height.xp_yp, 0, 'height xp_yp unscaled')
	check_equal(nav._rooms[1].height.xp_yn, 10, 'height xp_yn unscaled')
	check_equal(nav._rooms[1].height.xn_yp, 20, 'height xn_yp unscaled')
	check_equal(nav._rooms[1].height.xn_yn, 30, 'height xn_yn unscaled')

	local door = nav._room_doors[1]
	check_equal(door.pos.x, 150, 'door low x scaling')
	check_equal(door.pos.y, -100, 'door low y scaling')
	check_equal(door.pos.z, 0.25, 'door low z unscaled')
	check_equal(door.pos1.x, 150, 'door high x scaling')
	check_equal(door.pos1.y, 100, 'door high y scaling')
	check_equal(door.pos1.z, 0.25, 'door high z unscaled')
	check_equal(door.rooms[1], 2, 'door low quad')
	check_equal(door.rooms[2], 3, 'door high quad')

	-- r200 gameplay shape: itr_get_door_in_alignment reads .center.
	check(door.center ~= nil, 'door center built')
	check_equal(door.center.x, 150, 'door center x is the midpoint')
	check_equal(door.center.y, 0, 'door center y is the midpoint')
	check_equal(door.center.z, 0.25, 'door center z is the midpoint')
	check(door.center ~= door.pos and door.center ~= door.pos1, 'center is a fresh Vector3')

	-- Vectors are copies, not aliases of the load data.
	check(door.pos ~= load_data.door_low_pos[1], 'door pos must be a copy')
	check(door.pos1 ~= load_data.door_high_pos[1], 'door pos1 must be a copy')
	check(nav._visibility_groups[1].pos ~= load_data.visibility_groups[1].pos, 'vis group pos must be a copy')

	-- Mutating the rebuilt data must not touch the fixture.
	door.pos.x = -1
	check_equal(load_data.door_low_pos[1].x, 1.5, 'mutating nav door pos must not touch load data')

	-- Mutating the fixture must not touch the rebuilt data.
	load_data.door_low_pos[1].x = 999
	load_data.door_high_pos[1].y = 999
	load_data.visibility_groups[1].pos.x = 999
	check_equal(door.pos.x, -1, 'fixture mutation must not reach rebuilt door pos')
	check_equal(door.pos1.y, 100, 'fixture mutation must not reach rebuilt door pos1')
	check_equal(nav._visibility_groups[1].pos.x, 0.5, 'fixture mutation must not reach vis group pos')

	-- Quad -> vis group map and vis group -> segment map (string ids).
	check_equal(nav._rooms[1].vis_group, 1, 'quad 1 vis group')
	check_equal(nav._rooms[2].vis_group, 1, 'quad 2 vis group')
	check_equal(nav._rooms[3].vis_group, 2, 'quad 3 vis group')
	check_equal(nav._rooms[4].vis_group, 3, 'quad 4 vis group')
	check_equal(nav._visibility_groups[1].seg, '1', 'vis group 1 segment is a string id')
	check_equal(nav._visibility_groups[2].seg, '1', 'vis group 2 segment is a string id')
	check_equal(nav._visibility_groups[3].seg, '2', 'vis group 3 segment is a string id')

	-- v5/r200 map shapes the ported code expects.
	check(nav._visibility_groups[1].rooms[2] == true, 'vis group rooms map')
	check(nav._visibility_groups[1].visible_groups[2] == true, 'vis group visible map')
	check(nav._visibility_groups[1].vis_groups[2] == true, 'vis group vis_groups alias')
	check(nav._visibility_groups[1].vis_groups == nav._visibility_groups[1].visible_groups, 'alias shares one table')
	check(nav._visibility_groups[1].visible_groups[1] == nil, 'vis group does not list itself')
	check_equal(#nav._visibility_groups[1].quads, 2, 'vis group quad list')

	-- One navdata event, no fallback.
	local navdata = find_event('navdata')
	check(navdata ~= nil, 'navdata event emitted')
	check_equal(navdata.fields.rooms, 4, 'navdata rooms field')
	check_equal(navdata.fields.room_doors, 1, 'navdata room_doors field')
	check_equal(navdata.fields.vis_groups, 3, 'navdata vis_groups field')
	check_equal(count_events('navdata'), 1, 'exactly one navdata event')
	check_equal(count_events('fallback'), 0, 'no fallback event')
	check(counters.fallback == nil, 'fallback counter untouched')
end

function tests.vanilla_accessor_uses_shim()
	reset_events()

	local nav = make_nav(100)
	check(IterNavShim.rebuild(nav, make_load_data()) == true, 'rebuild before accessor test')
	check_equal(nav:get_nav_seg_from_i_room(1), '1', 'vanilla accessor on quad 1')
	check_equal(nav:get_nav_seg_from_i_room(3), '1', 'vanilla accessor on quad 3')
	check_equal(nav:get_nav_seg_from_i_room(4), '2', 'vanilla accessor on quad 4')
end

function tests.respects_grid_size()
	reset_events()

	local nav = make_nav(50)
	check(IterNavShim.rebuild(nav, make_load_data()) == true, 'rebuild with grid_size 50')
	check_equal(nav._rooms[1].borders.x_pos, 75, 'border scaled by grid_size 50')
	check_equal(nav._room_doors[1].pos.x, 75, 'door scaled by grid_size 50')
	check_equal(nav._room_doors[1].pos.z, 0.25, 'door z still unscaled')
	check_equal(nav._room_doors[1].center.x, 75, 'door center scaled by grid_size 50')
	check_equal(IterNavShim.stats(nav).grid, 50, 'grid reported in stats')
end

function tests.accepts_numeric_string_keys()
	reset_events()

	-- ScriptSerializer may round-trip integer keys as numeric strings.
	local data = make_load_data()
	data.visibility_groups[1].quads = { '1', '2' }
	data.visibility_groups[2].quads = { '3' }
	data.visibility_groups[3].quads = { '4' }
	data.door_low_quads = { '2', '99' }
	data.door_high_quads = { '3', '99' }
	data.segments[1].vis_groups = { '1', '2' }
	data.segments[2].vis_groups = { '3' }

	local nav = make_nav(100)
	check(IterNavShim.rebuild(nav, data) == true, 'numeric string keys accepted')
	check_equal(nav._rooms[3].vis_group, 2, 'quad 3 vis group from string key')
	check_equal(nav._visibility_groups[1].seg, '1', 'vis group 1 segment from string key')
	check_equal(IterNavShim.stats(nav).room_doors, 1, 'door from string quad key')
	check_equal(nav._room_doors[1].rooms[1], 2, 'door low quad is numeric')
end

function tests.unowned_vis_group_and_missing_pos()
	reset_events()

	local data = make_load_data()
	-- Fourth group: no owner segment, no pos, no quads.
	data.visibility_groups[4] = {
		visible_groups = {}
	}

	local nav = make_nav(100)
	check(IterNavShim.rebuild(nav, data) == true, 'rebuild with an unowned vis group')

	local stats = IterNavShim.stats(nav)
	check_equal(stats.vis_groups, 4, 'vis group count includes the unowned group')
	check_equal(stats.groups_without_seg, 1, 'groups_without_seg counts the unowned group')

	local orphan = nav._visibility_groups[4]
	check_equal(orphan.seg, nil, 'unowned vis group has no segment')
	check(orphan.pos ~= nil, 'missing pos defaults to a vector')
	check_equal(orphan.pos.x, 0, 'default pos x')
	check_equal(orphan.pos.y, 0, 'default pos y')
	check_equal(orphan.pos.z, 0, 'default pos z')
	check_equal(#orphan.quads, 0, 'unowned vis group has no quads')
end

function tests.clear_resets()
	reset_events()

	local nav = make_nav(100)
	check(IterNavShim.rebuild(nav, make_load_data()) == true, 'rebuild before clear')
	IterNavShim.clear(nav)

	check(nav._rooms ~= nil and next(nav._rooms) == nil, 'rooms cleared')
	check(nav._room_doors ~= nil and next(nav._room_doors) == nil, 'room doors cleared')
	check(nav._visibility_groups ~= nil and next(nav._visibility_groups) == nil, 'vis groups cleared')
	check(IterNavShim.stats(nav) == nil, 'stats cleared')
end

function tests.rejects_v6_only_data()
	reset_events()

	local nav = make_nav(100)
	check(IterNavShim.rebuild(nav, make_load_data()) == true, 'seed tables before fallback')
	check_equal(#nav._rooms, 4, 'seed rooms present')

	-- Native v6 data carries no v5 quad arrays. It arrives outside a level
	-- load (delete_nav_segment, build_complete_clbk), so keep the geometry.
	local v6_only = {
		version = 6,
		segments = {
			{
				id = 1,
				pos = { x = 0, y = 0, z = 0 },
				vis_groups = { 1 }
			}
		}
	}

	check(IterNavShim.rebuild(nav, v6_only) == false, 'v6-only data must be rejected')

	local stats = IterNavShim.stats(nav)
	check(stats ~= nil, 'fallback stats stored')
	check_equal(stats.fallback, 1, 'fallback flag set')
	check_equal(stats.reason, 'v6_only_data', 'fallback reason')
	check_equal(stats.rooms, 4, 'kept stats report the existing rooms')
	check_equal(#nav._rooms, 4, 'v6-only payload keeps the built rooms')
	check_equal(#nav._room_doors, 1, 'v6-only payload keeps the built doors')
	check_equal(#nav._visibility_groups, 3, 'v6-only payload keeps the built vis groups')
	check_equal(nav:get_nav_seg_from_i_room(4), '2', 'accessor still works after v6-only payload')

	local fallback = find_event('fallback')
	check(fallback ~= nil, 'fallback event emitted')
	check_equal(fallback.fields.subsystem, 'shim', 'fallback subsystem field')
	check_equal(fallback.fields.reason, 'v6_only_data', 'fallback reason field')
	check_equal(fallback.fields.msg, nil, 'v6-only fallback carries no error message')
	check_equal(count_events('fallback'), 1, 'exactly one fallback event')
	check_equal(counters.fallback, 1, 'fallback counter incremented')
end

function tests.rejects_missing_pieces()
	reset_events()

	local nav = make_nav(100)
	check(IterNavShim.rebuild(nav, make_load_data()) == true, 'seed tables before failures')

	check(IterNavShim.rebuild(nav, nil) == false, 'nil load data rejected')
	check_equal(IterNavShim.stats(nav).reason, 'no_load_data', 'nil load data reason')
	check(next(nav._rooms) == nil, 'nil load data drops stale rooms')

	check(IterNavShim.rebuild(nav, { version = 6, segments = {} }) == false, 'empty segments rejected')
	check_equal(IterNavShim.stats(nav).reason, 'no_segments', 'empty segments reason')

	local no_groups = make_load_data()
	no_groups.visibility_groups = {}
	check(IterNavShim.rebuild(nav, no_groups) == false, 'empty visibility groups rejected')
	check_equal(IterNavShim.stats(nav).reason, 'no_vis_groups', 'empty visibility groups reason')

	-- The post-converter data only has *_quads; the v5 *_rooms names are not
	-- accepted as aliases.
	local no_doors = make_load_data()
	no_doors.door_low_rooms = no_doors.door_low_quads
	no_doors.door_high_rooms = no_doors.door_high_quads
	no_doors.door_low_quads = nil
	no_doors.door_high_quads = nil
	check(IterNavShim.rebuild(nav, no_doors) == false, 'missing door quads rejected')
	check_equal(IterNavShim.stats(nav).reason, 'no_door_quads', 'missing door quads reason')
	check(next(nav._room_doors) == nil, 'missing door quads drops stale doors')

	local no_grid = make_nav(nil)
	no_grid._grid_size = nil
	check(IterNavShim.rebuild(no_grid, make_load_data()) == false, 'nil grid size rejected')
	check_equal(IterNavShim.stats(no_grid).reason, 'no_grid_size', 'nil grid size reason')
	check(next(no_grid._rooms) == nil, 'nil grid size builds nothing')

	local zero_grid = make_nav(0)
	check(IterNavShim.rebuild(zero_grid, make_load_data()) == false, 'zero grid size rejected')
	check_equal(IterNavShim.stats(zero_grid).reason, 'no_grid_size', 'zero grid size reason')

	check_equal(counters.fallback, 6, 'one fallback per rejected build')
end

function tests.rebuild_error_is_one_fallback()
	reset_events()

	local nav = make_nav(100)
	check(IterNavShim.rebuild(nav, make_load_data()) == true, 'seed tables before rebuild error')

	-- Any error inside build() is caught by the single pcall boundary.
	local broken = make_load_data()
	broken.quad_heights_xp_yp = setmetatable({}, {
		__index = function()
			error('heights boom')
		end
	})

	check(IterNavShim.rebuild(nav, broken) == false, 'throwing build returns false')

	local stats = IterNavShim.stats(nav)
	check_equal(stats.reason, 'rebuild_error', 'rebuild error reason')
	check_equal(stats.fallback, 1, 'rebuild error fallback flag')
	check(next(nav._rooms) == nil, 'corrupt data drops stale rooms')

	check_equal(count_events('fallback'), 1, 'exactly one fallback line')
	check_equal(count_events('err'), 0, 'no separate err event')

	local fallback = find_event('fallback')
	check_equal(fallback.fields.reason, 'rebuild_error', 'fallback line reason field')
	check(fallback.fields.msg ~= nil, 'fallback line carries the short error')
	check(tostring(fallback.fields.msg):find('heights boom', 1, true) ~= nil, 'fallback msg names the error')
	check_equal(counters.fallback, 1, 'one fallback counted')
end

function tests.survives_bad_optional_data()
	reset_events()

	local nav = make_nav(100)
	local broken = make_load_data()
	broken.visibility_groups[1].quads = 'not a table'

	local ok = IterNavShim.rebuild(nav, broken)
	check(ok == true, 'malformed optional lists degrade instead of raising')
	check_equal(IterNavShim.stats(nav).vis_groups, 3, 'vis groups still built')
	check_equal(IterNavShim.stats(nav).fallback, 0, 'no fallback for optional data')
	check_equal(find_event('err'), nil, 'no internal error logged')
end

local function main()
	local names = {}

	for name in pairs(tests) do
		names[#names + 1] = name
	end

	table.sort(names)

	for _, name in ipairs(names) do
		local ok, err = pcall(tests[name])

		if not ok then
			io.stderr:write(string.format('FAIL %s: %s\n', name, tostring(err)))
			os.exit(1)
		end

		io.write('ok ' .. name .. '\n')
	end

	io.write(string.format('%d checks, %d tests passed\n', checks, #names))
end

local ok, err = pcall(main)

if not ok then
	io.stderr:write('FAIL: ' .. tostring(err) .. '\n')
	os.exit(1)
end
