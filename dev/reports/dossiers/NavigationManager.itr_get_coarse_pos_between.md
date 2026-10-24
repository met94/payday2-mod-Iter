# Function dossier: lua/navigationmanager.lua :: NavigationManager.itr_get_coarse_pos_between

Category: **MOD_ONLY**

- ITER: 24 lines, params `(segment1_id, segment2_id, near_pos, access_pos)`
- 246.1: not found
- 248.2: not found

Normalized signature: `self` is omitted for methods; the body is the porting surface.

## ITER body (V8.57)

```lua
function NavigationManager.itr_get_coarse_pos_between(segment1_id, segment2_id, near_pos, access_pos)
local doors = self._nav_segments[segment1_id].neighbours[segment2_id]
	if not doors then
		return false
	end

	local segment1 = self._nav_segments[segment1_id]
	local best_pos = segment1.choke_point_proxies[segment2_id]
	if best_pos then
		return best_pos
	end

	best_pos = segment1.out_proxies[segment2_id]
	if best_pos then
		return best_pos
	end

	best_pos = segment1.in_proxies[segment2_id]
	if best_pos then
		return best_pos
	end

	return self:itr_get_closest_door_to_pos(self._room_doors, doors, nil, near_pos, access_pos, false)
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

**Call sites.** `lua/navigationmanager.lua:1124` and `:1153`, both inside the Iter search. No game caller.
**Intent.** Return the position a unit should pass through when moving from segment1 to segment2: choke proxy, else out, else in, else the closest usable door.
**248.2 constraint.** Needs `segment.neighbours[segment2_id]` to exist (`:918`) and proxies already computed; ids are strings, so any numeric id from the search path breaks the lookup. Proxies are built only on the host (`Network:is_server()`, `:666`).
**Target mechanism.** `itr_prepare_nav_data` (`:665-698`) after `_resolve_segment_neighbours` (`:700-702`): neighbour lists, `itr_copy_door_data`, `itr_prepare_streamline_data`; fields `choke_point_proxies`/`out_proxies`/`in_proxies` written by `itr_find_proxies` (`:554`, `:586`, `:619`).
**Decision.** PORT (F1/F2) once T1/T2 confirm proxy counts; guard against `segment1.choke_point_proxies` being nil.
**Acceptance.** T4 search (`evt=probe search_ok>0`) plus T2 `evt=proxy in_proxies=>0 out_proxies=>0`; no dedicated event.
**Cost if wrong.** Returns `false`, the search skips that neighbour (`:1154`), which can produce no-path where vanilla finds one; otherwise falls back to the closest-door lookup.
**Evidence gaps.** If any client-side caller runs `search_coarse`, proxies are absent there (`:666` early return) and `:924` nil-indexes — no evidence either way in current logs.
