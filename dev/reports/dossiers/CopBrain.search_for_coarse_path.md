# Function dossier: lua/copbrain.lua :: CopBrain.search_for_coarse_path

Category: **MOD_EDIT_CLEAN**

- ITER: 37 lines, params `(search_id, to_seg, verify_clbk, access_neg)`
- 246.1: 20 lines, params `(search_id, to_seg, verify_clbk, access_neg)`
- 248.2: 20 lines, params `(search_id, to_seg, verify_clbk, access_neg)`

Normalized signature: `self` is omitted for methods; the body is the porting surface.

## ITER body (V8.57)

```lua
function CopBrain.search_for_coarse_path(search_id, to_seg, verify_clbk, access_neg)
local to_pos
	local objective = self._logic_data.objective
	if objective then
		to_pos = objective.pos
		if not to_pos and alive(objective.follow_unit) then
			to_pos = objective.follow_unit:movement():nav_tracker():field_position()
		end
	end

	local params = {
		from_tracker = self._unit:movement():nav_tracker(),
		to_seg = to_seg,
		access = {'walk'},
		id = search_id,
		results_clbk = callback(self, self, 'clbk_coarse_pathing_results', search_id),
		verify_clbk = verify_clbk,
		access_pos = self._logic_data.char_tweak.access,
		access_neg = access_neg,
		to_pos = to_pos
	}
	self._logic_data.active_searches[search_id] = 2

	_search_path_queued = true

	managers.navigation:search_coarse(params)

	if _search_path_queued then
		local cs = managers.navigation._coarse_searches
		local last_search = cs[#cs]
		if last_search then
			last_search.from_pos = self._logic_data.m_pos
		end
	end

	return true
end
```

## 246.1 vanilla (a3180fc)

```lua
function CopBrain.search_for_coarse_path(search_id, to_seg, verify_clbk, access_neg)
local params = {
		from_tracker = self._unit:movement():nav_tracker(),
		to_seg = to_seg,
		access = {
			"walk"
		},
		id = search_id,
		results_clbk = callback(self, self, "clbk_coarse_pathing_results", search_id),
		verify_clbk = verify_clbk,
		access_pos = self._logic_data.char_tweak.access,
		access_neg = access_neg
	}

	self._logic_data.active_searches[search_id] = 2

	managers.navigation:search_coarse(params)

	return true
end
```

## 248.2 vanilla (e3a8b616)

```lua
function CopBrain.search_for_coarse_path(search_id, to_seg, verify_clbk, access_neg)
local params = {
		from_tracker = self._unit:movement():nav_tracker(),
		to_seg = to_seg,
		access = {
			"walk"
		},
		id = search_id,
		results_clbk = callback(self, self, "clbk_coarse_pathing_results", search_id),
		verify_clbk = verify_clbk,
		access_pos = self._logic_data.char_tweak.access,
		access_neg = access_neg
	}

	self._logic_data.active_searches[search_id] = 2

	managers.navigation:search_coarse(params)

	return true
end
```

## Diff 246.1 -> ITER

```diff
--- 246.1 vanilla
+++ ITER
@@ -1,19 +1,36 @@
-local params = {
-		from_tracker = self._unit:movement():nav_tracker(),
-		to_seg = to_seg,
-		access = {
-			"walk"
-		},
-		id = search_id,
-		results_clbk = callback(self, self, "clbk_coarse_pathing_results", search_id),
-		verify_clbk = verify_clbk,
-		access_pos = self._logic_data.char_tweak.access,
-		access_neg = access_neg
-	}
-
-	self._logic_data.active_searches[search_id] = 2
-
-	managers.navigation:search_coarse(params)
-
-	return true
+local to_pos
+	local objective = self._logic_data.objective
+	if objective then
+		to_pos = objective.pos
+		if not to_pos and alive(objective.follow_unit) then
+			to_pos = objective.follow_unit:movement():nav_tracker():field_position()
+		end
+	end
+
+	local params = {
+		from_tracker = self._unit:movement():nav_tracker(),
+		to_seg = to_seg,
+		access = {'walk'},
+		id = search_id,
+		results_clbk = callback(self, self, 'clbk_coarse_pathing_results', search_id),
+		verify_clbk = verify_clbk,
+		access_pos = self._logic_data.char_tweak.access,
+		access_neg = access_neg,
+		to_pos = to_pos
+	}
+	self._logic_data.active_searches[search_id] = 2
+
+	_search_path_queued = true
+
+	managers.navigation:search_coarse(params)
+
+	if _search_path_queued then
+		local cs = managers.navigation._coarse_searches
+		local last_search = cs[#cs]
+		if last_search then
+			last_search.from_pos = self._logic_data.m_pos
+		end
+	end
+
+	return true
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
