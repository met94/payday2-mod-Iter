# ITER 248.2 port — function ledger

Generated: 2026-10-24T12:37:01.312Z
Old baseline: `a3180fc`  Target: `e3a8b616`

Status is the proposed action. `PORT` = port ITER intent onto 248.2; `audit` = ITER-only, check API calls; `delete` = stale 246.1 copy; `keep` = no port work; `drop/rewrite` = target function gone; `BLOCKED` = parse failure.

Scope: top-level function definitions only. Nested helpers are folded into their parent function body and are ported with it.

## Totals

| category | count |
|---|---:|
| MOD_EDIT_VANILLA_CHANGED | 6 |
| MOD_ONLY_HOOK | 7 |
| MOD_ONLY | 55 |
| MOD_EDIT_CLEAN | 32 |

## lua/coreworldinstancemanager.lua

| done | status | function | mod L | old L | new L | note |
|---:|---|---|---:|---:|---:|---|
| [ ] | keep | `CoreWorldInstanceManager._get_instance_mission_data` | 14 | 15 | 15 |  |

## lua/coremissionmanager.lua

| done | status | function | mod L | old L | new L | note |
|---:|---|---|---:|---:|---:|---|
| [ ] | **PORT** | `MissionScript.load` | 19 | 17 | 25 |  |
| [ ] | audit | `_add_forbid_custom` | 19 | 0 | 0 |  |
| [ ] | audit | `_make_navlink` | 47 | 0 | 0 |  |
| [ ] | audit | `itr_mk_toggle` | 20 | 0 | 0 |  |
| [ ] | audit | `itr_mk_trigger` | 23 | 0 | 0 |  |
| [ ] | keep | `MissionManager._add_script` | 9 | 3 | 3 |  |
| [ ] | keep | `MissionScript._create_elements` | 21 | 16 | 16 |  |
| [ ] | keep | `MissionScript.save` | 11 | 15 | 15 |  |

## lua/coreworlddefinition.lua

| done | status | function | mod L | old L | new L | note |
|---:|---|---|---:|---:|---:|---|
| [ ] | keep | `WorldDefinition._create_statics_unit` | 9 | 5 | 5 |  |
| [ ] | keep | `WorldDefinition.create` | 17 | 220 | 220 |  |

## lua/localizationmanager.lua

No function definitions (hook/overlay file).

## lua/menumanager.lua

| done | status | function | mod L | old L | new L | note |
|---:|---|---|---:|---:|---:|---|
| [ ] | audit | `IterMenuCreator.modify_node` | 16 | 0 | 0 |  |

## lua/missionmanager.lua

| done | status | function | mod L | old L | new L | note |
|---:|---|---|---:|---:|---:|---|
| [ ] | audit | `ElementAINavSeg.client_on_executed` | 3 | 0 | 0 |  |
| [ ] | audit | `ElementAINavSeg.init` | 3 | 0 | 0 |  |
| [ ] | audit | `ElementAINavSeg.on_executed` | 12 | 0 | 0 |  |
| [ ] | audit | `ElementChangeBodyProperty._change` | 14 | 0 | 0 |  |
| [ ] | audit | `ElementChangeBodyProperty.client_on_executed` | 3 | 0 | 0 |  |
| [ ] | audit | `ElementChangeBodyProperty.init` | 3 | 0 | 0 |  |
| [ ] | audit | `ElementChangeBodyProperty.on_executed` | 14 | 0 | 0 |  |
| [ ] | audit | `ElementDeleteVehicle.on_executed` | 4 | 0 | 0 |  |

## lua/navigationmanager.lua

| done | status | function | mod L | old L | new L | note |
|---:|---|---|---:|---:|---:|---|
| [ ] | **PORT** | `NavigationManager.clbk_navfield` | 35 | 163 | 176 |  |
| [ ] | **PORT** | `NavigationManager.register_cover_units` | 27 | 80 | 75 |  |
| [ ] | **PORT** | `NavigationManager.set_nav_segment_state` | 13 | 36 | 38 |  |
| [ ] | **PORT** | `NavigationManager.unregister_anim_nav_link` | 14 | 63 | 69 |  |
| [ ] | audit (hook) | `Hooks.PostHook:NavigationManager._clear:Iter_nav_shim_clear` | 12 | 0 | 0 | Hooks:PostHook/PreHook callback; audit and port with the hooked method |
| [ ] | audit (hook) | `Hooks.PostHook:NavigationManager._resolve_segment_neighbours:Iter_nav_prepare` | 3 | 0 | 0 | Hooks:PostHook/PreHook callback; audit and port with the hooked method |
| [ ] | audit (hook) | `Hooks.PostHook:NavigationManager._send_nav_field_to_engine:Iter_nav_shim_rebuild` | 3 | 0 | 0 | Hooks:PostHook/PreHook callback; audit and port with the hooked method |
| [ ] | audit (hook) | `Hooks.PostHook:NavigationManager.on_simulation_ended:Iter_nav_link_summary` | 21 | 0 | 0 | Hooks:PostHook/PreHook callback; audit and port with the hooked method |
| [ ] | audit (hook) | `Hooks.PostHook:NavigationManager.on_simulation_ended:Iter_nav_summary` | 5 | 0 | 0 | Hooks:PostHook/PreHook callback; audit and port with the hooked method |
| [ ] | audit (hook) | `Hooks.PostHook:NavigationManager.set_load_data:Iter_nav_heist` | 31 | 0 | 0 | Hooks:PostHook/PreHook callback; audit and port with the hooked method |
| [ ] | audit (hook) | `Hooks.PostHook:NavigationManager.update:Iter_nav_heartbeat` | 35 | 0 | 0 | Hooks:PostHook/PreHook callback; audit and port with the hooked method |
| [ ] | audit | `get_coarse_dis` | 8 | 0 | 0 |  |
| [ ] | audit | `is_vec3` | 9 | 0 | 0 |  |
| [ ] | audit | `itr_add_door_pos_to` | 10 | 0 | 0 |  |
| [ ] | audit | `itr_get_door_in_alignment` | 31 | 0 | 0 |  |
| [ ] | audit | `itr_get_navlink_usage` | 17 | 0 | 0 |  |
| [ ] | audit | `itr_get_rooms_having_access_to_next_level` | 16 | 0 | 0 |  |
| [ ] | audit | `itr_log_navlink_usage` | 12 | 0 | 0 |  |
| [ ] | audit | `NavigationManager.itr_copy_door_data` | 11 | 0 | 0 |  |
| [ ] | audit | `NavigationManager.itr_execute_coarce_search` | 197 | 0 | 0 |  |
| [ ] | audit | `NavigationManager.itr_find_best_navlink` | 47 | 0 | 0 |  |
| [ ] | audit | `NavigationManager.itr_find_choke_point` | 24 | 0 | 0 |  |
| [ ] | audit | `NavigationManager.itr_find_proxies` | 153 | 0 | 0 |  |
| [ ] | audit | `NavigationManager.itr_flood` | 50 | 0 | 0 |  |
| [ ] | audit | `NavigationManager.itr_get_accessibility` | 34 | 0 | 0 |  |
| [ ] | audit | `NavigationManager.itr_get_all_doors_of_segment` | 30 | 0 | 0 |  |
| [ ] | audit | `NavigationManager.itr_get_closest_door_to_pos` | 98 | 0 | 0 |  |
| [ ] | audit | `NavigationManager.itr_get_coarse_pos_between` | 31 | 0 | 0 |  |
| [ ] | audit | `NavigationManager.itr_get_door_between` | 31 | 0 | 0 |  |
| [ ] | audit | `NavigationManager.itr_get_room_to_doors` | 16 | 0 | 0 |  |
| [ ] | audit | `NavigationManager.itr_is_contiguous` | 41 | 0 | 0 |  |
| [ ] | audit | `NavigationManager.itr_make_neighbours_list` | 16 | 0 | 0 |  |
| [ ] | audit | `NavigationManager.itr_prepare_nav_data` | 36 | 0 | 0 |  |
| [ ] | audit | `NavigationManager.itr_prepare_streamline_data` | 18 | 0 | 0 |  |
| [ ] | audit | `NavigationManager.itr_streamline` | 64 | 0 | 0 |  |
| [ ] | audit | `path_copy` | 12 | 0 | 0 |  |
| [ ] | keep | `NavigationManager.register_anim_nav_link` | 66 | 45 | 45 |  |

## lua/groupaistatebase.lua

| done | status | function | mod L | old L | new L | note |
|---:|---|---|---:|---:|---:|---|
| [ ] | keep | `GroupAIStateBase.on_nav_seg_neighbour_state` | 6 | 35 | 35 |  |

## lua/elementspecialobjective.lua

| done | status | function | mod L | old L | new L | note |
|---:|---|---|---:|---:|---:|---|
| [ ] | audit | `Iter.get_navlink_vector` | 11 | 0 | 0 |  |
| [ ] | keep | `ElementSpecialObjective._finalize_values` | 19 | 105 | 105 |  |

## lua/copbrain.lua

| done | status | function | mod L | old L | new L | note |
|---:|---|---|---:|---:|---:|---|
| [ ] | keep | `CopBrain.clbk_coarse_pathing_results` | 31 | 3 | 3 |  |
| [ ] | keep | `CopBrain.clbk_pathing_results` | 21 | 41 | 41 |  |
| [ ] | keep | `CopBrain.search_for_coarse_path` | 37 | 20 | 20 |  |

## lua/copactionwalk.lua

| done | status | function | mod L | old L | new L | note |
|---:|---|---|---:|---:|---:|---|
| [ ] | **PORT** | `CopActionWalk.on_exit` | 7 | 47 | 49 |  |
| [ ] | audit | `CopActionWalk.itr_append_next_step` | 31 | 0 | 0 |  |
| [ ] | audit | `CopActionWalk.itr_check_extensible` | 19 | 0 | 0 |  |
| [ ] | audit | `CopActionWalk.itr_check_navlink_delay` | 9 | 0 | 0 |  |
| [ ] | audit | `CopActionWalk.itr_clear_navlink_reservation` | 13 | 0 | 0 |  |
| [ ] | audit | `CopActionWalk.itr_delete_path_ahead` | 22 | 0 | 0 |  |
| [ ] | audit | `CopActionWalk.itr_get_alternate_navlink` | 11 | 0 | 0 |  |
| [ ] | audit | `CopActionWalk.itr_get_wait_pos` | 5 | 0 | 0 |  |
| [ ] | audit | `CopActionWalk.itr_prepare_for_upcoming_navlink` | 38 | 0 | 0 |  |
| [ ] | audit | `CopActionWalk.itr_reserve_navlink` | 32 | 0 | 0 |  |
| [ ] | audit | `CopActionWalk.itr_set_navlink_delay` | 10 | 0 | 0 |  |
| [ ] | audit | `CopActionWalk.itr_switch_to_sibling_navlink` | 53 | 0 | 0 |  |
| [ ] | audit | `CopActionWalk.itr_update_navlink_queue_data` | 17 | 0 | 0 |  |
| [ ] | audit | `CopActionWalk.itr_update_wait_for_navlink_availability` | 27 | 0 | 0 |  |
| [ ] | keep | `CopActionWalk._advance_simplified_path` | 22 | 11 | 11 |  |
| [ ] | keep | `CopActionWalk._chk_correct_pose` | 8 | 28 | 28 |  |
| [ ] | keep | `CopActionWalk._chk_shortcut_pos_to_pos` | 50 | 11 | 11 |  |
| [ ] | keep | `CopActionWalk._init` | 23 | 160 | 160 |  |
| [ ] | keep | `CopActionWalk._play_nav_link_anim` | 11 | 93 | 93 |  |
| [ ] | keep | `CopActionWalk._upd_nav_link_first_frame` | 8 | 9 | 9 |  |

## lua/coplogicidle.lua

| done | status | function | mod L | old L | new L | note |
|---:|---|---|---:|---:|---:|---|
| [ ] | keep | `CopLogicIdle._perform_objective_action` | 6 | 25 | 25 |  |

## lua/coplogictravel.lua

| done | status | function | mod L | old L | new L | note |
|---:|---|---|---:|---:|---:|---|
| [ ] | audit | `_on_enemy_weapons_hot` | 3 | 0 | 0 |  |
| [ ] | audit | `_update_destination` | 17 | 0 | 0 |  |
| [ ] | audit | `CopLogicTravel.itr_simplify_coarse_path` | 127 | 0 | 0 |  |
| [ ] | keep | `CopLogicTravel._begin_coarse_pathing` | 8 | 19 | 19 |  |
| [ ] | keep | `CopLogicTravel._check_start_path_ahead` | 41 | 26 | 26 |  |
| [ ] | keep | `CopLogicTravel._chk_request_action_walk_to_advance_pos` | 13 | 31 | 31 |  |
| [ ] | keep | `CopLogicTravel._chk_stop_for_follow_unit` | 50 | 25 | 25 |  |
| [ ] | keep | `CopLogicTravel._get_allowed_travel_nav_segs` | 9 | 37 | 37 |  |
| [ ] | keep | `CopLogicTravel._get_exact_move_pos` | 41 | 98 | 98 |  |
| [ ] | keep | `CopLogicTravel._upd_pathing` | 29 | 44 | 44 |  |
| [ ] | keep | `CopLogicTravel.action_complete_clbk` | 11 | 104 | 104 |  |
| [ ] | keep | `CopLogicTravel.enter` | 11 | 150 | 150 |  |
| [ ] | keep | `CopLogicTravel.upd_advance` | 14 | 71 | 71 |  |

## lua/drill.lua

| done | status | function | mod L | old L | new L | note |
|---:|---|---|---:|---:|---:|---|
| [ ] | keep | `Drill._unregister_investigate_SO` | 25 | 19 | 19 |  |
| [ ] | keep | `Drill.clbk_investigate_SO_verification` | 18 | 25 | 25 |  |
| [ ] | keep | `Drill.on_investigate_SO_administered` | 7 | 8 | 8 |  |

## lua/civilianbrain.lua

**UNHOOKED FILE** — not referenced by mod.txt; it never loads.

## lua/civilianlogictravel.lua

**UNHOOKED FILE** — not referenced by mod.txt; it never loads.

## lua/corecode.lua

**UNHOOKED FILE** — not referenced by mod.txt; it never loads.

## lua/iter_diag.lua

**UNHOOKED FILE** — not referenced by mod.txt; it never loads.

## lua/iter_nav_v6_shim.lua

**UNHOOKED FILE** — not referenced by mod.txt; it never loads.

## lua/teamaibrain.lua

**UNHOOKED FILE** — not referenced by mod.txt; it never loads.

## lua/_navdatapatches.lua

**UNHOOKED FILE** — not referenced by mod.txt; it never loads.

