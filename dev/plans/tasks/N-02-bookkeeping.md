# N-02 — nav bookkeeping on v6 keys

Status: implemented.
Depends on: N-01.
Unblocks: P3 streamline, P4 nav links.

## Goal

Make the r200 bookkeeping wrappers safe on 248.2 before any feature code
uses them:

- segment ids are strings; every lookup normalises with `tostring`;
- missing segments/neighbours/cover trackers are guarded, never indexed;
- the overlay can be enabled (`nav_overlay=true`) without changing behaviour
  while `nav_streamline`/`nav_ai` stay off.

## Changes

- `itr_make_neighbours_list`: string key, missing-neighbour guard.
- `set_nav_segment_state`: `tostring(id)`, missing-segment guard.
- `clbk_navfield`: missing-segment guards in both passes.
- `register_cover_units`: nil cover/tracker/script-data guards; runs vanilla
  path when `nav_streamline` is off.
- `register_anim_nav_link` / `unregister_anim_nav_link`: interval derivation
  and delay mutation only when `nav_streamline` is on; nav-link element map
  exposed as `NavigationManager.itr_navlink_elements` for diagnostics.
- Feature split: `nav_overlay` (shim + bookkeeping), `nav_streamline`
  (proxies/streamline/search), `nav_ai` (AI cluster).
- `evt=heist` post-hook on `set_load_data` for T1.

## Acceptance

- `nav_overlay=true, nav_streamline=false, nav_ai=false`: heist loads, no
  Iter errors, no behaviour change beyond diagnostics.
- `!iter nav` reports `rooms/room_doors/vis_groups > 0`, `string keys > 0`,
  `missing_neighbours=0`.
- `gates.ps1` PASS.
