# Function dossier: lua/navigationmanager.lua :: NavigationManager.itr_find_best_navlink

Category: **MOD_ONLY**

- ITER: 46 lines, params `(segment1_id, segment2_id, access_pos, near_pos, current_navlink_element)`
- 246.1: not found
- 248.2: not found

Normalized signature: `self` is omitted for methods; the body is the porting surface.

## ITER body (V8.57)

```lua
function NavigationManager.itr_find_best_navlink(segment1_id, segment2_id, access_pos, near_pos, current_navlink_element)
local door_list = self._nav_segments[segment1_id].neighbours[segment2_id]
	if not door_list then
		return
	end

	local best_dis = 100000000000000
	local best_time_to_wait = 100000000000
	local best_navlink, best_navlink_element
	for i = #door_list, 1, -1 do
		local navlink = door_list[i]
		if type(navlink) == 'userdata' and navlink:alive() and not navlink:is_obstructed() and navlink:check_access(access_pos) then
			local navlink_element = _navlink_elements[navlink:key()]

			local interval = navlink_element._values.itr_interval
			local extra_time_to_go = math_max(0, 1.5 - interval)
			local navpos = navlink_element:value('position')

			local queue_length = navlink_element.itr_navlink_queue_length or 0
			if navlink_element == current_navlink_element then
				queue_length = queue_length - 1
			end

			local time_to_wait = queue_length * (interval + extra_time_to_go)

			if near_pos then
				local my_time_to_go = mvec3_dis(near_pos, navpos) / (self.itr_navlink_coef * 0.7)
				time_to_wait = time_to_wait - extra_time_to_go + math_max(0, my_time_to_go - interval)
			end

			local user = navlink_element.itr_reserved_by_unit
			if alive(user) and user:id() ~= -1 then
				time_to_wait = time_to_wait + interval + math_max(0, mvec3_dis(user:position(), navpos) / self.itr_navlink_coef - interval)
			end

			if time_to_wait < best_time_to_wait then
				best_time_to_wait = time_to_wait
				best_dis = dis
				best_navlink = navlink
				best_navlink_element = navlink_element
			end
		end
	end

	return best_navlink, best_navlink_element
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
