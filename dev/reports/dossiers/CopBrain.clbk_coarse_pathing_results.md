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

## Port notes (P1)

1. **Wrapper or replacement.** Wrapper. `lua/copbrain.lua:56` captures `itr_original_copbrain_clbkcoarsepathingresults = CopBrain.clbk_coarse_pathing_results`; the replacement body `:57-87` calls it unconditionally at `:86` after rewriting `path`.
2. **Call sites.** r200: registered as `results_clbk` at `lua/copbrain.lua:33`. 248.2: registered at `lib/units/enemies/cop/copbrain.lua:563`; called from `navigationmanager.lua:1441` (same-segment fast path) and from the coarse-search pump/`_execute_coarce_search` result return.
3. **Intent.** Before vanilla stores/consumes a coarse path: drop `coarse_dis`/`has_navlinks` bookkeeping, decide direct-to-pos in whisper mode, pin `path[1][2]` to the unit's live position and `path[#path][2]` to the follow unit's position, then streamline the path through `managers.navigation:itr_streamline`.
4. **248.2 delta.** None. Vanilla is only 3 lines (`copbrain.lua:584-586`, a delegate to `_add_pathing_result` at `:630-634`); no 246.1→248.2 hunk touches it. Path entry shape is still `{seg_id, pos}` (`navigationmanager.lua:1268-1289`), so `path[1][2]`/`path[#path][2]` remain valid.
5. **Target mechanism.** Port as-is as a wrapper, gated on `managers.navigation.itr_streamline` existing (the worktree already carries the streamline-only variant at `lua/copbrain.lua:21-50`, which skips the direct-to-pos branch). Fields: `my_data.itr_direct_to_pos`, `path.has_navlinks`, `path.coarse_dis`.
6. **Decision.** **PORT** (P3 streamline / P5 direct-to-pos). Do not convert it to a replacement — the captured original is what keeps `active_searches`/`pathing_results` bookkeeping correct.
7. **Acceptance.** T4 + T5. Log `evt=streamline k=points_in,points_out,direct=0|1,navlinks=0|1,ok`; `evt=err` only from the pcall boundary.
8. **Cost if wrong.** Worst case is a path rewritten so the unit walks to `m_pos` (no-op) and then a streamline result with bad proxies ⇒ detour, or a `fallback` to the vanilla path. If the wrapper is installed twice (streamline-only + full), `path[1][2]` is rewritten twice — harmless, but the double `itr_streamline` pass doubles probe cost.
9. **Evidence gaps.** r200 sets `my_data.itr_direct_to_pos` when whisper mode and *never clears it* when a later path has no nav links (`:67-73`, the clear is only inside the `has_navlinks` branch), so a stale direct target survives conditions changes. Confirm with a T4 log that `direct=1` does not persist across objective changes.
