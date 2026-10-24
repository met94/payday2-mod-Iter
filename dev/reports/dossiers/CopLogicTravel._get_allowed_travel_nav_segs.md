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
