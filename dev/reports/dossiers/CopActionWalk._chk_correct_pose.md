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

## Port notes (P1)

1. **Wrapper or replacement.** **Wrapper, not a replacement.** `lua/copactionwalk.lua:426` captures `itr_original_copactionwalk_chkcorrectpose = CopActionWalk._chk_correct_pose` and `:433` calls it with `self`. The 8-line r200 body is only the shield-global restore around the vanilla call — the intent-map line "8 vs 29 lines; old body likely stale" compared a wrapper against a vanilla body, which is why it read as stale.
2. **Call sites.** r200: class override of `CopActionWalk._chk_correct_pose`. 248.2: `copactionwalk.lua:2538`, `:2566` (definition `:2762-2789`), plus the cross-class users `lib/units/enemies/cop/actions/full_body/copactionact.lua:1606`, `copactionhurt.lua:1338`, `upper_body/copactionhealed.lua:30` — so the wrapper also runs for full-body actions.
3. **Intent.** While a shield cop climbs a nav link, `_upd_nav_link_first_frame` clears the `shield` anim global (`:418-421`); this function restores it on the next pose check so the shield does not stay lowered for the rest of the heist.
4. **248.2 delta.** None. 248.2 `:2762-2789` (28 lines, not 29) is byte-identical to 246.1 (`:2740`); no hunk in `pd2diff 246.1 248.2` covers it. The only file-level changes are `_chk_start_anim`, `on_exit`, `_upd_start_anim`, `get_husk_interrupt_desc`.
5. **Target mechanism.** Port as-is as a wrapper; no body re-application needed. It depends only on `self._ext_movement._anim_global` (`copmovement.lua:583-584`, `:606-615`) and `self._ext_movement._machine:set_global('shield', 0|1)`. Both still exist at 248.2.
6. **Decision.** **PORT** (P4, bundled with L-04 nav-link work). Cost is zero when `_anim_global` is never `'shield'` (the comparison is false and the body is a pass-through), so it is not worth a separate flag — but it must be installed *after* the vanilla body is captured, i.e. in the same file as the other `CopActionWalk` wrappers.
7. **Acceptance.** T3 (Hotline D1 / Biker D2, ladder-heavy). Log `evt=navlink k=shield_cleared=1` / `k=shield_restored=1` with `unit=<key>`; absence of both on a shield-unit level means the branch is dead there.
8. **Cost if wrong.** If `'shield'` is not the global name at 248.2, the block is dead code (no gameplay effect). If it *is* and the restore is skipped, shield cops keep the shield global off after the first climb — visual only, but they would stop blocking from the front, which is a real combat-difficulty change.
9. **Evidence gaps.** The string `'shield'` appears nowhere in 248.2 `copactionwalk.lua`; `anim_global_switch` is set from `switch_data` in `copinventory.lua:152-153`, and the shield weapon tweak that supplies it lives in tweak data, not in this decompiled repo. Cannot statically prove the global is still named `shield`.
