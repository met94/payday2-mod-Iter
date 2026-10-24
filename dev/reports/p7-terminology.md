# P7 terminology and Bomb level ids

## The Bomb ids — confirmed

| Heist | Job id | Level id | World | r200 patch? |
|---|---|---|---|---|
| The Bomb: Dockyard | `crojob1` | **`crojob2`** | `narratives/butcher/thebomb/stage_2` | **yes** |
| The Bomb: Forest | `crojob2` | **`crojob3`** | `narratives/butcher/thebomb/stage_3` | no |

Evidence:

- `lib/tweak_data/levelstweakdata.lua`: `crojob2.world_name = stage_2`,
  `crojob3.world_name = stage_3`.
- Payday Wiki: Dockyard `crojob1 (job) crojob2 (level)`;
  Forest `crojob2 (job) crojob3 (level)`.
- Runtime: loading Dockyard logs `evt=heist level=crojob2`; loading Forest
  logs `level=crojob3`.
- Code: `_navdatapatches.lua` has one block keyed `crojob2`; there is no
  `crojob3` block or alias.

Consequence: the Dockyard dumps are the relevant ones. Forest has no r200
patch to port.

## What the P7 commands are

They are read-only inspection commands, not gameplay tests:

- `!iter navdump <segment_id>` — prints one navigation segment:
  position, visibility groups, neighbours and door-type counts, and the
  quads (navmesh polygons) in its visibility groups.
- `!iter navdoors <seg_a> <seg_b>` — prints every door that connects those
  two segments: door id, the two quad ids it joins, endpoint positions and
  centre.
- `!iter patch` — last map-patch result and counts.
- `!iter nav` — overall segment/room/door counts.

Goal: replace r200's dead neighbour writes with real geometry. For each
patch we need to know whether a door already exists between the target
segments, and which quads/doors to add or move if not.

## Nav terms

- **Quad** (also "room" in v5): a convex navmesh polygon. A segment's
  `vis_groups` reference groups whose `quads` are its polygons.
- **Door**: a navmesh edge/opening between two quads. It is not a scripted
  door object; it is the traversal link between two nav quads. Each has a
  low/high endpoint pair and the two quad ids it connects.
- **Segment** (`nav_segment`): a group of quads the AI navigates as one
  path node. Segment neighbours are computed by the engine from the doors
  between their quads.
- **Neighbour write** (v5 pattern): r200 set
  `data.nav_segments[a].neighbours[b] = {door_id}` directly. 248.2's
  `_convert_nav_data_v5_to_v6` sets every segment's `neighbours = {}` and
  the engine recomputes them from doors, so those writes are dead.

## Status after the dumps

- `arm_for` (Train Heist): dead writes redundant; doors 5188, 5205/5210,
  5195/5206 already exist. Removed.
- `crojob2` (Dockyard): transfers leave doors 758/764/772/773 between 28↔74;
  28↔52 has none. Removed.
- Remaining partial: `escape_street`, `jolly`, `moon`, `peta`.
- `skm_mallcrasher` dead-only.
