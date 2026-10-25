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

## Port notes (P1)

1. **Wrapper or replacement.** Replacement. `lua/copbrain.lua:18-54` never captures or calls the vanilla body — there is no `itr_original_*search*` local anywhere in the file. It is the only AI function in the cluster that is a true replacement, and it must stay one: `to_pos` has to be inside `params` before the queued search runs.
2. **Call sites.** r200: no in-tree caller (installed by class override); callback registered `lua/copbrain.lua:33`. 248.2: `lib/units/enemies/cop/logics/coplogictravel.lua:1570`, `coplogicflee.lua:225`, `coplogicattack.lua:1616`, `lib/units/civilians/logics/civilianlogictravel.lua:239`, `civilianlogicescort.lua:130` (all via `unit:brain():search_for_coarse_path`).
3. **Intent.** Give the coarse search the real objective position (`objective.pos`, else the follow unit's field position) so the final coarse step lands on the objective instead of the segment centre; also correct the queued search's start position to the unit's live `m_pos`.
4. **248.2 delta.** None. Dossier diff "No differences"; `pd2diff 246.1 248.2` hunks in `copbrain.lua` are at 88, 1093, 1157, 1202 only. 248.2 body `lib/units/enemies/cop/copbrain.lua:555-574` is line-for-line the 246.1 body.
5. **Target mechanism.** Port as-is onto the 248.2 param set. `params.to_pos` is honoured by `lib/managers/navigationmanager.lua:1437` (`pos_to = params.to_pos or self._nav_segments[end_i_seg].pos`). The `last_search.from_pos` write (`lua/copbrain.lua:45-51`) has **no consumer** in vanilla `_execute_coarce_search` (`navigationmanager.lua:1236-1330` builds path pos from `to_pos`/`seg.pos` only); only the ported search reads it (`lua/navigationmanager.lua:1109`).
6. **Decision.** **PORT** (P5, C-01/C-03) as a replacement. Keep the 248.2 param list verbatim plus `to_pos`; keep the `_search_path_queued` guard because 248.2 `search_coarse` still has the same-segment synchronous callback path (`navigationmanager.lua:1439-1451`).
7. **Acceptance.** T4 (Big Bank / Border Crossing). Log `evt=search k=id,to_seg,to_pos=1,from_pos=<0|1>,ok`; plus `evt=fallback k=reason=no_from_pos_consumer` once per heist when the ported search is not installed.
8. **Cost if wrong.** `to_pos` lost ⇒ coarse paths end at the segment centre and units walk the last leg to the objective (visible as a stop-and-go at the final segment), not a crash. `from_pos` written to a foreign search ⇒ one unit starts a coarse search from another unit's position (rare, self-correcting on the next search).
9. **Evidence gaps.** (a) `_search_path_queued` is a single file-level upvalue shared by all CopBrains, and `search_coarse` returns early on invalid segments (`navigationmanager.lua:1419-1435`) *without* clearing it — the `cs[#cs]` write then patches the previous search. r200 has this bug; fix on port by re-reading `#cs` before/after. (b) Whether LIES also replaces `_execute_coarce_search` at 248.2 (R5) is unresolved, so the `from_pos` consumer may not be Iter's.
