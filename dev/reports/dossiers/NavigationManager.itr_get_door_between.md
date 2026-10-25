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

## Port notes (P1)

**Call sites.** `lua/coplogictravel.lua:296` only (`nav_ai`, follow-unit retarget). No game caller.
**Intent.** Return the point on the boundary between two segments nearest a reference position, so a follower's path can be retargeted.
**248.2 constraint.** No door ids exist in v6; the pair index must supply them and `_room_doors[id].center` is shim-built. The fallback (`:840-843`) passes the engine neighbour list into `itr_get_closest_door_to_pos`, which only works through the `Vector3` branch.
**Target mechanism.** S-01 `itr_shim_door_by_pair` lookup (`:814-838`) plus the `center` fallback `mvec3_lerp(pos,pos1,0.5)` (`:825`); R6 records the resulting `_room_doors` audit error (baseline 12).
**Decision.** PORT (F8, S-01 implemented). Current body is `:814-844`; the dossier body above is the pre-S-01 numeric version.
**Acceptance.** T5 follow-unit (no card yet) and indirect T1 `evt=heist missing_neighbours=0`; `evt=proxy` proves the index is populated.
**Cost if wrong.** The follower keeps its old destination segment and re-routes the long way; no error unless `segment1_id` is numeric (`:840` nil index).
**Evidence gaps.** No follow-unit test card exists; the numeric-id fallback at `:840` will nil-index if Iter search ever emits numeric ids (`:1208`).
