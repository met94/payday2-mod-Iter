# ITER 248.2 API audit

Target: `e3a8b616`

- hooks: 17/17 ok
- method checks: 0/0 ok
- errors: 11
- review: 32

## Hook checks

| status | hook | script | note |
|---|---|---|---|
| ok | `core/lib/managers/coreworldinstancemanager` | `lua/coreworldinstancemanager.lua` |  |
| ok | `core/lib/managers/mission/coremissionmanager` | `lua/coremissionmanager.lua` |  |
| ok | `core/lib/utils/dev/editor/coreworlddefinition` | `lua/coreworlddefinition.lua` |  |
| ok | `lib/managers/localizationmanager` | `lua/localizationmanager.lua` |  |
| ok | `lib/managers/menumanager` | `lua/menumanager.lua` |  |
| ok | `lib/managers/missionmanager` | `lua/missionmanager.lua` |  |
| ok | `lib/managers/navigationmanager` | `lua/navigationmanager.lua` |  |
| ok | `lib/managers/group_ai_states/groupaistatebase` | `lua/groupaistatebase.lua` |  |
| ok | `lib/managers/mission/elementspecialobjective` | `lua/elementspecialobjective.lua` |  |
| ok | `lib/units/civilians/civilianbrain` | `lua/civilianbrain.lua` |  |
| ok | `lib/units/civilians/logics/civilianlogictravel` | `lua/civilianlogictravel.lua` |  |
| ok | `lib/units/enemies/cop/copbrain` | `lua/copbrain.lua` |  |
| ok | `lib/units/enemies/cop/actions/lower_body/copactionwalk` | `lua/copactionwalk.lua` |  |
| ok | `lib/units/enemies/cop/logics/coplogicidle` | `lua/coplogicidle.lua` |  |
| ok | `lib/units/enemies/cop/logics/coplogictravel` | `lua/coplogictravel.lua` |  |
| ok | `lib/units/player_team/teamaibrain` | `lua/teamaibrain.lua` |  |
| ok | `lib/units/props/drill` | `lua/drill.lua` |  |

## Hook method checks

None.

## Errors

- `lua/navigationmanager.lua:181` `_visibility_groups` — Never assigned in nav v6. `local vis_group_rooms = self._visibility_groups[i_vis_group].rooms`
- `lua/navigationmanager.lua:190` `_room_doors` — Removed in nav v6; doors are position vectors in segment.neighbours. `for door_id, door in pairs(self._room_doors) do`
- `lua/navigationmanager.lua:212` `get_nav_seg_from_i_room` — Reads _rooms/_visibility_groups, which nav v6 never builds. `if segment_id == self:get_nav_seg_from_i_room(room_id) then`
- `lua/navigationmanager.lua:226` `_room_doors` — Removed in nav v6; doors are position vectors in segment.neighbours. `local all_doors = self._room_doors`
- `lua/navigationmanager.lua:278` `_room_doors` — Removed in nav v6; doors are position vectors in segment.neighbours. `local all_doors = self._room_doors`
- `lua/navigationmanager.lua:332` `_rooms` — Removed at runtime in nav v6. `local room_data = self._rooms[room_id]`
- `lua/navigationmanager.lua:376` `_room_doors` — Removed in nav v6; doors are position vectors in segment.neighbours. `local all_doors = self._room_doors`
- `lua/navigationmanager.lua:525` `_room_doors` — Removed in nav v6; doors are position vectors in segment.neighbours. `local data = self._room_doors[door_id]`
- `lua/navigationmanager.lua:650` `_room_doors` — Removed in nav v6; doors are position vectors in segment.neighbours. `return self:itr_get_closest_door_to_pos(self._room_doors, door_list, nil, near_pos, nil, true)`
- `lua/navigationmanager.lua:747` `_room_doors` — Removed in nav v6; doors are position vectors in segment.neighbours. `return self:itr_get_closest_door_to_pos(self._room_doors, doors, nil, near_pos, access_pos, false)`
- `lua/navigationmanager.lua:752` `_room_doors` — Removed in nav v6; doors are position vectors in segment.neighbours. `local all_doors = self._room_doors`

## Review

- `lua/copactionwalk.lua:365` `_quad_field` — New engine surface; verify method/arg shapes. `_qf = managers.navigation._quad_field`
- `lua/copbrain.lua:43` `search_coarse` — Start/end validation added at 247. `managers.navigation:search_coarse(params)`
- `lua/coplogictravel.lua:296` `_quad_field` — New engine surface; verify method/arg shapes. `local pos = not managers.navigation._quad_field:is_nav_segment_blocked(follow_unit_nav_seg, data.SO_access) and managers.navigation:itr_get_door_between(data.itr_follow_unit_nav_seg, follow_unit_nav_s`
- `lua/drill.lua:14` `search_coarse` — Start/end validation added at 247. `if not managers.navigation:search_coarse(search_params) then`
- `lua/navigationmanager.lua:44` `_quad_field` — New engine surface; verify method/arg shapes. `local location_script_data = self._quad_field:get_script_data(nav_tracker)`
- `lua/navigationmanager.lua:46` `_quad_field` — New engine surface; verify method/arg shapes. `self._quad_field:destroy_nav_tracker(nav_tracker)`
- `lua/navigationmanager.lua:53` `_nav_segments` — Keyed by tostring(id); neighbours are door vectors. `local navseg = self._nav_segments and self._nav_segments[navseg_id]`
- `lua/navigationmanager.lua:60` `_nav_segments` — Keyed by tostring(id); neighbours are door vectors. `if not self._nav_segments[neighbour_seg_id].disabled then`
- `lua/navigationmanager.lua:132` `_nav_segments` — Keyed by tostring(id); neighbours are door vectors. `local nav_seg = self._nav_segments[nav_seg_id]`
- `lua/navigationmanager.lua:144` `_nav_segments` — Keyed by tostring(id); neighbours are door vectors. `local nav_seg = self._nav_segments[nav_seg_id]`
- `lua/navigationmanager.lua:166` `_nav_segments` — Keyed by tostring(id); neighbours are door vectors. `if self._nav_segments[id].neighbours then`
- `lua/navigationmanager.lua:167` `_nav_segments` — Keyed by tostring(id); neighbours are door vectors. `for neighbour_id in pairs(self._nav_segments[id].neighbours) do`
- `lua/navigationmanager.lua:179` `_nav_segments` — Keyed by tostring(id); neighbours are door vectors. `if self._nav_segments[segment_id] and next(self._nav_segments[segment_id].vis_groups) then`
- `lua/navigationmanager.lua:180` `_nav_segments` — Keyed by tostring(id); neighbours are door vectors. `for _, i_vis_group in ipairs(self._nav_segments[segment_id].vis_groups) do`
- `lua/navigationmanager.lua:377` `_nav_segments` — Keyed by tostring(id); neighbours are door vectors. `local all_nav_segments = self._nav_segments`
- `lua/navigationmanager.lua:502` `_nav_segments` — Keyed by tostring(id); neighbours are door vectors. `for segment_id, segment in pairs(self._nav_segments) do`
- `lua/navigationmanager.lua:506` `_nav_segments` — Keyed by tostring(id); neighbours are door vectors. `for segment_id, segment in pairs(self._nav_segments) do`
- `lua/navigationmanager.lua:510` `_nav_segments` — Keyed by tostring(id); neighbours are door vectors. `local neighbour_choke_point_proxies = self._nav_segments[neighbour_seg_id].choke_point_proxies`
- `lua/navigationmanager.lua:522` `_nav_segments` — Keyed by tostring(id); neighbours are door vectors. `for _, segment in pairs(self._nav_segments) do`
- `lua/navigationmanager.lua:534` `send_nav_field_to_engine` — Renamed _send_nav_field_to_engine(load_data); v5 data format. `local itr_original_navigationmanager_sendnavfieldtoengine = NavigationManager.send_nav_field_to_engine`
- `lua/navigationmanager.lua:535` `send_nav_field_to_engine` — Renamed _send_nav_field_to_engine(load_data); v5 data format. `function NavigationManager:send_nav_field_to_engine()`
- `lua/navigationmanager.lua:539` `_nav_segments` — Keyed by tostring(id); neighbours are door vectors. `for navseg_id in pairs(self._nav_segments) do`
- `lua/navigationmanager.lua:586` `_quad_field` — New engine surface; verify method/arg shapes. `local nav_tracker = self._quad_field:create_nav_tracker(door_pos, true)`
- `lua/navigationmanager.lua:588` `_quad_field` — New engine surface; verify method/arg shapes. `self._quad_field:destroy_nav_tracker(nav_tracker)`
- `lua/navigationmanager.lua:648` `_nav_segments` — Keyed by tostring(id); neighbours are door vectors. `local door_list = self._nav_segments[segment1_id].neighbours[segment2_id]`
- `lua/navigationmanager.lua:655` `_nav_segments` — Keyed by tostring(id); neighbours are door vectors. `local door_list = self._nav_segments[segment1_id].neighbours[segment2_id]`
- `lua/navigationmanager.lua:726` `_nav_segments` — Keyed by tostring(id); neighbours are door vectors. `local doors = self._nav_segments[segment1_id].neighbours[segment2_id]`
- `lua/navigationmanager.lua:731` `_nav_segments` — Keyed by tostring(id); neighbours are door vectors. `local segment1 = self._nav_segments[segment1_id]`
- `lua/navigationmanager.lua:751` `_nav_segments` — Keyed by tostring(id); neighbours are door vectors. `local all_segs = self._nav_segments`
- `lua/navigationmanager.lua:898` `_quad_field` — New engine surface; verify method/arg shapes. `if access_pos and self._quad_field:is_nav_segment_blocked(end_i_seg, access_pos) then`
- `lua/navigationmanager.lua:903` `_nav_segments` — Keyed by tostring(id); neighbours are door vectors. `local all_nav_segments = self._nav_segments`
- `lua/navigationmanager.lua:953` `_quad_field` — New engine surface; verify method/arg shapes. `elseif access_pos and self._quad_field:is_nav_segment_blocked(neighbour_seg_id, access_pos) then`

