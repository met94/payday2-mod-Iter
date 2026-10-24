# Function dossier: lua/navigationmanager.lua :: NavigationManager.itr_copy_door_data

Category: **MOD_ONLY**

- ITER: 14 lines, params `()`
- 246.1: not found
- 248.2: not found

Normalized signature: `self` is omitted for methods; the body is the porting surface.

## ITER body (V8.57)

```lua
function NavigationManager.itr_copy_door_data()
self.itr_room_doors = {}

	for _, segment in pairs(self._nav_segments) do
		for _, door_list in pairs(segment.neighbours) do
			for _, door_id in pairs(door_list) do
				local data = self._room_doors[door_id]
				local center = Vector3()
				mvector3.lerp(center, data.pos, data.pos1, 0.5)
				self.itr_room_doors[door_id] = { center, data.pos, data.pos1 }
			end
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
