-- Iter diagnostics: stable, machine-readable log events.
-- Loaded from corecode.lua before the navigation overlay.

Iter.diag = Iter.diag or {}

local D = Iter.diag

D.version = 1
D.counters = D.counters or {}
D.counters.err = D.counters.err or 0
D.session_id = D.session_id or string.format('%04x', math.random(0, 0xffff))

local function level()
	return tonumber(Iter.settings and Iter.settings.debug_log) or 0
end

local function sanitize(value)
	local text = tostring(value)
	text = text:gsub('%s+', '_')
	text = text:gsub('[^%w%._%+%-/:%[%]?]', '')

	if #text > 120 then
		text = text:sub(1, 120)
	end

	return text
end

local function emit(line)
	if not log then
		return
	end

	pcall(log, line)
end

local function fields_to_text(fields)
	local parts = {}

	for key, value in pairs(fields or {}) do
		parts[#parts + 1] = tostring(key) .. '=' .. sanitize(value)
	end

	table.sort(parts)

	return table.concat(parts, ' ')
end

function D.active(min_level)
	return level() >= (min_level or 1)
end

function D.event(event_name, fields, min_level)
	if not D.active(min_level or 1) then
		return
	end

	local payload = string.format(
		'[ITER-NAV] v=%d sid=%s evt=%s %s',
		D.version,
		D.session_id,
		sanitize(event_name),
		fields_to_text(fields)
	)

	emit(payload)
end

function D.err(where, message)
	D.counters.err = (D.counters.err or 0) + 1

	-- Errors are on by default, but a player can silence them with
	-- error_log=false in iter.txt.
	if Iter.settings and Iter.settings.error_log == false then
		return
	end

	emit(string.format(
		'[ITER-ERR] where=%s msg=%s',
		sanitize(where),
		sanitize(message)
	))
end

function D.count(name, amount)
	D.counters[name] = (D.counters[name] or 0) + (amount or 1)
end

-- Watch channel. Two tiers with different switches:
--   D.watch  -- opt-in digest (`Iter.settings.watch_log`, default false)
--   D.alarm  -- always on, hard failures only, rate limited per name and per
--               level so a broken level cannot flood the log either.
-- The always-on tier exists because a session with everything off otherwise
-- leaves no evidence at all; see docs/investigations/ai-suite-fps.md
-- (Counterfeit `pal`: one cop held a nav link 204.8 s, invisible without the
-- dev harness).
D.alarm_last = D.alarm_last or {}
D.alarm_budget_left = D.alarm_budget_left or 20
D.alarm_window = 60

function D.watch_enabled()
	return (Iter.settings and Iter.settings.watch_log) and true or false
end

function D.watch(event_name, fields)
	if not D.watch_enabled() then
		return
	end

	local parts = { '[ITER-WATCH] v=' .. D.version }
	parts[#parts + 1] = 'sid=' .. D.session_id
	parts[#parts + 1] = 'evt=' .. sanitize(event_name)
	parts[#parts + 1] = fields_to_text(fields)

	emit(table.concat(parts, ' '))
end

function D.alarm(name, fields, now)
	if (D.alarm_budget_left or 0) <= 0 then
		return
	end

	now = tonumber(now) or D.now()
	local last = D.alarm_last[name]

	if last and now - last < D.alarm_window then
		return
	end

	D.alarm_last[name] = now
	D.alarm_budget_left = D.alarm_budget_left - 1

	local parts = { '[ITER-WATCH] v=' .. D.version }
	parts[#parts + 1] = 'sid=' .. D.session_id
	parts[#parts + 1] = 'evt=alarm'
	parts[#parts + 1] = 'name=' .. sanitize(name)
	parts[#parts + 1] = fields_to_text(fields)

	emit(table.concat(parts, ' '))

	if D.alarm_budget_left <= 0 then
		emit('[ITER-WATCH] v=' .. D.version .. ' sid=' .. D.session_id .. ' evt=alarm_budget_exhausted')
	end
end

-- Called on level change: the budget is per level, not per session.
function D.watch_reset()
	D.alarm_last = {}
	D.alarm_budget_left = 20
end

function D.observe_ms(name, ms)
	local current = D.counters[name]

	if not current or ms > current then
		D.counters[name] = ms
	end
end

function D.reset()
	D.counters = { err = 0 }
end

function D.summary(extra)
	local fields = {}
	local source = extra or {}

	for key, value in pairs(D.counters) do
		fields[key] = value
	end

	for key, value in pairs(source) do
		fields[key] = value
	end

	D.event('summary', fields, 1)
end

function D.now()
	if TimerManager and TimerManager.game then
		local ok, t = pcall(function()
			return TimerManager:game():time()
		end)

		if ok then
			return t
		end
	end

	return 0
end

function D.span_ms(start_time)
	return (D.now() - (start_time or 0)) * 1000
end
