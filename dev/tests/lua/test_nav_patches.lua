-- Offline test for the P7 per-call map-patch wrapper.
-- Run: tools\luajit\luajit.exe dev\tests\lua\test_nav_patches.lua

local checks = 0
local events = {}

local function check(condition, message)
	if not condition then
		error(message, 2)
	end
	checks = checks + 1
end

local function find_event(name)
	for i = #events, 1, -1 do
		if events[i].name == name then
			return events[i]
		end
	end
end

Iter = {
	settings = {
		map_patches = true,
		map_change_unknown = true,
		map_change_jewelry_store = true,
		map_change_skm_mallcrasher = true,
		debug_log = 1
	},
	diag = {
		event = function(name, fields)
			events[#events + 1] = { name = name, fields = fields or {} }
		end,
		err = function(where, message)
			events[#events + 1] = { name = 'err', fields = { where = where, msg = message } }
		end,
		count = function() end
	}
}

local current_level = 'unknown'

function Iter:get_level_id()
	return current_level
end

Vector3 = function(x, y, z)
	return { x = x or 0, y = y or 0, z = z or 0 }
end

mvector3 = {
	add = function() end,
	copy = function(v) return v end,
	set_x = function() end,
	set_y = function() end,
	x = function(v) return v.x end,
	y = function(v) return v.y end,
	z = function(v) return v.z end
}

math.min_max = function(a, b)
	return math.min(a, b), math.max(a, b)
end

local vanilla_calls = 0

NavigationManager = {
	set_load_data = function(self, data)
		vanilla_calls = vanilla_calls + 1
		return 'vanilla'
	end
}

Hooks = {
	PostHook = function() end
}

dofile('lua/_navdatapatches.lua')

check(type(NavigationManager.set_load_data) == 'function', 'wrapper installed')
check(NavigationManager.set_load_data ~= nil, 'wrapper differs from vanilla')

-- map_patches off: the wrapper is installed but the per-call gate must call
-- vanilla and emit no patch event.
Iter.settings.map_patches = false
current_level = 'jewelry_store'
vanilla_calls = 0
events = {}
NavigationManager.set_load_data(nav, { version = 5, door_low_rooms = {} })
check(vanilla_calls == 1, 'map_patches off calls vanilla once')
check(#events == 0, 'map_patches off emits no patch event')
Iter.settings.map_patches = true

-- v6 data: skip and call vanilla.
vanilla_calls = 0
events = {}
local nav = {}
check(NavigationManager.set_load_data(nav, { version = 6 }) == 'vanilla', 'v6 returns vanilla result')
check(vanilla_calls == 1, 'v6 calls vanilla once')
check(find_event('patch').fields.result == 'skip_version', 'v6 logs skip_version')

-- v5 data, level has no patch: skip_nopatch.
current_level = 'unknown'
vanilla_calls = 0
events = {}
check(NavigationManager.set_load_data(nav, { version = 5, door_low_rooms = {} }) == 'vanilla', 'no-patch returns vanilla')
check(vanilla_calls == 1, 'no-patch calls vanilla once')
check(find_event('patch').fields.result == 'skip_nopatch', 'no-patch logs skip_nopatch')

-- v5 data, setting off: skip_setting.
current_level = 'unknown'
Iter.settings.map_change_unknown = false
vanilla_calls = 0
events = {}
NavigationManager.set_load_data(nav, { version = 5, door_low_rooms = {} })
check(vanilla_calls == 1, 'disabled map calls vanilla once')
check(find_event('patch').fields.result == 'skip_setting', 'disabled map logs skip_setting')
Iter.settings.map_change_unknown = true

-- Skirmish Mallcrasher: dead at v6 (navlink seal has no data expression).
current_level = 'skm_mallcrasher'
Iter.settings.map_change_skm_mallcrasher = true
vanilla_calls = 0
events = {}
NavigationManager.set_load_data(nav, { version = 5, door_low_rooms = {} })
check(vanilla_calls == 1, 'skm_mallcrasher calls vanilla once')
check(find_event('patch').fields.result == 'skip_dead', 'skm_mallcrasher logs skip_dead')
check(find_event('patch').fields.level == 'skm_mallcrasher', 'skm_mallcrasher logs its own level id')

-- v5 data, level with a patch but CRC data mismatch: mismatch and vanilla.
current_level = 'jewelry_store'
vanilla_calls = 0
events = {}
local mismatch_data = {
	version = 5,
	door_low_rooms = {},
	door_high_rooms = {},
	room_borders_x_neg = {},
	room_borders_x_pos = {},
	room_borders_y_neg = {},
	room_borders_y_pos = {},
	room_heights_xn_yn = {},
	room_heights_xn_yp = {},
	room_heights_xp_yn = {},
	room_heights_xp_yp = {},
	room_vis_groups = {}
}
NavigationManager.set_load_data(nav, mismatch_data)
check(vanilla_calls == 1, 'mismatch calls vanilla once')
check(find_event('patch').fields.result == 'mismatch', 'mismatch logged')

print(string.format('%d checks, P7 wrapper test passed', checks))
