-- Offline test for the test-harness bot objective description.
--
-- Why: `diag bot` lines reported `obj=follow,follow=?,in_place` for stuck bots,
-- which is ambiguous between "no follow unit at all", "the follow unit is
-- dead", and "a unit whose key could not be read". The owner of the stuck bot
-- (Keepers / Useful Bots / LIES) cannot be decided without that distinction.
--
-- Run from the worktree root:
--   tools\luajit\luajit.exe dev\tests\lua\test_harness_bot_obj.lua

local checks = 0
local function check(condition, message)
	if not condition then
		error(message, 2)
	end
	checks = checks + 1
end

-- The harness only needs Hooks at load time; everything else it touches is
-- guarded by pcall.
Hooks = { Add = function() end }

-- Unit liveness mirror of the game helper used by the harness.
alive = function(unit)
	if unit == nil then
		return false
	end

	return unit._alive ~= false
end

dofile('dev/test-harness/lua/chatmanager.lua')

local TH = Iter_TestHarness
check(type(TH) == 'table', 'Iter_TestHarness table missing')
check(type(TH.objective_desc) == 'function', 'objective_desc is not exported for tests')

local function unit(key, is_alive)
	return {
		_key = key,
		_alive = is_alive,
		key = function(self)
			return self._key
		end
	}
end

local function brain(objective)
	return {
		objective = function()
			return objective
		end
	}
end

local function desc(objective)
	return TH.objective_desc(brain(objective))
end

-- 1. follow objective without a unit reference: nil, not dead, not a key.
do
	local got = desc({ type = 'follow' })
	check(got == 'follow,follow=nil', 'nil follow unit: got ' .. got)
end

-- 2. follow unit present but destroyed.
do
	local got = desc({ type = 'follow', follow_unit = unit(100234, false) })
	check(got == 'follow,follow=dead:100234', 'dead follow unit: got ' .. got)
end

-- 3. live follow unit reports its key.
do
	local got = desc({ type = 'follow', follow_unit = unit(100235, true) })
	check(got == 'follow,follow=100235', 'live follow unit: got ' .. got)
end

-- 4. a plain key (no unit object) cannot be tested for liveness.
do
	local got = desc({ type = 'follow', follow_unit_key = 100236 })
	check(got == 'follow,follow=key:100236', 'plain follow key: got ' .. got)
end

-- 5. a unit object without key() stays ambiguous but never reads as nil.
do
	local got = desc({ type = 'follow', follow_unit = { _alive = true } })
	check(got == 'follow,follow=?', 'keyless follow unit: got ' .. got)
end

-- 6. the remaining objective flags survive the change.
do
	local got = desc({
		type = 'follow',
		follow_unit = nil,
		in_place = true,
		is_default = true,
		called = true
	})
	check(got == 'follow,follow=nil,in_place,dflt,called', 'objective flags: got ' .. got)
end

-- 7. assist units get the same liveness treatment.
do
	local got = desc({ type = 'revive', assist_unit = unit(100237, false) })
	check(got == 'revive,follow=nil,assist=dead:100237', 'dead assist unit: got ' .. got)
end

-- 8. non-follow objectives still say follow=nil so the field is never absent.
do
	local got = desc({ type = 'defend', in_place = false })
	check(got == 'defend,follow=nil', 'defend objective: got ' .. got)
end

print(string.format('%d checks, harness bot objective test passed', checks))
