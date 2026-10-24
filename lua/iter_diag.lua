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
	text = text:gsub('[^%w%._%+%-/:%[%]]', '')

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

	emit(string.format(
		'[ITER-ERR] where=%s msg=%s',
		sanitize(where),
		sanitize(message)
	))
end

function D.count(name, amount)
	D.counters[name] = (D.counters[name] or 0) + (amount or 1)
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
