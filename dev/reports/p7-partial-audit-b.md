# P7 partial audit B — v6 survival, 11 level blocks

Read-only static audit. No code changed, no runtime claim made. Sources:

- `lua/_navdatapatches.lua` (current worktree `feat/iter-full-nav`, HEAD `9005d2b`).
- `game-data/Payday-2-LuaJIT-Complete/lib/managers/navigationmanager.lua` at
  `e3a8b616` (248.2).
- Same file at `a3180fc` (246.1), the r200-target era.

Scope: `jewelry_store`, `jolly`, `kenaz`, `kosugi`, `mex`, `mia_1`, `moon`,
`pbr`, `peta`, `roberts`, `watchdogs_1`.

## 0. The v6 data path (verified, cited)

1. `set_load_data` converts first: `if data.version < 6 then data =
   self:_convert_nav_data_v5_to_v6(data)` (`navigationmanager.lua:215-217`),
   then `_load_nav_data` (229), `_send_nav_field_to_engine` (230),
   `_resolve_segment_neighbours` (231).
2. The converter **hard-codes empty neighbours** for every segment:
   `local segment = { id = ..., pos = ..., vis_groups = ...,
   location_id = ..., neighbours = {} }` (`navigationmanager.lua:290-296`,
   literal at 295). Any `data.nav_segments[x].neighbours` write in a v5 table
   is therefore discarded, including the two-way
   `data.nav_segments[a].neighbours[b] = {...}` idiom.
3. The engine payload contains **no neighbour field**:
   quads `quad_borders_*` / `quad_heights_*` (`:1778-1785`), doors
   `door_low_pos` / `door_high_pos` **and door→quad ownership**
   `door_low_quads` / `door_high_quads` (`:1786-1789`), `visibility_groups`
   (`:1790`, each group carries its `quads` list, built at `:269-287`),
   segments as `unique_id` / `position` / `vis_groups` only (`:1770-1774`,
   `:1791`).
4. Topology is recomputed engine-side: `_resolve_segment_neighbours`
   (`:326-351`) fills `segment.neighbours` from
   `self._quad_field:nav_segment_neighbours(ids_id)` (`:328-329`).
5. Therefore these edits survive: `append_room` (quads + `vis_groups[..].rooms`
   → converter `:280-282`), `append_door` (positions + quad ids → `:262-265`),
   `append_vis_group` (→ `:269-287`), `add_segment` (→ `:289-299`),
   `transfer_room` (quad re-ownership via `vis_groups[..].rooms` → `:280-282`),
   `room_borders_*` / `room_heights_*` / `door_*_pos` edits.
6. Confirmed this is a 247 regression in behaviour: `_convert_nav_data_v5_to_v6`
   was introduced by `5d84b4be` ("247",
   `git log -S"_convert_nav_data_v5_to_v6"`), and is absent at 246.1, where the
   tables were used directly: `self._nav_segments = data.nav_segments`
   followed by neighbour cloning (`a3180fc:lib/managers/navigationmanager.lua:416-425`),
   and `room_vis_groups` was read per room (`:357`). The r200 neighbour writes
   were live in their era.
7. Side note, harmless: `transfer_room` also writes `data.room_vis_groups[id]`
   (`_navdatapatches.lua:841`); the v6 converter never reads that table
   (`navigationmanager.lua:238-304`; the only 248.2 uses are the builder path,
   `:455`, `:468`). The two `vis_groups` writes on `:839-840` are what actually
   survive, and they are consistent.
8. Gate caveat: the signature check that must pass before a block runs hashes
   only doors / borders / heights / `room_vis_groups`
   (`_navdatapatches.lua:772-802`), never `nav_segments`. So a block can report
   `result=applied` (`:960`) while all it did was dead neighbour writes — this
   is why the earlier count-based audit (`dev/reports/p7-map-patch-audit.md:13-40`)
   over-reports value.

### Decision rules used below

- A dead write that **mirrors the endpoints of a surviving `append_door`** is
  redundant: the door's two quads, with their owning segments, produce the same
  link on recompute.
- A dead write that is **induced by a `transfer_room`** is redundant: moving a
  quad to another segment flips exactly the doors that have one endpoint in the
  moved set from intra-segment to cross-segment, and vice versa. The recompute
  derives the adjusted door set automatically.
- A dead write that **replaces an entire neighbour table**
  (`nav_segments[s].neighbours = { ... }`) is a *seal*, not a connection. A seal
  deletes links that no surviving edit removes, so it is not covered by the two
  rules above.
- Confidence tags: `VERIFIED` = data path proven by the citations in §0;
  `UNVERIFIED` = depends on quad→segment membership or on engine-internal
  rules, neither of which is readable from this repo (no `.nav_data` present).

## 1. `jewelry_store` — lines 359-371

**Block:** `jewelry_store`, `lua/_navdatapatches.lua:359-371`.

**Surviving edits**

- `:362` `append_room(-8, -12, 87, 86, 27.5, 27.5, 27.5, 27.5, 5)` — new quad in
  segment 5 (converter `:280-282`). VERIFIED.
- `:364` `append_door(Vector3(-12, 86, 27.5), Vector3(-11, 86, 27.5), 882, rid)`
  — new door, quad 882 ↔ new quad (converter `:262-265`). VERIFIED.
- `:368` `append_door(Vector3(-8, 86, 27.5), Vector3(-8, 87, 27.5), 826, rid)`
  — second new door, quad 826 ↔ new quad. VERIFIED (its link is never named in
  the dead writes, so the door is the sole carrier and it survives).

**Dead neighbour writes**

- `:365` `table.insert(data.nav_segments[5].neighbours[96], did)` — 5 ↔ 96,
  via the door from `:364`.
- `:366` `table.insert(data.nav_segments[96].neighbours[5], did)` — reverse.

**Verdict: `SURVIVES_AS_IS`.** The 5↔96 pair is expressed twice over: by the new
door at `:364` (existing quad 882 on one side, new segment-5 quad on the other)
and by the pre-existing 5↔96 doors that `table.insert` at `:365` presupposes
(inference: `table.insert` on a nil field raises; that this line did not raise
in the r200 source is UNVERIFIED, but if the field was nil the patch would have
aborted and the r200 changelog would show it). Either way the pair survives.

**Confidence: MEDIUM.** Safe because the conclusion does not depend on which
segment owns quad 882: if 882 ∈ 96 the new door recreates 5↔96; if 882 ∉ 96 the
old 5↔96 doors still exist untouched. UNVERIFIED residue: quad→segment
membership of 882 and 826, and the engine rule that a door whose two quads are
in two segments yields exactly that link.

**Player POV:** the small room/alcove reachable through the two added doorways
stays usable by AI.

## 2. `jolly` — lines 373-393

**Block:** `jolly`, `lua/_navdatapatches.lua:373-393`.

**Surviving edits**

- `:376` `room_borders_x_pos[2420] += 2`, `:377` `room_borders_y_neg[2420] -= 1`,
  `:378` `room_borders_y_pos[3445] += 1` → `quad_borders_*`
  (`navigationmanager.lua:254-257`). VERIFIED.
- `:380-381` `door_high_pos[4547]` shifted x+1 → `door_high_pos`
  (`:1787`). VERIFIED.
- `:388` `append_door(pos, pos1, 2420, 3445)` whose `pos`/`pos1` are derived from
  the edited room 3445 borders (`:383-386`) → new door, quads 2420 ↔ 3445
  (converter `:262-265`). VERIFIED.

**Dead neighbour writes**

- `:389` `data.nav_segments[141].neighbours[87] = { did }` — 141 ↔ 87, and
  simultaneously *narrows* 141's 87-list to the new door only.
- `:390` `data.nav_segments[87].neighbours = { [141] = { did } }` — 87 ↔ 141
  **and wipes every other neighbour of segment 87**.

**Verdict: `NEEDS_REWRITE`.** The connection 141↔87 survives via the door at
`:388`; the *seal* of segment 87 (removal of all its other links) has no
surviving expression. Evidence the seal is deliberate rather than Lua shorthand:
the same pair is assigned non-destructively on `:389` and destructively on
`:390` in the same block.

**Rewrite (if the seal matters):** a v6-expressible seal can only be a door/quad
edit, not a neighbour edit — reassign `door_low_rooms` / `door_high_rooms` of the
other doors that touch segment 87 so that both of their quads sit inside one
segment (those tables reach the engine: converter `:264-265`, payload `:1788-1789`).
Whether a same-segment door is inert for pathing is **UNVERIFIED**. If the seal
was not load-bearing, `DROP` `:389-390`; the block's surviving value is the 4
geometry edits plus 1 door.

**Confidence: MEDIUM** for "connection survives"; **LOW** for seal intent —
nothing in the repo shows what segment 87's other links were (no `.nav_data`).
Marked UNVERIFIED.

**Player POV:** the widened/relocated doorway still works; if the r200 patch was
also meant to stop AI reaching that room from a second side, that restriction is
gone at 248.2.

## 3. `kenaz` — lines 395-407

**Block:** `kenaz`, `lua/_navdatapatches.lua:395-407`.

**Surviving edits**

- `:398` `append_room(27, 23, -83, -84, -877.5 x4, 189)` — new quad in segment
  189. VERIFIED.
- `:400` `append_door(Vector3(23, -84, -877.5), Vector3(23, -83, -877.5), 1683, rid)`
  — quad 1683 ↔ new quad. VERIFIED.
- `:404` `append_door(Vector3(27, -84, ...), Vector3(27, -83, ...), 3468, rid)`
  — quad 3468 ↔ new quad; unnamed in the dead writes, so the door is the sole
  carrier. VERIFIED.

**Dead neighbour writes**

- `:401` `data.nav_segments[57].neighbours[189] = { did }` — 57 ↔ 189.
- `:402` `data.nav_segments[189].neighbours[57] = { did }` — reverse.

**Verdict: `SURVIVES_AS_IS`.** Both writes mirror the endpoints of the door at
`:400`; the second door `:404` adds a further link that nothing duplicates.

**Confidence: MEDIUM.** Assignments (not `table.insert`), so there is no
pre-existing-link presupposition here; the verdict rests on quad 1683 belonging
to segment 57 — **UNVERIFIED** (no nav data), corroborated only by the r200
author having picked that quad as the door's other side while naming 57.

**Player POV:** the doorway added around the level's outer area still connects
the same spaces.

## 4. `kosugi` — lines 409-451

**Block:** `kosugi`, `lua/_navdatapatches.lua:409-451`.

**Surviving edits**

- `:412-423` twelve `transfer_room(id, 2, 3)` — quads 1744, 1747, 1751, 1752,
  1753, 1755, 1756, 1758, 1759, 1766, 1767, 1772 move from segment 2 to 3
  (converter `:280-282`). VERIFIED.
- `:437` `append_vis_group(150, Vector3(4901.0, -2921.7, 975.9))` → new
  visibility group; `:884-887` of the helper also cross-links it with every
  existing group → converter `:269-287`. VERIFIED.
- `:438` `add_segment(150, ...)` → converter `:289-299`. VERIFIED.
- `:440` `append_room(204, 188, -77, -157, 982.69, 1000.94, 982.69, 1000.94, 150)`
  — new quad in the new segment. VERIFIED.
- `:442` `append_door(Vector3(188, -77, 982.69), Vector3(204, -77, 982.69), 1651, rid)`
  — quad 1651 ↔ new quad. VERIFIED.
- `:446` `append_door(Vector3(188, -157, 1000.94), Vector3(199, -157, 1000.94), 31, rid)`
  — quad 31 ↔ new quad. VERIFIED.

**Dead neighbour writes**

- `:425-430` copy `nav_segments[123].neighbours[2]` into `[123].neighbours[3]`
  and `[3].neighbours[123]`, then set `[2].neighbours[123] = nil` and
  `[123].neighbours[2] = nil` — i.e. re-point 123's links from 2 to 3, then
  delete 2 ↔ 123.
- `:432-433` `data.nav_segments[2].neighbours[3] = { 3028 }` and the reverse —
  force 2 ↔ 3 to the single door 3028.
- `:443-444` `nav_segments[150].neighbours[65] = { did }` and reverse — dock
  access, 150 ↔ 65.
- `:447-448` `nav_segments[150].neighbours[69] = { did }` and reverse —
  150 ↔ 69.

**Verdict: `SURVIVES_AS_IS`.** `:425-430` is exactly the transfer-induced
adjustment (every door that used to cross 2/123 now crosses 3/123, because one
endpoint changed owner), so recompute yields it and the `nil`s are satisfied
automatically. `:443-444` / `:447-448` mirror the endpoints of the doors at
`:442` / `:446`. The new segment + vis group + quad survive in full, which is
the block's headline feature (dock access).

**Residual, not a verdict change:** `:432-433` is a *narrowing* of an existing
link set to one door (3028) that no transfer induces. If that link was
previously carried by several doors, the narrowing is lost. UNVERIFIED whether
more doors ever existed.

**Confidence: MEDIUM.** Highest-value edits (vis group, segment, quad, two
doors, transfers) are VERIFIED; only the dependency on quad membership of quads
1651 and 31 (→ segments 65 / 69) and the 3028 narrowing are UNVERIFIED.

**Player POV:** the dock area gains a working nav segment, so AI can path onto
the pier the same way it did in r200.

## 5. `mex` — lines 453-472

**Block:** `mex`, `lua/_navdatapatches.lua:453-472`.

**Surviving edits**

- `:456-463` `transfer_room(id, 235, 192)` for 3908, 3916, 3907, 3896, 3906,
  3899, 3889, 3898 (converter `:280-282`). VERIFIED.
- `:467` `transfer_room(2627, 214, 192)`. VERIFIED.

**Dead neighbour writes**

- `:464` / `:465` `nav_segments[235].neighbours[192]` and the reverse =
  `{ 6866, 6867, 6868, 6833, 6834, 6835 }` — 235 ↔ 192 through six existing doors.
- `:468` / `:469` `nav_segments[214].neighbours[192]` and the reverse =
  `{ 4662, 4663, 4664 }` — 214 ↔ 192 through three existing doors.

**Verdict: `SURVIVES_AS_IS`.** This block is *only* ownership changes; the two
neighbour pairs are the door-induced consequence of those changes (the listed
doors had both endpoints inside 235/214 before the move and now straddle the
boundary), so recompute reproduces both lists. Nothing else in the block depends
on the dead writes.

**Confidence: MEDIUM-HIGH.** The door-id lists are themselves evidence that
those doors exist and that they straddle the new boundary; the only UNVERIFIED
assumption is that every listed door touches at least one moved quad — a door
that does not would lose its link.

**Player POV:** the interior/exterior split of the affected rooms stays as
intended, so AI uses the same doorways between those areas.

## 6. `mia_1` — lines 474-558

**Block:** `mia_1`, `lua/_navdatapatches.lua:474-558`.

**Surviving edits**

- `:478-539` — 36 `append_room` calls adding quads to segments 3, 20, 22, 9, 26,
  12, 48, 6, 5, 7, 8, 14, 13, 80 (each call's last argument is the segment;
  converter `:280-282`). VERIFIED as data; note **no doors are appended in this
  block**, so these rooms only extend their segment's area.
- `:541-548` eight `transfer_room(id, 20, 113)` (1901, 1902, 1903, 1904, 1905,
  1906, 1907, 1910). VERIFIED.
- `:552-553` `transfer_room(1945, 119, 22)`, `transfer_room(1946, 119, 22)`.
  VERIFIED.

**Dead neighbour writes**

- `:549` / `:550` `nav_segments[20].neighbours[113] = { 3207 }` and reverse —
  20 ↔ 113 through door 3207, after the 20→113 transfer.
- `:554` / `:555` `nav_segments[22].neighbours[119] = { 3276, 3277, 3281 }` and
  reverse — 22 ↔ 119 through three doors, after the 119→22 transfer.

**Verdict: `SURVIVES_AS_IS`.** Both writes are transfer-induced (doors 3207 and
3276/3277/3281 straddle the boundary that the transfers create), and the 36
appended quads carry no neighbour semantics at all. No connection in this block
is expressed *only* by a dead write.

**Confidence: MEDIUM.** Transfers and quad additions are VERIFIED; two
UNVERIFIED assumptions remain: (a) a quad appended to a segment is contiguous
with that segment's existing area — otherwise it is an isolated island, which
was equally true in v5 (`a3180fc:...:344-357` builds rooms with a `vis_group`
tag and no per-quad links); (b) the listed doors really touch the moved quads.

**Player POV:** the widened rooms/floors on this level stay walkable; underground
room access is unchanged.

## 7. `moon` — lines 560-577

**Block:** `moon`, `lua/_navdatapatches.lua:560-577`.

**Surviving edits**

- `:563` `room_borders_x_neg[2777] -= 1`, `:564` `room_borders_y_neg[2777] -= 1`
  → `quad_borders_*` (`navigationmanager.lua:255-257`). VERIFIED.
- `:566-571` `pos` copied from `door_high_pos[4981]`, offset by (-2, -2) then x+1,
  fed to `append_door(pos, pos1, 2777, 2758)` — new door, quads 2777 ↔ 2758.
  VERIFIED.

**Dead neighbour writes**

- `:573` `data.nav_segments[22].neighbours[23] = { #data.door_low_pos }` — 22 ↔ 23
  via the door just appended (`#data.door_low_pos` is the id returned by
  `append_door`, `_navdatapatches.lua:867-874`).
- `:574` `data.nav_segments[23].neighbours = { [22] = { #data.door_low_pos } }` —
  23 ↔ 22 **and wipes every other neighbour of segment 23**.

**Verdict: `NEEDS_REWRITE`.** Same class as `jolly`: the connection survives
through the door at `:571`, but the seal of segment 23 does not. A seal has no
v6 expression through quads/`append_*`; reproducing it needs door→quad
reassignment on segment 23's other doors (converter `:264-265`), and whether a
same-segment door is pathing-inert is **UNVERIFIED**. If the seal was
incidental, `DROP` `:573-574` and keep the door plus the two border edits.

**Confidence: MEDIUM** for the connection half (VERIFIED data path, UNVERIFIED
quad→segment for 2777/2758), **LOW** for seal intent (UNVERIFIED).

**Player POV:** the extra doorway still opens; a room that used to be sealed to a
single neighbouring area may now be reachable from other sides.

## 8. `pbr` — lines 579-596

**Block:** `pbr`, `lua/_navdatapatches.lua:579-596`.

**Surviving edits**

- `:582` `room_borders_y_pos[1222] = -286` → `quad_borders_y_pos`
  (`navigationmanager.lua:256`). VERIFIED.
- `:584` `append_door(Vector3(38, -287, -58), Vector3(38, -286, -82), 1147, 1222)`
  — new door, quads 1147 ↔ 1222 (a long door: 24 units in z, spanning the wall
  at y ≈ -286.5). VERIFIED.
- `:588` `room_borders_x_pos[5714] = -30`, `:589` `room_borders_y_pos[5714] = -96`.
  VERIFIED.
- `:591` `append_door(Vector3(-30, -97, -160.145), Vector3(-30, -96, -160.145), 990, 5714)`
  — new door, quads 990 ↔ 5714. VERIFIED.

**Dead neighbour writes**

- `:585` / `:586` `nav_segments[39].neighbours[40] = { did }` and reverse —
  39 ↔ 40 through the door from `:584`.
- `:592` / `:593` `nav_segments[30].neighbours[52] = { did }` and reverse —
  30 ↔ 52 through the door from `:591`.

**Verdict: `SURVIVES_AS_IS`.** Both pairs mirror the endpoints of a surviving
door; every edit in the block reaches the engine.

**Confidence: MEDIUM.** Data path VERIFIED; quad→segment mapping (1147∈39,
1222∈40, 990∈30, 5714∈52) is **UNVERIFIED**.

**Player POV:** the two opened accesses (one wide vehicle-scale opening, one
person-scale opening) remain usable by AI.

## 9. `peta` — lines 598-615

**Block:** `peta`, `lua/_navdatapatches.lua:598-615`.

**Surviving edits**

- `:601` `transfer_room(121, 53, 47)` — quad 121 moves to segment 47
  (converter `:280-282`). VERIFIED.
- `:605-610` `pos` from `door_high_pos[11860]` (y+4, then y+9) fed to
  `append_door(pos, pos1, 97, 5959)` — new door, quads 97 ↔ 5959. VERIFIED.

**Dead neighbour writes**

- `:602` / `:603` `nav_segments[53].neighbours[47] = { 201 }` and reverse —
  53 ↔ 47 via door 201; transfer-induced, redundant.
- `:611` `data.nav_segments[47].neighbours[91] = { did }` — 47 ↔ 91 via the new door.
- `:612` `data.nav_segments[91].neighbours = { [47] = { did } }` — 91 ↔ 47
  **and wipes every other neighbour of segment 91**.

**Verdict: `NEEDS_REWRITE`.** `:602-603` are redundant (transfer-induced,
survive by recompute). `:611` is redundant (door at `:610`). `:612` is a seal
with no surviving expression. Same rewrite basis as `jolly` / `moon`: door→quad
reassignment for 91's other doors, engine rule **UNVERIFIED**; otherwise `DROP`
`:611-612`.

**Confidence: MEDIUM** for the surviving half (transfer + door VERIFIED, quad
membership UNVERIFIED), **LOW** for seal intent (UNVERIFIED).

**Player POV:** the new shortcut doorway into the neighbouring area still exists;
if the r200 patch also closed that area off from every other side, that closure
is gone.

## 10. `roberts` — lines 617-627

**Block:** `roberts`, `lua/_navdatapatches.lua:617-627`.

**Surviving edits**

- `:621` `append_room(-30, -34, 101, 84, -18.14 x4, 218)` — new quad in segment 218.
  VERIFIED.
- `:624` `append_room(7, -10, 103, 95, -68.21 x4, 3)` — new quad in segment 3.
  VERIFIED.

**Dead neighbour writes**

- None. The block contains no `nav_segments` access at all.

**Verdict: `SURVIVES_AS_IS`.** Both edits are pure quad additions and reach the
converter and the engine payload unchanged. This is the cleanest of the eleven.

**Confidence: MEDIUM.** No neighbour semantics are involved, so the only
UNVERIFIED point is the same as `mia_1`: that a quad appended to a segment is
contiguous with that segment's area (otherwise the added floor is unreachable,
which would equally have been true pre-247).

**Player POV:** the extra floor patches around the two entries remain walkable, so
AI cover/patrol on them is unchanged from r200.

## 11. `watchdogs_1` — lines 639-677

**Block:** `watchdogs_1`, `lua/_navdatapatches.lua:639-677`.

**Surviving edits**

- `:642-645` `transfer_room(id, 134, 52)` for 896, 897, 898, 899 — four quads
  move from segment 134 to 52 (converter `:280-282`). VERIFIED.

**Dead neighbour writes** (all operate on the 134 ↔ 52 door lists)

- `:647-648` cache the two lists (`d134t52`, `d52t134`) — reads only.
- `:650-663` delete doors `1852, 1855, 1943, 1944, 1949, 1953, 1959, 1960` from
  both lists → tried to *remove* those 134 ↔ 52 connections.
- `:665-674` insert doors `1564, 1565, 1566, 1573` into both lists → tried to
  *add* those 134 ↔ 52 connections.

**Verdict: `SURVIVES_AS_IS`.** Both edits are the mechanical consequence of the
four transfers: a door with one endpoint among 896-899 flips from intra-134 to
134↔52 (the four inserts), and a door that already crossed 134↔52 and had a
moved endpoint becomes intra-52 (the eight deletes). Recompute derives exactly
that adjusted set, so no surviving expression is needed. The `table.delete` /
`table.insert` calls also imply both lists already exist, i.e. a 134↔52 link
exists natively.

**Residual, not a verdict change:** if the eight deletions were a *curation*
rather than the mechanical flip, the curation is lost. It is scoped to one
segment pair and is therefore more plausibly mechanical than the whole-table
wipes in `jolly` / `moon` / `peta`; the `kosugi` `:432-433` narrowing is the same
class of residual. UNVERIFIED.

**Confidence: MEDIUM.** Transfer path VERIFIED; the door-list flip and the engine
rule behind it are **UNVERIFIED** (no nav data, engine internals not in repo).

**Player POV:** the affected corridor keeps its intended 134/52 split, so AI
crosses between those areas through the same set of doorways.

## Summary

| Level | Lines | Verdict | Confidence | Rewrite needed? |
|---|---|---|---|---|
| `jewelry_store` | 359-371 | SURVIVES_AS_IS | MEDIUM | No |
| `jolly` | 373-393 | NEEDS_REWRITE | MEDIUM / LOW (seal) | Yes, if the seal of segment 87 matters — else drop 389-390 |
| `kenaz` | 395-407 | SURVIVES_AS_IS | MEDIUM | No |
| `kosugi` | 409-451 | SURVIVES_AS_IS | MEDIUM | No (residual: 432-433 narrows 2↔3 to door 3028) |
| `mex` | 453-472 | SURVIVES_AS_IS | MEDIUM-HIGH | No |
| `mia_1` | 474-558 | SURVIVES_AS_IS | MEDIUM | No |
| `moon` | 560-577 | NEEDS_REWRITE | MEDIUM / LOW (seal) | Yes, if the seal of segment 23 matters — else drop 573-574 |
| `pbr` | 579-596 | SURVIVES_AS_IS | MEDIUM | No |
| `peta` | 598-615 | NEEDS_REWRITE | MEDIUM / LOW (seal) | Yes, if the seal of segment 91 matters — else drop 611-612 |
| `roberts` | 617-627 | SURVIVES_AS_IS | MEDIUM | No |
| `watchdogs_1` | 639-677 | SURVIVES_AS_IS | MEDIUM | No (residual: 650-674 curation) |

Dead-write inventory: 8 of 11 blocks carry writes that only mirror surviving
`append_door` endpoints or the transfer-induced boundary flip, and can be deleted
with no data-path loss (`jewelry_store` 365-366, `kenaz` 401-402, `kosugi`
425-430 / 443-444 / 447-448, `mex` 464-465 / 468-469, `mia_1` 549-550 /
554-555, `pbr` 585-586 / 592-593, `peta` 602-603, `watchdogs_1` 647-674). Three
blocks also carry a whole-table wipe whose seal semantics are unexpressible
(`jolly` 390, `moon` 574, `peta` 612) — those are the only decisions that need a
human call.

## Not verified / out of scope

- No `.nav_data` in this repo, so every quad→segment membership claim above
  (882, 826, 1683, 3468, 1651, 31, 1147, 1222, 990, 5714, 97, 5959, 2777, 2758,
  2420, 3445) is **UNVERIFIED**.
- Engine-internal rules are **UNVERIFIED**: that a door crossing two segments
  yields that link, that a door with both quads in one segment yields none, and
  that quads added to a segment merge with its area.
- No runtime behaviour claimed. `_resolve_segment_neighbours` is called on every
  load (`navigationmanager.lua:231`), but what the engine returns is not
  observable statically.
- `jolly` / `moon` / `peta` seals: the r200 nav data that would show what was
  deleted is not in this repo (UNVERIFIED).
