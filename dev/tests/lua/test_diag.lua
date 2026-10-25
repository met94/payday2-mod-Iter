-- Offline test for the diag logger gates.
-- Run: tools\luajit\luajit.exe dev\tests\lua\test_diag.lua

local checks = 0
local lines = {}

local function check(condition, message)
	if not condition then
		error(message, 2)
	end
	checks = checks + 1
end

log = function(message)
	lines[#lines + 1] = message
end

Iter = {
	settings = {
		debug_log = 0,
		error_log = true
	},
	diag = {}
}

dofile('lua/iter_diag.lua')

-- debug events are off at debug_log=0
lines = {}
Iter.diag.event('probe', { a = 1 })
check(#lines == 0, 'debug event leaked at debug_log=0')

-- counters never log
lines = {}
Iter.diag.count('search_ok')
Iter.diag.count('search_ok', 2)
check(#lines == 0, 'counter logged')
check(Iter.diag.counters.search_ok == 3, 'counter value wrong')

-- errors are on by default
lines = {}
Iter.diag.err('where', 'message')
check(#lines == 1 and lines[1]:find('%[ITER%-ERR%]'), 'error line missing')
check(Iter.diag.counters.err == 1, 'error counter wrong')

-- error logging can be turned off
Iter.settings.error_log = false
lines = {}
Iter.diag.err('where', 'message')
check(#lines == 0, 'error leaked with error_log=false')
check(Iter.diag.counters.err == 2, 'error counter must still increment')

-- debug events at debug_log=1
Iter.settings.error_log = true
Iter.settings.debug_log = 1
lines = {}
Iter.diag.event('probe', { a = 1 })
check(#lines == 1 and lines[1]:find('%[ITER%-NAV%]') and lines[1]:find('evt=probe'), 'debug event missing')
check(lines[1]:find('a=1'), 'debug field missing')

print(string.format('%d checks, diag gate test passed', checks))
