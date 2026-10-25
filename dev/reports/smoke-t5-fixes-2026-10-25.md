# Iter log scan

File: `C:\Program Files (x86)\Steam\steamapps\common\PAYDAY 2\mods\logs\2026_10_25_log.txt`

- setup: 6
- FATAL: 0
- Lua errors: 1
- Iter errors: 0
- harness: 3
- harness errors: 0
- nav events: 16 (boot=4 heist=1 navdata=1 navlink=4 patch=1 proxy=1 summary=4)
- result: OK

## Card

Result: PASS

| check | actual | expected | result |
|---|---:|---:|---|
| setup | true | true | PASS |
| fatal | 0 | 0 | PASS |
| iterErrors | 0 | 0 | PASS |
| fallback | 0 | 0 | PASS |
| summary.search_ok | 193 | >0 | PASS |
| summary.path_extend_ok | 85 | >0 | PASS |

## Iter setup

- 56: `06:04:22 AM Lua: [INFO] [BLT] Setting up mod 'Iter'`
- 128: `06:04:22 AM Lua: [INFO] [BLT] Setting up mod 'Iter'`
- 214: `06:04:25 AM Lua: [INFO] [BLT] Setting up mod 'Iter'`
- 367: `06:05:07 AM Lua: [INFO] [BLT] Setting up mod 'Iter'`
- 440: `06:05:08 AM Lua: [INFO] [BLT] Setting up mod 'Iter'`
- 512: `06:05:08 AM Lua: [INFO] [BLT] Setting up mod 'Iter'`

## FATAL

None.

## Iter errors

None.

## Other Lua errors

- 319: `06:04:33 AM Log:  (D:\a\PAYDAY2-SuperBLT\PAYDAY2-SuperBLT\src\InitiateState.cpp:98) mods/BeardLib/Modules/Utils/ModAssetsModule.lua:156: attempt to compare number with nil`

## Harness output

- 190: `06:04:25 AM Lua: [ITER-TEST] harness loaded (p7auto + navpath)`
- 573: `06:05:08 AM Lua: [ITER-TEST] harness loaded (p7auto + navpath)`
- 599: `06:06:28 AM Lua: [ITER-TEST] ai total=25 travelling=14 coarse_path=18 direct_to_pos=0 path_ahead=0 pending_path_ahead=1 extend(ok=32 skip=2)`

## Harness errors

None.

