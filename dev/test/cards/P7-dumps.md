# P7 topology dump card

Goal: collect the v6 topology for the six partial map patches and the
dead-only Mallcrasher patch. Each command prints `[ITER-TEST]` lines; send
one log for the whole session.

Requirements:

- Build `3bbc5be` or newer (includes `navdump`/`navdoors`).
- Enable **Dev: v6 map patches** so dumps show the patched data.
- Load each heist, run the listed commands, quit to menu. No need to finish
  the heist.

| Heist (level id) | Commands |
|---|---|
| Transport: Train Heist (`arm_for`) | `!iter navdump 56` `!iter navdump 57` `!iter navdump 58` `!iter navdump 59` `!iter navdump 60` `!iter navdoors 56 57` `!iter navdoors 59 60` `!iter navdoors 58 59` |
| The Bomb: Forest (`crojob2`) | `!iter navdump 28` `!iter navdump 52` `!iter navdump 74` `!iter navdoors 28 52` `!iter navdoors 28 74` `!iter navdoors 52 74` |
| Escape: Street (`escape_street`) | `!iter navdump 48` `!iter navdump 63` `!iter navdoors 48 63` |
| Aftershock (`jolly`) | `!iter navdump 87` `!iter navdump 141` `!iter navdoors 87 141` |
| Stealing Xmas (`moon`) | `!iter navdump 22` `!iter navdump 23` `!iter navdoors 22 23` |
| Goat Simulator D1 (`peta`) | `!iter navdump 47` `!iter navdump 53` `!iter navdump 91` `!iter navdoors 47 91` `!iter navdoors 47 53` |
| Mallcrasher (`skm_mallcrasher`) | `!iter navdump 8` `!iter navdump 11` `!iter navdoors 8 11` |

Expected per command: `[ITER-TEST] navdump ...` / `navdoors ... total=N`.
No `[ITER-ERR]`, no crash. The numbers tell us which quads and door ids
need to be re-pointed for v6.
