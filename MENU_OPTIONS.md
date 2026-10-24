# Iter menu options

Menu path: **Options → Mod Options → Iter**.

This build is the r200 navigation port to PAYDAY 2 248.2 (Diesel 3). The
toggles below are **development gates**: each subsystem is off until its test
card passes. A normal player should leave the defaults alone.

## Core

### Dev: v6 navigation overlay (`nav_overlay`)

Rebuilds the v6 nav geometry (`_rooms`, `_room_doors`, `_visibility_groups`)
from the v5 load data and installs the guarded bookkeeping wrappers.

- Default: **ON** (required by every other nav feature).
- Off: Iter behaves like Iter Lite; no nav hooks beyond diagnostics.
- Heist restart required.

### Dev: streamline (`nav_streamline`)

Computes choke-point proxies and applies the path streamliner to coarse
paths.

- Default: **ON**.
- Requires the overlay.
- Heist restart required.

### Dev: Iter coarse search (`nav_search`)

Replaces vanilla's coarse search with Iter's weighted search and cache.

- Default: **ON**.
- Requires the overlay.
- Heist restart required.

### Dev: nav-link queue tracking (`navlink_queue`)

Tracks nav-link intervals, reservations and queue lengths, and lets units
switch to a sibling link when one is busy.

- Default: **ON**.
- Diagnostics work alone; reservation/switch needs the AI cluster.
- Heist restart required.

### Dev: AI cluster (`nav_ai`)

Installs the Iter AI wrappers: nav-link animations, path extender hooks,
direct-to-pos plumbing, follow-unit updates.

- Default: **ON**.
- Requires the overlay.
- Heist restart required.

### Dev: path extender (`path_extender`)

Precomputes the next detailed path and appends it to the live walk action.

- Default: **OFF** until T5.
- Requires the overlay **and** the AI cluster.
- Heist restart required.

### Dev: direct-to-pos (`direct_to_pos`)

In whisper mode, walk straight to the objective position.

- Default: **ON**.
- Heist restart required.

### Dev: v6 map patches (`map_patches`)

Applies the r200 per-level nav fixes after a version/CRC check.

- Default: **OFF**.
- Logs `applied`, `applied_partial`, `mismatch` or `skip_*` per level.
- 18 levels survive as-is; 3 are being rewritten for v6 (moon, peta,
  Mallcrasher).
- Heist restart required.

### Rebuild NavLinks (`rebuild_navlinks`)

The r200 SO nav-link vector rebuild (kept from the Lite build).

- Default: ON.
- Heist restart required.

## Map toggles

`map_change_<level>` toggles remain for every level. They are only consulted
when `Dev: v6 map patches` is on. Levels whose patch is a no-op at v6 log
`skip_dead`.

## Diagnostics

`debug_log` is set by the test harness (`!iter setting debug_log 0|1|2`), not
by this menu.

- 0: errors only.
- 1: summaries, patch status, nav-link heartbeat.
- 2: verbose events.
