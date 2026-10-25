# P7 partial audit A — v6 survival, 10 level blocks

Scope: `lua/_navdatapatches.lua` blocks `alex_2`, `arm_fac`, `arm_for`,
`born`, `branchbank`, `chas`, `crojob2`, `escape_street`, `firestarter_1`,
`framing_frame_1`. Static, read-only. No runtime claim is made anywhere below;
anything that needs shipped level data or the engine binary is marked
UNVERIFIED.

Companions: `dev/reports/p7-map-patch-audit.md` (whole-file census),
`dev/plans/tasks/P7-map-patches.md:14-17` (premise), `dev/reports/drop-log.md:31-40`.

## Premise, re-verified against the game source

| Fact | Evidence |
| --- | --- |
| 248.2 converts v5 on load | `lib/managers/navigationmanager.lua:215-217` (`if data.version < 6 then data = self:_convert_nav_data_v5_to_v6(data)`) |
| v5 `nav_segments[..].neighbours` are dropped | same file `:289-299` builds each v6 segment with `neighbours = {}` (`:295`) and never reads `segment_v5.neighbours` |
| load path repeats that drop | `:311-323`, `neighbours = {}` at `:317` |
| neighbours are rebuilt from the quad field | `:231` and `:326-351` (`_quad_field:nav_segment_neighbours`, overwrite at `:332`) |
| only quads/doors/vis-groups are sent to the engine | `:1760-1795`, segments carry `unique_id/position/vis_groups` only (`:1770-1774`); `door_low_quads`/`door_high_quads` at `:1788-1789` |
| the surviving fields are exactly what the patch helpers write | converter `:254-267` (room_borders -> quad_borders, room heights -> quad heights, door_low/high_rooms -> door_low/high_quads), `:269-287` (vis_groups -> visibility_groups with `quads`), `:289-299` (nav_segments -> segments) |
| 246.1 honoured the writes (why r200 wrote them) | `git show a3180fc:lib/managers/navigationmanager.lua:416` (`self._nav_segments = data.nav_segments`) and `:421-426` (clone of `nav_seg.neighbours`) |
| converter landed in 247, not 248 | `git log a3180fc..e3a8b616 -- lib/managers/navigationmanager.lua` = `5d84b4be` (247), `d8a9ae2f` (248.1), `e3a8b616` (248.2); `_convert_nav_data_v5_to_v6` present in all three, absent at `a3180fc` |
| patch data is still version 5 | `NavFieldBuilder._VERSION = 5` at `a3180fc`, `5d84b4be`, `e3a8b616` |

Helper semantics used below (`lua/_navdatapatches.lua`):

- `append_room` (`:847-863`) writes the four quad borders, four heights, and puts
  the new quad in `vis_groups[seg2vg[segment_id]].rooms` (`:859-860`) and in
  `room_vis_groups` (`:859`). Both reach v6 (converter `:280-282`, `:269-287`).
- `append_door` (`:867-875`) writes `door_low_pos/high_pos` and
  `door_low_rooms/high_rooms`; the room ids are quad ids and reach v6 as
  `door_low_quads/door_high_quads` (converter `:264-265`).
- `transfer_room` (`:838-843`) moves a quad between vis groups
  (`vis_groups[..].rooms`, `room_vis_groups`), i.e. it relabels quad -> segment
  ownership; it reaches v6 through `:269-287` + `:293`.
- `append_vis_group` (`:877-894`) / `add_segment` (`:896-904`) reach v6 through
  converter `:269-287` / `:289-299`.

Cross-cutting UNVERIFIED assumption (applies to every `SURVIVES_AS_IS` below):
the engine links segment A to segment B when a door joins a quad owned by A's
vis group to a quad owned by B's vis group. The engine side
(`nav_segment_neighbours`) is binary; the only in-repo evidence is that v6
segments carry `vis_groups` (`navigationmanager.lua:1773`) and the quad field
reports neighbours per `Idstring(segment.unique_id)` (`:328-329`). Whether a
bordering quad pair without a door also yields a link is UNVERIFIED and matters
only for `escape_street` (empty-door link, see below).

Second cross-cutting UNVERIFIED item, out of scope but relevant to every
appended door: the patch passes absolute `Vector3` values into
`door_low_pos/door_high_pos`; 246.1 multiplied those by `grid_size` on load
(`a3180fc:lib/managers/navigationmanager.lua:394-397`), while 248.2 forwards
them raw to the engine (`navigationmanager.lua:1786-1789`). Whether the engine
applies the same grid scaling is engine-side and not checked here.

---

## 1. alex_2

**Block:** `alex_2`, `lua/_navdatapatches.lua:62-84`.

**Surviving edits** (all reach v6):

- `:65` `append_room(119,117,111,110, ..., 55)` -> quad `rid`, owner segment 55.
- `:66` `append_door((117,110,22.5)-(119,110,22.5), 456, rid)` -> quad 456 to
  the segment-55 quad.
- `:68` `append_room(..., 55)` -> second quad, owner segment 55.
- `:69` `append_door((117,111,74)-(119,111,74), rid-1, rid)` -> intra-segment
  (55<->55) quad link.
- `:71` `append_room(..., 90)` -> quad owner segment 90.
- `:72` `append_door((117,122,181)-(119,122,181), rid-1, rid)` -> joins the
  segment-55 quad from `:68` to the segment-90 quad from `:71`; `did` saved.
- `:77` `append_room(..., 90)` -> second segment-90 quad.
- `:78` `append_door((117,134,280)-(119,134,280), rid-1, rid)` -> intra-90.
- `:79` `append_door((117,135,222.5)-(119,135,222.5), 685, rid)` -> segment-90
  quad to existing quad 685.
- `:81` `data.room_borders_y_neg[685] = 135` -> quad border edit (converter
  `:257`).

**Dead neighbour writes:**

- `:74` `data.nav_segments[55].neighbours[90] = { did }` — wanted segment 55
  connected to segment 90 through the door created at `:72`.
- `:75` `data.nav_segments[90].neighbours[55] = { did }` — reverse of the same.

**Verdict:** `SURVIVES_AS_IS`. The door at `:72` spans exactly the quad that
`:68` assigned to segment 55 and the quad that `:71` assigned to segment 90, so
the 55<->90 connection the dead writes assert is already expressed by surviving
geometry, with both endpoint quads created by this same block (no dependence on
unknown shipped quad ids). The dead writes are redundant.

**Confidence:** HIGH for redundancy (endpoint ownership is fixed by `:859-860`
in this file plus `:68/:71` segment args); MEDIUM for the engine link rule
(cross-cutting UNVERIFIED above).

---

## 2. arm_fac

**Block:** `arm_fac`, `lua/_navdatapatches.lua:86-100`.

**Surviving edits:**

- `:90` `append_room(24,32,-130,-131, ..., 11)` -> quad `rid`, owner segment 11
  (comment `:89` "around truck 100226").
- `:91` `append_door((24,-130,232.389)-(24,-131,232.389), 108, rid)`; `did`
  saved -> quad 108 to the segment-11 quad.
- `:92` `append_door(..., 175, rid)` -> quad 175 to the segment-11 quad.
- `:93` `append_door(..., 164, rid)` -> quad 164 to the segment-11 quad.
- `:94` `append_door(..., 97, rid)` -> quad 97 to the segment-11 quad.

**Dead neighbour writes:**

- `:96` `table.insert(data.nav_segments[9].neighbours[11], did)` — wanted
  segment 9 connected to segment 11 through the door at `:91`.
- `:97` `table.insert(data.nav_segments[11].neighbours[9], did)` — reverse.

**Verdict:** `SURVIVES_AS_IS`. The connection asserted is 9<->11 and the door at
`:91` joins the new segment-11 quad to existing quad 108; if quad 108 is owned
by the vis group of segment 9 the link is re-derived with no rewrite. That
ownership is shipped level data, so the condition is UNVERIFIED — a rewrite is
only needed if quad 108 belongs to a third segment. Note `:96` would also throw
if `neighbours[11]` were nil (the whole block is inside `pcall`,
`lua/_navdatapatches.lua:952`), which is a separate, pre-existing fragility.

**Confidence:** MEDIUM. Door/quad edits certainly survive; the 9<->11 pairing
hinges on the unseen `room_vis_groups[108]` (UNVERIFIED).

---

## 3. arm_for

**Block:** `arm_for`, `lua/_navdatapatches.lua:102-132`.

**Surviving edits** (transfers only, no geometry added):

- `:108` `transfer_room(2689, 57, 56)`.
- `:110` `transfer_room(2701, 58, 59)`.
- `:112-120` `transfer_room(2704..2712, 59, 60)` (nine quads).

No `append_room`, no `append_door`, no `add_segment`, no border/pos edit in this
block.

**Dead neighbour writes:**

- `:122` `data.nav_segments[56].neighbours[57] = {5188}` and `:123` reverse —
  wanted 56<->57 through existing door 5188.
- `:125` `data.nav_segments[59].neighbours[60] = {5210}` and `:126` reverse —
  wanted 59<->60 through existing door 5210.
- `:128` `data.nav_segments[59].neighbours[58] = {5195}` and `:129` reverse —
  wanted 58<->59 through existing door 5195.

**Verdict:** `NEEDS_REWRITE` (rewrite may collapse to "nothing to do" after a
data check). All three connections exist only as neighbour entries; nothing in
the block creates a door. The transfers can still change the derived topology,
because moving a quad changes which segment owns each endpoint of an existing
door: if door 5188 spans a quad now owned by 56 and another quad still owned by
57, v6 derives 56<->57 by itself and the dead write is redundant. Whether that
holds for 5188/5210/5195 depends on shipped quad ownership and door endpoints
(UNVERIFIED). Concretely: dump `room_vis_groups[<low_room>]`,
`room_vis_groups[<high_room>]` for doors 5188/5210/5195 from the loaded v5 data;
if a pair already differs across the intended segments, delete `:122-129` and
keep the block as transfers only. If both endpoints land in the same segment,
add `append_door` on the shared border between a quad of each target segment
(coordinates must come from the same dump; nothing in this repo carries them).

**Confidence:** LOW. The transfer edits are verified to survive
(`:838-843` -> converter `:269-287`, `:293`); the derived topology is not
verifiable statically.

---

## 4. born

**Block:** `born`, `lua/_navdatapatches.lua:148-166`.

**Surviving edits:**

- `:152` `data.room_borders_y_neg[442] = -46` — quad border (converter `:257`).
- `:153` `append_door((39,-46,72.5)-(39,-45,72.5), 442, 457)` — quad 442 to quad
  457 (bar counter). No dead write depends on it.
- `:156` `data.room_borders_y_pos[2798] = 111` — moves quad 2798's border to the
  y=111 line the doors sit on.
- `:158` `did = append_door((-149,111,22.4998)-(-146,111,22.4998), 2798, 3405)`.
- `:159` `append_door((-146,111,22.4998)-(-140,111,22.4998), 2798, 3381)`.
- `:160` `append_door((-140,111,22.4998)-(-138,111,22.4998), 2798, 3379)`.

**Dead neighbour writes:**

- `:162` `data.nav_segments[50].neighbours[51] = { did, did + 1, did + 2 }` —
  wanted 50<->51 through the three doors from `:158-160`.
- `:163` reverse.

**Verdict:** `SURVIVES_AS_IS`. The dead write names exactly the three doors this
block creates, and each of those doors joins quad 2798 (whose border `:156`
moves onto their y line) to one of 3405/3381/3379. If those quads sit in the two
segments 50/51, v6 derives the link; the door ids are not needed. If they do
not, the three doors still survive but the intended segment pair does not, which
would be a `NEEDS_REWRITE` on quad choice rather than on coordinates.

**Confidence:** MEDIUM. Door and border edits verified to survive; the 50/51
ownership of quads 2798/3405/3381/3379 is UNVERIFIED.

---

## 5. branchbank

**Block:** `branchbank`, `lua/_navdatapatches.lua:168-194`.

**Surviving edits:**

- `:172-173` `rid = 551`, `data.room_borders_y_pos[rid] = 41` — quad border.
- `:174-175` `mvector3.set_y(data.door_high_pos[999], 41)` — door endpoint
  position edit; survives through converter `:262-263`.
- `:178` `append_room(-129,-130,76,53, ..., 17)` -> quad `rid`, owner segment 17
  (comment `:177` "Parking, grid side").
- `:179` `append_door((-130,76,22.5)-(-129,76,22.5), 504, rid)` -> quad 504 to
  the segment-17 quad.
- `:180` `did = append_door((-130,53,22.5)-(-129,53,22.5), 553, rid)` -> quad 553
  to the segment-17 quad.
- `:185` `data.room_borders_x_pos[508] = -130` — quad border.
- `:186` `append_door((-130,66,22.5)-(-130,67,22.5), 508, rid)` -> quad 508 to
  the segment-17 quad (after the border move).
- `:189` `append_room(-110,-124,114,113, ..., 15)` -> second quad, owner segment
  15 (comment `:188` "Parking, other side").
- `:190-191` doors 375 and 414 onto that segment-15 quad.

**Dead neighbour writes:**

- `:182` `table.insert(data.nav_segments[17].neighbours[18], did)` — wanted
  17<->18 through the door at `:180`.
- `:183` reverse.

**Verdict:** `SURVIVES_AS_IS`. The asserted pair is 17<->18 and the door at
`:180` joins the new segment-17 quad to existing quad 553; if quad 553 belongs
to segment 18 the link is re-derived. The other three doors (`:179`, `:186`,
`:190-191`) have no dead-write counterpart and were always pure geometry. As
with `arm_fac:96`, `:182` would throw on a nil `neighbours[18]` (caught by the
`pcall` at `:952`).

**Confidence:** MEDIUM. Geometry survival verified; `room_vis_groups[553] ==
seg2vg[18]` UNVERIFIED.

---

## 6. chas

**Block:** `chas`, `lua/_navdatapatches.lua:196-205`.

**Surviving edits:**

- `:200` `append_room(93,98,159,160, ..., 11)` -> quad `rid`, owner segment 11
  (comment `:199` "between 2 cars in front of SF souvenirs").
- `:201` `append_door((93,159,503.519)-(93,160,508), 125, rid)`.
- `:202` `append_door((98,159,503.519)-(98,160,503.519), 161, rid)`.

**Dead neighbour writes:** none.

**Verdict:** `SURVIVES_AS_IS`. Nothing in the block is discarded; whether the
new walkable pocket actually helps depends on quads 125/161 being owned by
segment 11 (UNVERIFIED), i.e. whether the two doors are intra-segment links that
open the pocket. Note the door at `:201` has mismatched z on its two endpoints
(`503.519` vs `508`); that is authorial, forwards to the engine unchanged
(converter `:262-263`), and is worth one in-game look if the pocket misbehaves.

**Confidence:** HIGH that the block survives the converter; MEDIUM on the
in-game effect.

---

## 7. crojob2

**Block:** `crojob2`, `lua/_navdatapatches.lua:207-233`.

**Surviving edits** (transfers only):

- `:210` `transfer_room(414, 28, 74)`.
- `:211` `transfer_room(417, 28, 74)`.
- `:212` `transfer_room(418, 28, 74)`.
- `:213` `transfer_room(424, 28, 74)`.

No door, quad, segment or vis-group is created.

**Dead neighbour writes (the whole rest of the block):**

- `:215-218` loop over `data.nav_segments[28].neighbours[52]`: copies each door
  id into `[74][52]` (`:216`) and `[52][74]` (`:217`), then nils
  `[28][52]` (`:219`) and `[52][28]` (`:220`) — wanted the 52-side links moved
  from 28 to 74 and the old 28<->52 link removed.
- `:222-225` adds door ids 758/764/772/773 as 28<->74 links — wanted 28
  connected to 74.
- `:227-230` removes door ids 1776/1777 from 28<->74 — wanted those two doors
  not to carry the 28<->74 link.

**Verdict:** `NEEDS_REWRITE`. Every asserted connection and both removals live
only in the discarded lists. Rewrite shape: after the four transfers, dump
`door_low_quads/door_high_quads` for 758/764/772/773 and read
`room_vis_groups` for each endpoint. If a door already spans a quad in seg 28's
vis group and a quad in seg 74's, the add is redundant; otherwise add
`append_door` on the shared border between a 28 quad and a 74 quad. The two
removals (`:219-220`, `:227-230`) have **no v6 equivalent**: a door that exists
in the data will produce a link, and there is no supported quad/door
verification in `_navdatapatches.lua` for deleting one. Recommend documenting
them as an accepted loss unless a door-position move (`room_borders_*` /
`door_*_pos`) can be found that leaves the two quads non-adjacent.

**Confidence:** LOW. Transfers verified to survive; all four intended topology
changes are UNVERIFIED and at least two are not expressible.

---

## 8. escape_street

**Block:** `escape_street`, `lua/_navdatapatches.lua:284-304`.

**Surviving edits:**

- `:287` `append_vis_group(63, Vector3(1270,-1310,400))` -> new vis group for
  segment 63; survives through converter `:269-287`.
- `:288` `add_segment(63, ...)` -> new v6 segment with
  `vis_groups = { seg2vg[63] }` (`:896-904`); survives through converter
  `:289-299`.
- `:293-296` four `append_room(..., 63)` -> four quads, all owned by segment 63
  (`:859-860`).
- `:298-301` four `append_door` calls chaining those quads: `rid`<->`rid+1`,
  `rid`<->`rid+2`, `rid+1`<->`rid+3`, `rid+2`<->`rid+3` — a closed ring of
  intra-segment (63<->63) links.

**Dead neighbour writes:**

- `:290` `data.nav_segments[63].neighbours[48] = {}` — wanted segment 63
  connected to segment 48 with an empty door list.
- `:291` `data.nav_segments[48].neighbours[63] = {}` — reverse.

**Verdict:** `NEEDS_REWRITE`, limited to the 63<->48 link. The segment, its vis
group and the four rooms/doors are fully geometric and survive as-is; but
nothing in the block joins a segment-63 quad to a segment-48 quad, so the only
thing that expressed 63<->48 was the dead write. Rewrite shape: either (a) add
`append_door` between one of the new quads and a quad owned by segment 48 (that
quad id and its coordinates must be dumped from the shipped data; the empty list
in `:290` implies the r200 author considered them border-adjacent, no door
needed), or (b) rely on engine quad-border adjacency if bordering quads link
without a door — that is exactly the cross-cutting UNVERIFIED item, so it needs
one in-game check before either variant is chosen. Cheap discriminator: the
current `evt=patch` record plus `!iter` shim stats show whether segment 63 is
reachable at all in-game (`dev/plans/tasks/P7-map-patches.md:50-54`).

**Confidence:** MEDIUM that the geometry half survives, LOW on the 63<->48 link
(UNVERIFIED, depends on engine border-adjacency semantics).

---

## 9. firestarter_1

**Block:** `firestarter_1`, `lua/_navdatapatches.lua:306-318`.

**Surviving edits:**

- `:310` `data.room_borders_x_pos[576] = -12` — quad border.
- `:311` `data.room_borders_y_neg[576] = 159` — quad border; together they pull
  quad 576 onto the door line.
- `:313` `did = append_door((-13,159,21.98)-(-12,159,21.98), 576, 1124)` — joins
  existing quads 576 and 1124.

**Dead neighbour writes:**

- `:314` `table.insert(data.nav_segments[29].neighbours[52], did)` — wanted
  29<->52 through the door at `:313`.
- `:315` reverse.

**Verdict:** `SURVIVES_AS_IS`. The only asserted connection is 29<->52 and the
door at `:313` spans quads 576/1124; the two border edits at `:310-311` exist to
make that door sit on the quad edge. If 576 and 1124 are owned by 52 and 29
respectively, v6 derives the link. Both quad ids are shipped data, so the
ownership is UNVERIFIED.

**Confidence:** MEDIUM-HIGH: the block is small, its surviving edits are exactly
the ones that matter, and the dead write adds nothing that the door does not
already encode; residual risk is only the segment ownership of 576/1124.

---

## 10. framing_frame_1 (shared with gallery)

**Block:** `framing_frame_1` or `gallery`, `lua/_navdatapatches.lua:324-357`;
signature aliased at `:770` (`nav_data_sigs.framing_frame_1 =
nav_data_sigs.gallery`).

**Surviving edits:**

- `:327` `append_vis_group(100, Vector3(2457,6,0))` — new vis group for segment
  100.
- `:329-339` assigns nine quads (858, 859, 870, 871, 872, 873, 881, 883, 884) to
  `vg.rooms`.
- `:340-343` for each of those quads: removes it from
  `data.vis_groups[seg2vg[13]].rooms` (`:341`) and points
  `data.room_vis_groups[room_id]` at `seg2vg[100]` (`:342`). Quad ownership move
  -> survives through converter `:269-287` (which reads
  `vis_group_v5.rooms` at `:280-282`, not `room_vis_groups`).
- `:345` `add_segment(100, ...)` — new v6 segment, `vis_groups = { seg2vg[100] }`
  (`:896-904`), survives through converter `:289-299`.

**Dead neighbour writes:**

- `:347` `data.nav_segments[100].neighbours[1] = data.nav_segments[1].neighbours[13]`
  — wanted segment 100 to inherit the door list of the old 1<->13 link.
- `:348` `data.nav_segments[100].neighbours[13] = {1561,1589,1590,1616}` — wanted
  100<->13 through those four doors.
- `:350` `data.nav_segments[1].neighbours[100] = data.nav_segments[1].neighbours[13]`
  — reverse of `:347`.
- `:351` `data.nav_segments[13].neighbours[100] = data.nav_segments[100].neighbours[13]`
  — reverse of `:348`.
- `:353` `data.nav_segments[1].neighbours[13] = nil` — wanted 1<->13 removed.
- `:354` `data.nav_segments[13].neighbours[1] = nil` — reverse.

**Verdict:** `SURVIVES_AS_IS` for the split, with one accepted loss. The
segmentation change is carried entirely by geometry: the nine quads move from
segment 13's vis group to segment 100's, and any door that used to bridge
segment 1 and those quads now bridges segment 1 and segment 100 — which is the
additions in `:347/:350` (1<->100) and `:348/:351` (100<->13). No rewrite is
needed for those. The **removal** at `:353-354` (1<->13) is not expressible:
if any door still joins a quad remaining in segment 13's vis group to a quad in
segment 1's, v6 keeps 1<->13 alive, and there is no supported link delete
(cf. `crojob2` `:227-230`). Treat as accepted loss, or express it by moving the
offending quad(s) into segment 100's group the same way `:341-342` does — that
is the only lever the converter offers. Ownership of the remaining segment-13
quads is UNVERIFIED.

**Confidence:** MEDIUM. The add path is structurally certain (quads move, doors
do not); the removal half is UNVERIFIED and cannot be expressed without a level
data dump.

---

## Summary

| Level | Lines | Verdict | Key evidence | Rewrite needed? |
| --- | --- | --- | --- | --- |
| alex_2 | 62-84 | SURVIVES_AS_IS | door `:72` joins the seg-55 quad (`:68`) to the seg-90 quad (`:71`) = dead pair at `:74-75` | no; delete `:74-75` |
| arm_fac | 86-100 | SURVIVES_AS_IS | door `:91` (quad 108 -> seg-11 quad) covers `:96-97` if 108 is in seg 9 (UNVERIFIED) | no; delete `:96-97` |
| arm_for | 102-132 | NEEDS_REWRITE | only transfers `:108-120`; all three links (`:122-129`) exist only as dead writes | yes, unless doors 5188/5210/5195 already span the new owners |
| born | 148-166 | SURVIVES_AS_IS | doors `:158-160` are exactly the ids in `:162-163`; border `:156` moves quad 2798 onto their line | no; delete `:162-163` |
| branchbank | 168-194 | SURVIVES_AS_IS | door `:180` (quad 553 -> seg-17 quad) covers `:182-183` if 553 is in seg 18 (UNVERIFIED) | no; delete `:182-183` |
| chas | 196-205 | SURVIVES_AS_IS | room `:200` + doors `:201-202`; zero dead writes | no |
| crojob2 | 207-233 | NEEDS_REWRITE | only transfers `:210-213`; adds `:222-225` and removals `:219-220`/`:227-230` all dead | yes for adds; removals not expressible |
| escape_street | 284-304 | NEEDS_REWRITE | seg 63 + 4 quads + 4 doors survive, but 63<->48 exists only at `:290-291` | yes, for 63<->48 only |
| firestarter_1 | 306-318 | SURVIVES_AS_IS | border `:310-311` + door `:313` (quads 576/1124) cover `:314-315` | no; delete `:314-315` |
| framing_frame_1 | 324-357 | SURVIVES_AS_IS | quad move `:341-342` + `add_segment` `:345` carry the split; only the 1<->13 delete `:353-354` is lost | no for adds; removal is an accepted loss |

Counts: 7 `SURVIVES_AS_IS`, 3 `NEEDS_REWRITE`, 0 `DROP` (no block in this batch
has zero surviving value).

## Player POV and decision

- Player-visible effect: the seven `SURVIVES_AS_IS` levels keep their r200
  walkability fixes (Alex parking gaps, the Armored Transport truck, Biker bar
  counter and bunker doors, Branch Bank parking, the Nine Yards market pocket,
  Firestarter day-1 truck access, Framing Frame's gallery split). No visual
  change; AI pathing inside the patched pockets is the only thing that moves.
- `arm_for`, `crojob2`, `escape_street`: until rewritten, cops and bots may
  refuse the cross-segment transitions those patches were written for — most
  visible on CroJob2 (moving the 52-side doors onto segment 74) and on
  Escape Street (a whole added segment that may be unreachable).
- Decision: keep the seven `SURVIVES_AS_IS` blocks and strip their dead writes;
  park `arm_for`/`crojob2`/`escape_street` as rewrite candidates. Do not add
  them to `dead_patches` (`lua/_navdatapatches.lua:808-810`) yet — their
  transfers still change the derived graph, so disabling the block would
  regress topology.
- Artifacts: this report; per-block line citations; no code changed.

## Follow-ups (ordered by cost)

1. Bedrock data check (one level load, no gameplay): dump `room_vis_groups`,
  `door_low_quads`, `door_high_quads` per level to settle every UNVERIFIED
  ownership question above in one pass. This decides `arm_fac`, `born`,
  `branchbank`, `firestarter_1` (dead-write deletion is safe) and
  `arm_for` (whether 5188/5210/5195 already bridge the right owners).
2. In-game discriminator for the engine border-adjacency rule: load
  `escape_street` and check whether segment 63 has neighbours at all. If
  bordering quads link without a door, `:290-291` were also redundant and
  `escape_street` drops to `SURVIVES_AS_IS`.
3. Record the two inexpressible removals (`crojob2:227-230`,
  `framing_frame_1:353-354`) in `dev/reports/drop-log.md`; they are the only
  items in this batch that geometry cannot express.
4. Optional cleanup, independent of verdicts: `arm_fac:96` and
  `branchbank:182` assume `neighbours[..]` is non-nil and would raise inside the
  block `pcall` (`lua/_navdatapatches.lua:952-958`), producing
  `result=error` instead of `applied`. Deleting the dead writes removes the
  hazard.
