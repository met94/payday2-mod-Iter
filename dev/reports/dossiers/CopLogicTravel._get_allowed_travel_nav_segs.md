# Function dossier: lua/coplogictravel.lua :: CopLogicTravel._get_allowed_travel_nav_segs

Category: **MOD_EDIT_CLEAN**

- ITER: 9 lines, params `(data, my_data, to_pos)`
- 246.1: 37 lines, params `(data, my_data, to_pos)`
- 248.2: 37 lines, params `(data, my_data, to_pos)`

Normalized signature: `self` is omitted for methods; the body is the porting surface.

## ITER body (V8.57)

```lua
function CopLogicTravel._get_allowed_travel_nav_segs(data, my_data, to_pos)
local itr_nav_segs = my_data.itr_nav_segs
	if itr_nav_segs then
		my_data.itr_nav_segs = nil
		return itr_nav_segs
	end

	return itr_original_coplogictravel_getallowedtravelnavsegs(data, my_data, to_pos)
end
```

## 246.1 vanilla (a3180fc)

```lua
function CopLogicTravel._get_allowed_travel_nav_segs(data, my_data, to_pos)
local nav_segs = {}
	local added_segs = {}

	for _, nav_point in ipairs(my_data.coarse_path) do
		local area = managers.groupai:state():get_area_from_nav_seg_id(nav_point[1])

		for nav_seg_id, _ in pairs(area.nav_segs) do
			if not added_segs[nav_seg_id] then
				added_segs[nav_seg_id] = true

				table.insert(nav_segs, nav_seg_id)
			end
		end
	end

	local end_nav_seg = managers.navigation:get_nav_seg_from_pos(to_pos, true)
	local end_area = managers.groupai:state():get_area_from_nav_seg_id(end_nav_seg)

	for nav_seg_id, _ in pairs(end_area.nav_segs) do
		if not added_segs[nav_seg_id] then
			added_segs[nav_seg_id] = true

			table.insert(nav_segs, nav_seg_id)
		end
	end

	local standing_nav_seg = data.unit:movement():nav_tracker():nav_segment()

	if not added_segs[standing_nav_seg] then
		table.insert(nav_segs, standing_nav_seg)

		added_segs[standing_nav_seg] = true
	end

	return nav_segs
end
```

## 248.2 vanilla (e3a8b616)

```lua
function CopLogicTravel._get_allowed_travel_nav_segs(data, my_data, to_pos)
local nav_segs = {}
	local added_segs = {}

	for _, nav_point in ipairs(my_data.coarse_path) do
		local area = managers.groupai:state():get_area_from_nav_seg_id(nav_point[1])

		for nav_seg_id, _ in pairs(area.nav_segs) do
			if not added_segs[nav_seg_id] then
				added_segs[nav_seg_id] = true

				table.insert(nav_segs, nav_seg_id)
			end
		end
	end

	local end_nav_seg = managers.navigation:get_nav_seg_from_pos(to_pos, true)
	local end_area = managers.groupai:state():get_area_from_nav_seg_id(end_nav_seg)

	for nav_seg_id, _ in pairs(end_area.nav_segs) do
		if not added_segs[nav_seg_id] then
			added_segs[nav_seg_id] = true

			table.insert(nav_segs, nav_seg_id)
		end
	end

	local standing_nav_seg = data.unit:movement():nav_tracker():nav_segment()

	if not added_segs[standing_nav_seg] then
		table.insert(nav_segs, standing_nav_seg)

		added_segs[standing_nav_seg] = true
	end

	return nav_segs
end
```

## Diff 246.1 -> ITER

```diff
--- 246.1 vanilla
+++ ITER
@@ -1,36 +1,8 @@
-local nav_segs = {}
-	local added_segs = {}
-
-	for _, nav_point in ipairs(my_data.coarse_path) do
-		local area = managers.groupai:state():get_area_from_nav_seg_id(nav_point[1])
-
-		for nav_seg_id, _ in pairs(area.nav_segs) do
-			if not added_segs[nav_seg_id] then
-				added_segs[nav_seg_id] = true
-
-				table.insert(nav_segs, nav_seg_id)
-			end
-		end
-	end
-
-	local end_nav_seg = managers.navigation:get_nav_seg_from_pos(to_pos, true)
-	local end_area = managers.groupai:state():get_area_from_nav_seg_id(end_nav_seg)
-
-	for nav_seg_id, _ in pairs(end_area.nav_segs) do
-		if not added_segs[nav_seg_id] then
-			added_segs[nav_seg_id] = true
-
-			table.insert(nav_segs, nav_seg_id)
-		end
-	end
-
-	local standing_nav_seg = data.unit:movement():nav_tracker():nav_segment()
-
-	if not added_segs[standing_nav_seg] then
-		table.insert(nav_segs, standing_nav_seg)
-
-		added_segs[standing_nav_seg] = true
-	end
-
-	return nav_segs
+local itr_nav_segs = my_data.itr_nav_segs
+	if itr_nav_segs then
+		my_data.itr_nav_segs = nil
+		return itr_nav_segs
+	end
+
+	return itr_original_coplogictravel_getallowedtravelnavsegs(data, my_data, to_pos)
 end
\ No newline at end of file
```

## Diff 246.1 -> 248.2

```diff
No differences.
```

## Porter checklist

- [ ] Decision: keep ITER body, adopt 248.2 vanilla, or merge.
- [ ] If merge: re-apply the ITER intent onto the 248.2 body, not the 246.1 body.
- [ ] Check removed/changed APIs (`_room_doors`, numeric `_nav_segments`, `no_dispose`, `session():send_to_peers_synched`, ...).
- [ ] Check new 248.2 fields/callbacks this function must preserve.
- [ ] Run `luajit -bl` and `api-audit` on the file.

## Port notes (P1)

1. **Wrapper or replacement.** Wrapper. `lua/coplogictravel.lua:106` captures `itr_original_coplogictravel_getallowedtravelnavsegs`; `:107-115` returns `my_data.itr_nav_segs` and **nils it** on the first call, otherwise calls the original at `:114`.
2. **Call sites.** r200: the mod's `_check_start_path_ahead` at `:382`. 248.2: `coplogictravel.lua:1391` (`_check_start_path_ahead`) and `:1550` (`_chk_start_pathing_to_next_nav_point`); definition `:1331-1367`.
3. **Intent.** Restrict the *detailed* search that follows a direct-to-pos coarse path to the segments the original coarse path actually crossed, so the walk does not cut through segments the coarse search had rejected; the one-shot nil keeps vanilla behaviour for every later search.
4. **248.2 delta.** None (file byte-identical 246.1↔248.2). The consumer contract is still valid: `nav_segs` is a `CopBrain:search_for_path`/`search_for_path_from_pos` param (`copbrain.lua:509`, `:528`) and is passed straight into `managers.navigation:search_pos_to_pos`. 248.2 segment ids are strings, and `my_data.itr_nav_segs` is populated from `coarse_path[i][1]`, i.e. already string ids — no `tostring` shim needed.
5. **Target mechanism.** Port as-is as a wrapper. Fields: `my_data.itr_nav_segs` (written by `_get_exact_move_pos`, consumed here once).
6. **Decision.** **PORT** (P6, F8/A-03). It is 9 lines and only activates when `_get_exact_move_pos` wrote `itr_nav_segs`, i.e. only on the direct path — so it cannot affect vanilla routing.
7. **Acceptance.** T5. Log `evt=search k=nav_segs=<n>,source=itr|vanilla` on the two call paths, and `evt=fallback k=reason=itr_nav_segs_failed` if the restricted search returns `failed`.
8. **Cost if wrong.** A restricted `nav_segs` list that omits a segment the real route needs makes the detailed search fail; `_upd_pathing` then either fails the objective (`:366`, `:387`) or retries via the followup-SO branch. Because the list is consumed once, the failure is not self-healing on the same tick.
9. **Evidence gaps.** No retry-without-restriction exists in r200. Confirm on T5 whether a failed restricted search is recoverable on the next logic tick (it should be, since `itr_nav_segs` is nil by then) — needs a log, not static reading.
