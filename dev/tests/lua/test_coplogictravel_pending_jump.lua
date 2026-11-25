-- Offline unit test for the pending coarse-path jump clamp in
-- lua/coplogictravel.lua (itr_clamp_pending_jump). Runs on bare LuaJIT, no
-- game/engine:
--   tools\luajit\luajit.exe dev\tests\lua\test_coplogictravel_pending_jump.lua
--
-- Regression: CopLogicTravel._chk_stop_for_follow_unit truncates
-- my_data.coarse_path while a walk to a farther going_to_index is in flight, and
-- itr_simplify_coarse_path can shrink the path too. Neither updated
-- going_to_index, so LIES' travel logic could set coarse_path_index past the new
-- end on walk completion (over-range index, crash).

local script_path = (arg and arg[0]) or 'dev/tests/lua/test_coplogictravel_pending_jump.lua'
local test_dir = script_path:match('^(.*)[/\\][^/\\]+$') or '.'

local function resolve(relative)
	local candidates = {
		relative,
		test_dir .. '/../../../' .. relative
	}

	for _, candidate in ipairs(candidates) do
		local handle = io.open(candidate, 'r')

		if handle then
			handle:close()
			return candidate
		end
	end

	error('cannot locate ' .. relative .. ' from ' .. script_path)
end

local function vector3(x, y, z)
	return {
		x = x or 0,
		y = y or 0,
		z = z or 0
	}
end

local function noop() end

ModPath = 'mods/Iter/'
RequiredScript = 'lib/units/logics/coplogictravel'

mvector3 = {
	copy = function(v, dst)
		if dst then
			dst.x, dst.y, dst.z = v.x, v.y, v.z

			return dst
		end

		return { x = v.x, y = v.y, z = v.z }
	end
}

deep_clone = function(value)
	if type(value) ~= 'table' then
		return value
	end

	local copy = {}

	for k, v in pairs(value) do
		copy[k] = deep_clone(v)
	end

	return copy
end

alive = function(unit)
	return unit ~= nil and unit._alive ~= false
end

Iter = {
	settings = {
		nav_overlay = true,
		nav_ai = true,
		nav_streamline = true,
		direct_to_pos = true,
		path_extender = true
	},
	diag = {
		event = noop,
		count = noop,
		err = noop
	}
}

-- DelayedCalls callbacks are not run: load order only, nothing under test.
DelayedCalls = {
	Add = noop
}

CopLogicTravel = {
	enter = noop,
	_upd_pathing = noop,
	_get_exact_move_pos = noop,
	_get_allowed_travel_nav_segs = noop,
	action_complete_clbk = noop,
	upd_advance = noop,
	_begin_coarse_pathing = noop,
	_chk_request_action_walk_to_advance_pos = noop,
	_get_pos_on_wall = function(pos) return pos end
}

local nav = {
	searches = 0
}

managers = {
	navigation = nav,
	groupai = {
		state = function()
			return {
				add_listener = noop
			}
		end
	}
}

dofile(resolve('lua/coplogictravel.lua'))

local checks = 0

local function check(condition, label)
	checks = checks + 1

	if not condition then
		error('check failed: ' .. label, 2)
	end
end

local function path_entry(seg, pos)
	return { seg, pos or vector3(seg, 0, 0) }
end

local function make_unit(nav_seg)
	return {
		anim_data = function() return {} end,
		movement = function()
			return {
				chk_action_forbidden = function() return false end,
				nav_tracker = function()
					return {
						nav_segment = function() return nav_seg end
					}
				end
			}
		end
	}
end

-- 1. _chk_stop_for_follow_unit truncation: the path is cut to
--    coarse_path_index + 1, so a pending jump to 5 must land on 2.
local function follow_case(going_to_index)
	local coarse_path = {
		path_entry(1),
		path_entry(2),
		path_entry(3),
		path_entry(4),
		path_entry(5)
	}
	local my_data = {
		coarse_path = coarse_path,
		coarse_path_index = 1,
		going_to_index = going_to_index
	}
	local follow_unit = {
		_alive = true,
		position = function() return vector3(50, 0, 0) end,
		movement = function()
			return {
				nav_tracker = function()
					return {
						nav_segment = function() return 7 end
					}
				end
			}
		end
	}
	local data = {
		objective = {
			type = 'follow',
			follow_unit = follow_unit
		},
		unit = make_unit(7),
		pos_rsrv_id = 1,
		logic = {
			on_new_objective = noop
		}
	}

	nav.find_cover_in_nav_seg_1 = function() return nil end
	nav.find_random_position_in_segment = function() return vector3(60, 0, 0) end

	CopLogicTravel._chk_stop_for_follow_unit(data, my_data)

	return my_data
end

local truncated = follow_case(5)
check(#truncated.coarse_path == 2, 'the follow-unit truncation keeps index + 1 entries')
check(truncated.going_to_index == 2, 'the pending jump is clamped to the new end (2)')
check(truncated.going_to_index ~= #truncated.coarse_path - 1, 'the clamp is not a minus-one offset')

-- 2. A pending jump inside the new end is left alone.
local untouched = follow_case(1)
check(#untouched.coarse_path == 2, 'the truncating branch still runs')
check(untouched.going_to_index == 1, 'an in-range pending jump is not moved')

-- 3. itr_simplify_coarse_path: the neighbour shortcut drops an entry and the
--    streamlined path stays short, so a pending jump to 4 must land on 2.
local simplify_data = {
	SO_access = { 'walk' },
	brain = {
		_SO_access = { 'walk' },
		cancel_all_pathing_searches = noop
	}
}
local simplify_my_data = {
	coarse_path = {
		path_entry(1),
		path_entry(2),
		path_entry(3),
		path_entry(4)
	},
	coarse_path_index = 1,
	going_to_index = 4
}

nav.get_nav_seg_neighbours = function(self, seg)
	return {
		[3] = {}
	}
end
nav.itr_get_accessibility = function() return 0 end
nav.itr_streamline = function() return true end

local changed = CopLogicTravel.itr_simplify_coarse_path(simplify_data, simplify_my_data)

check(changed == true, 'the simplify pass reports a shorter path')
check(#simplify_my_data.coarse_path == 2, 'the simplify pass leaves two entries')
check(simplify_my_data.going_to_index == 2, 'the pending jump is clamped to the simplified end')
check(simplify_my_data.going_to_index ~= #simplify_my_data.coarse_path - 1, 'the clamp is not a minus-one offset')

-- 4. No truncation: an in-range pending jump is untouched and the pass reports
--    no change.
local stable_data = {
	SO_access = { 'walk' },
	brain = {
		_SO_access = { 'walk' },
		cancel_all_pathing_searches = noop
	}
}
local stable_my_data = {
	coarse_path = {
		path_entry(1),
		path_entry(2),
		path_entry(3),
		path_entry(4)
	},
	coarse_path_index = 1,
	going_to_index = 4
}

nav.get_nav_seg_neighbours = function(self, seg)
	return {}
end

local stable_changed = CopLogicTravel.itr_simplify_coarse_path(stable_data, stable_my_data)

check(stable_changed == false, 'a path the simplifier cannot shorten reports no change')
check(#stable_my_data.coarse_path == 4, 'the path keeps its length')
check(stable_my_data.going_to_index == 4, 'an in-range pending jump is not moved')

io.write(string.format('ok: pending coarse-path jump clamp (%d checks)\n', checks))
