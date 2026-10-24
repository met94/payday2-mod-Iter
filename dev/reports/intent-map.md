# Iter full-nav port — intent map

Purpose: preserve what r200 was trying to do, not necessarily how it did it.
Every restored function gets one row here before its port task starts; the
generated per-function inventory is `dev/port-ledger.md`.

Status legend:

- **PORT** — target contract unchanged; adapt data shapes/keys and keep intent.
- **REIMPLEMENT** — old mechanism is dead; rebuild the intent on 248.2.
- **KEEP** — the mod's body still matches the current vanilla contract; port as-is.
- **DROP** — target no longer exists or the feature is superseded; record why.
- **DEFER** — valuable but blocked; keep out of the build and revisit later.

## Navigation features

### F1. Coarse-search weighting and cache

- **Intent:** pick long paths that account for nav-link waiting and vertical
  cost, not just raw distance; reuse cheap results briefly.
- **r200 mechanism:** full `_execute_coarce_search` override; Dijkstra over
  `itr_enabled_neighbours_i`; distance + z penalty + nav-link delay; 2 s cache
  keyed by access/start/end.
- **248.2 constraint:** search data shape changed (`seg_to_search`,
  `discovered_seg`, string ids, engine neighbours); caller now sets `from_pos`.
- **Decision:** REIMPLEMENT.
- **Target:** Iter weighting inside the 248.2 search contract; cache keyed by
  string ids + access; invalidate on segment state change.
- **Acceptance:** T4; `search` events show ok/fail/cache; no stale path after
  `set_nav_segment_state`.
- **Cost if wrong:** AI keeps vanilla distances; routes can be slightly less
  optimal, but pathing still works.

### F2. Streamliner and proxies

- **Intent:** remove silly detours at segment transitions; route through the
  middle of doorways and choke points rather than door corners.
- **r200 mechanism:** build room/visibility/ door graph, flood levels, choke
  points, in/out proxies; rewrite each coarse step's position; pick the best
  door/nav link.
- **248.2 constraint:** `_rooms`, `_room_doors`, `_visibility_groups` are not
  built; doors are Vector3/nav-link positions; segment ids are strings.
- **Decision:** REIMPLEMENT (shim + port).
- **Target:** rebuild rooms/doors/vis-groups from v5 load data; run the same
  flood/proxy intent on quads; apply `itr_streamline` to coarse paths.
- **Acceptance:** T1/T2; probe reduction in path length/points; no nil steps.
- **Cost if wrong:** paths stay vanilla; no movement risk if the flag is off.

### F3. Path extender

- **Intent:** keep NPCs moving through segment changes instead of pausing to
  start a new detailed path.
- **r200 mechanism:** precompute the next detailed path while walking; append
  to the live `CopActionWalk` simplified path; fake-complete handling.
- **248.2 constraint:** `CopActionWalk._init` and path helpers changed; live
  path mutation remains available but has different timing.
- **Decision:** REIMPLEMENT (P6), behind `path_extender`.
- **Target:** precompute and append on the current action; verify on
  `_calculate_simplified_path` and nav-link first-frame behavior.
- **Acceptance:** T5; no sliding, no double path, no stuck action.
- **Cost if wrong:** NPCs pause at segment changes; can be disabled.

### F4. Nav-link cleaner and intervals

- **Intent:** reduce artificial nav-link usage delays so units do not queue at
  ladders/jumps/climbs; still respect the animation.
- **r200 mechanism:** derive `itr_interval` from `so_action`; rewrite
  `values.interval`; manage `set_delay_time`.
- **248.2 constraint:** nav-link element lifecycle and `delay_time` still
  exist; element table must be maintained across register/unregister/obstruct.
- **Decision:** REIMPLEMENT.
- **Target:** element map keyed by nav-link key; interval table; apply delay
  in `_play_nav_link_anim`; restore on unregister.
- **Acceptance:** T3; queue lengths bounded; no unit waiting forever.
- **Cost if wrong:** vanilla delays remain; no correctness loss.

### F5. Nav-link congestion, queueing, load sharing

- **Intent:** spread units across parallel links and avoid conga lines;
  estimate wait and pick alternates.
- **r200 mechanism:** `_navlink_planned_use`, `itr_reserved_by_unit`,
  `itr_navlink_queue_length`, `itr_find_best_navlink`, sibling switch.
- **248.2 constraint:** same conceptual data, new element bookkeeping.
- **Decision:** REIMPLEMENT (largest behavioural piece).
- **Target:** reservation + queue + alternate selection with bounded state;
  expose counters for logs.
- **Acceptance:** T3; max queue threshold; switch success; no deadlock.
- **Cost if wrong:** vanilla link contention; disable flag.

### F6. Direct-to-pos

- **Intent:** in whisper-mode / straight-line objectives, walk directly to the
  objective instead of following a coarse path.
- **r200 mechanism:** `CopLogicTravel._get_exact_move_pos` shortcut using
  `my_data.itr_direct_to_pos`; skip coarse steps; release cover.
- **248.2 constraint:** `_get_exact_move_pos` is larger but the wrapper point
  remains; coarse path is `{seg,pos}`.
- **Decision:** PORT (small, high value).
- **Target:** wrapper that returns the objective pos only when the stored path
  is valid; restore path otherwise.
- **Acceptance:** T4; `direct` counter; no lost objectives.
- **Cost if wrong:** units keep the coarse path; low risk.

### F7. Shortcut finder

- **Intent:** cut a path when a straight walk is possible.
- **r200 mechanism:** sphere-cast/verification in
  `CopActionWalk._chk_shortcut_pos_to_pos`.
- **248.2 constraint:** function still exists; AI path and nav-link data
  changed.
- **Decision:** DEFER until P6; re-baseline against 248.2 and only port if the
  verification still matches the intent.
- **Acceptance:** T5.
- **Cost if wrong:** no shortcuts; paths follow the mesh.

### F8. Forbidden segments for followers

- **Intent:** keep team AI out of segments forbidden to them while following.
- **r200 mechanism:** `_get_allowed_travel_nav_segs` override and coarse path
  filtering.
- **248.2 constraint:** function still exists; segment state API changed to
  string ids.
- **Decision:** PORT in P6.
- **Acceptance:** T5.
- **Cost if wrong:** followers may path into forbidden segments; vanilla
  behaviour.

### F9. SO nav-link rebuild

- **Intent:** fix nav-link data where the start/search positions are in
  different segments.
- **r200 mechanism:** `ElementSpecialObjective._finalize_values` fixes the
  vector via `Iter:get_navlink_vector`.
- **248.2 constraint:** feature is already in Iter Lite and only uses trackers
  and `get_nav_seg_from_pos`; no v6 break known.
- **Decision:** KEEP (verify with T6).
- **Acceptance:** no nav-link mismatch logs.
- **Cost if wrong:** vanilla nav links; map fixes may regress.

### F10. Per-level nav-data patches

- **Intent:** fix map-specific nav holes, blocked doors, and access.
- **r200 mechanism:** 26 level blocks patching v5 rooms/doors/segments and
  neighbour lists, CRC-guarded.
- **248.2 constraint:** v5 converter still runs; converter discards explicit
  `neighbours`; doors/quads survive; level data may have drifted.
- **Decision:** REIMPLEMENT per level (P7).
- **Target:** v5 gate + CRC; keep geometry edits; replace dead neighbour
  writes where needed; per-level toggles.
- **Acceptance:** T6; `patch` event per level: applied/mismatch/skip.
- **Cost if wrong:** some map fixes off; no global break.

## AI cluster

| File / function | Intent | 248.2 constraint | Decision |
|---|---|---|---|
| `CopBrain.search_for_coarse_path` | pass objective pos / from pos into the search | caller contract stable; string ids | PORT (P5) |
| `CopBrain.clbk_coarse_pathing_results` | streamline before vanilla consumes the path; set direct-to-pos | wrapper point stable | PORT (P3/P5) |
| `CopBrain.clbk_pathing_results` | append next detailed path to live action | wrapper stable | PORT (P6) |
| `CopActionWalk._init` | expand one-point paths; prepare nav-link state | vanilla body changed; wrapper point stable | REIMPLEMENT (P6) |
| `CopActionWalk` nav-link methods | delay/queue/alternate/reservation | internals changed; re-baseline | REIMPLEMENT (P4) |
| `CopActionWalk._chk_correct_pose` | pose correction for nav links | wrapper (8 lines) around a 28-line unchanged 248.2 body | PORT (P4) |
| `CopActionWalk._upd_nav_link_first_frame` | first-frame nav-link update | wrapper around a 9-line unchanged body | PORT (P4) |
| `CopLogicTravel._get_exact_move_pos` | direct-to-pos | larger vanilla body; wrapper | PORT (P5) |
| `CopLogicTravel._check_start_path_ahead` | path extender | replacement; only delta is `from_pos` | REIMPLEMENT (P6) |
| `CopLogicTravel.upd_advance` | path extender tick | wrapper; skips vanilla tick | PORT (P6) |
| `CopLogicTravel._chk_request_action_walk_to_advance_pos` | prepend position for one-point path | signature extended | PORT (P6) |
| `CopLogicTravel._chk_stop_for_follow_unit` | follow-unit destination updates | body changed | REIMPLEMENT (P6) |
| `CopLogicTravel.itr_simplify_coarse_path` | prune backtracks / use streamline | custom helper; new path shape | REIMPLEMENT (P3) |
| `GroupAIStateBase.on_nav_seg_neighbour_state` | keep neighbour lists fresh | function exists | PORT (P4) |
| `CopLogicIdle._perform_objective_action` | animation variant fallback | cosmetic | DEFER |
| `CivilianBrain.clbk_pathing_results` | civilian path results | function gone (inherits CopBrain) | DROP |
| `TeamAIBrain.clbk_pathing_results` | team AI path results | function gone (inherits CopBrain) | DROP |
| `CivilianLogicTravel._optimize_path` | civilian path optimization | stale: predates 242 statics raycast + padding | DROP |

## Rulings

1. **Old baseline is `a3180fc` (246.1 restyle) for function parsing.** The
   pre-restyle `b36f5fbb` fails luaparse in two files; content is identical.
   Cost if wrong: body diffs use restyled text; no semantic drift expected.
2. **Ledger categories are inventory, not decisions.** Intent map owns the
   PORT/REIMPLEMENT/DROP/DEFER call. Cost if wrong: a stale function may look
   "keep" until its dossier is reviewed.
3. **`_navdatapatches` is intentionally unhooked.** It is `dofile`d by the nav
   overlay; the ledger's UNHOOKED flag is expected for that file.
4. **The overlay stays inert until each flag is enabled.** `nav_core_dev`
   guards dev sessions; `streamline_path` remains the user-facing master gate.
   Cost if wrong: a test build may look like vanilla until the flag is set.
