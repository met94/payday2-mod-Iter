-- Offline unit test for the follow-unit guard in lua/copbrain.lua
-- (CopBrain:clbk_coarse_pathing_results) and the matching guard in lua/drill.lua.
-- Runs on bare LuaJIT, no game/engine:
--   tools\luajit\luajit.exe dev\tests\lua\test_copbrain_follow_unit.lua
--
-- Regression: a queued coarse search can land after the followed unit was
-- destroyed. Before the guard, `objective.follow_unit:position()` on the freed
-- unit was an engine access violation (crash 2026-11-01 12:39:26, heist `auc`).

local script_path = (arg and arg[0]) or 'dev/tests/lua/test_copbrain_follow_unit.lua'
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

Vector3 = vector3
ModPath = 'mods/Iter/'
RequiredScript = 'lib/units/enemies/cop/copbrain'

mvector3 = {
	angle = function() return 0 end,
	length = function() return 3 end,
	set = function(dst, src) return src end,
	subtract = function() return vector3() end
}

Iter = {
	settings = {
		nav_overlay = true,
		nav_ai = true,
		nav_streamline = true,
		nav_search = true,
		direct_to_pos = false,
		path_extender = false
	},
	diag = {
		event = noop,
		count = noop,
		err = noop
	}
}

CopBrain = {
	clbk_coarse_pathing_results = function(self, search_id, path)
		raw_callback_calls = (raw_callback_calls or 0) + 1
	end,
	clbk_pathing_results = noop
}

raw_callback_calls = 0

local streamline_calls = 0

managers = {
	navigation = {
		_coarse_searches = {},
		itr_streamline = function(self, path, access)
			streamline_calls = streamline_calls + 1

			return path
		end,
		search_coarse = noop
	},
	groupai = {
		state = function()
			return {
				whisper_mode = function() return false end
			}
		end
	}
}

-- Engine liveness test: a destroyed unit reports false.
alive = function(unit)
	return unit ~= nil and unit._alive ~= false
end

dofile(resolve('lua/copbrain.lua'))

local checks = 0

local function check(condition, label)
	checks = checks + 1

	if not condition then
		error('check failed: ' .. label, 2)
	end
end

local function make_path()
	return {
		{ 10 },
		{ 11, vector3(1, 2, 3) },
		{ 12, vector3(4, 5, 6) }
	}
end

local function make_data(follow_unit)
	return {
		m_pos = vector3(7, 8, 9),
		internal_data = {},
		objective = follow_unit ~= nil and { follow_unit = follow_unit } or nil
	}
end

local function call_callback(data, path)
	path = path or make_path()

	CopBrain.clbk_coarse_pathing_results({
		_logic_data = data,
		_SO_access = {}
	}, 'follow_test', path)

	return path
end

-- 1. A destroyed follow unit must not be dereferenced.
local path_before
local freed = { _alive = false, position = function() error('freed unit dereferenced') end }
local data = make_data(freed)
local path = make_path()
path_before = path[#path][2]

local ok, err = pcall(function()
	return CopBrain.clbk_coarse_pathing_results({
		_logic_data = data,
		_SO_access = {}
	}, 'follow_test', path)
end)
check(ok, 'dead follow unit must not raise: ' .. tostring(err))
check(path[#path][2] == path_before, 'dead follow unit must not rewrite the path endpoint')
check(path[1][2] == data.m_pos, 'the start position is still rewritten')
check(raw_callback_calls == 1, 'the original callback still runs once')
checks = checks + 1

-- 2. A live follow unit still gets the streamline endpoint.
local live_pos = vector3(100, 200, 300)
local live = { _alive = true, position = function() return live_pos end }
raw_callback_calls = 0
streamline_calls = 0

local live_path = call_callback(make_data(live))

check(live_path[#live_path][2] == live_pos, 'live follow unit sets the streamline endpoint')
check(streamline_calls >= 1, 'the streamliner runs')
check(raw_callback_calls == 1, 'the original callback runs once for the live case')
checks = checks + 1

-- 3. No objective: path still streamlined, endpoint untouched.
local plain_path = make_path()
local plain_before = plain_path[#plain_path][2]
raw_callback_calls = 0

call_callback({ m_pos = vector3(1, 1, 1), internal_data = {} }, plain_path)

check(plain_path[#plain_path][2] == plain_before, 'no objective leaves the endpoint untouched')
check(raw_callback_calls == 1, 'the original callback runs once without an objective')
checks = checks + 1

-- 4. The same guard exists on the drill interaction path (source scan: the
--    function needs heavy engine stubs, so pin the text instead).
local drill_source = io.open(resolve('lua/drill.lua'), 'r')
check(drill_source ~= nil, 'drill.lua readable')
local drill_text = drill_source:read('*a')
drill_source:close()

check(
	drill_text:find('if not alive%(receiver_unit%) then', 1) ~= nil,
	'drill on_investigate_SO_administered guards a destroyed receiver'
)
checks = checks + 1

io.write(string.format('ok: copbrain follow-unit guard (%d checks)\n', checks))
