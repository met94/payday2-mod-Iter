# Function dossier: lua/navigationmanager.lua :: NavigationManager.itr_get_door_between

Category: **MOD_ONLY**

- ITER: 6 lines, params `(segment1_id, segment2_id, near_pos)`
- 246.1: not found
- 248.2: not found

Normalized signature: `self` is omitted for methods; the body is the porting surface.

## ITER body (V8.57)

```lua
function NavigationManager.itr_get_door_between(segment1_id, segment2_id, near_pos)
local door_list = self._nav_segments[segment1_id].neighbours[segment2_id]
	if door_list then
		return self:itr_get_closest_door_to_pos(self._room_doors, door_list, nil, near_pos, nil, true)
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
