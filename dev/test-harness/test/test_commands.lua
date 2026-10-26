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
    ['48'] = { vis_groups = { '21' }, neighbours = {} },
    ['63'] = { vis_groups = { '20' }, neighbours = { ['48'] = { {}, {} } } },
    ['99'] = { neighbours = {} }
  },
  _visibility_groups = {
    ['20'] = { visible_groups = { ['21'] = true } },
    ['21'] = { visible_groups = {} }
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
assert(line:find('see_fwd=1 see_rev=0', 1, true), 'navpath visibility flags wrong: ' .. line)
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
    ['8'] = { pos = { x = 0, y = 0, z = 0 }, vis_groups = {}, neighbours = { ['11'] = { {} } } },
    ['11'] = { pos = { x = 0, y = 0, z = 0 }, vis_groups = {}, neighbours = { ['8'] = { {} } } },
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
local dumped = Iter_TestHarness.p7_dump(true)
assert(dumped == true, 'p7 dump should report success')
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

current_level = 'skm_mallcrasher'
lines = {}
Iter_TestHarness.p7_dump(true)
p7_text = table.concat(lines, '\n')
assert(p7_text:find('p7auto level=skm_mallcrasher patches=on', 1, true), 'skm_mallcrasher plan missing: ' .. p7_text)
assert(p7_text:find('navdoors 8<->11', 1, true), 'skm_mallcrasher doors missing')

Iter_TestHarness.p7_auto_enabled = false
lines = {}
assert(Iter_TestHarness.p7_dump(false) == false, 'p7 auto off should report no dump')
assert(#lines == 0, 'p7 auto off should emit nothing')
Iter_TestHarness.p7_auto_enabled = true

assert(parse('!iter p7').command == 'p7', 'p7 command not parsed')
assert(parse('!iter p7 auto off').args[2] == 'off', 'p7 auto toggle args wrong')

-- Auto tick: a nav load bumps the generation; the first update frame after
-- the settle delay dumps exactly once.
p7_nav._rooms = { [1] = true }
current_level = 'escape_street'
Iter_TestHarness.p7_auto_enabled = true
Iter_TestHarness.p7_note_load()
lines = {}
Iter_TestHarness.p7_tick(10)
assert(#lines == 0, 'p7 tick should wait for the settle delay')
Iter_TestHarness.p7_tick(12)
assert(table.concat(lines, '\n'):find('p7auto level=escape_street', 1, true), 'p7 tick did not dump')
lines = {}
Iter_TestHarness.p7_tick(20)
assert(#lines == 0, 'p7 tick should dump only once per load')

-- force level: host-only level jump for the escape narratives.
local loaded
local fake_session = {
  load_level = function(self, level, mission, world_setting, level_class_name, level_id)
    loaded = { level, mission, world_setting, level_class_name, level_id }
  end
}

tweak_data = {
  levels = {
    escape_street = { world_name = 'narratives/escapes/escape_street' },
    skm_mallcrasher = { world_name = 'narratives/skm/skm_mallcrasher', group_ai_state = 'skirmish' }
  }
}
Global = { game_settings = {} }
Network = { is_server = function() return true end }
managers = {
  network = {
    session = function() return fake_session end,
    host_game = function() error('force should reuse an existing session') end
  }
}

lines = {}
Iter_TestHarness.force_level({ 'escape_street' })
assert(Global.game_settings.level_id == 'escape_street', 'force did not set level_id')
assert(Global.game_settings.mission == 'none', 'force did not set mission')
assert(loaded and loaded[1] == 'narratives/escapes/escape_street' and loaded[5] == 'escape_street', 'force load_level args wrong')
assert(table.concat(lines, '\n'):find('force: loading escape_street', 1, true), 'force did not log the load')

lines = {}
Iter_TestHarness.force_level({ 'nope' })
assert(table.concat(lines, '\n'):find('force: unknown level nope', 1, true), 'force unknown level message wrong')

lines = {}
Iter_TestHarness.force_level({ 'skm_mallcrasher' })
assert(table.concat(lines, '\n'):find('force: skirmish levels must be loaded through Crime Spree', 1, true), 'force skirmish guard wrong')

assert(parse('!iter force escape_street').args[1] == 'escape_street', 'force args wrong')

-- navquad: border/height/segment dump.
managers.navigation = p7_nav
p7_nav._rooms = {
  [2777] = {
    vis_group = 21,
    borders = { x_neg = 1.5, x_pos = 2.5, y_neg = 3.5, y_pos = 4.5 },
    height = { xn_yn = 10, xn_yp = 11, xp_yn = 12, xp_yp = 13 }
  }
}
p7_nav._visibility_groups = { [21] = { seg = '23' } }

lines = {}
Iter_TestHarness.dump_quad({ '2777', '999' })
local quad_text = table.concat(lines, '\n')
assert(quad_text:find('navquad id=2777 vg=21 seg=23', 1, true), 'navquad header wrong: ' .. quad_text)
assert(quad_text:find('borders=(1.5,3.5)-(2.5,4.5)', 1, true), 'navquad borders wrong: ' .. quad_text)
assert(quad_text:find('height=(10.0,11.0,12.0,13.0)', 1, true), 'navquad height wrong: ' .. quad_text)
assert(quad_text:find('navquad id=2777 doors=none', 1, true), 'navquad doors line wrong: ' .. quad_text)
assert(quad_text:find('navquad id=999 missing', 1, true), 'navquad missing id wrong: ' .. quad_text)
assert(parse('!iter navquad 2777').command == 'navquad', 'navquad command not parsed')

-- setting with no value must not delete the key.
Iter.settings.map_patches = true
lines = {}
Iter_TestHarness.set_setting('map_patches', nil)
assert(table.concat(lines, '\n'):find('setting: missing value', 1, true), 'set_setting nil guard wrong')
assert(Iter.settings.map_patches == true, 'set_setting nil must not delete the key')

assert(parse('!iter bots').command == 'bots', 'bots command not parsed')
assert(parse('!iter cops').command == 'cops', 'cops command not parsed')
assert(parse('!iter diag off').command == 'diag' and parse('!iter diag off').args[1] == 'off', 'diag off args wrong')
assert(parse('!iter diag').args[1] == nil, 'bare diag should have no args')
assert(type(Iter_TestHarness.dump_bots) == 'function', 'dump_bots missing')
assert(type(Iter_TestHarness.dump_cops) == 'function', 'dump_cops missing')
assert(type(Iter_TestHarness.diag_tick) == 'function', 'diag_tick missing')
assert(type(Iter_TestHarness.diag_toggle) == 'function', 'diag_toggle missing')

-- !iter links: queued/reserved first, from/to/pos/search fields, reserved key.
local fake_link_nav = {
  itr_navlink_elements = {
    ['linkA'] = {
      _values = {
        so_action = 'e_nl_up_stairs',
        itr_from_navseg = '63',
        itr_to_navseg = '48',
        itr_interval = 2,
        position = { x = 10, y = 20, z = 0 },
        search_position = { x = 11, y = 21, z = 0 }
      },
      itr_navlink_queue_length = 2,
      itr_reserved_by_unit = { _alive = true, key = function() return '100234' end },
      itr_navlink_queue_oldest_t = 100
    },
    ['linkB'] = {
      _values = { so_action = 'e_nl_through_window', interval = 0 },
      itr_navlink_queue_length = 0
    }
  }
}

alive = function(unit)
  return unit and unit._alive ~= false
end
TimerManager = {
  game = function()
    return { time = function() return 105 end }
  end
}

managers = { navigation = fake_link_nav }
lines = {}
Iter_TestHarness.dump_links()
local link_text = table.concat(lines, '\n')
assert(link_text:find('link key=linkA action=e_nl_up_stairs from=63 to=48 interval=2.00 queue=2 reserved=100234 wait=5.0', 1, true), 'queued link line wrong: ' .. link_text)
assert(link_text:find('pos=10,20,0 search=11,21,0', 1, true), 'link positions wrong: ' .. link_text)
assert(link_text:find('link key=linkB action=e_nl_through_window from=? to=?', 1, true), 'non-queued link line wrong: ' .. link_text)
assert(link_text:find('links total=2 queued=1 reserved=1', 1, true), 'links summary wrong: ' .. link_text)
assert(lines[1]:find('key=linkA', 1, true), 'queued link should print first: ' .. lines[1])

-- !iter bots: logic/objective/action/coarse/wait/carry/stay/kpr/pos.
local function fake_bot(key, objective, id)
  return {
    _alive = true,
    key = function() return key end,
    id = function() return id end,
    position = function() return { x = 100, y = 200, z = 0 } end,
    brain = function()
      return {
        _current_logic_name = 'travel',
        objective = objective,
        _logic_data = {
          internal_data = {
            coarse_path = { {}, {}, {} },
            coarse_path_index = 2,
            advancing = { _action_desc = { type = 'walk' } }
          }
        }
      }
    end,
    movement = function()
      return {
        _carry_unit = {
          carry_data = function()
            return { carry_id = function() return 'downed_x' end }
          end
        },
        _should_stay = true,
        _should_stay_pos = { x = 5, y = 6, z = 0 },
        chk_action_forbidden = function() return false end
      }
    end
  }
end

managers = {
  groupai = {
    state = function()
      return {
        all_AI_criminals = function()
          return {
            ['1'] = { unit = fake_bot('bot1', nil, 1001) },
            ['2'] = {
              unit = fake_bot('bot2', function()
                return {
                  type = 'revive',
                  follow_unit = { key = function() return '100234' end },
                  in_place = true
                }
              end, 1002)
            }
          }
        end
      }
    end
  }
}
local fake_groupai = managers.groupai

lines = {}
Iter_TestHarness.dump_bots()
local bot_text = table.concat(lines, '\n')
assert(bot_text:find('bot key=1 id=1001 logic=travel obj=? action=walk coarse=3/2 wait=none carry=downed_x stay=yes@5,6,0 kpr=none pos=100,200,0 walk_forbidden=no', 1, true), 'bot line wrong: ' .. bot_text)
assert(bot_text:find('bot key=2 id=1002 logic=travel obj=revive,follow=100234,in_place', 1, true), 'bot objective flags wrong: ' .. bot_text)
assert(bot_text:find('bots total=2', 1, true), 'bots summary wrong: ' .. bot_text)

-- !iter cops: only cops holding a coarse path without advancing, or waiting.
local function fake_cop(key, my_data)
  return {
    _alive = true,
    key = function() return key end,
    id = function() return 2001 end,
    position = function() return { x = 1, y = 2, z = 0 } end,
    brain = function()
      return {
        _current_logic_name = 'travel',
        objective = function()
          return { type = 'advance' }
        end,
        _logic_data = { internal_data = my_data }
      }
    end,
    movement = function()
      return { chk_action_forbidden = function() return false end }
    end
  }
end

managers = {
  enemy = {
    all_enemies = function()
      return {
        ['copA'] = {
          unit = fake_cop('copA', {
            coarse_path = { {}, {} },
            coarse_path_index = 1,
            advancing = { itr_wait_for_navlink = 'linkA', itr_wait_for_navlink_availability_t = 90 }
          })
        },
        ['copB'] = {
          unit = fake_cop('copB', {
            coarse_path = { {}, {} },
            coarse_path_index = 2,
            advancing = { _action_desc = { type = 'walk' } }
          })
        },
        ['copC'] = { unit = fake_cop('copC', {}) }
      }
    end
  }
}

lines = {}
Iter_TestHarness.dump_cops()
local cop_text = table.concat(lines, '\n')
assert(cop_text:find('cop key=copA id=2001 logic=travel obj=advance,follow=nil action=none coarse=2/1', 1, true), 'waiting cop line wrong: ' .. cop_text)
assert(cop_text:find('wait=iter=linkA,since=90.0,age=15.0', 1, true), 'cop wait state wrong: ' .. cop_text)
assert(cop_text:find('cop key=copB', 1, true) == nil, 'advancing cop should not be listed: ' .. cop_text)
assert(cop_text:find('cop key=copC', 1, true) == nil, 'idle cop without coarse path should not be listed: ' .. cop_text)
assert(cop_text:find('cops total=3 waiting=1', 1, true), 'cops summary wrong: ' .. cop_text)

-- !iter diag: toggle + automatic tick (link, bot, cop lines and throttling).
lines = {}
Iter_TestHarness.diag_toggle({ 'off' })
assert(table.concat(lines, '\n'):find('diag: off', 1, true), 'diag off status wrong')
assert(Iter_TestHarness.diag_enabled == false, 'diag off did not disable')

lines = {}
Iter_TestHarness.diag_toggle({})
assert(table.concat(lines, '\n'):find('diag: off', 1, true), 'bare diag status wrong')

lines = {}
Iter_TestHarness.diag_toggle({ 'on' })
assert(Iter_TestHarness.diag_enabled == true, 'diag on did not enable')

local fake_enemies = managers.enemy
managers.navigation = fake_link_nav
managers.enemy = fake_enemies
managers.groupai = fake_groupai
Iter_TestHarness.diag_last_t = nil
Iter_TestHarness.diag_link_log = {}
Iter_TestHarness.diag_bot_state = {}
Iter_TestHarness.diag_cop_log = {}

lines = {}
Iter_TestHarness.diag_tick(200)
local diag_text = table.concat(lines, '\n')
assert(diag_text:find('diag link key=linkA action=e_nl_up_stairs from=63 to=48 interval=2.00 queue=2 reserved=100234 wait=100.0', 1, true), 'diag link line wrong: ' .. diag_text)
assert(diag_text:find('diag cop key=copA', 1, true), 'diag waiting cop missing: ' .. diag_text)

lines = {}
Iter_TestHarness.diag_tick(201)
assert(#lines == 0, 'diag tick should throttle to 2 s')

lines = {}
Iter_TestHarness.diag_tick(210)
diag_text = table.concat(lines, '\n')
assert(diag_text:find('diag bot key=1 id=1001 logic=travel obj=? action=walk coarse=3/2 wait=none carry=downed_x stay=yes@5,6,0 kpr=none moved=0 pos=100,200,0', 1, true), 'diag stuck bot line wrong: ' .. diag_text)
assert(diag_text:find('moved=0 pos=100,200,0', 1, true), 'diag bot moved field wrong: ' .. diag_text)

-- Diagnostic field access must survive a bare manager (no brains/movements).
managers = { navigation = fake_link_nav }
Iter_TestHarness.diag_link_log = {}
Iter_TestHarness.diag_bot_state = {}
Iter_TestHarness.diag_cop_log = {}
Iter_TestHarness.diag_last_t = nil
lines = {}
local diag_ok, diag_err = pcall(Iter_TestHarness.diag_tick, 300)
assert(diag_ok, 'diag tick with no group AI must not error: ' .. tostring(diag_err))
diag_ok, diag_err = pcall(Iter_TestHarness.dump_bots)
assert(diag_ok and table.concat(lines, '\n'):find('bots total=0', 1, true) ~= nil, 'dump_bots without group AI must report zero: ' .. tostring(diag_err))
diag_ok, diag_err = pcall(Iter_TestHarness.dump_cops)
assert(diag_ok and table.concat(lines, '\n'):find('cops total=0 waiting=0', 1, true) ~= nil, 'dump_cops without enemies must report zero: ' .. tostring(diag_err))

print('ok: Iter test-harness parser')
