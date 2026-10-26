# Iter menu options

Menu path: **Options → Mod Options → Iter**.

The release defaults match original Iter: navigation, path extender, map
patches and the idle cosmetic are on. The menu only exposes the player-facing
switches; the subsystem flags live in the settings file for troubleshooting.

## Player options

### Improve NPC pathing (`nav_overlay`)

Master switch for the restored r200 navigation core (v6 geometry shim,
streamline, coarse search, nav-link queue, AI wrappers, direct-to-pos, path
extender).

- Default: **ON**.
- Off: the nav core is disabled; vanilla navigation.
- Game restart required (the master flag is read at load; the other
  toggles apply on the next heist load).

### Rebuild NavLinks (`rebuild_navlinks`)

The r200 SO nav-link vector rebuild.

- Default: **ON**.
- Takes effect on the next heist load.

### Map toggles (`map_change_<level>`)

One toggle per level, grouped after a divider. A toggle gates both the
nav-data block and the existing world/mission fix for that level. The
settings-only `map_patches` flag gates only the nav-data blocks; the
world/mission fixes still follow each `map_change_*` toggle.

- Default: **ON** for every level.
- Levels whose patch is dead at v6 log `skip_dead`; CRC mismatches log
  `mismatch` and skip safely.
- Current status: 21 clean blocks (22 level ids), 2 accepted losses (moon,
  peta), 1 dead nav block (`skm_mallcrasher`, but its skirmish door blocker
  and obstacle still apply), dinner/flat no nav ops but obstacle/mission
  fixes. The standard Vlad Mallcrasher is a different heist and is not
  patched.

## Settings-only (troubleshooting)

These are not in the menu. Edit `mods\saves\iter.txt` with the game closed,
then relaunch. Missing keys fall back to the defaults below.

| Setting | Default | Meaning |
|---|---|---|
| `nav_streamline` | `true` | choke-point proxies + path streamliner |
| `nav_search` | `true` | Iter weighted coarse search + cache |
| `nav_ai` | `true` | Iter AI wrappers |
| `navlink_queue` | `true` | nav-link intervals/queue/reservations/alternates |
| `path_extender` | `true` | live path appending + shortcut finder |
| `direct_to_pos` | `true` | whisper-mode straight-line objectives |
| `map_patches` | `true` | gates the nav-data blocks only; world/mission fixes follow `map_change_*` |
| `cop_idle_fix` | `true` | cosmetic idle animation variant |
| `debug_log` | `0` | debug events: 0 off, 1 on (2 reserved for verbose) |
| `error_log` | `true` | `[ITER-ERR]` lines; set `false` to silence caught errors |
| `watch_log` | `false` | `[ITER-WATCH]` digest every 60 s (troubleshooting recorder) |

Debug events are off by default. Set `debug_log=1` (or `2`) in `iter.txt` when
running the dev harness/cards; `!iter ai`/`p7` output then appears. Error
lines stay on unless `error_log=false`. None of these settings is in the menu.

To silence caught errors, add `"error_log": false` to
`mods\saves\iter.txt` (game closed) or use `!iter setting error_log false`.

### Watch channel (`watch_log`) and alarms

Two tiers, so a log from a normal session still contains evidence:

- **Alarms** are always on, but only fire on a hard failure and are heavily
  bounded: one line per alarm name per 60 s, 20 lines per level, then a single
  `evt=alarm_budget_exhausted` line. Alarm names:
  `navlink_queue_long` (more than 20 units waiting on one link),
  `navlink_wait_long` (a unit waiting more than 120 s),
  `navlink_stale_burst` (more than 5 stale reservations released in a minute).
  A healthy heist produces **zero** alarm lines.
- **Digest** is opt-in: `"watch_log": true` in `mods\saves\iter.txt` (or
  `!iter setting watch_log true`). With it on, Iter writes one header line at
  heist start, one `[ITER-WATCH] evt=digest` line per 60 s of play, and one
  final digest on heist end. Each carries the nav-link counters
  (`reserve_busy`, `reserve_ok`, stale/dead clears), search ok/fail, and the
  worst link of the last minute (action, segments, hold time, queue length,
  worst wait).

Why: the Counterfeit nav-link fault of 2026-10-26 (one cop held a link for
204.8 s) was only diagnosable because the dev test harness was installed. The
alarm tier makes a repeat of that visible in any player's log without moving
the diagnostics cost onto normal sessions, and the digest tier gives a
time series when someone is actively troubleshooting.


`streamline_path` is a legacy original-Iter key. It is republished after
`Iter:load()` as a **runtime mirror** of `nav_overlay and nav_streamline` for
Useful Bots, which reads it once, at load. `Iter:save()` recomputes the mirror
from the live switches and persists it (`true` when pathing is on, `false` when
it is off), so the in-memory value never goes stale and a downgrade to original
Iter keeps the effective setting. Manual edits to `streamline_path` in
`iter.txt` do not stick: `load()` drops the saved value and rebuilds the mirror
from `nav_overlay`/`nav_streamline`. Use those two keys instead.

An old file with `streamline_path=false` and no `nav_overlay` key is migrated to
`nav_overlay=false` so a player who disabled original Iter stays disabled.

Useful Bots only notices a menu change after a game restart: its guard runs at
load. Turning **Improve NPC pathing** off takes effect in Iter on the next heist
load, but Useful Bots keeps the decision it read at launch.

## Notes

- Changing a toggle takes effect on the next heist load.
- `map_patches` can be turned off in `iter.txt` to disable every map fix while
  keeping the nav core.
- The `!iter` chat commands are a dev harness and are not shipped.
