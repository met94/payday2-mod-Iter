# Iter full-nav port — drop log

Functions or features removed instead of ported. Each entry says why and what
the player loses.

## Dropped in P1 (static decision, pending dossier confirmation)

| Item | Why | Player impact |
|---|---|---|
| `CivilianBrain.clbk_pathing_results` | function no longer exists at 248.2; nothing calls it | none; vanilla civilian pathing |
| `TeamAIBrain.clbk_pathing_results` | function no longer exists at 248.2 | none; vanilla team-AI pathing |

Both files are now inert (`return` only) and their hooks were removed from
`mod.txt` (hook count 17 -> 14). Git history keeps the r200 bodies.

## Deferred

| Item | Why | Revisit |
|---|---|---|
| `CopLogicIdle._perform_objective_action` | cosmetic animation variant (`e_so_ntl_idle_look3` -> `look2`); no nav impact | gated by `cop_idle_fix=false` |
| `CopActionWalk._chk_correct_pose` | reviewed: 8-line wrapper around an unchanged 28-line body; PORT in P4, not a drop | P4 done |

## Dropped in P6 (static decision, confirmed by dossier)

| Item | Why | Player impact |
|---|---|---|
| `CivilianLogicTravel._optimize_path` | r200 body predates the 242 statics raycast + padding improvements | civilians keep the better vanilla 248.2 pathing |

File is inert (`return` only) and its hook was removed from `mod.txt`.

## P7 cleanup — discarded neighbour writes

At 248.2 `_convert_nav_data_v5_to_v6` always creates v6 segments with an empty
`neighbours` table. Any explicit write to
`data.nav_segments[..].neighbours` in a v5 patch block is therefore discarded
before `_resolve_segment_neighbours` rebuilds the graph from doors/quads.

The dead writes were removed from every `SURVIVES_AS_IS` block (18 levels;
`arm_for`, `crojob2`, `escape_street` and `jolly` were confirmed by runtime
dumps first). Their topology survives through `append_door` / `transfer_room` /
quad edits. The two `applied_partial` blocks (`moon`, `peta`) keep their writes
until the accepted loss is revisited: removing them would make the remaining
intent harder to read, and the log status already tells the truth.
`skm_mallcrasher` / `mallcrasher` no longer carries neighbour writes; its seal
is rewritten as a quad transfer (A/B pending).

Accepted loss, no v6 expression:

| Level | Lost edit | Why |
|---|---|---|
| `framing_frame_1` | `nav_segments[1].neighbours[13] = nil` (and reverse) | a door that still joins quads of segments 1 and 13 keeps the link alive; there is no supported link delete. The split itself survives because the nine quads move to segment 100. |

## P7 accepted losses

| Level | Lost edit | Why | Player impact |
|---|---|---|---|
| `moon` | 22<->23 link through the appended door 4983 | Door geometry is exactly on the shared quad edge, but the engine does not derive a segment link. Visibility groups see each other (see_fwd/see_rev = 1/1), so that is not the gate. `navpath 22->23` fails. | AI will not use the added Stealing Xmas doorway; the area stays unreachable to AI as in vanilla. |
| `peta` | 53<->47 hat-shop link through door 201 | Same shape: door 201 is exactly on the shared edge of quads 126/121, visibility is 1/1, and `navpath 47->53` still fails. The block's other edit (new 47<->91 door) works and is kept. | AI cannot enter the hat shop through the intended doorway; the r200 hat-shop move is not reproduced. |

Both blocks stay `applied_partial` with their dead writes: the geometry still
runs, and the marker keeps the loss visible in the log.

## Candidate drops (confirm during P7)

- `_navdatapatches` entries whose only effect was explicit `neighbours` writes
  (69 writes): the v6 converter recomputes neighbours and discards them. A
  level patch survives only if its doors/quads produce the intended topology.
  Static audit: `dev/reports/p7-map-patch-audit.md`.
  - `skm_mallcrasher` is DEAD_ONLY: rewrite as a door/quad change or drop.
  - `dinner` and `flat` have no operations: drop the blocks.
- Patches whose CRC no longer matches the shipped nav data: skip with a
  `patch` event; do not fail the heist.
