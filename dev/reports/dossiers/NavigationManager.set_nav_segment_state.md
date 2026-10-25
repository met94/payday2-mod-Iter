# Function dossier: lua/navigationmanager.lua :: NavigationManager.set_nav_segment_state

Category: **MOD_EDIT_VANILLA_CHANGED**

- ITER: 10 lines, params `(id, ...)`
- 246.1: 36 lines, params `(id, state, filter_group)`
- 248.2: 38 lines, params `(id, state, filter_group)`

Normalized signature: `self` is omitted for methods; the body is the porting surface.

## ITER body (V8.57)

```lua
function NavigationManager.set_nav_segment_state(id, ...)
itr_original_navigationmanager_setnavsegmentstate(self, id, ...)

	self:itr_make_neighbours_list(id)
	if self._nav_segments[id].neighbours then
		for neighbour_id in pairs(self._nav_segments[id].neighbours) do
			self:itr_make_neighbours_list(neighbour_id)
		end
	end
end
```

## 246.1 vanilla (a3180fc)

```lua
function NavigationManager.set_nav_segment_state(id, state, filter_group)
if not self._nav_segments[id] then
		debug_pause("[NavigationManager:set_nav_segment_state] inexistent nav_segment", id)

		return
	end

	if state == "forbid_custom" then
		local access_filter = self:convert_SO_AI_group_to_access(filter_group)

		self._quad_field:set_nav_segment_blocked_filter(id, access_filter)

		self._nav_segments[id].blocked_group = filter_group

		return
	end

	self._quad_field:set_nav_segment_blocked_filter(id, 0)

	self._nav_segments[id].blocked_group = nil

	local wanted_state = state == "allow_access" and true or false
	local cur_state = self._quad_field:is_nav_segment_enabled(id)
	local seg_disabled_state

	if not wanted_state then
		seg_disabled_state = true
	end

	self._nav_segments[id].disabled = seg_disabled_state

	if wanted_state ~= cur_state then
		self._quad_field:set_nav_segment_enabled(id, wanted_state)
		managers.groupai:state():on_nav_segment_state_change(id, wanted_state)
	end
end
```

## 248.2 vanilla (e3a8b616)

```lua
function NavigationManager.set_nav_segment_state(id, state, filter_group)
local unique_id = tostring(id)

	if not self._nav_segments[unique_id] then
		debug_pause("[NavigationManager:set_nav_segment_state] nonexistent nav_segment", unique_id)

		return
	end

	if state == "forbid_custom" then
		local access_filter = self:convert_SO_AI_group_to_access(filter_group)

		self._quad_field:set_nav_segment_blocked_filter(unique_id, access_filter)

		self._nav_segments[unique_id].blocked_group = filter_group

		return
	end

	self._quad_field:set_nav_segment_blocked_filter(unique_id, 0)

	self._nav_segments[unique_id].blocked_group = nil

	local wanted_state = state == "allow_access" and true or false
	local cur_state = self._quad_field:is_nav_segment_enabled(unique_id)
	local seg_disabled_state

	if not wanted_state then
		seg_disabled_state = true
	end

	self._nav_segments[unique_id].disabled = seg_disabled_state

	if wanted_state ~= cur_state then
		self._quad_field:set_nav_segment_enabled(unique_id, wanted_state)
		managers.groupai:state():on_nav_segment_state_change(unique_id, wanted_state)
	end
end
```

## Diff 246.1 -> ITER

```diff
--- 246.1 vanilla
+++ ITER
@@ -1,35 +1,9 @@
-if not self._nav_segments[id] then
-		debug_pause("[NavigationManager:set_nav_segment_state] inexistent nav_segment", id)
-
-		return
-	end
-
-	if state == "forbid_custom" then
-		local access_filter = self:convert_SO_AI_group_to_access(filter_group)
-
-		self._quad_field:set_nav_segment_blocked_filter(id, access_filter)
-
-		self._nav_segments[id].blocked_group = filter_group
-
-		return
-	end
-
-	self._quad_field:set_nav_segment_blocked_filter(id, 0)
-
-	self._nav_segments[id].blocked_group = nil
-
-	local wanted_state = state == "allow_access" and true or false
-	local cur_state = self._quad_field:is_nav_segment_enabled(id)
-	local seg_disabled_state
-
-	if not wanted_state then
-		seg_disabled_state = true
-	end
-
-	self._nav_segments[id].disabled = seg_disabled_state
-
-	if wanted_state ~= cur_state then
-		self._quad_field:set_nav_segment_enabled(id, wanted_state)
-		managers.groupai:state():on_nav_segment_state_change(id, wanted_state)
-	end
+itr_original_navigationmanager_setnavsegmentstate(self, id, ...)
+
+	self:itr_make_neighbours_list(id)
+	if self._nav_segments[id].neighbours then
+		for neighbour_id in pairs(self._nav_segments[id].neighbours) do
+			self:itr_make_neighbours_list(neighbour_id)
+		end
+	end
 end
\ No newline at end of file
```

## Diff 246.1 -> 248.2

```diff
--- 246.1 vanilla
+++ 248.2 vanilla
@@ -1,5 +1,7 @@
-if not self._nav_segments[id] then
-		debug_pause("[NavigationManager:set_nav_segment_state] inexistent nav_segment", id)
+local unique_id = tostring(id)
+
+	if not self._nav_segments[unique_id] then
+		debug_pause("[NavigationManager:set_nav_segment_state] nonexistent nav_segment", unique_id)
 
 		return
 	end
@@ -7,29 +9,29 @@ if not self._nav_segments[id] then
 	if state == "forbid_custom" then
 		local access_filter = self:convert_SO_AI_group_to_access(filter_group)
 
-		self._quad_field:set_nav_segment_blocked_filter(id, access_filter)
+		self._quad_field:set_nav_segment_blocked_filter(unique_id, access_filter)
 
-		self._nav_segments[id].blocked_group = filter_group
+		self._nav_segments[unique_id].blocked_group = filter_group
 
 		return
 	end
 
-	self._quad_field:set_nav_segment_blocked_filter(id, 0)
+	self._quad_field:set_nav_segment_blocked_filter(unique_id, 0)
 
-	self._nav_segments[id].blocked_group = nil
+	self._nav_segments[unique_id].blocked_group = nil
 
 	local wanted_state = state == "allow_access" and true or false
-	local cur_state = self._quad_field:is_nav_segment_enabled(id)
+	local cur_state = self._quad_field:is_nav_segment_enabled(unique_id)
 	local seg_disabled_state
 
 	if not wanted_state then
 		seg_disabled_state = true
 	end
 
-	self._nav_segments[id].disabled = seg_disabled_state
+	self._nav_segments[unique_id].disabled = seg_disabled_state
 
 	if wanted_state ~= cur_state then
-		self._quad_field:set_nav_segment_enabled(id, wanted_state)
-		managers.groupai:state():on_nav_segment_state_change(id, wanted_state)
+		self._quad_field:set_nav_segment_enabled(unique_id, wanted_state)
+		managers.groupai:state():on_nav_segment_state_change(unique_id, wanted_state)
 	end
 end
\ No newline at end of file
```

## Porter checklist

- [ ] Decision: keep ITER body, adopt 248.2 vanilla, or merge.
- [ ] If merge: re-apply the ITER intent onto the 248.2 body, not the 246.1 body.
- [ ] Check removed/changed APIs (`_room_doors`, numeric `_nav_segments`, `no_dispose`, `session():send_to_peers_synched`, ...).
- [ ] Check new 248.2 fields/callbacks this function must preserve.
- [ ] Run `luajit -bl` and `api-audit` on the file.
