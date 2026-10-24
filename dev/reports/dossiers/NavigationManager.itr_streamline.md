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

## Port notes (P1)

**Call sites.** `lua/copbrain.lua:34` (pcall, streamline-only mode), `lua/copbrain.lua:116` (`nav_ai`), `lua/coplogictravel.lua:256` (`nav_ai`), self-calls `lua/navigationmanager.lua:1088` and `:1224`; dev harness `dev/test-harness/lua/chatmanager.lua:290`. No game caller (name is Iter-only).
**Intent.** Rewrite each coarse step's pass-through position to a door centre or proxy so units stop cutting corners at segment transitions.
**248.2 constraint.** Coarse path steps are `{seg_id_string, pos}` with a final `{end_i_seg, to_pos}` (`:1268-1291`); `segment.neighbours[x]` is a list of `Vector3`/nav-link userdata, never door ids (`:331-348`); `choke_point_proxies`/`in_proxies`/`out_proxies` exist only after the shim and proxy pass (`:632-698`).
**Target mechanism.** Shim `_room_doors` plus `itr_shim_door_by_pair` (shim `:306-343`, `:387`), `itr_prepare_nav_data` post-hook on `_resolve_segment_neighbours` (`:700-702`), and `itr_get_door_in_alignment`'s numeric branch (`:894-915`) consuming shim door ids.
**Decision.** PORT (F2). The body is correct on 248.2 data *if* `_room_doors` and proxies exist; add a guard returning `false` when `_room_doors` is empty or `step1[2]` cannot resolve, so a partial shim cannot nil-index.
**Acceptance.** T2 `[ITER-NAV] ... evt=probe stream_ok=>0 stream_fail=0`, with `stream_points` below `raw_points` and `avg_len` not longer. No `evt=streamline` emitter yet (plan §7) — probe is the only proof today.
**Cost if wrong.** `copbrain.lua:34` catches errors and keeps the vanilla path; `coplogictravel.lua:256` restores `path_backup` on `false`. Worst case is silently vanilla routing — except an error thrown outside the pcall (`:1088`, `:1224`).
**Evidence gaps.** `:950` `all_segs[step1[1]].pos` nil-crashes if ids are numeric (Iter search output) or a segment is missing; the `step2[3]` navlink marker (`:982`) is read by `lua/coplogictravel.lua:170` but its 248.2 consumer semantics are unverified.
