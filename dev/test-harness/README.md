# ITER test harness (dev-only)

Not shipped. Used for 2–3 minute smoke tests during the 248.2 port.

## Install

1. Package or export the mod build to `dist/ITER` (see `dev/build.ps1`).
2. Copy `dist/ITER` into `…\PAYDAY 2\mods\ITER`.
3. Copy this folder into `…\PAYDAY 2\mods\ITER-TestHarness`.
4. Launch the game, load `Jewelry Store` on Normal.

## Commands

Type in chat:

| Command | Effect |
|---|---|
| `!iter nav` | Log nav segment count, missing neighbours, door types, cover count. |
| `!iter cover` | Validate `_covers` and run `find_cover_near_pos_1` from the player. |
| `!iter alarm` | Force `on_police_called` + `on_police_weapons_hot` + `set_assault_mode(true)`. |
| `!iter assault` | `set_assault_mode(true)` only; weaker than `alarm`. |
| `!iter state` | Dump group AI state: server, police called, weapons hot, assault, scheduler, groups, spawning, cops. |
| `!iter gen probe [nsegs] [ncands]` | Dry-run Nav-B cover generation on `nsegs` (default 1) segments, up to `ncands` (default 8) candidates each; logs the funnel, ships nothing. |
| `!iter gen run [nsegs] [ncands]` | Schedule the real Nav-B generation pass (defaults: whole map, 8 candidates/segment); funnel line when it finishes. |
| `!iter setting <key> <value>` | Change a ITER setting at runtime. |
| `!iter dump` | Log ITER settings, cached-nav size, cover count. |
| `!iter help` | List commands. |

All output is prefixed `[ITER-TEST]` so `dev/tools/log-scan.mjs` can extract it.

## 2-minute smoke script

1. Load `Jewelry Store` Normal.
2. `!iter nav` → expect `segments>0`, `missing_neighbours=0`, door vectors, `covers>0`.
3. `!iter cover` → expect either a cover or a clean “no cover found”, never a Lua error.
4. Shoot once to trigger the alarm; `!iter alarm`, then `!iter state`.
5. Wait ~45 seconds; `!iter state` again. Watch cop pathing and cover use.
6. Quit; send the latest `mods\logs\*.txt`.

## Static test

```
tools\luajit\luajit.exe dev/test-harness/test/test_commands.lua
```
