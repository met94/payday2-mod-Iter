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
