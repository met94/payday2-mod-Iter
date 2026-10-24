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

## Candidate drops (confirm during P7)

- `_navdatapatches` entries whose only effect was explicit `neighbours` writes
  (69 writes): the v6 converter recomputes neighbours and discards them. A
  level patch survives only if its doors/quads produce the intended topology.
- Patches whose CRC no longer matches the shipped nav data: skip with a
  `patch` event; do not fail the heist.
