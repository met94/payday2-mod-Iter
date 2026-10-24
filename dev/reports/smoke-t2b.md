# Iter log scan

File: `C:\Program Files (x86)\Steam\steamapps\common\PAYDAY 2\mods\logs\2026_10_24_log.txt`

- setup: 15
- FATAL: 0
- Lua errors: 3
- Iter errors: 0
- harness: 4
- harness errors: 0
- nav events: 18 (boot=10 heist=2 navdata=2 probe=2 proxy=2)
- result: OK

## Card

Result: FAIL

| check | actual | expected | result |
|---|---:|---:|---|
| setup | true | true | PASS |
| fatal | 0 | 0 | PASS |
| iterErrors | 0 | 0 | PASS |
| fallback | 0 | 0 | PASS |
| proxy.segments | 268 | >0 | PASS |
| proxy.ms | 0 | <2000 | PASS |
| probe.pairs | 58 | >0 | PASS |
| probe.search_ok | 33 | >0 | PASS |
| probe.search_fail | 25 | <=6 | FAIL |
| probe.stream_ok | 33 | >0 | PASS |
| probe.stream_fail | 0 | 0 | PASS |

## Iter setup

- 56: `01:08:35 PM Lua: [INFO] [BLT] Setting up mod 'Iter Lite'`
- 128: `01:08:35 PM Lua: [INFO] [BLT] Setting up mod 'Iter Lite'`
- 213: `01:08:35 PM Lua: [INFO] [BLT] Setting up mod 'Iter Lite'`
- 358: `01:08:56 PM Lua: [INFO] [BLT] Setting up mod 'Iter Lite'`
- 431: `01:08:56 PM Lua: [INFO] [BLT] Setting up mod 'Iter Lite'`
- 503: `01:08:56 PM Lua: [INFO] [BLT] Setting up mod 'Iter Lite'`
- 604: `01:09:43 PM Lua: [INFO] [BLT] Setting up mod 'Iter Lite'`
- 677: `01:09:44 PM Lua: [INFO] [BLT] Setting up mod 'Iter Lite'`
- 749: `01:09:44 PM Lua: [INFO] [BLT] Setting up mod 'Iter Lite'`
- 887: `01:09:55 PM Lua: [INFO] [BLT] Setting up mod 'Iter Lite'`
- 960: `01:09:56 PM Lua: [INFO] [BLT] Setting up mod 'Iter Lite'`
- 1032: `01:09:56 PM Lua: [INFO] [BLT] Setting up mod 'Iter Lite'`
- 1152: `01:10:28 PM Lua: [INFO] [BLT] Setting up mod 'Iter Lite'`
- 1225: `01:10:28 PM Lua: [INFO] [BLT] Setting up mod 'Iter Lite'`
- 1297: `01:10:29 PM Lua: [INFO] [BLT] Setting up mod 'Iter Lite'`

## FATAL

None.

## Iter errors

None.

## Other Lua errors

- 317: `01:08:42 PM Log:  (D:\a\PAYDAY2-SuperBLT\PAYDAY2-SuperBLT\src\InitiateState.cpp:98) mods/BeardLib/Modules/Utils/ModAssetsModule.lua:156: attempt to compare number with nil`
- 837: `01:09:47 PM Log:  (D:\a\PAYDAY2-SuperBLT\PAYDAY2-SuperBLT\src\InitiateState.cpp:98) mods/BeardLib/Modules/Utils/ModAssetsModule.lua:156: attempt to compare number with nil`
- 1397: `01:10:32 PM Log:  (D:\a\PAYDAY2-SuperBLT\PAYDAY2-SuperBLT\src\InitiateState.cpp:98) mods/BeardLib/Modules/Utils/ModAssetsModule.lua:156: attempt to compare number with nil`

## Harness output

- 577: `01:09:35 PM Lua: [ITER-TEST] probe pairs=28 search(ok=21 fail=7) streamline(ok=21 fail=0) points(raw=151 stream=172) avg_len(raw=6861.7 stream=6393.5)`
- 579: `01:09:38 PM Lua: [ITER-TEST] nav segments=160 keys(string=160 numeric=0) missing_neighbours=0 doors(vector=896 numeric=0 links=71 unknown=0) shim(rooms=3873 room_doors=6504 vis_groups=160) proxies(segments=160 choke=88 in=26 out=184) navlink_elements=71 covers=1519 bad_covers=0`
- 1125: `01:10:18 PM Lua: [ITER-TEST] probe pairs=30 search(ok=12 fail=18) streamline(ok=12 fail=0) points(raw=64 stream=76) avg_len(raw=3325.9 stream=2939.5)`
- 1127: `01:10:20 PM Lua: [ITER-TEST] nav segments=108 keys(string=108 numeric=0) missing_neighbours=0 doors(vector=594 numeric=0 links=34 unknown=0) shim(rooms=2037 room_doors=3283 vis_groups=108) proxies(segments=108 choke=74 in=30 out=170) navlink_elements=34 covers=957 bad_covers=0`

## Harness errors

None.

