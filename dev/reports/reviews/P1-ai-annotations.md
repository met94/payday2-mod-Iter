# P1 AI-cluster annotation review

Scope: 17 dossiers in `dev/reports/dossiers/` annotated with `## Port notes (P1)`;
r200 = `98940fb`, old baseline `a3180fc` (246.1), target `e3a8b616` (248.2).
No dossiers were regenerated; only appended.

| function | wrapper/replace | decision | key evidence | open question |
|---|---|---|---|---|
| `CopBrain.search_for_coarse_path` | replace | PORT (P5) | `lua/copbrain.lua:18-54` no original call; 248.2 body `copbrain.lua:555-574` identical to 246.1; `to_pos` honoured at `navigationmanager.lua:1437` | `from_pos` write has no consumer in vanilla `_execute_coarce_search` (`:1236-1330`); only the ported search reads it (`lua/navigationmanager.lua:1109`) |
| `CopBrain.clbk_coarse_pathing_results` | wrapper | PORT (P3/P5) | capture `lua/copbrain.lua:56`, call `:86`; vanilla 3 lines `copbrain.lua:584-586` | stale `itr_direct_to_pos` never cleared when a later path has no navlinks (`:67-73`) |
| `CopBrain.clbk_pathing_results` | wrapper | PORT (P6) | capture `:89`, call `:91`; vanilla 41 lines `copbrain.lua:588-628` | `itr_append_next_step` is server-only (`copactionwalk.lua:40`) but called unguarded (`:96`) |
| `CopActionWalk._init` | wrapper | PORT (P6) | capture `copactionwalk.lua:15`, call `:31`; pre-expansion matches vanilla's two unsimplified branches (`:492-495`, read at `:502-508`) | calls `itr_prepare_for_upcoming_navlink` exactly when `self._sync` (client) though it is defined in `if Network:is_server()` (`:40`) |
| `CopActionWalk._chk_correct_pose` | wrapper | PORT (P4) | capture `:426`, call `:433`; 248.2 body 28 lines `:2762-2789` byte-identical to 246.1 (246.1 `:2740`) | no `shield` string anywhere in 248.2 `copactionwalk.lua`; `anim_global_switch` comes from tweak data (`copinventory.lua:152`) |
| `CopActionWalk._upd_nav_link_first_frame` | wrapper | PORT (P4) | capture `:416`, call `:423`; 9 lines `:2365-2373` identical; updator set at `:1014`, `:1324` | same shield-name gap; `on_exit` does not restore the global on a mid-climb interrupt |
| `CopLogicTravel._upd_pathing` | wrapper | PORT (P6) | capture `coplogictravel.lua:33`, call `:61`; file **byte-identical** 246.1↔248.2 | early `return` at `:53` skips vanilla's `data.pathing_results = nil` (`:354`) |
| `CopLogicTravel._get_exact_move_pos` | wrapper | PORT (P5 + P6) | capture `:64`, call `:103`; 98-line vanilla `:1411-1508`; `criminal1` still a team id (`levelstweakdata.lua:781`) | `itr_direct_to_pos` has no clear on objective change/`enter` |
| `CopLogicTravel._get_allowed_travel_nav_segs` | wrapper | PORT (P6) | capture `:106`, call `:114`; one-shot `itr_nav_segs`; consumer `copbrain.lua:509/528` | no retry when the restricted search fails |
| `CopLogicTravel.action_complete_clbk` | wrapper | PORT (P6) | capture `:314`, call `:320`; `expired()` still `self._expired` (`copactionwalk.lua:1431-1433`); team alias at `teamailogictravel.lua:20` | r200 restores `_expired` after the call, so listeners see a fake-expired action |
| `CopLogicTravel._check_start_path_ahead` | **replace** | REIMPLEMENT (P6) | no original call `:345-385`; vanilla 26 lines `:1369-1394`; only delta is `from_pos` (`:1390` `pos_rsrv.move_dest` vs r200 `:368` path tail) | `data.pos_rsrv` may be nil for units without a move_dest reservation |
| `CopLogicTravel.upd_advance` | wrapper | PORT (P6) | capture `:387`, call `:399`; vanilla 71 lines `:215-285` | r200 skips the whole vanilla tick (incl. `data.t = t` at `:219`) while `itr_want_path_ahead` is set |
| `CopLogicTravel._chk_request_action_walk_to_advance_pos` | wrapper (varargs) | PORT (P6) | capture `:330`, call `:338`; 248.2 signature now 7 args `:751`; vanilla start-point fixer `coplogicattack.lua:550-557` via `:753` | `_is_loud` is a delayed-listener file local; not observable in logs today |
| `CopLogicTravel._chk_stop_for_follow_unit` | **replace** | REIMPLEMENT (P6) | no original call `:264-312`; vanilla 25 lines `:1612-1636` sets `objective.in_place` + `on_new_objective` (`:1631-1633`) which r200 drops | first call always takes the `nil` branch (`data.itr_follow_unit_nav_seg` set only at `:311`) |
| `GroupAIStateBase.on_nav_seg_neighbour_state` | wrapper | PORT (P4) | capture `groupaistatebase.lua:4`, call `:6`; vanilla 35 lines `:4971-5005` untouched by 246.1→248.2; helper `lua/navigationmanager.lua:105-120`, consumer `:1142` | vanilla derefs `all_nav_segs[seg_id].disabled` (`:4983`) / `other_nav_seg.disabled` (`:4989`) without nil guards |
| `CopLogicIdle._perform_objective_action` | wrapper | DEFER | capture `coplogicidle.lua:8`, call `:13`; variant strings exist (`elementspecialobjective.lua:854-855`) | no record of which heist motivated the `look3`→`look2` swap |
| `CivilianLogicTravel._optimize_path` | **replace** | **DROP** | no original call `:13-76`; vanilla 57 lines `:119-175`; 242 commit `9af31e98` added `math.UP*4`, `World:raycast` statics, 75-110 padding — r200 has none | none; signature has no other caller |

## Explicit rulings

- `CivilianBrain.clbk_pathing_results` — **DROP**. Never existed in vanilla: `grep` finds no
  definition at 246.1 or 248.2 (ledger MOD_ONLY_HOOK, old 0 / new 0); `CivilianBrain = class(CopBrain)`
  (`civilianbrain.lua:10`) inherits `CopBrain.clbk_pathing_results` (`copbrain.lua:588`). r200's body is
  gated to `level_id == 'pal'` (`lua/civilianbrain.lua:8`) and its only payload is the dropped
  `_optimize_path`. Current worktree still installs it at `lua/civilianbrain.lua:12-21`; empty it at P6/A-04.
- `TeamAIBrain.clbk_pathing_results` — **DROP**, same evidence: no vanilla definition at either version,
  `TeamAIBrain = class(CopBrain)` (`teamaibrain.lua:9`), payload is `_optimize_path(path, true)`.
  Current worktree still installs it at `lua/teamaibrain.lua:8-17`.
- `CivilianLogicTravel._optimize_path` — **DROP**, stale by construction, not by age: it forks the
  pre-242 body (232.4 has no `math.UP`, no statics raycast, no padding) and would replace the 248.2
  version that has all three. Vanilla already calls it for hostages (`civilianlogictravel.lua:202`).
- `CopActionWalk._chk_correct_pose` — the 8-line r200 body is a **wrapper**, not a replacement, so the
  "8 vs 29" comparison was a category error; 248.2 has 28 lines, byte-identical to 246.1, and the
  captured original still works. Valid; PORT with the shield-name caveat.
