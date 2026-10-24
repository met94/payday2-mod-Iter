# P7 topology dump card

Status: Train Heist (`arm_for`) and The Bomb: Dockyard (`crojob2`) are done —
both survive as-is; their dead neighbour writes were removed.

Remaining: collect dumps for the four partial levels and Mallcrasher.

| Heist (level id) | Commands |
|---|---|
| Escape: Street (`escape_street`) | `!iter navdump 48` `!iter navdump 63` `!iter navdoors 48 63` |
| Aftershock (`jolly`) | `!iter navdump 87` `!iter navdump 141` `!iter navdoors 87 141` |
| Stealing Xmas (`moon`) | `!iter navdump 22` `!iter navdump 23` `!iter navdoors 22 23` |
| Goat Simulator D1 (`peta`) | `!iter navdump 47` `!iter navdump 53` `!iter navdump 91` `!iter navdoors 47 91` `!iter navdoors 47 53` |
| Mallcrasher (`skm_mallcrasher`) | `!iter navdump 8` `!iter navdump 11` `!iter navdoors 8 11` |

Notes:

- One command per chat line, each with `!iter`, no semicolons.
- Enable **Dev: v6 map patches** so dumps reflect patched data.
- Load heist → paste block → quit to menu. One log for the session.
- The Bomb: Forest (`crojob3`) and The Bomb: Dockyard (`crojob2`) are
  different levels; the r200 patch is Dockyard only.

