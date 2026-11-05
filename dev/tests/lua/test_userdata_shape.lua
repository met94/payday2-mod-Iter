-- Offline regression test for the userdata shape guards in Iter's nav code.
-- Runs on bare LuaJIT, no game/engine:
--   tools\luajit\luajit.exe dev\tests\lua\test_userdata_shape.lua
--
-- The guards are rejection guards, not shape proofs (see
-- dev/reports/opaque-userdata-shapes.md). This test pins the accepted domain:
-- nil / number / string / table are rejected, a Vector3-like userdata is
-- rejected by itr_alive, a nav-link-like userdata (no `alive` method, or one
-- that reports liveness) is treated as existing. The helpers are sliced out of
-- the shipped files, not copied, so the test tracks the real code.

local script_path = (arg and arg[0]) or 'dev/tests/lua/test_userdata_shape.lua'
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

local function read(relative)
	local handle = assert(io.open(resolve(relative), 'r'))
	local source = handle:read('*a')
	handle:close()
	return source
end

-- Slice a top-level `local function` region: from the start marker to the
-- first column-0 `end` at or after `last_marker`.
local function slice(source, start_marker, last_marker)
	local start = source:find(start_marker, 1, true)
	check(start ~= nil, 'start marker not found: ' .. start_marker)

	local anchor = source:find(last_marker, start, true)
	check(anchor ~= nil, 'body marker not found: ' .. last_marker)

	local stop = source:find('\nend', anchor, true)
	check(stop ~= nil, 'terminating end not found for ' .. start_marker)

	return source:sub(start, stop + 3)
end

local nav_source = read('lua/navigationmanager.lua')
local walk_source = read('lua/copactionwalk.lua')

local nav_chunk = assert(loadstring(
	slice(nav_source, 'local function is_vec3(value)', 'local function itr_alive(obj)')
	.. '\nreturn is_vec3, itr_alive'
))
local is_vec3, itr_alive = nav_chunk()

local walk_chunk = assert(loadstring(
	slice(walk_source, 'local function itr_alive_navpoint(obj)', 'local function itr_alive_navpoint(obj)')
	.. '\nreturn itr_alive_navpoint'
))
local itr_alive_navpoint = walk_chunk()

-- Stand-ins: `newproxy(true)` is real userdata with a controllable __index, so
-- `type()` answers "userdata" exactly like the engine types.
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

local function navlink_like(methods)
	local value = newproxy(true)

	getmetatable(value).__index = function(_, key)
		-- A nav-link object has no Vector3 coordinates.
		if key == 'x' or key == 'y' or key == 'z' then
			return nil
		end

		return (methods or {})[key]
	end

	return value
end

local vector = vector3_like(1, 2, 3)
local navlink = navlink_like()
local live_navlink = navlink_like({ alive = function() return true end })
local dead_navlink = navlink_like({ alive = function() return false end })
local flagged_navlink = navlink_like({ alive = true })

-- is_vec3: userdata with numeric x/y/z only.
check(is_vec3(nil) == false, 'is_vec3(nil)')
check(is_vec3(1) == false, 'is_vec3(number)')
check(is_vec3('pos') == false, 'is_vec3(string)')
check(is_vec3({ x = 1, y = 2, z = 3 }) == false, 'is_vec3(table)')
check(is_vec3(vector) == true, 'is_vec3(Vector3-like)')
check(is_vec3(navlink) == false, 'is_vec3(nav-link-like)')
checks = checks + 1

-- itr_alive: non-userdata is absent; Vector3 is not a unit; a nav link without
-- alive() counts as existing; alive() decides when it exists.
check(itr_alive(nil) == false, 'itr_alive(nil)')
check(itr_alive(1) == false, 'itr_alive(number)')
check(itr_alive({}) == false, 'itr_alive(table)')
check(itr_alive(vector) == false, 'itr_alive(Vector3-like)')
check(itr_alive(navlink) == true, 'itr_alive(nav-link without alive)')
check(itr_alive(live_navlink) == true, 'itr_alive(nav-link alive)')
check(itr_alive(dead_navlink) == false, 'itr_alive(nav-link dead)')
check(itr_alive(flagged_navlink) == true, 'itr_alive(non-function alive)')
checks = checks + 1

-- copactionwalk copy. Unlike itr_alive it has no is_vec3 term: its callers
-- route positions through `nav_point.x` first (copactionwalk.lua:130), so a
-- Vector3-like userdata is not expected here and counts as "existing".
check(itr_alive_navpoint(nil) == false, 'navpoint(nil)')
check(itr_alive_navpoint(1) == false, 'navpoint(number)')
check(itr_alive_navpoint({}) == false, 'navpoint(table)')
check(itr_alive_navpoint(vector) == true, 'navpoint(Vector3-like has no alive)')
check(itr_alive_navpoint(navlink) == true, 'navpoint(nav-link without alive)')
check(itr_alive_navpoint(live_navlink) == true, 'navpoint(nav-link alive)')
check(itr_alive_navpoint(dead_navlink) == false, 'navpoint(nav-link dead)')
checks = checks + 1

io.write(string.format('ok: userdata shape guards (%d checks)\n', checks))
