-- Offline unit test for the trailing-argument forward in lua/copbrain.lua
-- (CopBrain:clbk_pathing_results). Runs on bare LuaJIT, no game/engine:
--   tools\luajit\luajit.exe dev\tests\lua\test_copbrain_pathing_forward.lua
--
-- Regression: LIES (8.57.36) copies the callback as
-- `clbk_pathing_results(search_id, path, do_not_cache)`. Iter 205.4 declared the
-- wrapper with two parameters and forwarded only those, so the third argument
-- was dropped before the original callback ran. Nothing pins that today except
-- this test.

local script_path = (arg and arg[0]) or 'dev/tests/lua/test_copbrain_pathing_forward.lua'
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

-- path_extender must be on: that is the gate around the wrapper under test.
-- nav_ai keeps the streamline-only early return (lua/copbrain.lua:18) out of
-- the way, so the path_extender branch is the one that loads.
Iter = {
	settings = {
		nav_overlay = true,
		nav_ai = true,
		nav_streamline = true,
		nav_search = false,
		direct_to_pos = false,
		path_extender = true
	},
	diag = {
		event = noop,
		count = noop,
		err = noop
	}
}

-- The original callback records what the wrapper hands it. `...` is captured
-- with select('#', ...) so a dropped or added argument shows up as a count
-- mismatch, not just as a wrong value.
local forward = {
	calls = 0,
	vararg_count = nil,
	vararg1 = nil,
	search_id = nil,
	path = nil
}

CopBrain = {
	clbk_pathing_results = function(self, search_id, path, ...)
		forward.calls = forward.calls + 1
		forward.vararg_count = select('#', ...)
		forward.vararg1 = (select(1, ...))
		forward.search_id = search_id
		forward.path = path
	end,
	clbk_coarse_pathing_results = noop
}

managers = {
	navigation = {
		_coarse_searches = {},
		itr_streamline = function(self, path, access) return path end,
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

alive = function(unit)
	return unit ~= nil and unit._alive ~= false
end

-- Captured before the module load: the assertion below is what keeps this test
-- from passing vacuously. The stub is variadic too, so a stubbed call with three
-- arguments also reports one vararg - only the identity check proves that
-- lua/copbrain.lua actually replaced the callback with its wrapper.
local original = CopBrain.clbk_pathing_results

dofile(resolve('lua/copbrain.lua'))

assert(
	CopBrain.clbk_pathing_results ~= original,
	'path_extender wrapper must be installed'
)

-- `self = {}` has no `_logic_data`, so the wrapper runs the original and then
-- hits its logic-switch guard and returns - no further engine stubs needed.
-- Dot call on purpose: the receiver is an explicit empty table, not CopBrain.
local unit = {}
local path_two = { { 10 }, { 11, vector3(1, 2, 3) } }

CopBrain.clbk_pathing_results(unit, 'forward_two', path_two)

assert(forward.calls == 1, 'the original must run once per wrapper call')
assert(forward.vararg_count == 0, 'a two-argument call must forward no varargs')
assert(forward.vararg1 == nil, 'a two-argument call must forward no value')
assert(forward.search_id == 'forward_two', 'the search id must pass through unchanged')
assert(forward.path == path_two, 'the path table must pass through by reference')

local path_three = { { 20 }, { 21, vector3(4, 5, 6) } }
local calls_before = forward.calls

CopBrain.clbk_pathing_results(unit, 'forward_three', path_three, true)

assert(forward.calls == calls_before + 1, 'the original must run once per wrapper call')
assert(forward.vararg_count == 1, 'a three-argument call must forward exactly one vararg')
assert(forward.vararg1 == true, 'the trailing flag must arrive unchanged')
assert(forward.search_id == 'forward_three', 'the search id must pass through unchanged')
assert(forward.path == path_three, 'the path table must pass through by reference')

io.write('ok: CopBrain:clbk_pathing_results forwards the trailing argument\n')
