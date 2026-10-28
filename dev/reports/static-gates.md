# Iter 248.2 full-nav static gates

Generated: 2026-10-28 11:21:15Z

## Node tool tests

Result: PASS

Γä╣ pass 98
Γä╣ fail 0
Γä╣ cancelled 0
Γä╣ skipped 0
Γä╣ todo 0
Γä╣ duration_ms 149.6801

## Test-harness parser

Result: PASS

ok: Iter test-harness parser

## Lua unit tests (offline)

Result: PASS

test_corecode.lua: PASS
corecode settings: 29 checks PASS
test_diag.lua: PASS
9 checks, diag gate test passed
test_harness_bot_obj.lua: PASS
11 checks, harness bot objective test passed
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
test_watch.lua: PASS
14 checks, watch channel test passed

## LuaJIT syntax (runtime files)

Result: PASS

Files: 22
Failures: 0

## Free identifiers (game-file locals)

Result: PASS

Files: 15
Findings: 0

## Function ledger

Result: PASS

unchanged dev/port-ledger.md
unchanged dev/reports/port-ledger.json
files=22 functions=117 errors=0 unhooked=7
MOD_EDIT_CLEAN=31 MOD_ONLY=70 MOD_EDIT_VANILLA_CHANGED=6 MOD_ONLY_HOOK=10

## API audit

Result: PASS

hooks=15/15 methods=11/11 errors=12 review=32 suppressed=12 allowUnused=0
Baseline errors: 12 (current: 12)
Unused allowlist entries: 0

