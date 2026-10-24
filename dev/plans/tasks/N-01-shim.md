# N-01 — v6 nav geometry shim

Status: ready.
Depends on: H-02 (harness), H-03 (diag).
Unblocks: N-02, S-01..S-03.

## Goal

Reconstruct the runtime nav geometry tables that 248.2 dropped, from the v5
load data that the 248.2 converter still receives:

- `nav._rooms` (quads: borders + height + vis_group)
- `nav._room_doors` (position pair + the two quad ids)
- `nav._visibility_groups` (rooms/quads + owning segment)

This is the data source for Iter's flood/choke/proxy/streamline intent. It is
not a feature by itself; no AI behaviour changes in this task.

## Read first

- `dev/plans/full-nav-port.md` §4 and §7.
- `dev/reports/intent-map.md` F2, ruling R4.
- 248.2 `lib/managers/navigationmanager.lua`:
  - `set_load_data` / `_convert_nav_data_v5_to_v6` / `_load_nav_data` /
    `_send_nav_field_to_engine` / `_resolve_segment_neighbours`
    (lines ~207-360, ~1760-1792).
- 246.1 `set_load_data` for the v5 shapes (old baseline `a3180fc`), lines
  ~320-430.
- `lua/navigationmanager.lua` (restored r200) top gate.
- `lua/iter_diag.lua` for logging.

## Deliverables

1. New `lua/iter_nav_v6_shim.lua` exporting a table with:
   - `rebuild(nav, load_data)` — build the three tables and `nav.itr_shim`
     stats; return `true` on success, `false` on unsupported data (log
     `evt=fallback subsystem=shim reason=...`).
   - `clear(nav)` — reset the tables and stats.
   - `stats(nav)` — return the stats table.
2. Wire-up in `lua/navigationmanager.lua` (inside the `nav_overlay` gate):
   - `dofile(Iter._path .. 'lua/iter_nav_v6_shim.lua')` after the gate.
   - `Hooks:PostHook(NavigationManager, "_send_nav_field_to_engine", "Iter_nav_shim_rebuild", function(self, load_data) IterNavShim.rebuild(self, load_data) end)`.
   - `Hooks:PostHook(NavigationManager, "_clear", "Iter_nav_shim_clear", function(self) IterNavShim.clear(self) end)`.
3. New `dev/tests/lua/test_shim.lua` runnable with
   `tools\luajit\luajit.exe dev/tests/lua/test_shim.lua`, using a synthetic v5
   load-data fixture and a fake nav object. Assert:
   - room count, door count, vis-group count;
   - x/y scaling by `nav._grid_size`, z unchanged;
   - quad→vis-group and vis-group→segment maps;
   - unsupported (v6-only) data returns false and logs a fallback.
4. Add the test to `dev/tools/gates.ps1` (new section, `luajit` run).

## Rules

- Use `Vector3` copies; do not alias load-data vectors.
- Keys exactly as 248.2 uses them: segment ids are strings in `_nav_segments`.
- No behaviour changes outside the shim and its hooks.
- Do not touch `_navdatapatches`, AI files, or menu.
- Do not commit; the controller commits.

## Acceptance

- `gates.ps1` PASS (including the new shim test).
- `api-audit` errors do not increase (baseline 11).
- With `nav_overlay=true`, a heist log contains one `navdata` event with
  `rooms>0 room_doors>0 vis_groups>0`, and `fallback=0`.
- With `nav_overlay=false`, no shim code runs and boot stays clean.
