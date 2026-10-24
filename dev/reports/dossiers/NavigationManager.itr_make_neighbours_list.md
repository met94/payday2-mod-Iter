# Function dossier: lua/navigationmanager.lua :: NavigationManager.itr_make_neighbours_list

Category: **MOD_ONLY**

- ITER: 14 lines, params `(navseg_id)`
- 246.1: not found
- 248.2: not found

Normalized signature: `self` is omitted for methods; the body is the porting surface.

## ITER body (V8.57)

```lua
function NavigationManager.itr_make_neighbours_list(navseg_id)
local navseg = self._nav_segments and self._nav_segments[navseg_id]
	if not navseg then
		return
	end

	local list = {}
	for neighbour_seg_id in pairs(navseg.neighbours) do
		if not self._nav_segments[neighbour_seg_id].disabled then
			table.insert(list, neighbour_seg_id)
		end
	end
	navseg.itr_enabled_neighbours_i = list
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
