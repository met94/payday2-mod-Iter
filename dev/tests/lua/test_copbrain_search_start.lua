-- Offline unit test for the coarse-search start position in lua/copbrain.lua
-- (CopBrain:search_for_coarse_path), adopted from upstream Iter r205.
-- Runs on bare LuaJIT, no game/engine:
--   tools\luajit\luajit.exe dev\tests\lua\test_copbrain_search_start.lua
--
-- `search_coarse` only queues; the search itself may be executed later, and by
-- then another NPC can have queued its own search. Writing `from_pos` on
-- `cs[#cs]` without checking the id therefore stamped *this* NPC's position onto
-- *another* NPC's search, and the other cop started its coarse path from the
-- wrong place.

local script_path = (arg and arg[0]) or 'dev/tests/lua/test_copbrain_search_start.lua'
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
	clbk_coarse_pathing_results = noop,
	clbk_pathing_results = noop
}

function callback() return noop end
function alive(unit) return unit ~= nil and unit._alive ~= false end

-- What `search_coarse` would push: the caller decides the queued id so the test
-- can simulate "another NPC queued after this one".
local queued_id = 'mine'
local queued_searches = {}

managers = {
	navigation = {
		_coarse_searches = queued_searches,
		search_coarse = function(self, params)
			queued_searches[#queued_searches + 1] = {
				id = queued_id,
				to_seg = params.to_seg
			}
		end,
		itr_streamline = function(self, path) return path end
	},
	groupai = {
		state = function()
			return {
				whisper_mode = function() return false end
			}
		end
	}
}

dofile(resolve('lua/copbrain.lua'))

local checks = 0

local function check(condition, label)
	checks = checks + 1

	if not condition then
		error('check failed: ' .. label, 2)
	end
end

local my_pos = vector3(7, 8, 9)

local function make_brain()
	return {
		_unit = {
			movement = function()
				return {
					nav_tracker = function() return {} end
				}
			end
		},
		_logic_data = {
			m_pos = my_pos,
			objective = nil,
			char_tweak = { access = {} },
			active_searches = {}
		}
	}
end

-- 1. The queued search is ours: the start position is applied.
queued_id = 'mine'
queued_searches = {}
managers.navigation._coarse_searches = queued_searches

CopBrain.search_for_coarse_path(make_brain(), 'mine', 11)

check(#queued_searches == 1, 'one search queued')
check(queued_searches[1].from_pos == my_pos, 'own search takes the NPC position')

-- 2. Another NPC queued last: our position must not land on its search.
queued_id = 'someone_else'
queued_searches = {}
managers.navigation._coarse_searches = queued_searches

CopBrain.search_for_coarse_path(make_brain(), 'mine', 11)

check(#queued_searches == 1, 'one search queued')
check(queued_searches[1].from_pos == nil, 'another search keeps its own start position')

-- 3. Several searches in the queue: only the last entry is considered, and it
--    is not ours, so nothing is written at all.
queued_searches = {
	{ id = 'mine' },
	{ id = 'older' }
}
managers.navigation._coarse_searches = queued_searches
queued_id = 'someone_else'

CopBrain.search_for_coarse_path(make_brain(), 'mine', 11)

check(#queued_searches == 3, 'the search was queued')
check(queued_searches[3].from_pos == nil, 'the last entry belongs to another NPC')
check(queued_searches[1].from_pos == nil, 'an older entry is never touched')

print(string.format('%d checks, copbrain search-start test passed', checks))
