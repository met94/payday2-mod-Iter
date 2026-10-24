# P7 runtime card — dumps + path A/B

Status: Train Heist (`arm_for`) and The Bomb: Dockyard (`crojob2`) are done —
both survive as-is; their dead neighbour writes were removed.

Remaining: collect dumps for the four partial levels and Mallcrasher, then run
the `navpath` A/B for the same segment pairs.

## Order (each level, same session)

1. Menu: **Dev: v6 map patches** ON. Load the heist.
2. Run the dump commands for that level (below), one command per chat line.
3. Run `!iter navpath <from> <to>` for the listed pair(s).
4. Quit to menu. Menu: **Dev: v6 map patches** OFF. Reload the same heist.
5. Run the same `!iter navpath` pairs again. The `patches=` field must read
   `off`; this is the baseline.

Do not toggle mid-heist: patches apply in `NavigationManager:set_load_data`.

## Commands

| Heist (level id) | Patch on: dumps | navpath pairs |
|---|---|---|
| Escape: Street (`escape_street`) | `!iter navdump 48` `!iter navdump 63` `!iter navdoors 48 63` | `!iter navpath 63 48` |
| Aftershock (`jolly`) | `!iter navdump 87` `!iter navdump 141` `!iter navdoors 87 141` | `!iter navpath 141 87` + `!iter navpath 87 <X>` |
| Stealing Xmas (`moon`) | `!iter navdump 22` `!iter navdump 23` `!iter navdoors 22 23` | `!iter navpath 22 23` + `!iter navpath 23 <X>` |
| Goat Simulator D1 (`peta`) | `!iter navdump 47` `!iter navdump 53` `!iter navdump 91` `!iter navdoors 47 91` `!iter navdoors 47 53` | `!iter navpath 47 91` + `!iter navpath 91 <X>` |
| Mallcrasher (`skm_mallcrasher`) | `!iter navdump 8` `!iter navdump 11` `!iter navdoors 8 11` | none — patch is `skip_dead`; dump only |

`<X>` is any other neighbour of the sealed segment shown by its `navdump`
(`seg=87 -> <X> doors=...`). That pair is the seal test.

Also run `!iter patch` after each load to record `result=applied|applied_partial|skip_*`.

## What the dumps decide

- The quads under each segment's vis group and the door ids between the pair.
- For `jolly`/`moon`/`peta`: whether the r200 seal (whole neighbour table
  replaced) removed links that still exist as doors/quads at 248.2. If yes,
  the seal cannot be expressed as a data edit and needs an engine-side
  segment-state expression or an accepted loss.
- For `escape_street`: whether a segment-63 quad borders a segment-48 quad
  (door-less adjacency). If yes, the 63<->48 link may already come from the
  engine; if no, the block needs a new door.
- For `skm_mallcrasher`: which doors currently join segments 8 and 11. The
  r200 patch only emptied the neighbour lists; those doors are the reason the
  seal is dead at v6.

## Reading the A/B

`navpath` logs `level`, the live `patches` setting, `ok`, `steps`, `length`,
`direct` (door count on the from->to link) and `ids` (segment sequence).
Compare:

- add link: `direct` > 0 with patch, 0 without; `length`/`ids` may still
  differ because of a detour;
- seal: `direct` 0 with patch, > 0 without; route longer or different;
- move/edit: `length` or `ids` changes.

Confidence levels and the three separate claims: `dev/reports/p7-validation.md`.

Notes:

- One command per chat line, each with `!iter`, no semicolons.
- Load heist -> paste block -> quit to menu. One log for the session.
- The Bomb: Forest (`crojob3`) and The Bomb: Dockyard (`crojob2`) are
  different levels; the r200 patch is Dockyard only.
