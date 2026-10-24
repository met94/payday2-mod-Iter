# Iter full-nav port — drop log

Functions or features removed instead of ported. Each entry says why and what
the player loses.

## Dropped in P1 (static decision, pending dossier confirmation)

| Item | Why | Player impact |
|---|---|---|
| `CivilianBrain.clbk_pathing_results` | function no longer exists at 248.2; nothing calls it | none; vanilla civilian pathing |
| `TeamAIBrain.clbk_pathing_results` | function no longer exists at 248.2 | none; vanilla team-AI pathing |

## Deferred

| Item | Why | Revisit |
|---|---|---|
| `CopLogicIdle._perform_objective_action` | cosmetic animation variant (`e_so_ntl_idle_look3` -> `look2`); no nav impact | P6 |
| `CivilianLogicTravel._optimize_path` | r200 body predates the 242 vanilla improvements; likely inferior | P6 dossier, then drop or re-baseline |
| `CopActionWalk._chk_correct_pose` | 8-line r200 body vs 29-line 248.2 body; intent unclear without dossier | P6 |

## Candidate drops (confirm during P7)

- `_navdatapatches` entries whose only effect was explicit `neighbours` writes
  (69 writes): the v6 converter recomputes neighbours and discards them. A
  level patch survives only if its doors/quads produce the intended topology.
- Patches whose CRC no longer matches the shipped nav data: skip with a
  `patch` event; do not fail the heist.
