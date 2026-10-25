# Function dossier: lua/navigationmanager.lua :: NavigationManager.itr_get_closest_door_to_pos

Category: **MOD_ONLY**

- ITER: 69 lines, params `(all_doors, door_list, pos_from, pos_to, access_pos, navlink_accounting)`
- 246.1: not found
- 248.2: not found

Normalized signature: `self` is omitted for methods; the body is the porting surface.

## ITER body (V8.57)

```lua
function NavigationManager.itr_get_closest_door_to_pos(all_doors, door_list, pos_from, pos_to, access_pos, navlink_accounting)
local best_pos, best_pos_with_delay, t, min_congestion_risk
	local best_dis = 1000000000
	local is_direct, through_navlink, through_navlink_with_delay

	for i = #door_list, 1, -1 do
		local i_door = door_list[i]
		if type(i_door) == 'number' then
			for _, door_pos in ipairs(self.itr_room_doors[i_door]) do
				local nav_tracker = self._quad_field:create_nav_tracker(door_pos, true)
				local obstructed = nav_tracker:obstructed()
				self._quad_field:destroy_nav_tracker(nav_tracker)
				if not obstructed then
					local dis = (pos_from and mvec3_dis(pos_from, door_pos) or 0) + mvec3_dis(door_pos, pos_to)
					if dis <= best_dis then
						best_pos = door_pos
						best_dis = dis
						is_direct = true
					end
					break
				end
			end

		elseif is_direct then
			-- qued

		elseif i_door and i_door:alive() and not i_door:is_obstructed() and i_door:check_access(access_pos) then
			local element = _navlink_elements[i_door:key()]
			local start_pos = element:value('position')
			local end_pos = element:nav_link_end_pos()
			local dis = (pos_from and mvec3_dis(pos_from, start_pos) or 0) + mvec3_dis(start_pos, end_pos) + mvec3_dis(end_pos, pos_to)
			local nav_link_delay = element._values.itr_interval
			local congestion_risk = 0
			if nav_link_delay > 0 then
				t = t or TimerManager:game():time()
				local user = element.itr_reserved_by_unit
				congestion_risk = math_max(0, i_door:delay_time() - t)
					+ (
						(alive(user) and user:id() ~= -1 and 0 or 1)
						+ (element.itr_navlink_queue_length or 0)
						+ itr_get_navlink_usage(i_door, t)
					) * nav_link_delay
			end
			if congestion_risk == 0 then
				if dis * 1.4 < best_dis then
					is_direct = false
					best_pos = end_pos
					best_dis = dis * 1.4
					through_navlink = i_door
				end
			elseif not min_congestion_risk or congestion_risk < min_congestion_risk then
				min_congestion_risk = congestion_risk
				best_pos_with_delay = end_pos
				through_navlink_with_delay = i_door
			end
		end
	end

	if is_direct then
		through_navlink = nil
	else
		through_navlink = through_navlink or through_navlink_with_delay
		if through_navlink and navlink_accounting then
			itr_log_navlink_usage(through_navlink, t)
		end
	end

	return best_pos or best_pos_with_delay, through_navlink
end
```

## 246.1 vanilla (a3180fc)

246.1: not found.

## 248.2 vanilla (e3a8b616)

248.2: not found.

## Diff 246.1 -> ITER

Cannot diff: 246.1 function not found.

## Diff 246.1 -> 248.2

Cannot diff: old or new function missing.

## Porter checklist

- [ ] Decision: keep ITER body, adopt 248.2 vanilla, or merge.
- [ ] If merge: re-apply the ITER intent onto the 248.2 body, not the 246.1 body.
- [ ] Check removed/changed APIs (`_room_doors`, numeric `_nav_segments`, `no_dispose`, `session():send_to_peers_synched`, ...).
- [ ] Check new 248.2 fields/callbacks this function must preserve.
- [ ] Run `luajit -bl` and `api-audit` on the file.

## Port notes (P1)

**Call sites.** `lua/navigationmanager.lua:842` (`itr_get_door_between`), `:939` (`itr_get_coarse_pos_between`), `:975` (`itr_streamline`). No game caller.
**Intent.** Pick the cheapest crossing point between two segments: a door position, or a nav-link whose wait cost still beats the direct route.
**248.2 constraint.** `door_list` entries are `Vector3` (v6 doors) or nav-link userdata; numeric door ids come only from the shim pair index. `_navlink_elements` is keyed by `nav_link:key()` (overlay `:179`) and `element._values.itr_interval` is set only by the register wrapper (`:169`); `key()` is engine API with no vanilla 248.2 caller.
**Target mechanism.** `self.itr_room_doors` (`:651-661`, `{center,pos,pos1}` from shim doors), the `Vector3` branch `:758-765`, and the nav-link branch `:770-799` against L-01/L-02 element fields.
**Decision.** PORT (F2/S-03) with two guards: skip when `self.itr_room_doors[i_door]` is nil, and skip when `_navlink_elements[key]` is nil (unregistered link).
**Acceptance.** T2 `evt=probe stream_ok=>0 stream_fail=0`; T3 covers the `navlink_accounting=true` path (`:704-715`).
**Cost if wrong.** A nil index throws inside `itr_streamline`; the streamline-only wrapper pcall drops to vanilla paths (`lua/copbrain.lua:34-40`), so AI still moves but Iter routing is lost.
**Evidence gaps.** `create_nav_tracker(door_pos, true)` (`:744`) is not nil-checked; whether the engine returns nil for a mid-door centre (shim `center`, `:245-249`) is unverified. `nav_link:key()` at 248.2 is unverified (no vanilla use). The dossier body above predates the `Vector3` branch.
