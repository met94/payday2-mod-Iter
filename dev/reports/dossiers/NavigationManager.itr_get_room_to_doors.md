# Function dossier: lua/navigationmanager.lua :: NavigationManager.itr_get_room_to_doors

Category: **MOD_ONLY**

- ITER: 16 lines, params `(segment_id, all_seg_doors)`
- 246.1: not found
- 248.2: not found

Normalized signature: `self` is omitted for methods; the body is the porting surface.

## ITER body (V8.57)

```lua
function NavigationManager.itr_get_room_to_doors(segment_id, all_seg_doors)
local result = {}
	for door_id, door in pairs(all_seg_doors) do
		for _, room_id in ipairs(door.rooms) do
			if segment_id == self:get_nav_seg_from_i_room(room_id) then
				local ri = result[room_id]
				if not ri then
					ri = {}
					result[room_id] = ri
				end
				table_insert(ri, door_id)
			end
		end
	end
	return result
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
