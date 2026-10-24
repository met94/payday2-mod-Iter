# Function dossier: lua/navigationmanager.lua :: NavigationManager.itr_find_choke_point

Category: **MOD_ONLY**

- ITER: 24 lines, params `(room_flood_levels, room_level_counts, room_to_doors, door_flood_levels, important_rooms)`
- 246.1: not found
- 248.2: not found

Normalized signature: `self` is omitted for methods; the body is the porting surface.

## ITER body (V8.57)

```lua
function NavigationManager.itr_find_choke_point(room_flood_levels, room_level_counts, room_to_doors, door_flood_levels, important_rooms)
local lower_levels_contiguity = true
	local level_max = #room_level_counts
	local threshold = math_max(4, level_max / 2)
	for level, count in pairs(room_level_counts) do
		if level > threshold or level == level_max then
			break
		end
		if lower_levels_contiguity then
			lower_levels_contiguity = self:itr_is_contiguous(level, door_flood_levels, room_to_doors)
		end
		if count == 1 then -- choke point exists
			for room_id, room_level in pairs(room_flood_levels) do
				if room_level == level and important_rooms[room_id] then
					local room_data = self._rooms[room_id]
					local r_borders = room_data.borders
					local r_height = room_data.height
					return Vector3((r_borders.x_pos + r_borders.x_neg) / 2, (r_borders.y_pos + r_borders.y_neg) / 2, (r_height.xp_yp + r_height.xn_yn) / 2), lower_levels_contiguity
				end
			end
			break
		end			
	end
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
