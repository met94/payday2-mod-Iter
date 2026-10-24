# Function dossier: lua/navigationmanager.lua :: NavigationManager._execute_coarce_search

Category: **MOD_EDIT_VANILLA_CHANGED**

- ITER: 172 lines, params `(search_data)`
- 246.1: 103 lines, params `(search_data)`
- 248.2: 95 lines, params `(search_data)`

Normalized signature: `self` is omitted for methods; the body is the porting surface.

## ITER body (V8.57)

```lua
function NavigationManager._execute_coarce_search(search_data)
local t = TimerManager:game():time()
	local access_pos = search_data.access_pos
	local next_seg_id = search_data.start_i_seg
	local end_i_seg = search_data.end_i_seg
	local verify_clbk = search_data.verify_clbk

	local bypass_congestion = search_data.bypass_congestion
	if not bypass_congestion then
		if type(search_data.id) ~= 'string' then
			bypass_congestion = true
		else
			local fc = search_data.id:sub(1, 1)
			bypass_congestion = not (fc == 'T' or fc == 'C')
		end
	end

	local path_key = tostring(access_pos) .. ';' .. next_seg_id .. ';' .. end_i_seg
	if verify_clbk then
		path_key = path_key .. 'vc'
	end

	local cached_result = not bypass_congestion and self.itr_coarse_cache[path_key]
	if not cached_result then
		-- qued
	elseif type(cached_result) == 'number' then
		local fail_t = cached_result
		if t - fail_t < self.itr_coarse_fail_retry_t then
			return false
		end
	else
		if t - cached_result.t < self.itr_coarse_cache_lifetime then
			local result = path_copy(cached_result)
			result.t = nil
			return search_data.results_callback and result or self:itr_streamline(result)
		end
	end

	if access_pos and self._quad_field:is_nav_segment_blocked(end_i_seg, access_pos) then
		self.itr_coarse_cache[path_key] = t
		return false
	end

	local all_nav_segments = self._nav_segments
	local access_neg = search_data.access_neg
	local navlink_coef = self.itr_navlink_coef

	local potential_paths = {}
	local seg_to_search = {}
	local discovered_seg = {
		[next_seg_id] = {
			path = tostring(next_seg_id),
			delay = 0,
			steps_nr = 0,
			coarse_dis = 0,
			pos = search_data.from_pos or all_nav_segments[next_seg_id].pos
		}
	}

	local candidate
	repeat
		local navseg = all_nav_segments[next_seg_id]
		local neighbours = navseg.neighbours
		if neighbours then
			local consider_neighbours = true
			local from = discovered_seg[next_seg_id]
			local door_list = neighbours[end_i_seg]
			if door_list then
				local access_cost = bypass_congestion and 0 or self:itr_get_accessibility(door_list, access_pos, access_neg)
				if access_cost then
					local through_pos = self:itr_get_coarse_pos_between(next_seg_id, end_i_seg, from.pos, access_pos)
					consider_neighbours = access_cost > 0 or not through_pos
					if through_pos then
						local tmp = table.map_copy(from)
						tmp.delay = tmp.delay + access_cost
						tmp.coarse_dis = tmp.coarse_dis + get_coarse_dis(tmp.pos, through_pos, navseg.pos) + mvec3_dis(through_pos, search_data.to_pos or all_nav_segments[end_i_seg].pos)
						table_insert(potential_paths, tmp)

						if not candidate or tmp.coarse_dis < candidate.coarse_dis then
							if tmp.delay < 0.2 then
								candidate = tmp
							end
						end
					end
				end
			end

			if consider_neighbours then
				local enabled_neighbours = navseg.itr_enabled_neighbours_i
				for i = #enabled_neighbours, 1, -1 do
					local neighbour_seg_id = enabled_neighbours[i]
					if verify_clbk and not verify_clbk(neighbour_seg_id) then
						-- qued
					elseif access_pos and self._quad_field:is_nav_segment_blocked(neighbour_seg_id, access_pos) then
						-- qued
					else
						local door_list = neighbours[neighbour_seg_id]
						local access_cost = bypass_congestion and 0 or self:itr_get_accessibility(door_list, access_pos, access_neg)
						if access_cost then
							local through_pos = self:itr_get_coarse_pos_between(next_seg_id, neighbour_seg_id, from.pos, access_pos)
							if through_pos then
								local delay = from.delay + access_cost
								local coarse_dis = from.coarse_dis + get_coarse_dis(from.pos, through_pos, navseg.pos)
								local discovered = discovered_seg[neighbour_seg_id]
								if not discovered then
									if not candidate or coarse_dis + delay * navlink_coef < candidate.coarse_dis + candidate.delay * navlink_coef then
										table_insert(seg_to_search, neighbour_seg_id)
										discovered = {
											path = from.path .. ';' .. neighbour_seg_id,
											delay = delay,
											steps_nr = from.steps_nr + 1,
											coarse_dis = coarse_dis,
											pos = through_pos
										}
										discovered_seg[neighbour_seg_id] = discovered
									end
								else
									if coarse_dis + delay * navlink_coef < discovered.coarse_dis + discovered.delay * navlink_coef then
										table_insert(seg_to_search, neighbour_seg_id)
										discovered.path = from.path .. ';' .. neighbour_seg_id
										discovered.delay = delay
										discovered.steps_nr = from.steps_nr + 1
										discovered.coarse_dis = coarse_dis
										discovered.pos = through_pos
									end
								end
							end
						end
					end
				end
			end
		end

		next_seg_id = table_remove(seg_to_search, 1)
	until not next_seg_id

	local best_score = 100000000
	local best_path
	for _, ppath in ipairs(potential_paths) do
		local score = ppath.coarse_dis + ppath.delay * navlink_coef
		if score < best_score then
			best_score = score
			best_path = ppath
		end
	end

	if not best_path then
		self.itr_coarse_cache[path_key] = t
		return false
	end

	local i = 1
	local result = {}
	for idseg in string.gmatch(best_path.path, '%d+') do
		result[i] = { tonumber(idseg) }
		i = i + 1
	end
	result[i] = {
		end_i_seg,
		search_data.to_pos
	}
	result.has_navlinks = best_path.delay > 0
	result.coarse_dis = best_path.coarse_dis

	if best_path.delay == 0 then
		local cache_result = path_copy(result)
		cache_result.t = t
		self.itr_coarse_cache[path_key] = cache_result
	end

	return search_data.results_callback and result or self:itr_streamline(result)
end
```

## 246.1 vanilla (a3180fc)

```lua
function NavigationManager._execute_coarce_search(search_data)
local search_id = search_data.id
	local i = 0

	while true do
		if i == 500 then
			debug_pause("[NavigationManager:_execute_coarce_search] endless loop", inspect(search_data))

			return false
		else
			i = i + 1
		end

		local next_search_seg = search_data.seg_to_search[#search_data.seg_to_search]
		local next_search_i_seg = next_search_seg.i_seg

		table.remove(search_data.seg_to_search)

		local all_nav_segments = self._nav_segments
		local neighbours = all_nav_segments[next_search_i_seg].neighbours

		if neighbours[search_data.end_i_seg] then
			local entry_found

			for _, i_door in ipairs(neighbours[search_data.end_i_seg]) do
				if type(i_door) == "number" then
					entry_found = true

					break
				elseif TimerManager:game():time() > i_door:delay_time() and i_door:check_access(search_data.access_pos, search_data.access_neg) then
					entry_found = true

					break
				end
			end

			if entry_found then
				local i_seg = next_search_i_seg
				local this_seg = next_search_seg
				local prev_seg = search_data.end_i_seg
				local path = {
					{
						search_data.end_i_seg,
						search_data.to_pos
					}
				}

				table.insert(path, 1, {
					next_search_i_seg,
					next_search_seg.pos
				})

				local searched = search_data.seg_searched

				while this_seg.from do
					i_seg = this_seg.from
					this_seg = searched[i_seg]

					table.insert(path, 1, {
						i_seg,
						this_seg.pos
					})
				end

				return path
			end
		end

		local to_pos = search_data.to_pos
		local new_segments = self:_sort_nav_segs_after_pos(to_pos, next_search_i_seg, search_data.discovered_seg, search_data.verify_clbk, search_data.access_pos, search_data.access_neg)

		if new_segments then
			if search_data.access_pos then
				for i_seg, data in pairs(new_segments) do
					if self._quad_field:is_nav_segment_blocked(i_seg, search_data.access_pos) then
						new_segments[i_seg] = nil
					end
				end
			end

			local to_search = search_data.seg_to_search

			for i_seg, seg_data in pairs(new_segments) do
				local new_seg_weight = seg_data.weight
				local search_index = #to_search

				while search_index > 0 and new_seg_weight > to_search[search_index].weight do
					search_index = search_index - 1
				end

				table.insert(to_search, search_index + 1, seg_data)
			end
		end

		local nr_seg_to_search = #search_data.seg_to_search

		if nr_seg_to_search == 0 then
			return false
		else
			search_data.seg_searched[next_search_i_seg] = next_search_seg
		end
	end
end
```

## 248.2 vanilla (e3a8b616)

```lua
function NavigationManager._execute_coarce_search(search_data)
local search_id = search_data.id
	local t = TimerManager:game():time()
	local all_nav_segments = self._nav_segments

	for i = 1, 500 do
		local next_search_seg = search_data.seg_to_search[#search_data.seg_to_search]
		local next_search_i_seg = next_search_seg.i_seg

		table.remove(search_data.seg_to_search)

		local neighbours = all_nav_segments[next_search_i_seg].neighbours

		if neighbours[search_data.end_i_seg] then
			local entry_found

			for _, door in ipairs(neighbours[search_data.end_i_seg]) do
				if door.x then
					entry_found = true

					break
				elseif t > door:delay_time() and door:check_access(search_data.access_pos, search_data.access_neg) then
					entry_found = true

					break
				end
			end

			if entry_found then
				local i_seg = next_search_i_seg
				local this_seg = next_search_seg
				local prev_seg = search_data.end_i_seg
				local path = {
					{
						search_data.end_i_seg,
						search_data.to_pos
					}
				}
				local searched = search_data.seg_searched

				table.insert(path, 1, {
					next_search_i_seg,
					next_search_seg.pos
				})

				while this_seg.from do
					i_seg = this_seg.from
					this_seg = searched[i_seg]

					table.insert(path, 1, {
						i_seg,
						this_seg.pos
					})
				end

				return path
			end
		end

		local to_pos = search_data.to_pos
		local new_segments = self:_sort_nav_segs_after_pos(to_pos, next_search_i_seg, search_data.discovered_seg, search_data.verify_clbk, search_data.access_pos, search_data.access_neg)
		local to_search = search_data.seg_to_search

		if new_segments then
			if search_data.access_pos then
				for i_seg in pairs(new_segments) do
					if self._quad_field:is_nav_segment_blocked(i_seg, search_data.access_pos) then
						new_segments[i_seg] = nil
					end
				end
			end

			for _, seg_data in pairs(new_segments) do
				local new_seg_weight = seg_data.weight
				local search_index = #to_search

				while search_index > 0 and new_seg_weight > to_search[search_index].weight do
					search_index = search_index - 1
				end

				table.insert(to_search, search_index + 1, seg_data)
			end
		end

		if #to_search == 0 then
			return false
		end

		search_data.seg_searched[next_search_i_seg] = next_search_seg
	end

	debug_pause("[NavigationManager:_execute_coarce_search] endless loop", inspect(search_data))

	return false
end
```

## Diff 246.1 -> ITER

```diff
--- 246.1 vanilla
+++ ITER
@@ -1,102 +1,171 @@
-local search_id = search_data.id
-	local i = 0
-
-	while true do
-		if i == 500 then
-			debug_pause("[NavigationManager:_execute_coarce_search] endless loop", inspect(search_data))
-
-			return false
-		else
-			i = i + 1
-		end
-
-		local next_search_seg = search_data.seg_to_search[#search_data.seg_to_search]
-		local next_search_i_seg = next_search_seg.i_seg
-
-		table.remove(search_data.seg_to_search)
-
-		local all_nav_segments = self._nav_segments
-		local neighbours = all_nav_segments[next_search_i_seg].neighbours
-
-		if neighbours[search_data.end_i_seg] then
-			local entry_found
-
-			for _, i_door in ipairs(neighbours[search_data.end_i_seg]) do
-				if type(i_door) == "number" then
-					entry_found = true
-
-					break
-				elseif TimerManager:game():time() > i_door:delay_time() and i_door:check_access(search_data.access_pos, search_data.access_neg) then
-					entry_found = true
-
-					break
-				end
-			end
-
-			if entry_found then
-				local i_seg = next_search_i_seg
-				local this_seg = next_search_seg
-				local prev_seg = search_data.end_i_seg
-				local path = {
-					{
-						search_data.end_i_seg,
-						search_data.to_pos
-					}
-				}
-
-				table.insert(path, 1, {
-					next_search_i_seg,
-					next_search_seg.pos
-				})
-
-				local searched = search_data.seg_searched
-
-				while this_seg.from do
-					i_seg = this_seg.from
-					this_seg = searched[i_seg]
-
-					table.insert(path, 1, {
-						i_seg,
-						this_seg.pos
-					})
-				end
-
-				return path
-			end
-		end
-
-		local to_pos = search_data.to_pos
-		local new_segments = self:_sort_nav_segs_after_pos(to_pos, next_search_i_seg, search_data.discovered_seg, search_data.verify_clbk, search_data.access_pos, search_data.access_neg)
-
-		if new_segments then
-			if search_data.access_pos then
-				for i_seg, data in pairs(new_segments) do
-					if self._quad_field:is_nav_segment_blocked(i_seg, search_data.access_pos) then
-						new_segments[i_seg] = nil
-					end
-				end
-			end
-
-			local to_search = search_data.seg_to_search
-
-			for i_seg, seg_data in pairs(new_segments) do
-				local new_seg_weight = seg_data.weight
-				local search_index = #to_search
-
-				while search_index > 0 and new_seg_weight > to_search[search_index].weight do
-					search_index = search_index - 1
-				end
-
-				table.insert(to_search, search_index + 1, seg_data)
-			end
-		end
-
-		local nr_seg_to_search = #search_data.seg_to_search
-
-		if nr_seg_to_search == 0 then
-			return false
-		else
-			search_data.seg_searched[next_search_i_seg] = next_search_seg
-		end
-	end
+local t = TimerManager:game():time()
+	local access_pos = search_data.access_pos
+	local next_seg_id = search_data.start_i_seg
+	local end_i_seg = search_data.end_i_seg
+	local verify_clbk = search_data.verify_clbk
+
+	local bypass_congestion = search_data.bypass_congestion
+	if not bypass_congestion then
+		if type(search_data.id) ~= 'string' then
+			bypass_congestion = true
+		else
+			local fc = search_data.id:sub(1, 1)
+			bypass_congestion = not (fc == 'T' or fc == 'C')
+		end
+	end
+
+	local path_key = tostring(access_pos) .. ';' .. next_seg_id .. ';' .. end_i_seg
+	if verify_clbk then
+		path_key = path_key .. 'vc'
+	end
+
+	local cached_result = not bypass_congestion and self.itr_coarse_cache[path_key]
+	if not cached_result then
+		-- qued
+	elseif type(cached_result) == 'number' then
+		local fail_t = cached_result
+		if t - fail_t < self.itr_coarse_fail_retry_t then
+			return false
+		end
+	else
+		if t - cached_result.t < self.itr_coarse_cache_lifetime then
+			local result = path_copy(cached_result)
+			result.t = nil
+			return search_data.results_callback and result or self:itr_streamline(result)
+		end
+	end
+
+	if access_pos and self._quad_field:is_nav_segment_blocked(end_i_seg, access_pos) then
+		self.itr_coarse_cache[path_key] = t
+		return false
+	end
+
+	local all_nav_segments = self._nav_segments
+	local access_neg = search_data.access_neg
+	local navlink_coef = self.itr_navlink_coef
+
+	local potential_paths = {}
+	local seg_to_search = {}
+	local discovered_seg = {
+		[next_seg_id] = {
+			path = tostring(next_seg_id),
+			delay = 0,
+			steps_nr = 0,
+			coarse_dis = 0,
+			pos = search_data.from_pos or all_nav_segments[next_seg_id].pos
+		}
+	}
+
+	local candidate
+	repeat
+		local navseg = all_nav_segments[next_seg_id]
+		local neighbours = navseg.neighbours
+		if neighbours then
+			local consider_neighbours = true
+			local from = discovered_seg[next_seg_id]
+			local door_list = neighbours[end_i_seg]
+			if door_list then
+				local access_cost = bypass_congestion and 0 or self:itr_get_accessibility(door_list, access_pos, access_neg)
+				if access_cost then
+					local through_pos = self:itr_get_coarse_pos_between(next_seg_id, end_i_seg, from.pos, access_pos)
+					consider_neighbours = access_cost > 0 or not through_pos
+					if through_pos then
+						local tmp = table.map_copy(from)
+						tmp.delay = tmp.delay + access_cost
+						tmp.coarse_dis = tmp.coarse_dis + get_coarse_dis(tmp.pos, through_pos, navseg.pos) + mvec3_dis(through_pos, search_data.to_pos or all_nav_segments[end_i_seg].pos)
+						table_insert(potential_paths, tmp)
+
+						if not candidate or tmp.coarse_dis < candidate.coarse_dis then
+							if tmp.delay < 0.2 then
+								candidate = tmp
+							end
+						end
+					end
+				end
+			end
+
+			if consider_neighbours then
+				local enabled_neighbours = navseg.itr_enabled_neighbours_i
+				for i = #enabled_neighbours, 1, -1 do
+					local neighbour_seg_id = enabled_neighbours[i]
+					if verify_clbk and not verify_clbk(neighbour_seg_id) then
+						-- qued
+					elseif access_pos and self._quad_field:is_nav_segment_blocked(neighbour_seg_id, access_pos) then
+						-- qued
+					else
+						local door_list = neighbours[neighbour_seg_id]
+						local access_cost = bypass_congestion and 0 or self:itr_get_accessibility(door_list, access_pos, access_neg)
+						if access_cost then
+							local through_pos = self:itr_get_coarse_pos_between(next_seg_id, neighbour_seg_id, from.pos, access_pos)
+							if through_pos then
+								local delay = from.delay + access_cost
+								local coarse_dis = from.coarse_dis + get_coarse_dis(from.pos, through_pos, navseg.pos)
+								local discovered = discovered_seg[neighbour_seg_id]
+								if not discovered then
+									if not candidate or coarse_dis + delay * navlink_coef < candidate.coarse_dis + candidate.delay * navlink_coef then
+										table_insert(seg_to_search, neighbour_seg_id)
+										discovered = {
+											path = from.path .. ';' .. neighbour_seg_id,
+											delay = delay,
+											steps_nr = from.steps_nr + 1,
+											coarse_dis = coarse_dis,
+											pos = through_pos
+										}
+										discovered_seg[neighbour_seg_id] = discovered
+									end
+								else
+									if coarse_dis + delay * navlink_coef < discovered.coarse_dis + discovered.delay * navlink_coef then
+										table_insert(seg_to_search, neighbour_seg_id)
+										discovered.path = from.path .. ';' .. neighbour_seg_id
+										discovered.delay = delay
+										discovered.steps_nr = from.steps_nr + 1
+										discovered.coarse_dis = coarse_dis
+										discovered.pos = through_pos
+									end
+								end
+							end
+						end
+					end
+				end
+			end
+		end
+
+		next_seg_id = table_remove(seg_to_search, 1)
+	until not next_seg_id
+
+	local best_score = 100000000
+	local best_path
+	for _, ppath in ipairs(potential_paths) do
+		local score = ppath.coarse_dis + ppath.delay * navlink_coef
+		if score < best_score then
+			best_score = score
+			best_path = ppath
+		end
+	end
+
+	if not best_path then
+		self.itr_coarse_cache[path_key] = t
+		return false
+	end
+
+	local i = 1
+	local result = {}
+	for idseg in string.gmatch(best_path.path, '%d+') do
+		result[i] = { tonumber(idseg) }
+		i = i + 1
+	end
+	result[i] = {
+		end_i_seg,
+		search_data.to_pos
+	}
+	result.has_navlinks = best_path.delay > 0
+	result.coarse_dis = best_path.coarse_dis
+
+	if best_path.delay == 0 then
+		local cache_result = path_copy(result)
+		cache_result.t = t
+		self.itr_coarse_cache[path_key] = cache_result
+	end
+
+	return search_data.results_callback and result or self:itr_streamline(result)
 end
\ No newline at end of file
```

## Diff 246.1 -> 248.2

```diff
--- 246.1 vanilla
+++ 248.2 vanilla
@@ -1,32 +1,24 @@
 local search_id = search_data.id
-	local i = 0
-
-	while true do
-		if i == 500 then
-			debug_pause("[NavigationManager:_execute_coarce_search] endless loop", inspect(search_data))
-
-			return false
-		else
-			i = i + 1
-		end
+	local t = TimerManager:game():time()
+	local all_nav_segments = self._nav_segments
 
+	for i = 1, 500 do
 		local next_search_seg = search_data.seg_to_search[#search_data.seg_to_search]
 		local next_search_i_seg = next_search_seg.i_seg
 
 		table.remove(search_data.seg_to_search)
 
-		local all_nav_segments = self._nav_segments
 		local neighbours = all_nav_segments[next_search_i_seg].neighbours
 
 		if neighbours[search_data.end_i_seg] then
 			local entry_found
 
-			for _, i_door in ipairs(neighbours[search_data.end_i_seg]) do
-				if type(i_door) == "number" then
+			for _, door in ipairs(neighbours[search_data.end_i_seg]) do
+				if door.x then
 					entry_found = true
 
 					break
-				elseif TimerManager:game():time() > i_door:delay_time() and i_door:check_access(search_data.access_pos, search_data.access_neg) then
+				elseif t > door:delay_time() and door:check_access(search_data.access_pos, search_data.access_neg) then
 					entry_found = true
 
 					break
@@ -43,14 +35,13 @@ local search_id = search_data.id
 						search_data.to_pos
 					}
 				}
+				local searched = search_data.seg_searched
 
 				table.insert(path, 1, {
 					next_search_i_seg,
 					next_search_seg.pos
 				})
 
-				local searched = search_data.seg_searched
-
 				while this_seg.from do
 					i_seg = this_seg.from
 					this_seg = searched[i_seg]
@@ -67,19 +58,18 @@ local search_id = search_data.id
 
 		local to_pos = search_data.to_pos
 		local new_segments = self:_sort_nav_segs_after_pos(to_pos, next_search_i_seg, search_data.discovered_seg, search_data.verify_clbk, search_data.access_pos, search_data.access_neg)
+		local to_search = search_data.seg_to_search
 
 		if new_segments then
 			if search_data.access_pos then
-				for i_seg, data in pairs(new_segments) do
+				for i_seg in pairs(new_segments) do
 					if self._quad_field:is_nav_segment_blocked(i_seg, search_data.access_pos) then
 						new_segments[i_seg] = nil
 					end
 				end
 			end
 
-			local to_search = search_data.seg_to_search
-
-			for i_seg, seg_data in pairs(new_segments) do
+			for _, seg_data in pairs(new_segments) do
 				local new_seg_weight = seg_data.weight
 				local search_index = #to_search
 
@@ -91,12 +81,14 @@ local search_id = search_data.id
 			end
 		end
 
-		local nr_seg_to_search = #search_data.seg_to_search
-
-		if nr_seg_to_search == 0 then
+		if #to_search == 0 then
 			return false
-		else
-			search_data.seg_searched[next_search_i_seg] = next_search_seg
 		end
+
+		search_data.seg_searched[next_search_i_seg] = next_search_seg
 	end
+
+	debug_pause("[NavigationManager:_execute_coarce_search] endless loop", inspect(search_data))
+
+	return false
 end
\ No newline at end of file
```

## Porter checklist

- [ ] Decision: keep ITER body, adopt 248.2 vanilla, or merge.
- [ ] If merge: re-apply the ITER intent onto the 248.2 body, not the 246.1 body.
- [ ] Check removed/changed APIs (`_room_doors`, numeric `_nav_segments`, `no_dispose`, `session():send_to_peers_synched`, ...).
- [ ] Check new 248.2 fields/callbacks this function must preserve.
- [ ] Run `luajit -bl` and `api-audit` on the file.
