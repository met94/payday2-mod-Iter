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
| `!iter navquad <id...>` | Quad borders (world units), heights, vis group and owning segment. |
| `!iter navpath <from> <to>` | Coarse search between two segments; logs level, live `map_patches`, ok/steps/length, direct door count, visibility flags, segment ids. |
| `!iter p7` | Force the P7 dump for the current level (same output as the auto run). |
| `!iter p7 auto on\|off` | Enable/disable the auto P7 dump on heist start. Default: on for the five pending levels. |
| `!iter force <level_id>` | Host-only level jump (uses the tweak-data world name). Used for `escape_street`, which is not in Crime.net. |
| `!iter probe [n]` | Random coarse-search + streamline probe. |
| `!iter path` | Player walk action and next nav-link. |
| `!iter ai` | Travelling cops, coarse paths, direct-to-pos, path extender counters. |
| `!iter bots` | Every team AI criminal: logic, objective (follow/assist/in_place), advancing action, coarse path `len/idx`, nav-link wait, carried bag, hold position, kpr, position, walk forbidden. |
| `!iter cops` | Cops that hold a coarse path but are not advancing, or that wait at a nav link; longest wait first, up to 25. |
| `!iter links` | Nav-link elements: action, `from`/`to` segment, interval, queue, reserved unit, queue wait and positions. Queued/reserved links first (up to 40), then 10 idle ones. |
| `!iter diag [on\|off]` | Automatic `[ITER-TEST] diag …` logging on/off (default on); bare `!iter diag` prints the state. |
| `!iter alarm` | Force police called + weapons hot + assault mode. |
| `!iter assault` | `set_assault_mode(true)` only. |
| `!iter state` | Group-AI state summary. |
| `!iter setting <key> <value>` | Change an Iter setting at runtime. |
| `!iter dump` | Iter settings and nav summary. |
| `!iter reset` | Clear nav counters. |
| `!iter help` | List commands. |

All output is prefixed `[ITER-TEST]`; `dev/tools/log-scan.mjs` extracts it.

## Diagnostics: queued cops and stuck bots

The harness logs automatically (no command needed) from the existing deferred
`NavigationManager:update` posthook, throttled to one pass every 2 s. Lines are
`[ITER-TEST] diag <link|bot|cop> …`; `!iter diag off` silences them, `!iter diag
on` restores them.

- `diag link` — one line per nav link with `queue > 0` or a live reservation,
  once per link per 5 s, only when `wait >= 2` s or `queue >= 2`. Fields:
  `action from to interval queue reserved wait pos`.
- `diag bot` — once per bot per 10 s when it has not moved more than 50 units
  in the last 5 s: `logic obj action coarse wait carry stay kpr moved pos`.
  This distinguishes "legitimately holding / reviving" (objective `revive` or
  `stop`, `stay=yes@…`, `carry=…`) from "stuck" (`logic=travel`, `coarse=…`,
  `action=none`, `wait=…`, `moved=0`).
- `diag cop` — once per waiting cop per 10 s: `logic obj action wait coarse pos`.
  It shows which nav link is queued, how long the cop has been waiting
  (`wait=iter=…,since=…,age=…`) and whether it still holds a coarse path.

### Counterfeit (`pal`): cops queuing upstairs

Play until cops pile up at the stairs/fence and do not enter the basement, then:

1. Type `!iter links` — the queued link is the first line. Note `action`,
   `from`/`to`, `queue`, `reserved` and `wait`; compare `search`/`pos` with the
   stairs you are watching.
2. Type `!iter cops` — the cops holding a coarse path without advancing are
   listed, longest wait first. `wait=none` on all of them means the queue is
   not the blocker (look at the objective/action instead).
3. Leave the auto `diag link` / `diag cop` lines to accumulate for a minute,
   then send the log. They show whether the same link stays reserved and
   whether the same cops keep the same coarse path.

Optional A/B: `!iter setting navlink_queue false` in the same heist, then bait
cops down again. Diagnostic only; do not ship with the queue off.

### Bots freezing until shouted at

When a bot stops following, before shouting:

1. `!iter bots` — every bot with logic, objective, advancing action, coarse
   path progress, nav-link wait, carried bag and hold state.
2. Wait ~10 s without shouting, then send the log. The `[ITER-TEST] diag bot`
   line for that bot repeats with `moved=0` while `action`/`obj` stay put.

What separates the cases:

- `obj=revive,follow=…` or `stay=yes@…` → holding/reviving on purpose.
- `carry=…` and `action=none` → bag-drop/hold logic, not a nav stall.
- `wait=lies=…` / `wait=iter=…` → blocked on a nav link (ties to `diag link`).
- `coarse=0/N` or `coarse=1/N` with `action=none` → pathfinding returned
  nothing useful; send the level and the previous commands.

Fields can be `?` when the active logic does not expose them: `obj` for logics
without `brain:objective()`, `kpr` unless Keepers exposes `kpr_mode`, `stay`
unless the movement has `_should_stay`. That is expected, not an error.

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
