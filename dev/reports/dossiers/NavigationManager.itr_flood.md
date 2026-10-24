# Function dossier: lua/navigationmanager.lua :: NavigationManager.itr_flood

Category: **MOD_ONLY**

- ITER: 50 lines, params `(from_doors, room_to_doors)`
- 246.1: not found
- 248.2: not found

Normalized signature: `self` is omitted for methods; the body is the porting surface.

## ITER body (V8.57)

```lua
function NavigationManager.itr_flood(from_doors, room_to_doors)
local door_flood_levels = {}
	local to_process = {}
	local level = 1
	for _, door_id in pairs(from_doors) do
		if type(door_id) == 'number' then
			door_flood_levels[door_id] = level
			to_process[door_id] = true
		end
	end

	local all_doors = self._room_doors
	local door_level_counts = {}
	door_level_counts[1] = #from_doors
	local stop
	repeat
		stop = true
		level = level + 1
		local old_to_process = to_process
		to_process = {}
		for base_door_id in pairs(old_to_process) do
			for _, room_id in ipairs(all_doors[base_door_id].rooms) do
				local next_doors = room_to_doors[room_id]
				if next_doors then
					for _, door_id in ipairs(next_doors) do
						if not door_flood_levels[door_id] and not to_process[door_id] then
							to_process[door_id] = true
							door_flood_levels[door_id] = level
							local cnt = door_level_counts[level]
							door_level_counts[level] = cnt and cnt + 1 or 1
							stop = false
						end
					end
				end
			end
		end
	until stop

	local room_flood_levels = {}
	for door_id, level in pairs(door_flood_levels) do
		for _, room_id in ipairs(all_doors[door_id].rooms) do
			if room_to_doors[room_id] then -- to filter rooms of this segment
				local room_level = room_flood_levels[room_id]
				room_flood_levels[room_id] = room_level and math.min(room_level, level) or level
			end
		end
	end

	return room_flood_levels, door_flood_levels, door_level_counts
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
