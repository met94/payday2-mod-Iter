# ITER 248.2 API audit

Target: `e3a8b616`

- hooks: 14/14 ok
- method checks: 8/8 ok
- errors: 12
- review: 32
- suppressed (allowlisted): 12
- unused allowlist entries: 0

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
| ok | `lib/units/enemies/cop/copbrain` | `lua/copbrain.lua` |  |
| ok | `lib/units/enemies/cop/actions/lower_body/copactionwalk` | `lua/copactionwalk.lua` |  |
| ok | `lib/units/enemies/cop/logics/coplogicidle` | `lua/coplogicidle.lua` |  |
| ok | `lib/units/enemies/cop/logics/coplogictravel` | `lua/coplogictravel.lua` |  |
| ok | `lib/units/props/drill` | `lua/drill.lua` |  |

## Hook method checks

| status | hook | class.method | id |
|---|---|---|---|
| ok | PostHook | `NavigationManager._send_nav_field_to_engine` | `Iter_nav_shim_rebuild` |
| ok | PostHook | `NavigationManager._clear` | `Iter_nav_shim_clear` |
| ok | PostHook | `NavigationManager.set_load_data` | `Iter_nav_heist` |
| ok | PostHook | `NavigationManager.on_simulation_ended` | `Iter_nav_summary` |
| ok | PostHook | `NavigationManager.update` | `Iter_nav_heartbeat` |
| ok | PostHook | `NavigationManager.on_simulation_ended` | `Iter_nav_link_summary` |
| ok | PostHook | `NavigationManager._resolve_segment_neighbours` | `Iter_nav_prepare` |
| ok | PostHook | `NavigationManager._clear` | `Iter_patch_obstacle_clear` |

## Errors

- `lua/navigationmanager.lua:361` `_visibility_groups` - Never assigned in nav v6. `local vis_group_rooms = self._visibility_groups[i_vis_group].rooms`
- `lua/navigationmanager.lua:370` `_room_doors` - Removed in nav v6; doors are position vectors in segment.neighbours. `for door_id, door in pairs(self._room_doors) do`
- `lua/navigationmanager.lua:392` `get_nav_seg_from_i_room` - Reads _rooms/_visibility_groups, which nav v6 never builds. `if segment_id == self:get_nav_seg_from_i_room(room_id) then`
- `lua/navigationmanager.lua:406` `_room_doors` - Removed in nav v6; doors are position vectors in segment.neighbours. `local all_doors = self._room_doors`
- `lua/navigationmanager.lua:458` `_room_doors` - Removed in nav v6; doors are position vectors in segment.neighbours. `local all_doors = self._room_doors`
- `lua/navigationmanager.lua:512` `_rooms` - Removed at runtime in nav v6. `local room_data = self._rooms[room_id]`
- `lua/navigationmanager.lua:559` `_room_doors` - Removed in nav v6; doors are position vectors in segment.neighbours. `local all_doors = self._room_doors`
- `lua/navigationmanager.lua:734` `_room_doors` - Removed in nav v6; doors are position vectors in segment.neighbours. `for door_id, door in pairs(self._room_doors or {}) do`
- `lua/navigationmanager.lua:925` `_room_doors` - Removed in nav v6; doors are position vectors in segment.neighbours. `local door = self._room_doors[door_id]`
- `lua/navigationmanager.lua:945` `_room_doors` - Removed in nav v6; doors are position vectors in segment.neighbours. `return self:itr_get_closest_door_to_pos(self._room_doors, door_list, nil, near_pos, nil, true)`
- `lua/navigationmanager.lua:1059` `_room_doors` - Removed in nav v6; doors are position vectors in segment.neighbours. `return self:itr_get_closest_door_to_pos(self._room_doors, doors, nil, near_pos, access_pos, false)`
- `lua/navigationmanager.lua:1075` `_room_doors` - Removed in nav v6; doors are position vectors in segment.neighbours. `local all_doors = self._room_doors`

## Review

- `lua/copactionwalk.lua:395` `_quad_field` - New engine surface; verify method/arg shapes. `_qf = managers.navigation._quad_field`
- `lua/copbrain.lua:78` `search_coarse` - Start/end validation added at 247. `managers.navigation:search_coarse(params)`
- `lua/coplogictravel.lua:300` `_quad_field` - New engine surface; verify method/arg shapes. `local pos = nav.itr_get_door_between and not nav._quad_field:is_nav_segment_blocked(follow_unit_nav_seg, data.SO_access) and nav:itr_get_door_between(data.itr_follow_unit_nav_seg, follow_unit_nav_seg,`
- `lua/drill.lua:14` `search_coarse` - Start/end validation added at 247. `if not managers.navigation:search_coarse(search_params) then`
- `lua/navigationmanager.lua:43` `_nav_segments` - Keyed by tostring(id); neighbours are door vectors. `for key, segment in pairs(self._nav_segments or {}) do`
- `lua/navigationmanager.lua:51` `_nav_segments` - Keyed by tostring(id); neighbours are door vectors. `if not self._nav_segments[neighbour_id] then`
- `lua/navigationmanager.lua:60` `_nav_segments` - Keyed by tostring(id); neighbours are door vectors. `segments = table.size(self._nav_segments or {}),`
- `lua/navigationmanager.lua:119` `_quad_field` - New engine surface; verify method/arg shapes. `local location_script_data = self._quad_field:get_script_data(nav_tracker)`
- `lua/navigationmanager.lua:123` `_quad_field` - New engine surface; verify method/arg shapes. `self._quad_field:destroy_nav_tracker(nav_tracker)`
- `lua/navigationmanager.lua:131` `_nav_segments` - Keyed by tostring(id); neighbours are door vectors. `local navseg = self._nav_segments and self._nav_segments[unique_id]`
- `lua/navigationmanager.lua:138` `_nav_segments` - Keyed by tostring(id); neighbours are door vectors. `local neighbour = self._nav_segments[neighbour_seg_id]`
- `lua/navigationmanager.lua:306` `_nav_segments` - Keyed by tostring(id); neighbours are door vectors. `local nav_seg = self._nav_segments[nav_seg_id]`
- `lua/navigationmanager.lua:321` `_nav_segments` - Keyed by tostring(id); neighbours are door vectors. `local nav_seg = self._nav_segments[nav_seg_id]`
- `lua/navigationmanager.lua:345` `_nav_segments` - Keyed by tostring(id); neighbours are door vectors. `local nav_seg = self._nav_segments[unique_id]`
- `lua/navigationmanager.lua:359` `_nav_segments` - Keyed by tostring(id); neighbours are door vectors. `if self._nav_segments[segment_id] and next(self._nav_segments[segment_id].vis_groups or {}) then`
- `lua/navigationmanager.lua:360` `_nav_segments` - Keyed by tostring(id); neighbours are door vectors. `for _, i_vis_group in ipairs(self._nav_segments[segment_id].vis_groups) do`
- `lua/navigationmanager.lua:560` `_nav_segments` - Keyed by tostring(id); neighbours are door vectors. `local all_nav_segments = self._nav_segments`
- `lua/navigationmanager.lua:713` `_nav_segments` - Keyed by tostring(id); neighbours are door vectors. `for segment_id, segment in pairs(self._nav_segments) do`
- `lua/navigationmanager.lua:717` `_nav_segments` - Keyed by tostring(id); neighbours are door vectors. `for segment_id, segment in pairs(self._nav_segments) do`
- `lua/navigationmanager.lua:721` `_nav_segments` - Keyed by tostring(id); neighbours are door vectors. `local neighbour = self._nav_segments[neighbour_seg_id]`
- `lua/navigationmanager.lua:754` `_nav_segments` - Keyed by tostring(id); neighbours are door vectors. `for navseg_id in pairs(self._nav_segments) do`
- `lua/navigationmanager.lua:762` `_nav_segments` - Keyed by tostring(id); neighbours are door vectors. `for _, segment in pairs(self._nav_segments) do`
- `lua/navigationmanager.lua:838` `_quad_field` - New engine surface; verify method/arg shapes. `local nav_tracker = self._quad_field:create_nav_tracker(door_pos, true)`
- `lua/navigationmanager.lua:842` `_quad_field` - New engine surface; verify method/arg shapes. `self._quad_field:destroy_nav_tracker(nav_tracker)`
- `lua/navigationmanager.lua:943` `_nav_segments` - Keyed by tostring(id); neighbours are door vectors. `local door_list = self._nav_segments[segment1_id].neighbours[segment2_id]`
- `lua/navigationmanager.lua:950` `_nav_segments` - Keyed by tostring(id); neighbours are door vectors. `local door_list = self._nav_segments[segment1_id].neighbours[segment2_id]`
- `lua/navigationmanager.lua:1035` `_nav_segments` - Keyed by tostring(id); neighbours are door vectors. `local doors = self._nav_segments[segment1_id].neighbours[segment2_id]`
- `lua/navigationmanager.lua:1040` `_nav_segments` - Keyed by tostring(id); neighbours are door vectors. `local segment1 = self._nav_segments[segment1_id]`
- `lua/navigationmanager.lua:1074` `_nav_segments` - Keyed by tostring(id); neighbours are door vectors. `local all_segs = self._nav_segments`
- `lua/navigationmanager.lua:1241` `_quad_field` - New engine surface; verify method/arg shapes. `if access_pos and self._quad_field:is_nav_segment_blocked(end_i_seg, access_pos) then`
- `lua/navigationmanager.lua:1247` `_nav_segments` - Keyed by tostring(id); neighbours are door vectors. `local all_nav_segments = self._nav_segments`
- `lua/navigationmanager.lua:1347` `_quad_field` - New engine surface; verify method/arg shapes. `elseif access_pos and self._quad_field:is_nav_segment_blocked(neighbour_seg_id, access_pos) then`

## Suppressed (allowlisted)

- `lua/iter_nav_v6_shim.lua:62` `_rooms` - Removed at runtime in nav v6. `nav._rooms = {}`
- `lua/iter_nav_v6_shim.lua:63` `_room_doors` - Removed in nav v6; doors are position vectors in segment.neighbours. `nav._room_doors = {}`
- `lua/iter_nav_v6_shim.lua:64` `_visibility_groups` - Never assigned in nav v6. `nav._visibility_groups = {}`
- `lua/iter_nav_v6_shim.lua:68` `_rooms` - Removed at runtime in nav v6. `rooms = keep and #(nav._rooms or {}) or 0,`
- `lua/iter_nav_v6_shim.lua:69` `_room_doors` - Removed in nav v6; doors are position vectors in segment.neighbours. `room_doors = keep and #(nav._room_doors or {}) or 0,`
- `lua/iter_nav_v6_shim.lua:70` `_visibility_groups` - Never assigned in nav v6. `vis_groups = keep and #(nav._visibility_groups or {}) or 0,`
- `lua/iter_nav_v6_shim.lua:384` `_rooms` - Removed at runtime in nav v6. `nav._rooms = result.rooms`
- `lua/iter_nav_v6_shim.lua:385` `_room_doors` - Removed in nav v6; doors are position vectors in segment.neighbours. `nav._room_doors = result.room_doors`
- `lua/iter_nav_v6_shim.lua:386` `_visibility_groups` - Never assigned in nav v6. `nav._visibility_groups = result.visibility_groups`
- `lua/iter_nav_v6_shim.lua:400` `_rooms` - Removed at runtime in nav v6. `nav._rooms = {}`
- `lua/iter_nav_v6_shim.lua:401` `_room_doors` - Removed in nav v6; doors are position vectors in segment.neighbours. `nav._room_doors = {}`
- `lua/iter_nav_v6_shim.lua:402` `_visibility_groups` - Never assigned in nav v6. `nav._visibility_groups = {}`

## Allowlist usage

- used `lua/iter_nav_v6_shim.lua` `_rooms`
- used `lua/iter_nav_v6_shim.lua` `_room_doors`
- used `lua/iter_nav_v6_shim.lua` `_visibility_groups`

