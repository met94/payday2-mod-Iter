# P7 — map patches (next phase, deferred)

Status: deferred to the next implementation session. Core nav/AI port is
working; P7 is independent and large enough to own a phase.

## Why deferred

- `_navdatapatches.lua` selects a level with `local level_id =
  Iter:get_level_id()` at **file-load time**, then installs one
  `NavigationManager:set_load_data` override in an `if/elseif` chain.
  The nav overlay loads once per process; the selected id is not guaranteed
  to be the heist being loaded. The port must select the patch **inside**
  `set_load_data` at call time.
- 69 of the patch operations write `data.nav_segments[id].neighbours[...]`.
  The v6 converter discards neighbours and the engine recomputes them, so
  those writes are dead. A patch survives only if its added rooms/doors/quads
  produce the intended topology.
- 26 level blocks need a per-level audit (53 `append_room`, 36 `append_door`,
  51 `transfer_room`, 3 `add_segment`, 3 `append_vis_group`).
- CRC signatures were taken on 232.4-era v5 data. T1 confirms data version 5
  in 248.2, but each level still needs its CRC/apply status verified.

## Target design

1. Keep the helper functions (`_make_seg2vg`, `append_room`, `append_door`,
   `transfer_room`, `append_vis_group`, `add_segment`) at module scope.
2. Convert each level block into `local patches = { level_id = function(data) ... end }`.
3. One hook:
   ```
   function NavigationManager:set_load_data(data)
     if Iter.settings.map_patches and data.version < 6 and data.door_low_rooms then
       local level_id = Iter:get_level_id()
       local patch = patches[level_id]
       if patch then
         local ok, err = pcall(patch, data)
         Iter.diag.event('patch', {level=level_id, result=..., ...})
       end
     end
     return original(self, data)
   end
   ```
4. Remove or rewrite dead `neighbours` writes; add doors/quads where the
   engine can derive the connection.
5. Per-level toggle still honoured (`map_change_<level>`).
6. `!iter patch` prints the last status; `evt=patch` records
   `applied|mismatch|skip_version|skip_setting` and counts.

## Acceptance

- With `map_patches=true`, every patched level loads and logs exactly one
  `evt=patch` with `result=applied` or `result=mismatch` (never an error).
- CRC mismatch skips the level without touching data.
- The T6 card passes per level; a level with a dead neighbour write is either
  rewritten or marked dropped in `drop-log.md`.
- With `map_patches=false`, no patch code runs.
