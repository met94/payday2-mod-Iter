# P7 validation — how we know a patch is right

## Three separate claims

1. **The r200 author's intent was right.** Unknown from code alone. Evidence:
   map-specific comments with exact unit/room/door ids, a 200-revision
   changelog full of playtest fixes, CRC signatures that pin the nav data the
   patch was written against.
2. **The patch applies to the current data.** We verify: v5 data, CRC match,
   `evt=patch result=applied`, patch stats (rooms/doors/transfers).
3. **The patch still does what the author meant on v6.** Only partly verified.
   We verify topology (doors/quads exist, segments connect); we do **not** yet
   run behavioural A/B tests for most levels.

Applying without error is not proof of intent. We keep the three claims
separate in the docs.

## How the r200 author found the ids

Iter edits the navmesh data arrays directly: quads (v5 rooms), door
positions/quad ids, visibility groups, segments. The comments cite exact
ids: `100226` (a static unit), `room 104`, `2701 and 2703 are clones`,
`door_high_pos[4547]`, `door_high_pos[4981]`, `bc8566d71eae8505` (a unit
hash). Those ids cannot be guessed; they come from reading the level's nav
data / world definition.

PAYDAY 2 ships `NavFieldBuilder` and nav debug draws, and Iter already hooks
the world definition to move statics by `unit_id` (`coreworlddefinition.lua`).
The practical method is: dump or inspect the level's nav arrays/units,
identify the room/quad/door/segment ids, write the array patch, then verify
in-game and iterate. The CRC function exists precisely because the arrays
change between game updates; a mismatch means "do not patch".

This is empirical modding, not a formal proof. The changelog shows the author
fixing his own patches repeatedly (navlinks off by 2.75 m, streamline
failures, a Border Crossing patch removed for a crash).

## What we know per patch

| Class | Evidence | Confidence |
|---|---|---|
| Dead neighbour writes removed (`arm_for`, `crojob2`, `escape_street`, `jolly`) | `navdoors`/`navdump` show the intended doors or navlinks already exist; v6 ignores the writes | HIGH: removal is behaviour-neutral |
| SURVIVES_AS_IS static audit | geometry edits reach the v6 converter | MEDIUM: mechanism survives, intent unproven |
| `big` applied | `evt=patch applied`, data values changed | MEDIUM: mechanism, not behaviour |
| `applied_partial` (`moon`, `peta`) | geometry applies, but the intended cross-segment link is absent at runtime (`navpath` fails / segment isolated) | LOW until rewritten and tested |
| `skm_mallcrasher` | patch was neighbour-only | NONE: dead |

Runtime evidence for the four dumped levels:
`dev/reports/p7-runtime-2026-10-24.md`.

## Behavioural A/B test

The harness collects this automatically: on heist start it logs the dump block
for the five P7 levels (`p7auto level=… patches=…`). `!iter navpath <from> <to>`
also runs manually and prints one line per call:

```
navpath level=<level> patches=<on|off> <from>-><to> ok=1 steps=N positions=N
        length=<m> direct=<door count> ids=<seg;seg;...>
```

`direct` is the number of doors on the `from -> to` neighbour entry in the
loaded graph; it is read without searching, so it separates "graph changed"
from "search found a detour". `ids` is the returned segment sequence (first 32
steps).

Run once with `map_patches=true`, once with `false`, on the same heist and the
same segment pair. Reload the heist after the toggle: patches apply in
`set_load_data`.

Expected per patch intent:

- add-link patch: direct > 0 with the patch and 0 without it; the path may
  still exist via a detour, so compare `length`/`ids`;
- seal patch: direct = 0 with the patch and > 0 without it, plus a longer or
  different route;
- move/edit patch: path length or segment sequence changes.

This is objective and scriptable. Scenario tests (cops stuck at a specific
object) are still needed for a final release, but the path A/B test separates
"patch applies" from "patch changes the graph as intended".

## Limits

- CRC match proves the arrays match the author's baseline, not that the fix is
  still desirable after level changes.
- Some fixes depend on mission objects/doors spawned at runtime, not nav data.
- Iter's source has no tests; playtesting was the original oracle.
