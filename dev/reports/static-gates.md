# Iter 248.2 full-nav static gates

Generated: 2026-10-25 06:08:56Z

## Node tool tests

Result: PASS

Γä╣ pass 49
Γä╣ fail 0
Γä╣ cancelled 0
Γä╣ skipped 0
Γä╣ todo 0
Γä╣ duration_ms 134.0592

## Test-harness parser

Result: PASS

ok: Iter test-harness parser

## Lua unit tests (offline)

Result: PASS

test_nav_patches.lua: PASS
17 checks, P7 wrapper test passed
test_shim.lua: PASS
ok accepts_numeric_string_keys
ok clear_resets
ok door_by_pair_index
ok rebuild_error_is_one_fallback
ok rebuilds_tables
ok rejects_missing_pieces
ok rejects_v6_only_data
ok respects_grid_size
ok survives_bad_optional_data
ok unowned_vis_group_and_missing_pos
ok vanilla_accessor_uses_shim
144 checks, 11 tests passed

## LuaJIT syntax (runtime files)

Result: PASS

Files: 21
Failures: 0

## Free identifiers (game-file locals)

Result: PASS

Files: 14
Findings: 0

## Function ledger

Result: PASS

files=21 functions=103 errors=0 unhooked=7
MOD_EDIT_CLEAN=31 MOD_ONLY=59 MOD_EDIT_VANILLA_CHANGED=6 MOD_ONLY_HOOK=7
wrote D:\Programowanie\payday\2\v2\.worktrees\Iter-iter-full-nav\dev\port-ledger.md
wrote D:\Programowanie\payday\2\v2\.worktrees\Iter-iter-full-nav\dev\reports\port-ledger.json

## API audit

Result: PASS

hooks=14/14 methods=8/8 errors=12 review=32 suppressed=12 allowUnused=0
Baseline errors: 12 (current: 12)
Unused allowlist entries: 0

