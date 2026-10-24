# P7 map-patch audit — v6 survival

Source: `lua/_navdatapatches.lua` after the per-call refactor.
Static classification of each level block:

- **SURVIVES** — no dead neighbour writes; geometry/data edits reach the v6
  converter.
- **PARTIAL** — has geometry edits plus explicit `nav_segments[..].neighbours`
  writes. Geometry may express the same topology through doors/quads; the
  neighbour writes themselves are discarded by `_convert_nav_data_v5_to_v6`.
- **DEAD_ONLY** — only neighbour writes; the patch is a no-op at 248.2.

| Level | Verdict | Neighbour writes | Geometry ops | Other data edits |
|---|---|---:|---:|---:|
| alex_2 | PARTIAL | 2 | 9 | 1 |
| arm_fac | PARTIAL | 2 | 5 | 0 |
| arm_for | SURVIVES | 0 | 11 | 0 |
| big | SURVIVES | 0 | 0 | 4 |
| born | PARTIAL | 2 | 4 | 2 |
| branchbank | PARTIAL | 2 | 7 | 3 |
| chas | SURVIVES | 0 | 3 | 0 |
| crojob2 | SURVIVES | 0 | 4 | 0 |
| dinner | no-op | 0 | 0 | 0 |
| escape_park | SURVIVES | 0 | 0 | 12 |
| escape_street | PARTIAL | 2 | 10 | 0 |
| firestarter_1 | PARTIAL | 2 | 1 | 2 |
| flat | no-op | 0 | 0 | 0 |
| framing_frame_1 | PARTIAL | 6 | 2 | 2 |
| jewelry_store | PARTIAL | 2 | 3 | 0 |
| jolly | PARTIAL | 1 | 1 | 8 |
| kenaz | PARTIAL | 2 | 3 | 0 |
| kosugi | PARTIAL | 11 | 17 | 0 |
| mex | PARTIAL | 4 | 9 | 0 |
| mia_1 | PARTIAL | 4 | 46 | 0 |
| moon | PARTIAL | 1 | 1 | 4 |
| pbr | PARTIAL | 4 | 2 | 3 |
| peta | PARTIAL | 3 | 2 | 2 |
| roberts | SURVIVES | 0 | 2 | 0 |
| skm_mallcrasher | **DEAD_ONLY** | 2 | 0 | 0 |
| watchdogs_1 | PARTIAL | 2 | 4 | 23 |

## Runtime sample

Big Bank (`big`, SURVIVES): `evt=patch level=big result=applied`. The patch
sets `nav_segments[62].pos`, `room_borders_x_neg[489]` and two door positions;
all reach the v6 converter.

## Follow-up

1. `skm_mallcrasher` is a no-op at 248.2: rewrite as a door/quad change or
   drop it (candidate for `drop-log.md`).
2. `dinner` and `flat` have no nav-data operations; their `add_obstacle`
   side effects now live in a per-call wrapper (not file-load overrides).
3. PARTIAL levels need a per-level in-game check (T6): if the added doors
   produce the intended connectivity, remove the dead neighbour writes;
   otherwise re-express the connection as doors/quads. Status: the 16
   `SURVIVES_AS_IS` blocks are cleaned; the four partials and Mallcrasher
   keep their writes until the rewrite. `dev/tools/test/p7-dead-writes.test.mjs`
   guards the split.
4. Sample at least one PARTIAL level (Biker D1 `born`, Golden Grin `kenaz`)
   before calling P7 complete.

## Per-block audit

Two read-only audits cover every level block:

- `dev/reports/p7-partial-audit-a.md` — alex_2 … framing_frame_1.
- `dev/reports/p7-partial-audit-b.md` — jewelry_store … watchdogs_1.

Consolidated verdicts:

| Verdict | Levels |
|---|---|
| SURVIVES_AS_IS (16) | alex_2, arm_fac, arm_for, born, branchbank, chas, crojob2, firestarter_1, framing_frame_1, jewelry_store, kenaz, kosugi, mex, mia_1, pbr, roberts, watchdogs_1 |
| NEEDS_REWRITE (4) | escape_street, jolly, moon, peta |
| DEAD_ONLY (1) | skm_mallcrasher |
| no nav-data ops | dinner, flat (obstacle wrappers only) |

`crojob2` = The Bomb: Dockyard (level id; job id is `crojob1`).
The Bomb: Forest is level `crojob3` and has no r200 patch.

`arm_for` and `crojob2` (Dockyard) were verified by T6 dumps: the room
transfers already leave the intended doors in place; the old neighbour writes
were redundant. `escape_street`, `jolly`, `moon`, `peta` are logged as
`applied_partial`; their surviving geometry runs, but the neighbour-only
connection is lost until rewritten. `jolly`/`moon`/`peta` also lose a
neighbour-list seal; that needs an engine-side segment/state expression, not
a data write.

