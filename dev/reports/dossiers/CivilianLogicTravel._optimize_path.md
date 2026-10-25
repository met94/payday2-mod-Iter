# Function dossier: lua/civilianlogictravel.lua :: CivilianLogicTravel._optimize_path

Category: **MOD_EDIT_CLEAN**

- ITER: 64 lines, params `(path, allow_out_of_graph)`
- 246.1: 57 lines, params `(path)`
- 248.2: 57 lines, params `(path)`

Normalized signature: `self` is omitted for methods; the body is the porting surface.

## ITER body (V8.57)

```lua
function CivilianLogicTravel._optimize_path(path, allow_out_of_graph)
local path_nr = #path
	if path_nr <= 2 then
		return path
	end

	local function remove_duplicates(path)
		local removed_nr = 0
		for i = #path, 2, -1 do
			if mvec3_eq(path[i], path[i - 1]) then
				table_remove(path, i - 1)
				removed_nr = removed_nr + 1
			end
		end
		return removed_nr
	end

	path_nr = path_nr - remove_duplicates(path)

	local navman = managers.navigation
	local opt_path = {path[1]}
	local count = 1
	local i = 1

	local z = {}
	for i = 1, path_nr do
		local pi = path[i]
		if type(pi) ~= 'userdata' then
			return path
		end
		z[i] = mvec3_z(pi)
	end

	while i < path_nr do
		local pos_i = path[i]
		local pos_i_z = z[i]
		local next_index = i + 1

		for j = i + 1, path_nr, 1 do
			if math_abs(z[j] - pos_i_z) < 100 then
				if allow_out_of_graph then
					if not CopActionWalk._chk_shortcut_pos_to_pos(pos_i, path[j]) then
						next_index = j
					end
				else
					if not navman:raycast({
						pos_from = pos_i,
						pos_to = path[j]
					}) then
						next_index = j
					end
				end
			end
		end

		opt_path[count + 1] = path[next_index]
		count = count + 1
		i = next_index
	end

	remove_duplicates(opt_path)

	return opt_path
end
```

## 246.1 vanilla (a3180fc)

```lua
function CivilianLogicTravel._optimize_path(path)
if #path <= 2 then
		return path
	end

	local function remove_duplicates(path)
		for i = #path, 2, -1 do
			if path[i] == path[i - 1] then
				table.remove(path, i - 1)
			end
		end
	end

	remove_duplicates(path)

	local opt_path = {
		path[1]
	}
	local i, count = 1, 1
	local up = math.UP * 4

	while i < #path do
		local pos = path[i] + up
		local next_index = i + 1

		for j = i + 1, #path do
			local pos_to = path[j] + up

			if not managers.navigation:raycast({
				pos_from = pos,
				pos_to = pos_to
			}) then
				local ray_hit = World:raycast("ray", pos, pos_to, "slot_mask", managers.slot:get_mask("statics"), "sphere_cast_radius", 8)

				if not ray_hit then
					next_index = j
				end
			end
		end

		opt_path[count + 1] = path[next_index]
		count = count + 1
		i = next_index
	end

	remove_duplicates(opt_path)

	if #opt_path >= 2 then
		local normal = tmp_vec1
		local padding = math.random(75, 110)

		mvector3.direction(normal, opt_path[#opt_path - 1], opt_path[#opt_path])
		mvector3.subtract(opt_path[#opt_path], normal * padding)
	end

	return opt_path
end
```

## 248.2 vanilla (e3a8b616)

```lua
function CivilianLogicTravel._optimize_path(path)
if #path <= 2 then
		return path
	end

	local function remove_duplicates(path)
		for i = #path, 2, -1 do
			if path[i] == path[i - 1] then
				table.remove(path, i - 1)
			end
		end
	end

	remove_duplicates(path)

	local opt_path = {
		path[1]
	}
	local i, count = 1, 1
	local up = math.UP * 4

	while i < #path do
		local pos = path[i] + up
		local next_index = i + 1

		for j = i + 1, #path do
			local pos_to = path[j] + up

			if not managers.navigation:raycast({
				pos_from = pos,
				pos_to = pos_to
			}) then
				local ray_hit = World:raycast("ray", pos, pos_to, "slot_mask", managers.slot:get_mask("statics"), "sphere_cast_radius", 8)

				if not ray_hit then
					next_index = j
				end
			end
		end

		opt_path[count + 1] = path[next_index]
		count = count + 1
		i = next_index
	end

	remove_duplicates(opt_path)

	if #opt_path >= 2 then
		local normal = tmp_vec1
		local padding = math.random(75, 110)

		mvector3.direction(normal, opt_path[#opt_path - 1], opt_path[#opt_path])
		mvector3.subtract(opt_path[#opt_path], normal * padding)
	end

	return opt_path
end
```

## Diff 246.1 -> ITER

```diff
--- 246.1 vanilla
+++ ITER
@@ -1,56 +1,63 @@
-if #path <= 2 then
-		return path
-	end
-
-	local function remove_duplicates(path)
-		for i = #path, 2, -1 do
-			if path[i] == path[i - 1] then
-				table.remove(path, i - 1)
-			end
-		end
-	end
-
-	remove_duplicates(path)
-
-	local opt_path = {
-		path[1]
-	}
-	local i, count = 1, 1
-	local up = math.UP * 4
-
-	while i < #path do
-		local pos = path[i] + up
-		local next_index = i + 1
-
-		for j = i + 1, #path do
-			local pos_to = path[j] + up
-
-			if not managers.navigation:raycast({
-				pos_from = pos,
-				pos_to = pos_to
-			}) then
-				local ray_hit = World:raycast("ray", pos, pos_to, "slot_mask", managers.slot:get_mask("statics"), "sphere_cast_radius", 8)
-
-				if not ray_hit then
-					next_index = j
-				end
-			end
-		end
-
-		opt_path[count + 1] = path[next_index]
-		count = count + 1
-		i = next_index
-	end
-
-	remove_duplicates(opt_path)
-
-	if #opt_path >= 2 then
-		local normal = tmp_vec1
-		local padding = math.random(75, 110)
-
-		mvector3.direction(normal, opt_path[#opt_path - 1], opt_path[#opt_path])
-		mvector3.subtract(opt_path[#opt_path], normal * padding)
-	end
-
-	return opt_path
+local path_nr = #path
+	if path_nr <= 2 then
+		return path
+	end
+
+	local function remove_duplicates(path)
+		local removed_nr = 0
+		for i = #path, 2, -1 do
+			if mvec3_eq(path[i], path[i - 1]) then
+				table_remove(path, i - 1)
+				removed_nr = removed_nr + 1
+			end
+		end
+		return removed_nr
+	end
+
+	path_nr = path_nr - remove_duplicates(path)
+
+	local navman = managers.navigation
+	local opt_path = {path[1]}
+	local count = 1
+	local i = 1
+
+	local z = {}
+	for i = 1, path_nr do
+		local pi = path[i]
+		if type(pi) ~= 'userdata' then
+			return path
+		end
+		z[i] = mvec3_z(pi)
+	end
+
+	while i < path_nr do
+		local pos_i = path[i]
+		local pos_i_z = z[i]
+		local next_index = i + 1
+
+		for j = i + 1, path_nr, 1 do
+			if math_abs(z[j] - pos_i_z) < 100 then
+				if allow_out_of_graph then
+					if not CopActionWalk._chk_shortcut_pos_to_pos(pos_i, path[j]) then
+						next_index = j
+					end
+				else
+					if not navman:raycast({
+						pos_from = pos_i,
+						pos_to = path[j]
+					}) then
+						next_index = j
+					end
+				end
+			end
+		end
+
+		opt_path[count + 1] = path[next_index]
+		count = count + 1
+		i = next_index
+	end
+
+	remove_duplicates(opt_path)
+
+	return opt_path
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

1. **Wrapper or replacement.** **Replacement.** `lua/civilianlogictravel.lua:13-76` captures no original and never calls vanilla; it retypes the whole 64-line body with a second parameter (`allow_out_of_graph`).
2. **Call sites.** r200: `lua/civilianbrain.lua:16` (only when `Global.game_settings.level_id == 'pal'`, `civilianbrain.lua:8`) and `lua/teamaibrain.lua:12` (revive objective or whisper mode). Both callers are DROP candidates themselves. 248.2: `lib/units/civilians/logics/civilianlogictravel.lua:202` — vanilla calls it for hostages only (`if my_data.is_hostage`), definition `:119-175`; no other caller in `lib/`.
3. **Intent.** Shortcut a civilian/team-AI detailed path by straight-lining between points with a clear walkable line, so escorted civilians do not zig-zag along the mesh.
4. **248.2 delta.** The file is byte-identical 246.1↔248.2, but the *vanilla baseline r200 replaced* is already newer than r200. Commit `9af31e98` ("242", 2025-12-18) rewrote `_optimize_path` on top of the body r200 copied:
   - `:138`, `:141`, `:145` — every raycast endpoint is raised by `math.UP * 4`;
   - `:151` — a second `World:raycast(...)` against `slot_mask "statics"`, `sphere_cast_radius 8`, so a "clear" shortcut must clear static geometry, not just the nav graph;
   - `:166-172` — the last point is pulled back `math.random(75, 110)` units along the final direction, so the civilian stops before the destination instead of on it.
   r200 has none of the three (232.4 `_optimize_path` also lacks them, i.e. r200 forked the pre-242 body and only added `allow_out_of_graph`/`CopActionWalk._chk_shortcut_pos_to_pos`).
5. **Target mechanism.** None. Porting it would install the weaker pre-242 algorithm over the 248.2 one, drop the statics raycast and the stop padding, and change the signature vanilla calls with one argument — while the only code that would call the 2-arg form (`civilianbrain`, `teamaibrain`) is being dropped.
6. **Decision.** **DROP.** Confirmed stale on evidence, not on age: the 242 commit shows exactly which checks vanilla added, and r200 lacks all of them. Vanilla's hostage optimisation (`:202`) already covers the intent, more strictly.
7. **Acceptance.** No card. T7 only: confirm no `CivilianLogicTravel._optimize_path` override is installed by Iter (`api-audit` hook list), so LIES/NavFixes/Keepers see the vanilla function.
8. **Cost if wrong.** Escorted hostages keep the vanilla path (slightly longer, stops 75-110 units short of the target by design). No risk of the r200 failure mode, which is straight-lining through a wall the nav graph does not know about.
9. **Evidence gaps.** None outstanding for the signature: `grep _optimize_path` finds no reference in `lua/_navdatapatches.lua` or anywhere else outside the two dropped brains (`lua/civilianbrain.lua:16`, `lua/teamaibrain.lua:12`). The remaining unknown is whether vanilla's statics raycast ever false-negatives on a level Iter patches — unobservable without the port.
