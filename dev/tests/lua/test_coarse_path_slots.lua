-- Offline regression test for the coarse-path slot-2 guard in
-- lua/coplogictravel.lua (get_turn_back_index). Runs on bare LuaJIT:
--   tools\luajit\luajit.exe dev\tests\lua\test_coarse_path_slots.lua
--
-- Slot 2 of a coarse-path step is an engine Vector3 or nil at every writer
-- (game coplogictravel.lua:83-101, :114-122, :128-129, :1088-1096). The
-- `type(...) ~= 'userdata'` test is a rejection guard for non-vector junk, not
-- a proof that userdata is a Vector3; the nil-check shortcut would let a truthy
-- table/number reach the axis arithmetic. This test pins the guard.

local script_path = (arg and arg[0]) or 'dev/tests/lua/test_coarse_path_slots.lua'
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

local checks = 0

local function check(condition, message)
	if not condition then
		error(message, 2)
	end

	checks = checks + 1
end

local handle = assert(io.open(resolve('lua/coplogictravel.lua'), 'r'))
local source = handle:read('*a')
handle:close()

local start = source:find('local function check_turn_back_on_axis(axis)', 1, true)
check(start ~= nil, 'check_turn_back_on_axis not found')

local stop = source:find('\n\n\t\tlocal bad_from_index = get_turn_back_index()', start, true)
check(stop ~= nil, 'end of get_turn_back_index not found')

local body = source:sub(start, stop - 1)

local factory = assert(loadstring(
	'return function(coarse_path, coarse_path_index, coarse_path_nr)\n'
	.. body
	.. '\nreturn check_turn_back_on_axis, get_turn_back_index\nend'
))()

local function vector3_like(x, y, z)
	local value = newproxy(true)

	getmetatable(value).__index = function(_, key)
		if key == 'x' then
			return x
		elseif key == 'y' then
			return y
		elseif key == 'z' then
			return z
		end

		return nil
	end

	return value
end

-- 1. Vector3-like slot 2: a genuine turn-back on both axes resolves to step 2.
local path = {
	{ 10, vector3_like(0, 0, 0) },
	{ 11, vector3_like(1000, 1000, 0) },
	{ 12, vector3_like(0, 0, 0) }
}
local _, get_turn_back_index = factory(path, 1, 3)
check(get_turn_back_index() == 2, 'Vector3-like slot 2 resolves the turn-back')
checks = checks + 1

-- 2. nil slot 2 is rejected (the guard's documented outcome).
local nil_path = {
	{ 10, vector3_like(0, 0, 0) },
	{ 11 },
	{ 12, vector3_like(0, 0, 0) }
}
_, get_turn_back_index = factory(nil_path, 1, 3)
check(get_turn_back_index() == nil, 'nil slot 2 is rejected')
checks = checks + 1

-- 3. A truthy table in slot 2 is still rejected - the check removed by the
--    nil-check shortcut would be caught here.
local table_path = {
	{ 10, vector3_like(0, 0, 0) },
	{ 11, { x = 1000, y = 1000, z = 0 } },
	{ 12, vector3_like(0, 0, 0) }
}
_, get_turn_back_index = factory(table_path, 1, 3)
check(get_turn_back_index() == nil, 'table slot 2 is rejected')
checks = checks + 1

-- 4. Number / string slot 2 (truthy non-userdata) are rejected too.
local number_path = {
	{ 10, vector3_like(0, 0, 0) },
	{ 11, 1000 },
	{ 12, vector3_like(0, 0, 0) }
}
_, get_turn_back_index = factory(number_path, 1, 3)
check(get_turn_back_index() == nil, 'number slot 2 is rejected')
checks = checks + 1

local string_path = {
	{ 10, vector3_like(0, 0, 0) },
	{ 11, 'pos' },
	{ 12, vector3_like(0, 0, 0) }
}
_, get_turn_back_index = factory(string_path, 1, 3)
check(get_turn_back_index() == nil, 'string slot 2 is rejected')
checks = checks + 1

io.write(string.format('ok: coarse-path slot guard (%d checks)\n', checks))
