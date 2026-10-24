# Function dossier: lua/copactionwalk.lua :: CopActionWalk._chk_correct_pose

Category: **MOD_EDIT_CLEAN**

- ITER: 8 lines, params `()`
- 246.1: 28 lines, params `()`
- 248.2: 28 lines, params `()`

Normalized signature: `self` is omitted for methods; the body is the porting surface.

## ITER body (V8.57)

```lua
function CopActionWalk._chk_correct_pose()
if self.itr_shield_machine_switched then
		self.itr_shield_machine_switched = nil
		self._ext_movement._machine:set_global('shield', 1)
	end

	itr_original_copactionwalk_chkcorrectpose(self)
end
```

## 246.1 vanilla (a3180fc)

```lua
function CopActionWalk._chk_correct_pose()
local wanted_pose
	local pose = self._ext_anim.pose
	local available_poses = self._common_data.char_tweak.allowed_poses or {
		crouch = true,
		stand = true
	}

	if not pose then
		if available_poses.stand then
			wanted_pose = "stand"
		else
			wanted_pose = "crouch"
		end
	elseif not available_poses[pose] then
		wanted_pose = pose == "stand" and "crouch" or "stand"
	end

	if wanted_pose then
		local action_desc = {
			body_part = 4,
			no_sync = true,
			type = wanted_pose
		}

		self._ext_movement:action_request(action_desc)
	end
end
```

## 248.2 vanilla (e3a8b616)

```lua
function CopActionWalk._chk_correct_pose()
local wanted_pose
	local pose = self._ext_anim.pose
	local available_poses = self._common_data.char_tweak.allowed_poses or {
		crouch = true,
		stand = true
	}

	if not pose then
		if available_poses.stand then
			wanted_pose = "stand"
		else
			wanted_pose = "crouch"
		end
	elseif not available_poses[pose] then
		wanted_pose = pose == "stand" and "crouch" or "stand"
	end

	if wanted_pose then
		local action_desc = {
			body_part = 4,
			no_sync = true,
			type = wanted_pose
		}

		self._ext_movement:action_request(action_desc)
	end
end
```

## Diff 246.1 -> ITER

```diff
--- 246.1 vanilla
+++ ITER
@@ -1,27 +1,7 @@
-local wanted_pose
-	local pose = self._ext_anim.pose
-	local available_poses = self._common_data.char_tweak.allowed_poses or {
-		crouch = true,
-		stand = true
-	}
-
-	if not pose then
-		if available_poses.stand then
-			wanted_pose = "stand"
-		else
-			wanted_pose = "crouch"
-		end
-	elseif not available_poses[pose] then
-		wanted_pose = pose == "stand" and "crouch" or "stand"
-	end
-
-	if wanted_pose then
-		local action_desc = {
-			body_part = 4,
-			no_sync = true,
-			type = wanted_pose
-		}
-
-		self._ext_movement:action_request(action_desc)
-	end
+if self.itr_shield_machine_switched then
+		self.itr_shield_machine_switched = nil
+		self._ext_movement._machine:set_global('shield', 1)
+	end
+
+	itr_original_copactionwalk_chkcorrectpose(self)
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
