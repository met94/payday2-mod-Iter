# Function dossier: lua/navigationmanager.lua :: NavigationManager.itr_get_all_doors_of_segment

Category: **MOD_ONLY**

- ITER: 30 lines, params `(segment_id)`
- 246.1: not found
- 248.2: not found

Normalized signature: `self` is omitted for methods; the body is the porting surface.

## ITER body (V8.57)

```lua
function NavigationManager.itr_get_all_doors_of_segment(segment_id)
local room_mask = {}
	if self._nav_segments[segment_id] and next(self._nav_segments[segment_id].vis_groups) then
		for _, i_vis_group in ipairs(self._nav_segments[segment_id].vis_groups) do
			local vis_group_rooms = self._visibility_groups[i_vis_group].rooms
			for i_room, _ in pairs(vis_group_rooms) do
				room_mask[i_room] = true
			end
		end
	end

	local all_seg_doors = {}
	local room_neighbours = {}
	for door_id, door in pairs(self._room_doors) do
		local door_rooms = door.rooms
		local r1 = door_rooms[1]
		local r2 = door_rooms[2]
		local rm1 = room_mask[r1]
		local rm2 = room_mask[r2]
		if rm1 or rm2 then
			all_seg_doors[door_id] = door
		end
		if not rm1 then
			room_neighbours[r1] = true
		elseif not rm2 then
			room_neighbours[r2] = true
		end
	end
	return all_seg_doors, room_neighbours
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
