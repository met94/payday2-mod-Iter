-- Offline unit test for lua/corecode.lua settings load/save hygiene.
-- Runs on bare LuaJIT, no game/engine:
--   tools\luajit\luajit.exe dev\tests\lua\test_corecode.lua
-- io, json and dofile are stubbed; the settings file is kept in memory.

local script_path = (arg and arg[0]) or 'dev/tests/lua/test_corecode.lua'
local test_dir = script_path:match('^(.*)[/\\][^/\\]+$') or '.'

local function resolve_corecode()
	local candidates = {
		'lua/corecode.lua',
		test_dir .. '/../../../lua/corecode.lua'
	}

	for _, candidate in ipairs(candidates) do
		local handle = io.open(candidate, 'r')

		if handle then
			handle:close()
			return candidate
		end
	end

	error('cannot locate lua/corecode.lua from ' .. script_path)
end

local corecode_path = resolve_corecode()
local real_open = io.open
local checks = 0

local function check(condition, message)
	if not condition then
		error(message, 2)
	end

	checks = checks + 1
end

local function check_equal(actual, expected, message)
	if actual ~= expected then
		error(string.format('%s (expected %s, got %s)', message, tostring(expected), tostring(actual)), 2)
	end

	checks = checks + 1
end

-- The mirror is nil right after load and `false` after a save, so "off" is
-- asserted as either falsy value. Both are read as off by Useful Bots and by
-- upstream r200.
local function check_off(value, message)
	if value ~= nil and value ~= false then
		error(string.format('%s (expected nil or false, got %s)', message, tostring(value)), 2)
	end

	checks = checks + 1
end

local function copy_table(source)
	local copy = {}

	for k, v in pairs(source) do
		copy[k] = v
	end

	return copy
end

-- Scenario harness: `saved` is the file body the stubbed io.open returns for
-- reads, `written` collects the table json.encode saw on save.
local function run_scenario(tag, saved_settings)
	local scenario = {
		written = nil,
		read_ops = 0
	}

	_G.Iter = nil
	RequiredScript = tag
	ModPath = '/mods/Iter/'
	SavePath = '/saves/'

	_G.dofile = function()
		Iter.diag = {
			version = 'test',
			event = function() end,
			count = function() end,
			err = function() end
		}
	end

	_G.json = {
		decode = function()
			return saved_settings and copy_table(saved_settings) or nil
		end,
		encode = function(tbl)
			scenario.written = copy_table(tbl)
			return '{}'
		end
	}

	io.open = function(_, mode)
		if mode == 'w+' then
			return {
				write = function() end,
				close = function() end
			}
		end

		if not saved_settings then
			return nil
		end

		scenario.read_ops = scenario.read_ops + 1

		return {
			read = function()
				return '{}'
			end,
			close = function() end
		}
	end

	local chunk = assert(loadfile(corecode_path))
	chunk()

	return scenario
end

-- 1. Fresh install: defaults on, mirror tracks the effective state. The
-- returned scenario is asserted too: a missing file is never read and load()
-- alone never writes.
local fresh = run_scenario('fresh', nil)
check_equal(fresh.read_ops, 0, 'fresh install does not read a settings file')
check_equal(fresh.written, nil, 'load() alone does not write the settings file')
check_equal(Iter.settings.nav_overlay, true, 'default nav_overlay')
check_equal(Iter.settings.nav_streamline, true, 'default nav_streamline')
check_equal(Iter.settings.streamline_path, true, 'mirror is on when both flags are on')

-- 2. Pre-port save with pathing off: migration wins, mirror is nil, and save()
-- persists the effective false (downgrade compatibility).
local legacy = run_scenario('legacy_off', {
	streamline_path = false,
	nav_streamline = true
})
check_equal(legacy.read_ops, 1, 'a saved file is read once at load')
check_equal(Iter.settings.nav_overlay, false, 'legacy streamline_path=false migrates nav_overlay off')
check_off(Iter.settings.streamline_path, 'mirror is off when the master switch is off')

Iter:save()
check(legacy.written ~= nil, 'save() wrote a settings table')
check_equal(legacy.written.streamline_path, false, 'save() persists the effective false')
check_equal(legacy.written.nav_overlay, false, 'save() keeps the migrated master switch off')
check_off(Iter.settings.streamline_path, 'save() leaves the in-memory mirror off')

-- 3. Menu toggle then save: the mirror is recomputed from the live switches,
-- never restored from a stale load-time copy (a sentinel proves the rewrite).
local toggle = run_scenario('toggle_save', nil)
check_equal(toggle.read_ops, 0, 'fresh install read count is unchanged by save()')

Iter.settings.streamline_path = 'sentinel'
Iter.settings.nav_overlay = false
Iter:save()
check_off(Iter.settings.streamline_path, 'save() recomputes the mirror when nav_overlay is off')
check_equal(toggle.written.streamline_path, false, 'save() persists false when nav_overlay is off')

Iter.settings.nav_overlay = true
Iter:save()
check_equal(Iter.settings.streamline_path, true, 'save() recomputes the mirror when nav_overlay is back on')
check_equal(toggle.written.streamline_path, true, 'save() persists true when both switches are on')

Iter.settings.streamline_path = 'sentinel'
Iter.settings.nav_streamline = false
Iter:save()
check_off(Iter.settings.streamline_path, 'save() recomputes the mirror when nav_streamline is off')
check_equal(toggle.written.streamline_path, false, 'save() persists false when nav_streamline is off')

-- 4. Saved master switch off: mirror off at load, and save() writes false.
local off = run_scenario('save_off', {
	nav_overlay = false,
	nav_streamline = true
})
check_equal(off.read_ops, 1, 'saved master switch is read once at load')
check_off(Iter.settings.streamline_path, 'mirror is off with nav_overlay=false')
Iter:save()
check_equal(off.written.streamline_path, false, 'save() persists false with nav_overlay=false')
check_off(Iter.settings.streamline_path, 'save() leaves the mirror off with nav_overlay=false')

-- 5. Resurrection guard: a file that still says streamline_path=true while
-- nav_overlay=false must not resurrect pathing (downgrade round-trip).
local resurrect = run_scenario('resurrect', {
	streamline_path = true,
	nav_overlay = false,
	nav_streamline = true
})
check_equal(resurrect.read_ops, 1, 'resurrection fixture is read once at load')
check_equal(Iter.settings.nav_overlay, false, 'nav_overlay=false survives a stale true alias')
check_off(Iter.settings.streamline_path, 'stale true alias is recomputed to off at load')
Iter:save()
check_equal(resurrect.written.streamline_path, false, 'save() overwrites a stale true alias with false')
check_equal(resurrect.written.nav_overlay, false, 'save() keeps nav_overlay=false')
check_off(Iter.settings.streamline_path, 'mirror stays off after saving the resurrected file')

io.open = real_open

print(string.format('corecode settings: %d checks PASS', checks))
