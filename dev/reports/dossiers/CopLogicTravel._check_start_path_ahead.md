# Function dossier: lua/coplogictravel.lua :: CopLogicTravel._check_start_path_ahead

Category: **MOD_EDIT_CLEAN**

- ITER: 41 lines, params `(data)`
- 246.1: 26 lines, params `(data)`
- 248.2: 26 lines, params `(data)`

Normalized signature: `self` is omitted for methods; the body is the porting surface.

## ITER body (V8.57)

```lua
function CopLogicTravel._check_start_path_ahead(data)
local my_data = data.internal_data

	if my_data.processing_advance_path then
		return
	end

	local objective = data.objective
	local coarse_path = my_data.coarse_path
	if not coarse_path then
		return
	end

	local walk_action = my_data.advancing
	if not walk_action then
		return
	end

	local s_path = walk_action._simplified_path
	if not s_path then
		return
	end

	local from_pos = CopActionWalk._nav_point_pos(s_path[#s_path])

	local next_index = my_data.coarse_path_index + 2
	if next_index > #coarse_path then
		return
	end

	local to_pos = data.logic._get_exact_move_pos(data, next_index)
	if not to_pos then
		return
	end

	my_data.processing_advance_path = true
	local prio = data.logic.get_pathing_prio(data)
	local nav_segs = CopLogicTravel._get_allowed_travel_nav_segs(data, my_data, to_pos)

	data.brain:search_for_path_from_pos(my_data.advance_path_search_id, from_pos, to_pos, prio, nil, nav_segs)
end
```

## 246.1 vanilla (a3180fc)

```lua
function CopLogicTravel._check_start_path_ahead(data)
local my_data = data.internal_data

	if my_data.processing_advance_path then
		return
	end

	local objective = data.objective
	local coarse_path = my_data.coarse_path
	local next_index = my_data.coarse_path_index + 2
	local total_nav_points = #coarse_path

	if total_nav_points < next_index then
		return
	end

	local to_pos = data.logic._get_exact_move_pos(data, next_index)

	my_data.processing_advance_path = true

	local prio = data.logic.get_pathing_prio(data)
	local from_pos = data.pos_rsrv.move_dest.position
	local nav_segs = CopLogicTravel._get_allowed_travel_nav_segs(data, my_data, to_pos)

	data.unit:brain():search_for_path_from_pos(my_data.advance_path_search_id, from_pos, to_pos, prio, nil, nav_segs)
end
```

## 248.2 vanilla (e3a8b616)

```lua
function CopLogicTravel._check_start_path_ahead(data)
local my_data = data.internal_data

	if my_data.processing_advance_path then
		return
	end

	local objective = data.objective
	local coarse_path = my_data.coarse_path
	local next_index = my_data.coarse_path_index + 2
	local total_nav_points = #coarse_path

	if total_nav_points < next_index then
		return
	end

	local to_pos = data.logic._get_exact_move_pos(data, next_index)

	my_data.processing_advance_path = true

	local prio = data.logic.get_pathing_prio(data)
	local from_pos = data.pos_rsrv.move_dest.position
	local nav_segs = CopLogicTravel._get_allowed_travel_nav_segs(data, my_data, to_pos)

	data.unit:brain():search_for_path_from_pos(my_data.advance_path_search_id, from_pos, to_pos, prio, nil, nav_segs)
end
```

## Diff 246.1 -> ITER

```diff
--- 246.1 vanilla
+++ ITER
@@ -1,25 +1,40 @@
-local my_data = data.internal_data
-
-	if my_data.processing_advance_path then
-		return
-	end
-
-	local objective = data.objective
-	local coarse_path = my_data.coarse_path
-	local next_index = my_data.coarse_path_index + 2
-	local total_nav_points = #coarse_path
-
-	if total_nav_points < next_index then
-		return
-	end
-
-	local to_pos = data.logic._get_exact_move_pos(data, next_index)
-
-	my_data.processing_advance_path = true
-
-	local prio = data.logic.get_pathing_prio(data)
-	local from_pos = data.pos_rsrv.move_dest.position
-	local nav_segs = CopLogicTravel._get_allowed_travel_nav_segs(data, my_data, to_pos)
-
-	data.unit:brain():search_for_path_from_pos(my_data.advance_path_search_id, from_pos, to_pos, prio, nil, nav_segs)
+local my_data = data.internal_data
+
+	if my_data.processing_advance_path then
+		return
+	end
+
+	local objective = data.objective
+	local coarse_path = my_data.coarse_path
+	if not coarse_path then
+		return
+	end
+
+	local walk_action = my_data.advancing
+	if not walk_action then
+		return
+	end
+
+	local s_path = walk_action._simplified_path
+	if not s_path then
+		return
+	end
+
+	local from_pos = CopActionWalk._nav_point_pos(s_path[#s_path])
+
+	local next_index = my_data.coarse_path_index + 2
+	if next_index > #coarse_path then
+		return
+	end
+
+	local to_pos = data.logic._get_exact_move_pos(data, next_index)
+	if not to_pos then
+		return
+	end
+
+	my_data.processing_advance_path = true
+	local prio = data.logic.get_pathing_prio(data)
+	local nav_segs = CopLogicTravel._get_allowed_travel_nav_segs(data, my_data, to_pos)
+
+	data.brain:search_for_path_from_pos(my_data.advance_path_search_id, from_pos, to_pos, prio, nil, nav_segs)
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
