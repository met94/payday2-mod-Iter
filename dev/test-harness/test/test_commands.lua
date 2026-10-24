-- Static test for the Iter test-harness command parser.
-- Run from the worktree root:
--   tools\luajit\luajit.exe dev/test-harness/test/test_commands.lua

local hook_registered = false

Hooks = {
  Add = function(self, id, key, fn)
    assert(type(id) == 'string', 'hook id must be a string')
    assert(type(key) == 'string', 'hook key must be a string')
    assert(type(fn) == 'function', 'hook callback must be a function')
    hook_registered = true
  end
}

dofile('dev/test-harness/lua/chatmanager.lua')

assert(hook_registered, 'harness did not register ChatManagerOnSendMessage')
assert(type(Iter_TestHarness) == 'table', 'Iter_TestHarness table missing')
assert(type(Iter_TestHarness.parse_command) == 'function', 'parse_command missing')
assert(type(Iter_TestHarness.execute) == 'function', 'execute missing')
assert(type(Iter_TestHarness.execute_string) == 'function', 'execute_string missing')

local parse = Iter_TestHarness.parse_command

local cmd = parse('!iter nav')
assert(cmd and cmd.command == 'nav', 'nav command not parsed')

cmd = parse('!iter setting streamline_path false')
assert(cmd and cmd.command == 'setting', 'setting command not parsed')
assert(cmd.args[1] == 'streamline_path' and cmd.args[2] == 'false', 'setting args wrong')

cmd = parse('!iter probe 20')
assert(cmd and cmd.command == 'probe' and cmd.args[1] == '20', 'probe args wrong')

assert(type(Iter_TestHarness.force_alarm) == 'function', 'force_alarm missing')
assert(type(Iter_TestHarness.dump_state) == 'function', 'dump_state missing')
assert(type(Iter_TestHarness.dump_nav) == 'function', 'dump_nav missing')
assert(type(Iter_TestHarness.probe) == 'function', 'probe missing')
assert(parse('!iter alarm').command == 'alarm', 'alarm command not parsed')
assert(parse('!iter state').command == 'state', 'state command not parsed')
assert(parse('!iter patch').command == 'patch', 'patch command not parsed')
assert(parse('!iter links').command == 'links', 'links command not parsed')
assert(parse('!iter navdump 56').command == 'navdump', 'navdump command not parsed')
assert(parse('!iter navdoors 56 57').command == 'navdoors', 'navdoors command not parsed')
assert(parse('!iter navpath 63 48').command == 'navpath', 'navpath command not parsed')

cmd = parse('!iter')
assert(cmd and cmd.command == 'help', 'bare !iter should map to help')

assert(parse('hello') == nil, 'non-command should return nil')
assert(parse('!other nav') == nil, 'other prefix should return nil')

Iter = {}
log = function() end
local ok, err = pcall(Iter_TestHarness.dump)
assert(ok, 'dump with nil settings should not error: ' .. tostring(err))

-- navpath behaviour with a fake navigation manager.
local lines = {}
log = function(message)
  lines[#lines + 1] = message
end

mvector3 = {
  distance = function(a, b)
    local dx, dy, dz = a.x - b.x, a.y - b.y, a.z - b.z
    return math.sqrt(dx * dx + dy * dy + dz * dz)
  end
}

local function last_line()
  return lines[#lines] or ''
end

local fake_nav = {
  _nav_segments = {
    ['48'] = { neighbours = {} },
    ['63'] = { neighbours = { ['48'] = { {}, {} } } },
    ['99'] = { neighbours = {} }
  },
  search_coarse = function(self, params)
    if params.from_seg == '63' and params.to_seg == '48' then
      return {
        { '63', { x = 0, y = 0, z = 0 } },
        { '48', { x = 3, y = 4, z = 0 } }
      }
    end
    return false
  end
}

managers = { navigation = fake_nav }
Iter = {
  settings = { map_patches = true },
  get_level_id = function()
    return 'test_level'
  end
}

Iter_TestHarness.navpath({ '63', '48' })
local line = last_line()
assert(line:find('level=test_level patches=on 63->48 ok=1 steps=2', 1, true), 'navpath success header wrong: ' .. line)
assert(line:find('positions=2', 1, true), 'navpath positions wrong: ' .. line)
assert(line:find('length=5.0', 1, true), 'navpath length wrong: ' .. line)
assert(line:find('direct=2', 1, true), 'navpath direct count wrong: ' .. line)
assert(line:find('ids=63;48', 1, true), 'navpath ids wrong: ' .. line)

Iter = {
  settings = { map_patches = false },
  get_level_id = function()
    return 'test_level'
  end
}

Iter_TestHarness.navpath({ '99', '63' })
line = last_line()
assert(line:find('patches=off 99->63 ok=0 fail=search direct=0', 1, true), 'navpath fail line wrong: ' .. line)

fake_nav.search_coarse = function()
  error('boom')
end

Iter_TestHarness.navpath({ '63', '48' })
line = last_line()
assert(line:find('ok=0 err=', 1, true) and line:find('boom', 1, true), 'navpath error line wrong: ' .. line)

Iter_TestHarness.navpath({ '63', '77' })
line = last_line()
assert(line:find('navpath: no segment 77', 1, true), 'navpath missing segment line wrong: ' .. line)

-- p7 auto-dump: plan selection, seal alternative, toggle.
table.size = function(tbl)
  local count = 0
  for _ in pairs(tbl or {}) do
    count = count + 1
  end
  return count
end

local p7_nav = {
  _nav_segments = {
    ['48'] = { pos = { x = 0, y = 0, z = 0 }, vis_groups = {}, neighbours = {} },
    ['63'] = { pos = { x = 0, y = 0, z = 0 }, vis_groups = {}, neighbours = { ['48'] = { {}, {} } } },
    ['87'] = { pos = { x = 0, y = 0, z = 0 }, vis_groups = {}, neighbours = { ['141'] = { {} }, ['90'] = { {} } } },
    ['90'] = { pos = { x = 0, y = 0, z = 0 }, vis_groups = {}, neighbours = { ['87'] = { {} } } },
    ['141'] = { pos = { x = 0, y = 0, z = 0 }, vis_groups = {}, neighbours = { ['87'] = { {} } } }
  },
  _rooms = {},
  _room_doors = {},
  _visibility_groups = {},
  _covers = {},
  search_coarse = function()
    return false
  end
}

managers = { navigation = p7_nav }

local current_level = 'escape_street'

Iter = {
  settings = { map_patches = true },
  get_level_id = function()
    return current_level
  end
}

lines = {}
Iter_TestHarness.p7_dump(true)
local p7_text = table.concat(lines, '\n')
assert(p7_text:find('p7auto level=escape_street patches=on', 1, true), 'p7 header missing: ' .. p7_text)
assert(p7_text:find('navdump seg=48', 1, true), 'p7 dump missing segment 48')
assert(p7_text:find('navpath level=escape_street patches=on 63->48', 1, true), 'p7 path missing 63->48')

current_level = 'jolly'
lines = {}
Iter_TestHarness.p7_dump(true)
p7_text = table.concat(lines, '\n')
assert(p7_text:find('p7auto seal seg=87 exclude=141 alt=90', 1, true), 'p7 seal alternative wrong: ' .. p7_text)
assert(p7_text:find('navpath level=jolly patches=on 87->90', 1, true), 'p7 seal path missing 87->90')

Iter_TestHarness.p7_auto_enabled = false
lines = {}
Iter_TestHarness.p7_dump(false)
assert(#lines == 0, 'p7 auto off should emit nothing')
Iter_TestHarness.p7_auto_enabled = true

assert(parse('!iter p7').command == 'p7', 'p7 command not parsed')
assert(parse('!iter p7 auto off').args[2] == 'off', 'p7 auto toggle args wrong')

print('ok: Iter test-harness parser')
