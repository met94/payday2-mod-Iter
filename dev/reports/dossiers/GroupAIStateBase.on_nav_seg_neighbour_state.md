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

## Port notes (P1)

1. **Wrapper or replacement.** Wrapper. `lua/groupaistatebase.lua:4` captures `itr_groupaistatebase_onnavsegneighbourstate`; `:5-10` calls it first (`:6`) and then refreshes two per-segment neighbour lists (`:8-9`).
2. **Call sites.** r200: class override, so every vanilla caller hits it. 248.2: `lib/managers/navigationmanager.lua:932`, `:987` (`set_nav_segment_state`), `:2187`, `:2226` (nav-link/door state changes); definition `lib/managers/group_ai_states/groupaistatebase.lua:4971-5005` (246.1: 4961).
3. **Intent.** 248.2's vanilla handler rebuilds the *area* graph only. Iter's coarse search walks `navseg.itr_enabled_neighbours_i`, a cached per-segment list, so the cache must be rebuilt for both endpoints whenever a neighbour changes state.
4. **248.2 delta.** None in this function: `pd2diff 246.1 248.2` hunks in `groupaistatebase.lua` are at 6 (`IDS_UNIT`), 130 (`destroy`/persisting data), 1218 (`on_enemy_engaging`/`on_enemy_disengaging` nil guards), 1798, 3448, 3465, 4705 (`add_area` string ids + nil guard), 4884 (`_on_area_safety_status` whisper early-return) and 5994 (`register_loot_no_unit`) — `on_nav_seg_neighbour_state` is untouched (`:4971-5005`, 35 lines in both).
5. **Target mechanism.** Port as-is as a wrapper, behind the AI gate. `itr_make_neighbours_list` exists in the port at `lua/navigationmanager.lua:105-120`, already normalises `tostring(navseg_id)` and rebuilds `navseg.itr_enabled_neighbours_i` (`:119`), which the ported search consumes at `:1142`. The r200 file had **no settings gate**; the worktree already added `if not Iter.settings.nav_ai then return end` at `:4-6` — that gate is mandatory, because `itr_make_neighbours_list` is nil when the nav overlay is off.
6. **Decision.** **PORT** (P4, L-05). Two calls per state change, each O(neighbours); no allocation besides the list table.
7. **Acceptance.** T4 (cache correctness) and T3. Log `evt=search k=neighbours_rebuilt=2,avail=1` (count per heist) and `evt=fallback k=reason=nav_ai_off` if the helper is missing.
8. **Cost if wrong.** Stale `itr_enabled_neighbours_i` ⇒ the coarse search routes through a segment the level just disabled (a closed door or blocked link) ⇒ units path at a wall and re-seek. Worse: 248.2 vanilla dereferences `all_nav_segs[seg_id].disabled` and `other_nav_seg.disabled` without nil guards (`:4983`, `:4989`) although `add_area` got a guard in the same patch — a stale neighbour id here is a hard error inside the vanilla body, before Iter's wrapper runs.
9. **Evidence gaps.** Whether the port's `_execute_coarce_search` is the only consumer of `itr_enabled_neighbours_i` is unconfirmed (`lua/navigationmanager.lua:1142` is the only hit), so if P5 ships a different search shape this wrapper becomes dead weight. Also unmeasured: the per-state-change cost on door-heavy maps (Big Bank).
