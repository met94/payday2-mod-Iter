# Function dossier: lua/navigationmanager.lua :: NavigationManager.itr_streamline

Category: **MOD_ONLY**

- ITER: 53 lines, params `(path, access_pos)`
- 246.1: not found
- 248.2: not found

Normalized signature: `self` is omitted for methods; the body is the porting surface.

## ITER body (V8.57)

```lua
function NavigationManager.itr_streamline(path, access_pos)
local all_segs = self._nav_segments
	local all_doors = self._room_doors
	local path_nr = #path
	local step1 = path[1]
	local step2

	if not step1[2] then
		step1[2] = all_segs[step1[1]].pos
	end

	for i = 2, path_nr do
		step2 = path[i]

		local segment1 = all_segs[step1[1]]
		local segment2_id = step2[1]
		local door_list = segment1.neighbours[segment2_id]
		if door_list then
			local navlink
			local segment2 = all_segs[segment2_id]
			local step3 = path[i + 1]
			local segment3 = step3 and all_segs[step3[1]]

			local best_pos = segment1.choke_point_proxies[step2[1]]

			if not best_pos then
				local out_proxy = step3 and (segment3.choke_points[step2[1]] or segment2.out_proxies[step3[1]])
				local in_proxy = segment2.in_proxies[step1[1]] or step3 and all_segs[step3[1]].pos
				best_pos = itr_get_door_in_alignment(all_doors, door_list, step1[2], out_proxy or in_proxy)
			end

			if not best_pos then
				local proxy = step3 and segment2.in_proxies[step3[1]] or path[path_nr][2]
				best_pos, navlink = self:itr_get_closest_door_to_pos(all_doors, door_list, step1[2], proxy, access_pos, true)
				if not best_pos then
					return false
				end
			end

			step2[2] = best_pos
			step2[3] = navlink
		end

		step1 = step2
	end

	path[1][2] = nil
	if path_nr > 1 and path[path_nr - 1][1] ~= path[path_nr][1] then
		path[path_nr + 1] = { path[path_nr][1] }
		path[path_nr][1] = path[path_nr - 1][1]
	end
	return path
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
