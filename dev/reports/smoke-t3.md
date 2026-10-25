# Iter log scan

File: `C:\Program Files (x86)\Steam\steamapps\common\PAYDAY 2\mods\logs\2026_10_24_log.txt`

- setup: 15
- FATAL: 0
- Lua errors: 3
- Iter errors: 0
- harness: 48
- harness errors: 0
- nav events: 16 (boot=10 heist=2 navdata=2 proxy=2)
- result: OK

## Card

Result: FAIL

| check | actual | expected | result |
|---|---:|---:|---|
| setup | true | true | PASS |
| fatal | 0 | 0 | PASS |
| iterErrors | 0 | 0 | PASS |
| fallback | 0 | 0 | PASS |
| navlink.elements | undefined | >0 | FAIL |
| summary.navlink_registered | undefined | >0 | FAIL |
| summary.err | undefined | 0 | FAIL |

## Iter setup

- 56: `01:17:28 PM Lua: [INFO] [BLT] Setting up mod 'Iter Lite'`
- 128: `01:17:28 PM Lua: [INFO] [BLT] Setting up mod 'Iter Lite'`
- 213: `01:17:29 PM Lua: [INFO] [BLT] Setting up mod 'Iter Lite'`
- 361: `01:19:27 PM Lua: [INFO] [BLT] Setting up mod 'Iter Lite'`
- 434: `01:19:27 PM Lua: [INFO] [BLT] Setting up mod 'Iter Lite'`
- 506: `01:19:28 PM Lua: [INFO] [BLT] Setting up mod 'Iter Lite'`
- 638: `01:20:07 PM Lua: [INFO] [BLT] Setting up mod 'Iter Lite'`
- 711: `01:20:07 PM Lua: [INFO] [BLT] Setting up mod 'Iter Lite'`
- 783: `01:20:07 PM Lua: [INFO] [BLT] Setting up mod 'Iter Lite'`
- 923: `01:20:24 PM Lua: [INFO] [BLT] Setting up mod 'Iter Lite'`
- 996: `01:20:25 PM Lua: [INFO] [BLT] Setting up mod 'Iter Lite'`
- 1068: `01:20:25 PM Lua: [INFO] [BLT] Setting up mod 'Iter Lite'`
- 1192: `01:21:05 PM Lua: [INFO] [BLT] Setting up mod 'Iter Lite'`
- 1265: `01:21:05 PM Lua: [INFO] [BLT] Setting up mod 'Iter Lite'`
- 1337: `01:21:05 PM Lua: [INFO] [BLT] Setting up mod 'Iter Lite'`

## FATAL

None.

## Iter errors

None.

## Other Lua errors

- 318: `01:17:35 PM Log:  (D:\a\PAYDAY2-SuperBLT\PAYDAY2-SuperBLT\src\InitiateState.cpp:98) mods/BeardLib/Modules/Utils/ModAssetsModule.lua:156: attempt to compare number with nil`
- 882: `01:20:10 PM Log:  (D:\a\PAYDAY2-SuperBLT\PAYDAY2-SuperBLT\src\InitiateState.cpp:98) mods/BeardLib/Modules/Utils/ModAssetsModule.lua:156: attempt to compare number with nil`
- 1437: `01:21:08 PM Log:  (D:\a\PAYDAY2-SuperBLT\PAYDAY2-SuperBLT\src\InitiateState.cpp:98) mods/BeardLib/Modules/Utils/ModAssetsModule.lua:156: attempt to compare number with nil`

## Harness output

- 589: `01:19:39 PM Lua: [ITER-TEST] alarm: on_police_called + on_police_weapons_hot + set_assault_mode`
- 590: `01:19:54 PM Lua: [ITER-TEST] link key=userdata: 0x000009cf action=e_nl_up_1_down_5m interval=2.00 queue=0 reserved=none`
- 591: `01:19:54 PM Lua: [ITER-TEST] link key=userdata: 0x000009d0 action=e_nl_up_1_down_5m interval=2.00 queue=0 reserved=none`
- 592: `01:19:54 PM Lua: [ITER-TEST] link key=userdata: 0x000009d1 action=e_nl_up_1_down_5m interval=2.00 queue=0 reserved=none`
- 593: `01:19:54 PM Lua: [ITER-TEST] link key=userdata: 0x000009d2 action=e_nl_up_1_down_5m interval=2.00 queue=0 reserved=none`
- 594: `01:19:54 PM Lua: [ITER-TEST] link key=userdata: 0x000009d3 action=e_nl_up_1_down_5m interval=2.00 queue=0 reserved=none`
- 595: `01:19:54 PM Lua: [ITER-TEST] link key=userdata: 0x000009d4 action=e_nl_up_1_down_5m interval=2.00 queue=0 reserved=none`
- 596: `01:19:54 PM Lua: [ITER-TEST] link key=userdata: 0x000009d5 action=e_nl_up_1_down_5m interval=2.00 queue=0 reserved=none`
- 597: `01:19:54 PM Lua: [ITER-TEST] link key=userdata: 0x000009d6 action=e_nl_up_1_down_5m interval=2.00 queue=0 reserved=none`
- 598: `01:19:54 PM Lua: [ITER-TEST] link key=userdata: 0x000009d7 action=e_nl_up_1_down_5m interval=2.00 queue=0 reserved=none`
- 599: `01:19:54 PM Lua: [ITER-TEST] link key=userdata: 0x000009d8 action=e_nl_climb_over_2m interval=2.00 queue=0 reserved=none`
- 600: `01:19:54 PM Lua: [ITER-TEST] link key=userdata: 0x000009d9 action=e_nl_up_1_down_5m interval=2.00 queue=0 reserved=none`
- 601: `01:19:54 PM Lua: [ITER-TEST] link key=userdata: 0x000009da action=e_nl_up_1_down_5m interval=2.00 queue=0 reserved=none`
- 602: `01:19:54 PM Lua: [ITER-TEST] link key=userdata: 0x000009bf action=e_nl_up_1_down_5m interval=2.00 queue=0 reserved=none`
- 603: `01:19:54 PM Lua: [ITER-TEST] link key=userdata: 0x000009c0 action=e_nl_up_1_down_5m interval=2.00 queue=0 reserved=none`
- 604: `01:19:54 PM Lua: [ITER-TEST] link key=userdata: 0x000009c1 action=e_nl_up_1_down_5m interval=2.00 queue=0 reserved=none`
- 605: `01:19:54 PM Lua: [ITER-TEST] link key=userdata: 0x000009c2 action=e_nl_up_1_down_5m interval=2.00 queue=0 reserved=none`
- 606: `01:19:54 PM Lua: [ITER-TEST] link key=userdata: 0x000009c3 action=e_nl_up_1_down_5m interval=2.00 queue=0 reserved=none`
- 607: `01:19:54 PM Lua: [ITER-TEST] link key=userdata: 0x000009c4 action=e_nl_up_1_down_5m interval=2.00 queue=0 reserved=none`
- 608: `01:19:54 PM Lua: [ITER-TEST] link key=userdata: 0x000009c5 action=e_nl_up_1_down_5m interval=2.00 queue=0 reserved=none`
- 609: `01:19:54 PM Lua: [ITER-TEST] link key=userdata: 0x000009c6 action=e_nl_up_1_down_5m interval=2.00 queue=0 reserved=none`
- 610: `01:19:54 PM Lua: [ITER-TEST] links total=133 queued=0 shown=20`
- 611: `01:19:57 PM Lua: [ITER-TEST] ai total=38 travelling=0 coarse_path=0 direct_to_pos=0 path_ahead=0 pending_path_ahead=0`
- 612: `01:20:00 PM Lua: [ITER-TEST] path player_seg=51 pos=Vector3(-475, 675, -18.7126) action=none points= next_navlink=no`
- 1142: `01:20:37 PM Lua: [ITER-TEST] alarm: on_police_called + on_police_weapons_hot + set_assault_mode`
- 1144: `01:20:54 PM Lua: [ITER-TEST] link key=userdata: 0x0000176f action=e_nl_up_2m_down_1m interval=2.00 queue=0 reserved=none`
- 1145: `01:20:54 PM Lua: [ITER-TEST] link key=userdata: 0x00001770 action=e_nl_up_2_2_down_1m interval=2.00 queue=0 reserved=none`
- 1146: `01:20:54 PM Lua: [ITER-TEST] link key=userdata: 0x00001771 action=e_nl_up_0_5m_dwn_9m interval=2.00 queue=0 reserved=none`
- 1147: `01:20:54 PM Lua: [ITER-TEST] link key=userdata: 0x00001772 action=e_nl_up_0_5m_dwn_9m interval=2.00 queue=0 reserved=none`
- 1148: `01:20:54 PM Lua: [ITER-TEST] link key=userdata: 0x00001773 action=e_nl_down_4m_jump interval=1.00 queue=0 reserved=none`
- 1149: `01:20:54 PM Lua: [ITER-TEST] link key=userdata: 0x00001774 action=e_nl_down_4m_jump interval=1.00 queue=0 reserved=none`
- 1150: `01:20:54 PM Lua: [ITER-TEST] link key=userdata: 0x00001775 action=e_nl_climb_over_3m interval=2.00 queue=0 reserved=none`
- 1151: `01:20:54 PM Lua: [ITER-TEST] link key=userdata: 0x0000175f action=e_nl_down_2m interval=1.50 queue=0 reserved=none`
- 1152: `01:20:54 PM Lua: [ITER-TEST] link key=userdata: 0x00001760 action=e_nl_down_2m interval=1.50 queue=0 reserved=none`
- 1153: `01:20:54 PM Lua: [ITER-TEST] link key=userdata: 0x00001761 action=e_nl_down_2m interval=1.50 queue=0 reserved=none`
- 1154: `01:20:54 PM Lua: [ITER-TEST] link key=userdata: 0x00001762 action=e_nl_down_2m interval=1.50 queue=0 reserved=none`
- 1155: `01:20:54 PM Lua: [ITER-TEST] link key=userdata: 0x00001763 action=e_nl_down_2m interval=1.50 queue=0 reserved=none`
- 1156: `01:20:54 PM Lua: [ITER-TEST] link key=userdata: 0x00001764 action=e_nl_climb_over_3m interval=2.00 queue=0 reserved=none`
- 1157: `01:20:54 PM Lua: [ITER-TEST] link key=userdata: 0x00001765 action=e_nl_climb_over_3m interval=2.00 queue=0 reserved=none`
- 1158: `01:20:54 PM Lua: [ITER-TEST] link key=userdata: 0x00001766 action=e_nl_climb_over_3m interval=2.00 queue=0 reserved=none`
- 1159: `01:20:54 PM Lua: [ITER-TEST] link key=userdata: 0x00001767 action=e_nl_climb_over_3m interval=2.00 queue=0 reserved=none`
- 1160: `01:20:54 PM Lua: [ITER-TEST] link key=userdata: 0x00001768 action=e_nl_climb_over_3m interval=2.00 queue=0 reserved=none`
- 1161: `01:20:54 PM Lua: [ITER-TEST] link key=userdata: 0x00001769 action=e_nl_climb_over_3m interval=2.00 queue=0 reserved=none`
- 1162: `01:20:54 PM Lua: [ITER-TEST] link key=userdata: 0x0000176a action=e_nl_climb_over_3m interval=2.00 queue=0 reserved=none`
- 1163: `01:20:54 PM Lua: [ITER-TEST] link key=userdata: 0x0000176b action=e_nl_climb_over_3m interval=2.00 queue=0 reserved=none`
- 1164: `01:20:54 PM Lua: [ITER-TEST] links total=79 queued=0 shown=20`
- 1165: `01:20:57 PM Lua: [ITER-TEST] ai total=34 travelling=0 coarse_path=0 direct_to_pos=0 path_ahead=0 pending_path_ahead=0`
- 1166: `01:20:59 PM Lua: [ITER-TEST] path player_seg=25 pos=Vector3(385, -1440, 51.1) action=none points= next_navlink=no`

## Harness errors

None.

