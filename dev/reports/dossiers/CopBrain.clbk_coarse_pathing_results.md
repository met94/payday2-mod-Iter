# Function dossier: lua/copbrain.lua :: CopBrain.clbk_coarse_pathing_results

Category: **MOD_EDIT_CLEAN**

- ITER: 31 lines, params `(search_id, path)`
- 246.1: 3 lines, params `(search_id, path)`
- 248.2: 3 lines, params `(search_id, path)`

Normalized signature: `self` is omitted for methods; the body is the porting surface.

## ITER body (V8.57)

```lua
function CopBrain.clbk_coarse_pathing_results(search_id, path)
_search_path_queued = false

	if path then
		local data = self._logic_data
		local my_data = data.internal_data
		local objective = data.objective

		path.coarse_dis = nil

		if path.has_navlinks then
			path.has_navlinks = nil
			my_data.itr_direct_to_pos = nil

		elseif objective and objective.pos and managers.groupai:state():whisper_mode() then
			my_data.itr_direct_to_pos = objective.pos
		end

		if not my_data.itr_direct_to_pos then
			path[1][2] = data.m_pos

			if objective and objective.follow_unit then
				path[#path][2] = objective.follow_unit:position()
			end

			path = managers.navigation:itr_streamline(path, self._SO_access)
		end
	end

	itr_original_copbrain_clbkcoarsepathingresults(self, search_id, path)
end
```

## 246.1 vanilla (a3180fc)

```lua
function CopBrain.clbk_coarse_pathing_results(search_id, path)
self:_add_pathing_result(search_id, path)
end
```

## 248.2 vanilla (e3a8b616)

```lua
function CopBrain.clbk_coarse_pathing_results(search_id, path)
self:_add_pathing_result(search_id, path)
end
```

## Diff 246.1 -> ITER

```diff
--- 246.1 vanilla
+++ ITER
@@ -1,2 +1,30 @@
-self:_add_pathing_result(search_id, path)
+_search_path_queued = false
+
+	if path then
+		local data = self._logic_data
+		local my_data = data.internal_data
+		local objective = data.objective
+
+		path.coarse_dis = nil
+
+		if path.has_navlinks then
+			path.has_navlinks = nil
+			my_data.itr_direct_to_pos = nil
+
+		elseif objective and objective.pos and managers.groupai:state():whisper_mode() then
+			my_data.itr_direct_to_pos = objective.pos
+		end
+
+		if not my_data.itr_direct_to_pos then
+			path[1][2] = data.m_pos
+
+			if objective and objective.follow_unit then
+				path[#path][2] = objective.follow_unit:position()
+			end
+
+			path = managers.navigation:itr_streamline(path, self._SO_access)
+		end
+	end
+
+	itr_original_copbrain_clbkcoarsepathingresults(self, search_id, path)
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
