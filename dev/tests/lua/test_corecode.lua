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

-- 1. Fresh install: defaults on, mirror tracks the effective state.
run_scenario('fresh', nil)
check_equal(Iter.settings.nav_overlay, true, 'default nav_overlay')
check_equal(Iter.settings.nav_streamline, true, 'default nav_streamline')
check_equal(Iter.settings.streamline_path, true, 'mirror is on when both flags are on')

-- 2. Pre-port save with pathing off: migration wins, mirror is nil.
local legacy = run_scenario('legacy_off', {
	streamline_path = false,
	nav_streamline = true
})
check_equal(Iter.settings.nav_overlay, false, 'legacy streamline_path=false migrates nav_overlay off')
check_equal(Iter.settings.streamline_path, nil, 'mirror is nil when the master switch is off')

Iter:save()
check(legacy.written ~= nil, 'save() wrote a settings table')
check_equal(legacy.written.streamline_path, nil, 'save() must not persist streamline_path')
check_equal(legacy.written.nav_overlay, false, 'save() keeps the migrated master switch off')
check_equal(Iter.settings.streamline_path, nil, 'save() restores the nil mirror')

-- 3. Save from the default state: the key never reaches the file, the runtime
-- value survives the write (arbitrary sentinel proves the restore).
local defaults = run_scenario('save_default', nil)
Iter.settings.streamline_path = 'sentinel'
Iter:save()
check_equal(defaults.written.streamline_path, nil, 'save() must not persist streamline_path')
check_equal(Iter.settings.streamline_path, 'sentinel', 'save() restores the runtime mirror')

-- 4. Master switch turned off at runtime: mirror nil, key still excluded.
local off = run_scenario('save_off', {
	nav_overlay = false,
	nav_streamline = true
})
check_equal(Iter.settings.streamline_path, nil, 'mirror is nil with nav_overlay=false')
Iter:save()
check_equal(off.written.streamline_path, nil, 'save() must not persist streamline_path when off')
check_equal(Iter.settings.streamline_path, nil, 'save() keeps the mirror nil when off')

io.open = real_open

print(string.format('corecode settings: %d checks PASS', checks))
