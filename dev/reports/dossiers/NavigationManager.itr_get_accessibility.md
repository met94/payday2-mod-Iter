# Function dossier: lua/navigationmanager.lua :: NavigationManager.itr_get_accessibility

Category: **MOD_ONLY**

- ITER: 28 lines, params `(door_list, access_pos, access_neg)`
- 246.1: not found
- 248.2: not found

Normalized signature: `self` is omitted for methods; the body is the porting surface.

## ITER body (V8.57)

```lua
function NavigationManager.itr_get_accessibility(door_list, access_pos, access_neg)
local min_congestion_risk, t
	for i = #door_list, 1, -1 do
		local i_door = door_list[i]
		if type(i_door) == 'number' then
			return 0
		elseif i_door and i_door:alive() and not i_door:is_obstructed() and i_door:check_access(access_pos, access_neg) then
			t = t or TimerManager:game():time()
			local element = _navlink_elements[i_door:key()]
			local nav_link_delay = element._values.itr_interval
			if nav_link_delay > 0 then
				local user = element.itr_reserved_by_unit
				congestion_risk = math_max(0, i_door:delay_time() - t)
					+ (
						(alive(user) and user:id() ~= -1 and 0 or 1)
						+ (element.itr_navlink_queue_length or 0)
						+ itr_get_navlink_usage(i_door, t)
					) * nav_link_delay
				if congestion_risk == 0 then
					return 0.1
				elseif not min_congestion_risk or congestion_risk < min_congestion_risk then
					min_congestion_risk = congestion_risk
				end
			end
		end
	end
	return min_congestion_risk or 0.01
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
