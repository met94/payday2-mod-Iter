-- Offline unit test for the nil-objective contract of
-- CopLogicTravel._chk_stop_for_follow_unit (lua/coplogictravel.lua). Runs on
-- bare LuaJIT, no game/engine:
--   tools\luajit\luajit.exe dev\tests\lua\test_coplogictravel_nil_objective.lua
--
-- Regression: LIES replaces CopLogicTravel.upd_advance and calls
-- _chk_stop_for_follow_unit unconditionally; its own copy returns early when
-- data.objective is nil. Iter replaced that function with a copy that indexes
-- objective.type first, so LIES travel running with no objective (a state
-- vanilla upd_advance tolerates) hard-crashed: job-101601-474 and
-- job-101913-735, `attempt to index local 'objective' (a nil value)`.
-- The replacement must keep the contract of the function it replaces.

local script_path = (arg and arg[0]) or 'dev/tests/lua/test_coplogictravel_nil_objective.lua'
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

local function expect_no_error(label, fn)
	local ok, err = pcall(fn)

	check(ok, label .. (ok and '' or (': ' .. tostring(err))))
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

-- 1. A nil objective returns before touching the unit: this is the state LIES
--    travel can run in, and its own copy of this function guards it.
expect_no_error('nil objective returns without a unit', function()
	CopLogicTravel._chk_stop_for_follow_unit({ objective = nil }, {})
end)

-- 2. Same with a live unit and a coarse path: returns, does not index the path
--    and does not write the follow-unit nav-seg state on the data table.
local my_data = {
	coarse_path = {
		{ 1, vector3(0, 0, 0) },
		{ 2, vector3(1, 0, 0) }
	},
	coarse_path_index = 1
}
local nil_data = {
	objective = nil,
	unit = make_unit(7),
	itr_follow_unit_nav_seg = 42
}

expect_no_error('nil objective with a path returns', function()
	CopLogicTravel._chk_stop_for_follow_unit(nil_data, my_data)
end)
check(my_data.coarse_path_index == 1, 'a nil objective does not advance the path')
check(nil_data.itr_follow_unit_nav_seg == 42, 'a nil objective does not write itr_follow_unit_nav_seg')

-- 3. Non-follow objectives still short-circuit before the unit work.
expect_no_error('non-follow objective returns', function()
	CopLogicTravel._chk_stop_for_follow_unit({ objective = { type = 'defend_area' } }, {})
end)

-- 4. Follow objectives still take the old early return when no path index exists.
local follow_unit = make_unit(7)

expect_no_error('follow objective without a path index returns', function()
	CopLogicTravel._chk_stop_for_follow_unit({
		objective = { type = 'follow', follow_unit = follow_unit },
		unit = make_unit(7)
	}, {})
end)

io.write(string.format('ok: nil-objective travel guard (%d checks)\n', checks))
