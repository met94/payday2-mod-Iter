# Iter 248.2 full-nav static gates

Generated: 2026-10-24 12:20:39Z

## Node tool tests

Result: PASS

Γä╣ pass 47
Γä╣ fail 0
Γä╣ cancelled 0
Γä╣ skipped 0
Γä╣ todo 0
Γä╣ duration_ms 125.4954

## Test-harness parser

Result: PASS

ok: Iter test-harness parser

## Lua unit tests (offline)

Result: PASS

test_shim.lua: PASS
ok accepts_numeric_string_keys
ok clear_resets
ok rebuild_error_is_one_fallback
ok rebuilds_tables
ok rejects_missing_pieces
ok rejects_v6_only_data
ok respects_grid_size
ok survives_bad_optional_data
ok unowned_vis_group_and_missing_pos
ok vanilla_accessor_uses_shim
137 checks, 10 tests passed

## LuaJIT syntax (runtime files)

Result: PASS

Files: 21
Failures: 0

## Free identifiers (game-file locals)

Result: PASS

Files: 17
Findings: 0

## Function ledger

Result: PASS

files=21 functions=98 errors=0 unhooked=4
MOD_EDIT_CLEAN=33 MOD_ONLY=54 MOD_EDIT_VANILLA_CHANGED=7 MOD_ONLY_HOOK=3 VANISHED_IN_NEW=1
wrote D:\Programowanie\payday\2\v2\.worktrees\Iter-iter-full-nav\dev\port-ledger.md
wrote D:\Programowanie\payday\2\v2\.worktrees\Iter-iter-full-nav\dev\reports\port-ledger.json

## API audit

Result: PASS

hooks=17/17 methods=3/3 errors=11 review=32 suppressed=12 allowUnused=0
Baseline errors: 11 (current: 11)
Unused allowlist entries: 0

