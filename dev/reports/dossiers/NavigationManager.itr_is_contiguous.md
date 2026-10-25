# Function dossier: lua/navigationmanager.lua :: NavigationManager.itr_is_contiguous

Category: **MOD_ONLY**

- ITER: 41 lines, params `(level, door_flood_levels, room_to_doors)`
- 246.1: not found
- 248.2: not found

Normalized signature: `self` is omitted for methods; the body is the porting surface.

## ITER body (V8.57)

```lua
function NavigationManager.itr_is_contiguous(level, door_flood_levels, room_to_doors)
local all_doors = self._room_doors
	local level_doors = {}
	local room_pool = {}
	for door_id, door_level in pairs(door_flood_levels) do
		if door_level == level then
			level_doors[door_id] = true
			for _, room_id in ipairs(all_doors[door_id].rooms) do
				if room_to_doors[room_id] then
					room_pool[room_id] = true
				end
			end
		end
	end

	local start = next(room_pool)
	if not start then
		return false
	end
	local to_process = {[start] = true}
	local stop
	repeat
		stop = true
		local old_to_process = to_process
		to_process = {}
		for base_room_id, _ in pairs(old_to_process) do
			room_pool[base_room_id] = nil
			for _, door_id in pairs(room_to_doors[base_room_id]) do
				for _, room_id in ipairs(all_doors[door_id].rooms) do
					if room_pool[room_id] then
						to_process[room_id] = true
						stop = false
					end
				end
				level_doors[door_id] = nil
			end
		end
	until stop

	return not next(level_doors)
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
