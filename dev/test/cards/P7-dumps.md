# P7 runtime card — dumps + path A/B

Status: Train Heist (`arm_for`), The Bomb: Dockyard (`crojob2`), Escape:
Street (`escape_street`) and Aftershock (`jolly`) are done — all survive
as-is; their dead neighbour writes were removed. Patch-on dumps are collected
for the remaining levels: `dev/reports/p7-runtime-2026-10-24.md`. Remaining
P7 work: `moon`/`peta` are accepted losses; the skirmish `skm_mallcrasher`
rewrite is untested. The standard Vlad `mallcrasher` is a different heist and
out of scope.

The harness collects the data automatically. Enable **Dev: v6 map patches**,
load the heist, wait for the `p7auto` block in the log, quit. `!iter p7`
forces a run if the auto block is missing.

## Auto collection

On heist start the harness runs `!iter p7` automatically for:

| Heist (level id) | Logged |
|---|---|
| Escape: Street (`escape_street`) | `navdump 48 63`, `navdoors 48 63`, `navpath 63 48` |
| Aftershock (`jolly`) | `navdump 87 141`, `navdoors 87 141`, `navquad 2420 3445`, `navpath 141 87`, `navpath 87 <X>` |
| Stealing Xmas (`moon`) | `navdump 22 23`, `navdoors 22 23`, `navquad 2777 2758`, `navpath 22 23`, `navpath 23 <X>` |
| Goat Simulator D1 (`peta`) | `navdump 47 53 91`, `navdoors 47 91`, `navdoors 47 53`, `navquad 121 126`, `navpath 47 91`, `navpath 47 53`, `navpath 91 <X>` |
| Mallcrasher (skirmish `skm_mallcrasher` only) | `navdump 8 11`, `navdoors 8 11`, `navpath 8 11` (block is `skip_dead`) |

`<X>` is picked automatically as another neighbour of the sealed segment and
logged as `p7auto seal seg=… exclude=… alt=…`. That pair is the seal test.
For `jolly`/`peta` the sealed segment has only the intended neighbour and for
`moon` it has none, so the dump correctly logs `alt=none`; that is itself the
finding (seal already inherent / segment isolated).

The header records the live master gate: `p7auto level=… patches=on|off`.
`!iter p7` forces a re-run in the current heist; `!iter p7 auto off` disables
the automatic run.

### Escape: Street is not in Crime.net

It only appears as a random escape. Load any heist (host/solo), then type:

```
!iter force escape_street
```

This reuses the current network session and calls the game's level jump with
`tweak_data.levels.escape_street.world_name`. The escape loads, the auto dump
fires as usual, then quit to menu. Host only.

Skirmish levels (`group_ai_state == 'skirmish'`, e.g. `skm_mallcrasher`) are
refused: their job packages and mission state do not survive a mid-heist
switch (observed `NavigationManager:destroy` crash). Use Crime Spree.

## Run order

One pass per level, then a baseline pass:

1. Menu: **Dev: v6 map patches** ON. Load the heist. Wait ~2 s for the
   `p7auto` block. Quit to menu.
2. Repeat for the four Crime.net levels. For Escape: Street, load any heist
   and run `!iter force escape_street` in chat; the dump fires on the escape
   start. Then quit to menu.
3. Menu: **Dev: v6 map patches** OFF. Reload the two accepted-loss levels
   (moon, peta). Wait for the block. Quit. `skm_mallcrasher` needs a Crime
   Spree run; the standard `mallcrasher` is not patched.

Do not toggle mid-heist: patches apply in `NavigationManager:set_load_data`.

## Manual fallback (if `p7auto` is absent)

```
Escape: Street   !iter navdump 48 / navdump 63 / navdoors 48 63 / navpath 63 48
Aftershock       !iter navdump 87 / navdump 141 / navdoors 87 141 / navpath 141 87
Stealing Xmas    !iter navdump 22 / navdump 23 / navdoors 22 23 / navpath 22 23
Goat D1          !iter navdump 47 / navdump 53 / navdump 91 / navdoors 47 91 /
                 navdoors 47 53 / navpath 47 91
Mallcrasher      skirmish only: !iter navdump 8 / navdump 11 / navdoors 8 11
                 (standard Vlad job is a different heist, unpatched)
```

One command per chat line, each with `!iter`, no semicolons.

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
`direct` (door count on the from->to link), `see_fwd`/`see_rev` (visibility
groups list each other) and `ids` (segment sequence). Compare:

- add link: `direct` > 0 with patch, 0 without; `length`/`ids` may still
  differ because of a detour;
- seal: `direct` 0 with patch, > 0 without; route longer or different;
- move/edit: `length` or `ids` changes.

Confidence levels and the three separate claims: `dev/reports/p7-validation.md`.

Notes:

- The Bomb: Forest (`crojob3`) and The Bomb: Dockyard (`crojob2`) are
  different levels; the r200 patch is Dockyard only.
- One log for the whole session is fine; each `p7auto` block says its level
  and gate state.
