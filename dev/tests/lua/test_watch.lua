-- Offline test for the Iter watch channel (opt-in digest + always-on alarms).
-- Run: tools\luajit\luajit.exe dev\tests\lua\test_watch.lua

local checks = 0
local lines = {}

local function check(condition, message)
	if not condition then
		error(message, 2)
	end
	checks = checks + 1
end

local function count(needle)
	local n = 0

	for i = 1, #lines do
		if lines[i]:find(needle, 1, true) then
			n = n + 1
		end
	end

	return n
end

log = function(message)
	lines[#lines + 1] = message
end

Iter = {
	settings = {
		debug_log = 0,
		error_log = true,
		watch_log = false
	},
	diag = {}
}

Iter.now = 0

dofile('lua/iter_diag.lua')

local D = Iter.diag

-- 1. The digest channel is gated by watch_log (off by default).
lines = {}
D.watch('digest', { a = 1 })
check(#lines == 0, 'watch line leaked while watch_log=false')

Iter.settings.watch_log = true
lines = {}
D.watch('digest', { a = 1 })
check(#lines == 1, 'watch line missing while watch_log=true')
check(lines[1]:find('[ITER-WATCH]', 1, true), 'watch prefix missing')
check(lines[1]:find('evt=digest', 1, true), 'watch event name missing')
check(lines[1]:find('a=1', 1, true), 'watch field missing')

-- 2. Alarms are NOT gated by watch_log; they fire on a hard failure only.
Iter.settings.watch_log = false
D.watch_reset()
lines = {}
D.alarm('navlink_stale_burst', { count = 6 }, 100)
check(#lines == 1, 'alarm must fire with watch_log=false')
check(lines[1]:find('evt=alarm', 1, true), 'alarm event name missing')

-- 3. Same alarm is rate limited to once per 60 s.
lines = {}
D.alarm('navlink_stale_burst', { count = 7 }, 130)
check(#lines == 0, 'alarm repeated inside 60 s')
D.alarm('navlink_stale_burst', { count = 8 }, 161)
check(#lines == 1, 'alarm did not fire after the window')

-- 4. A different alarm name is independent.
lines = {}
D.alarm('navlink_wait_long', { wait = 130 }, 161)
check(#lines == 1, 'independent alarm name suppressed')

-- 5. Per-level budget: 20 alarms, then one budget line and silence.
D.watch_reset()
lines = {}
for i = 1, 25 do
	D.alarm('alarm_' .. i, { n = i }, 1000 + i)
end
check(count('[ITER-WATCH]') == 21, 'alarm budget not enforced: got ' .. count('[ITER-WATCH]'))
check(count('evt=alarm_budget_exhausted') == 1, 'budget exhaustion must be reported exactly once')

-- 6. watch_reset restores the budget and the rate limit (new level).
D.watch_reset()
lines = {}
D.alarm('alarm_1', { n = 1 }, 5000)
check(#lines == 1, 'watch_reset did not restore the budget')

-- 7. Alarms never write per frame: 600 calls inside one second produce one line.
D.watch_reset()
lines = {}
for i = 1, 600 do
	D.alarm('navlink_queue_long', { queue = 30 }, 7000)
end
check(#lines == 1, 'per-frame alarm storm: ' .. #lines .. ' lines')

print(string.format('%d checks, watch channel test passed', checks))
