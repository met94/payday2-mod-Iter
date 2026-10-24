# S-01/S-02 — v6 door topology and proxy port

Status: implemented, awaiting T1/T2 runtime data.
Depends on: N-01, N-02.
Unblocks: S-03/S-04/S-05 (streamline), P4 (nav links).

## Goal

Make the r200 flood/contiguity/choke-point/proxy intent work with v6 data:

- 248.2 neighbour entries are engine positions, not door ids;
- the shim rebuilds physical doors from v5 arrays;
- a door→segment-pair index recovers the door ids the flood needs.

## Changes

### Shim (`lua/iter_nav_v6_shim.lua`)

- `nav.itr_shim_door_by_pair[seg_a][seg_b] = {door_id...}` built from
  `_room_doors` and each quad's visibility group owner.
- Stats: `door_pairs`, `doors_without_pair`.
- Cleared with the other shim tables.

### Nav overlay (`lua/navigationmanager.lua`)

- `itr_find_proxies` uses the pair index instead of numeric neighbour entries;
  empty lists are counted (`proxy_no_doors`) and skipped.
- `itr_copy_door_data` copies the shim door table directly (center/pos/pos1).
- `itr_prepare_nav_data` runs after `_resolve_segment_neighbours`, host only:
  neighbour lists, door copy, proxies; logs `evt=proxy` with counts and ms.
- `itr_get_door_between` uses the pair index and door centers.
- `itr_get_closest_door_to_pos` and `itr_get_accessibility` understand v6
  Vector3 doors.
- `nav_search` is a separate gate; the custom search is not installed unless
  explicitly enabled.

## Acceptance

- `nav_overlay=true, nav_streamline=true, nav_search=false, nav_ai=false`:
  heist loads, `evt=proxy segments>0 choke>=0 ms=<n>`, no errors.
- `proxy_no_doors` is bounded (nav-link-only neighbours are expected).
- T2 probe still runs vanilla search; no Iter search override in the log.
- Offline shim tests include the door-pair index.
- `gates.ps1` PASS.
