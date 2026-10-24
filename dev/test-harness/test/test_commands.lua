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

cmd = parse('!iter')
assert(cmd and cmd.command == 'help', 'bare !iter should map to help')

assert(parse('hello') == nil, 'non-command should return nil')
assert(parse('!other nav') == nil, 'other prefix should return nil')

Iter = {}
log = function() end
local ok, err = pcall(Iter_TestHarness.dump)
assert(ok, 'dump with nil settings should not error: ' .. tostring(err))

print('ok: Iter test-harness parser')
