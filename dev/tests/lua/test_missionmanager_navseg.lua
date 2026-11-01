-- Offline unit test for the string nav segment keys in lua/missionmanager.lua
-- (ElementAINavSeg:on_executed), adopted from upstream Iter r201.
-- Runs on bare LuaJIT, no game/engine:
--   tools\luajit\luajit.exe dev\tests\lua\test_missionmanager_navseg.lua
--
-- 248.2 keys `NavigationManager._nav_segments` by `tostring(id)`
-- (lib/managers/navigationmanager.lua:312,322), so the numeric segment ids that
-- Iter's own mission elements carry (`add_nav_seg_neighbours` for
-- firestarter_3/branchbank, `remove_nav_seg_neighbours` for level `friend`)
-- never resolved: clbk_navfield found no segment and, with the nil guard in
-- place, the element was a silent no-op.

local script_path = (arg and arg[0]) or 'dev/tests/lua/test_missionmanager_navseg.lua'
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

local function noop() end

-- PD2 class(): instances inherit the class table, `super` is the base.
function class(base)
	local cls = {}

	cls.super = base
	cls.__index = cls

	return setmetatable(cls, {
		__index = base
	})
end

CoreMissionScriptElement = {
	MissionScriptElement = {
		on_executed = noop
	}
}

ElementUnloadStatic = {
	on_executed = noop
}

local calls = {}

managers = {
	navigation = {
		clbk_navfield = function(self, operation, args)
			calls[#calls + 1] = {
				operation = operation,
				args = args
			}
		end
	},
	vehicle = {
		on_simulation_started = noop
	},
	worlddefinition = {
		get_unit_on_load = noop
	}
}

function callback() return noop end
function alive() return true end

ModPath = 'mods/Iter/'
RequiredScript = 'lib/managers/missionmanager'

dofile(resolve('lua/missionmanager.lua'))

local checks = 0

local function check(condition, label)
	checks = checks + 1

	if not condition then
		error('check failed: ' .. label, 2)
	end
end

local function execute(operation, segment_ids)
	calls = {}

	local element = setmetatable({
		_values = {
			enabled = true,
			operation = operation,
			segment_ids = segment_ids
		}
	}, ElementAINavSeg)

	element:on_executed(nil)

	return calls
end

-- 1. add_nav_seg_neighbours: every key and value must be a string id.
local added = execute('add_nav_seg_neighbours', { 92, 55, 55, 92 })

check(#added == 2, 'one clbk_navfield call per pair, got ' .. #added)
check(added[1].operation == 'add_nav_seg_neighbours', 'operation is forwarded unchanged')

local first_key, first_list = next(added[1].args)

check(type(first_key) == 'string', 'segment key must be a string, got ' .. type(first_key))
check(first_key == '92', 'segment key must be the id as a string, got ' .. tostring(first_key))
check(type(first_list[1]) == 'string', 'neighbour id must be a string, got ' .. type(first_list[1]))
check(first_list[1] == '55', 'neighbour id must be the id as a string, got ' .. tostring(first_list[1]))

-- 2. remove_nav_seg_neighbours takes the same path (level `friend`).
local removed = execute('remove_nav_seg_neighbours', { 106, 55 })

check(#removed == 1, 'one call for the remove pair')
check(removed[1].operation == 'remove_nav_seg_neighbours', 'remove operation forwarded')

local remove_key = next(removed[1].args)

check(remove_key == '106', 'remove key must be a string, got ' .. tostring(remove_key))

-- 3. A disabled element still does nothing.
calls = {}

local disabled = setmetatable({
	_values = {
		enabled = false,
		operation = 'add_nav_seg_neighbours',
		segment_ids = { 1, 2 }
	}
}, ElementAINavSeg)

disabled:on_executed(nil)

check(#calls == 0, 'a disabled element must not touch the nav field')

print(string.format('%d checks, missionmanager nav-seg key test passed', checks))
