# Function dossier: lua/copactionwalk.lua :: CopActionWalk._upd_nav_link_first_frame

Category: **MOD_EDIT_CLEAN**

- ITER: 8 lines, params `(t)`
- 246.1: 9 lines, params `(t)`
- 248.2: 9 lines, params `(t)`

Normalized signature: `self` is omitted for methods; the body is the porting surface.

## ITER body (V8.57)

```lua
function CopActionWalk._upd_nav_link_first_frame(t)
if self._ext_movement._anim_global == 'shield' then
		self._ext_movement._machine:set_global('shield', 0)
		self.itr_shield_machine_switched = true
	end

	itr_original_copactionwalk_updnavlinkfirstframe(self, t)
end
```

## 246.1 vanilla (a3180fc)

```lua
function CopActionWalk._upd_nav_link_first_frame(t)
if self._next_is_nav_link.element:nav_link_wants_align_pos() and self:_stop_walk() then
		self:_set_updator("_upd_nav_link_blend_to_idle")

		return
	end

	self:_play_nav_link_anim(t)
end
```

## 248.2 vanilla (e3a8b616)

```lua
function CopActionWalk._upd_nav_link_first_frame(t)
if self._next_is_nav_link.element:nav_link_wants_align_pos() and self:_stop_walk() then
		self:_set_updator("_upd_nav_link_blend_to_idle")

		return
	end

	self:_play_nav_link_anim(t)
end
```

## Diff 246.1 -> ITER

```diff
--- 246.1 vanilla
+++ ITER
@@ -1,8 +1,7 @@
-if self._next_is_nav_link.element:nav_link_wants_align_pos() and self:_stop_walk() then
-		self:_set_updator("_upd_nav_link_blend_to_idle")
-
-		return
-	end
-
-	self:_play_nav_link_anim(t)
+if self._ext_movement._anim_global == 'shield' then
+		self._ext_movement._machine:set_global('shield', 0)
+		self.itr_shield_machine_switched = true
+	end
+
+	itr_original_copactionwalk_updnavlinkfirstframe(self, t)
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

1. **Wrapper or replacement.** Wrapper. `lua/copactionwalk.lua:416` captures `itr_original_copactionwalk_updnavlinkfirstframe`; `:417-424` clears the shield global when the unit mounts a nav link, then calls the original at `:423`.
2. **Call sites.** r200: installed as an updator on the walk action. 248.2: `copactionwalk.lua:1014` and `:1324` (`self:_set_updator("_upd_nav_link_first_frame")`); definition `:2365-2373`; also excluded by name in `_calculate_simplified_path` at `:2246`.
3. **Intent.** A shield cop cannot climb a ladder with the shield global active, so drop it for the duration of the nav-link first frame; `_chk_correct_pose` restores it afterwards.
4. **248.2 delta.** None. 248.2 `:2365-2373` (9 lines) is identical to 246.1 `:2343-2373`; no hunk touches it. The callee `_play_nav_link_anim` (`:2383`) also kept its `(t)` signature, so the wrapped call at `:423` is still correct.
5. **Target mechanism.** Port as-is as a wrapper. Fields: `self._ext_movement._anim_global`, `self.itr_shield_machine_switched` (consumed by `_chk_correct_pose`), `self._ext_movement._machine:set_global`.
6. **Decision.** **PORT** (P4). It is 8 lines, guarded, and is the producer for the flag `_chk_correct_pose` consumes — the pair must be ported or dropped together.
7. **Acceptance.** T3. Log `evt=navlink k=shield_cleared=1,global=<name>` once per unit per heist; if `global` is always non-shield the event never fires and the pair can be retired.
8. **Cost if wrong.** Same as `_chk_correct_pose`: dead code if the global name changed; if the clear fires but the restore does not (because `_chk_correct_pose` was not reached before the action ended), the shield stays visually down until the next pose correction. `on_exit` (`:894-936`) does not restore it, so a mid-climb interrupt can leave it off.
9. **Evidence gaps.** No static proof that any 248.2 unit has `_anim_global == 'shield'` (tweak data outside this repo). Also unverified: whether `_upd_nav_link_first_frame` is reached for shield units at all, since shield cops may use a different nav-link animation preset.
