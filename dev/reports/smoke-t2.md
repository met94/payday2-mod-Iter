# Iter log scan

File: `C:\Program Files (x86)\Steam\steamapps\common\PAYDAY 2\mods\logs\2026_10_24_log.txt`

- setup: 27
- FATAL: 0
- Lua errors: 5
- Iter errors: 0
- harness: 2
- harness errors: 0
- nav events: 29 (boot=18 heist=4 navdata=4 probe=2 proxy=1)
- result: OK

## Card

Result: PASS

| check | actual | expected | result |
|---|---:|---:|---|
| setup | true | true | PASS |
| fatal | 0 | 0 | PASS |
| iterErrors | 0 | 0 | PASS |
| fallback | 0 | 0 | PASS |
| probe.pairs | 38 | >0 | PASS |
| probe.search_ok | 37 | >0 | PASS |
| probe.search_fail | 1 | <=2 | PASS |
| probe.stream_ok | 37 | >0 | PASS |
| probe.stream_fail | 0 | 0 | PASS |

## Iter setup

- 57: `01:01:44 PM Lua: [INFO] [BLT] Setting up mod 'Iter Lite'`
- 129: `01:01:44 PM Lua: [INFO] [BLT] Setting up mod 'Iter Lite'`
- 214: `01:01:45 PM Lua: [INFO] [BLT] Setting up mod 'Iter Lite'`
- 361: `01:02:24 PM Lua: [INFO] [BLT] Setting up mod 'Iter Lite'`
- 434: `01:02:25 PM Lua: [INFO] [BLT] Setting up mod 'Iter Lite'`
- 506: `01:02:25 PM Lua: [INFO] [BLT] Setting up mod 'Iter Lite'`
- 602: `01:03:03 PM Lua: [INFO] [BLT] Setting up mod 'Iter Lite'`
- 675: `01:03:04 PM Lua: [INFO] [BLT] Setting up mod 'Iter Lite'`
- 747: `01:03:04 PM Lua: [INFO] [BLT] Setting up mod 'Iter Lite'`
- 885: `01:03:19 PM Lua: [INFO] [BLT] Setting up mod 'Iter Lite'`
- 958: `01:03:19 PM Lua: [INFO] [BLT] Setting up mod 'Iter Lite'`
- 1030: `01:03:19 PM Lua: [INFO] [BLT] Setting up mod 'Iter Lite'`
- 1146: `01:03:50 PM Lua: [INFO] [BLT] Setting up mod 'Iter Lite'`
- 1219: `01:03:50 PM Lua: [INFO] [BLT] Setting up mod 'Iter Lite'`
- 1291: `01:03:50 PM Lua: [INFO] [BLT] Setting up mod 'Iter Lite'`
- 1429: `01:04:04 PM Lua: [INFO] [BLT] Setting up mod 'Iter Lite'`
- 1502: `01:04:04 PM Lua: [INFO] [BLT] Setting up mod 'Iter Lite'`
- 1574: `01:04:04 PM Lua: [INFO] [BLT] Setting up mod 'Iter Lite'`
- 1672: `01:05:02 PM Lua: [INFO] [BLT] Setting up mod 'Iter Lite'`
- 1745: `01:05:02 PM Lua: [INFO] [BLT] Setting up mod 'Iter Lite'`
- 1817: `01:05:03 PM Lua: [INFO] [BLT] Setting up mod 'Iter Lite'`
- 1956: `01:05:24 PM Lua: [INFO] [BLT] Setting up mod 'Iter Lite'`
- 2029: `01:05:24 PM Lua: [INFO] [BLT] Setting up mod 'Iter Lite'`
- 2101: `01:05:24 PM Lua: [INFO] [BLT] Setting up mod 'Iter Lite'`
- 2203: `01:06:06 PM Lua: [INFO] [BLT] Setting up mod 'Iter Lite'`
- 2276: `01:06:07 PM Lua: [INFO] [BLT] Setting up mod 'Iter Lite'`
- 2348: `01:06:07 PM Lua: [INFO] [BLT] Setting up mod 'Iter Lite'`

## FATAL

None.

## Iter errors

None.

## Other Lua errors

- 306: `01:01:53 PM Log:  (D:\a\PAYDAY2-SuperBLT\PAYDAY2-SuperBLT\src\InitiateState.cpp:98) mods/BeardLib/Modules/Utils/ModAssetsModule.lua:156: attempt to compare number with nil`
- 842: `01:03:07 PM Log:  (D:\a\PAYDAY2-SuperBLT\PAYDAY2-SuperBLT\src\InitiateState.cpp:98) mods/BeardLib/Modules/Utils/ModAssetsModule.lua:156: attempt to compare number with nil`
- 1391: `01:03:53 PM Log:  (D:\a\PAYDAY2-SuperBLT\PAYDAY2-SuperBLT\src\InitiateState.cpp:98) mods/BeardLib/Modules/Utils/ModAssetsModule.lua:156: attempt to compare number with nil`
- 1915: `01:05:06 PM Log:  (D:\a\PAYDAY2-SuperBLT\PAYDAY2-SuperBLT\src\InitiateState.cpp:98) mods/BeardLib/Modules/Utils/ModAssetsModule.lua:156: attempt to compare number with nil`
- 2448: `01:06:10 PM Log:  (D:\a\PAYDAY2-SuperBLT\PAYDAY2-SuperBLT\src\InitiateState.cpp:98) mods/BeardLib/Modules/Utils/ModAssetsModule.lua:156: attempt to compare number with nil`

## Harness output

- 2174: `01:05:46 PM Lua: [ITER-TEST] probe pairs=20 search(ok=19 fail=1) streamline(ok=19 fail=0) points(raw=106 stream=125) avg_len(raw=4285.8 stream=3590.4)`
- 2177: `01:06:00 PM Lua: [ITER-TEST] probe pairs=18 search(ok=18 fail=0) streamline(ok=18 fail=0) points(raw=104 stream=122) avg_len(raw=5472.7 stream=4762.4)`

## Harness errors

None.

