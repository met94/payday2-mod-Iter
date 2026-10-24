# ITER test harness (dev-only)

Not shipped. Used for the 248.2 nav-port cards and P7 data collection.

## Install

1. Build with `dev/build.ps1` (writes `dist/Iter`; never touches the game).
2. Copy `dist/Iter` into `…\PAYDAY 2\mods\Iter`.
3. Copy this folder into `…\PAYDAY 2\mods\test-harness`.
   Do not keep a second copy under another folder: two harness instances
   double every `!iter` reply.
4. Launch the game and load a heist.

## Commands

One command per chat line.

| Command | Effect |
|---|---|
| `!iter nav` | Segment/neighbour/door/shim/proxy/nav-link counts. |
| `!iter patch` | Last `evt=patch` status: level, result, helper stats. |
| `!iter navdump <seg>` | Segment position, neighbours with door kinds, vis groups and quad ids. |
| `!iter navdoors <a> <b>` | Doors that join two segments, with quad ids and positions. |
| `!iter navpath <from> <to>` | Coarse search between two segments; logs level, live `map_patches`, ok/steps/length, direct door count, segment ids. |
| `!iter p7` | Force the P7 dump for the current level (same output as the auto run). |
| `!iter p7 auto on\|off` | Enable/disable the auto P7 dump on heist start. Default: on for the five pending levels. |
| `!iter probe [n]` | Random coarse-search + streamline probe. |
| `!iter path` | Player walk action and next nav-link. |
| `!iter ai` | Travelling cops, coarse paths, direct-to-pos, path extender counters. |
| `!iter links` | Nav-link elements, intervals, queues, reservations. |
| `!iter alarm` | Force police called + weapons hot + assault mode. |
| `!iter assault` | `set_assault_mode(true)` only. |
| `!iter state` | Group-AI state summary. |
| `!iter setting <key> <value>` | Change an Iter setting at runtime. |
| `!iter dump` | Iter settings and nav summary. |
| `!iter reset` | Clear nav counters. |
| `!iter help` | List commands. |

All output is prefixed `[ITER-TEST]`; `dev/tools/log-scan.mjs` extracts it.

## P7 auto dump

The harness post-hooks `NavigationManager:on_simulation_started`. When the
level is one of `escape_street`, `jolly`, `moon`, `peta`, `mallcrasher`
(skirmish alias `skm_mallcrasher`) and `!iter p7 auto` is on, it logs one block
with:

- `p7auto level=… patches=on|off` and the patch status;
- `navdump` for the card's segments (quads, neighbours, door kinds);
- `navdoors` for the card's pairs;
- `navpath` for the add-link pair and, for `jolly`/`moon`/`peta`, one extra
  pair to another neighbour of the sealed segment.

No commands are needed: load the heist, wait for the block, quit. Reload with
`Dev: v6 map patches` toggled for the A/B baseline. `!iter p7` re-runs the
block in the current heist if the auto run was missed.

## Static test

```
tools\luajit\luajit.exe dev/test-harness/test/test_commands.lua
```
