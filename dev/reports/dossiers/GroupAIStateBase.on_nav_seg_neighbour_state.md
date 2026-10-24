# Function dossier: lua/groupaistatebase.lua :: GroupAIStateBase.on_nav_seg_neighbour_state

Category: **MOD_EDIT_CLEAN**

- ITER: 6 lines, params `(start_seg_id, end_seg_id, state)`
- 246.1: 35 lines, params `(start_seg_id, end_seg_id, state)`
- 248.2: 35 lines, params `(start_seg_id, end_seg_id, state)`

Normalized signature: `self` is omitted for methods; the body is the porting surface.

## ITER body (V8.57)

```lua
function GroupAIStateBase.on_nav_seg_neighbour_state(start_seg_id, end_seg_id, state)
itr_groupaistatebase_onnavsegneighbourstate(self, start_seg_id, end_seg_id, state)

	managers.navigation:itr_make_neighbours_list(start_seg_id)
	managers.navigation:itr_make_neighbours_list(end_seg_id)
end
```

## 246.1 vanilla (a3180fc)

```lua
function GroupAIStateBase.on_nav_seg_neighbour_state(start_seg_id, end_seg_id, state)
local all_nav_segs = managers.navigation._nav_segments

	for area_id, area in pairs(self._area_data) do
		if area.nav_segs[start_seg_id] then
			for other_area_id, other_area in pairs(area.neighbours) do
				other_area.neighbours[area_id] = nil
			end

			area.neighbours = {}

			for seg_id, _ in pairs(area.nav_segs) do
				if not all_nav_segs[seg_id].disabled then
					local nav_seg_neighbours = all_nav_segs[seg_id].neighbours

					for other_nav_seg_id, door_list in pairs(nav_seg_neighbours) do
						local other_nav_seg = all_nav_segs[other_nav_seg_id]

						if not other_nav_seg.disabled then
							for other_area_id, other_area in pairs(self._area_data) do
								if other_area_id ~= area_id and other_area.nav_segs[other_nav_seg_id] then
									area.neighbours[other_area_id] = other_area

									if other_nav_seg.neighbours[seg_id] then
										other_area.neighbours[area_id] = area
									end
								end
							end
						end
					end
				end
			end
		end
	end
end
```

## 248.2 vanilla (e3a8b616)

```lua
function GroupAIStateBase.on_nav_seg_neighbour_state(start_seg_id, end_seg_id, state)
local all_nav_segs = managers.navigation._nav_segments

	for area_id, area in pairs(self._area_data) do
		if area.nav_segs[start_seg_id] then
			for other_area_id, other_area in pairs(area.neighbours) do
				other_area.neighbours[area_id] = nil
			end

			area.neighbours = {}

			for seg_id, _ in pairs(area.nav_segs) do
				if not all_nav_segs[seg_id].disabled then
					local nav_seg_neighbours = all_nav_segs[seg_id].neighbours

					for other_nav_seg_id, door_list in pairs(nav_seg_neighbours) do
						local other_nav_seg = all_nav_segs[other_nav_seg_id]

						if not other_nav_seg.disabled then
							for other_area_id, other_area in pairs(self._area_data) do
								if other_area_id ~= area_id and other_area.nav_segs[other_nav_seg_id] then
									area.neighbours[other_area_id] = other_area

									if other_nav_seg.neighbours[seg_id] then
										other_area.neighbours[area_id] = area
									end
								end
							end
						end
					end
				end
			end
		end
	end
end
```

## Diff 246.1 -> ITER

```diff
--- 246.1 vanilla
+++ ITER
@@ -1,34 +1,5 @@
-local all_nav_segs = managers.navigation._nav_segments
-
-	for area_id, area in pairs(self._area_data) do
-		if area.nav_segs[start_seg_id] then
-			for other_area_id, other_area in pairs(area.neighbours) do
-				other_area.neighbours[area_id] = nil
-			end
-
-			area.neighbours = {}
-
-			for seg_id, _ in pairs(area.nav_segs) do
-				if not all_nav_segs[seg_id].disabled then
-					local nav_seg_neighbours = all_nav_segs[seg_id].neighbours
-
-					for other_nav_seg_id, door_list in pairs(nav_seg_neighbours) do
-						local other_nav_seg = all_nav_segs[other_nav_seg_id]
-
-						if not other_nav_seg.disabled then
-							for other_area_id, other_area in pairs(self._area_data) do
-								if other_area_id ~= area_id and other_area.nav_segs[other_nav_seg_id] then
-									area.neighbours[other_area_id] = other_area
-
-									if other_nav_seg.neighbours[seg_id] then
-										other_area.neighbours[area_id] = area
-									end
-								end
-							end
-						end
-					end
-				end
-			end
-		end
-	end
+itr_groupaistatebase_onnavsegneighbourstate(self, start_seg_id, end_seg_id, state)
+
+	managers.navigation:itr_make_neighbours_list(start_seg_id)
+	managers.navigation:itr_make_neighbours_list(end_seg_id)
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
