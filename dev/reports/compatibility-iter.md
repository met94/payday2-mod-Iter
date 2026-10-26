# Iter full-nav port — compatibility matrix

Scope: **full Iter** (`priority 40`, version 200.4) against the
installed/workspace mods. "Full Iter" means every subsystem is on:
streamline, Iter coarse search, nav-link queue, direct-to-pos, path extender
and map patches. Static analysis plus the live runs so far (LIES installed in
the game during T1-T4, The Fixes during T5). No runtime claims beyond the
tests listed.

Priorities below are the agreed ownership targets, not necessarily what is
installed right now.

## Function ownership

| Mod | Priority | Shared surface with Iter | Verdict |
|---|---:|---|---|
| LIES | 100 | Iter owns `NavigationManager._execute_coarce_search`, `CopLogicTravel:_check_start_path_ahead`, `CopLogicTravel:_chk_stop_for_follow_unit`. Iter wraps LIES's `register_anim_nav_link`, `set_nav_segment_state`, `add_obstacle`, `register_cover_units`, `NavigationManager._clear` and `NavigationManager.update`. | Tested together (T1-T4): no Iter errors, AI/search/streamline working. Iter loads later, so Iter's search replaces LIES's; LIES's cover generation/search still runs. Iter's `_chk_stop_for_follow_unit` body supersedes LIES's follow-unit stop/relocate logic — see "Option 1" below. |
| NavFixes | 0 | `find_segment_doors`, `_sort_nav_segs_after_pos`, `register_anim_nav_link`, `remove_obstacle` | **Do not run together.** NavFixes loads after Iter and replaces `register_anim_nav_link`; Iter's nav-link element map would stop receiving new links, breaking the queue subsystem. Iter does not override the other three functions. Needs an absorption pass or exclusion. |
| Keepers | 10 target (0 installed) | `CopLogicTravel.enter`, `_get_exact_move_pos` consumers, `CopLogicAttack`, `TeamAILogic*`, nav | Keepers writes `itr_direct_to_pos` for converted keepers; that field is live again with `direct_to_pos=true`. Converted-keeper direct-to-pos smoke still pending; no function collision found in the dossiers. |
| The Fixes | -10 (supermod) | `CopActionWalk._init` (bare replace) | The Fixes loads last and replaces `_init`. Iter detects it via `_G.TheFixes` and re-wraps whatever function won after all mods load (`LocalizationManagerPostInit`/`GameSetupUpdate`), so host-side one-point path expansion and the `_init` nav-link prepare still run. On clients Iter skips its own expansion because The Fixes already prepends the current position. Tested: T5 PASS with The Fixes and `path_extender=true`. |
| Monkeepers | 99 target (100 installed) | `CopLogicIdle`, `TeamAILogicIdle`, `CopLogicBase` | Pinned to 99 in the AI suite contract to match the LIES documentation; the current checkout still ships 100. Iter enables `cop_idle_fix` by default; it only changes an idle animation variant, so no function collision. |
| Useful Bots | 0 | bot path/AI hooks, `TeamAILogicTravel.update` | Useful Bots owns bot behaviour. Iter publishes the legacy `streamline_path` runtime mirror so UB 2.4.3's load-time guard fires and UB skips its own post-walk path re-check. UB remains untouched. |
| Anticrash, HopLib, HUD/menu mods | 0-500 | `menumanager`, tweak data | Disjoint (`Iter:*` helpers, `MenuCallbackHandler` settings). Live logs show no Iter errors. |

## Option 1: coexistence with LIES's nav-link waits

Iter's coarse search builds nodes as `{segment_id, position}` only
(`navigationmanager.lua:1407-1420`), and Iter's streamliner may attach a single
navlink element at `[3]` for the door transitions it streamlined
(`navigationmanager.lua:1125`). Iter never writes `[4]`, the multi-link slot.

Consequence for LIES's `_chk_start_pathing_to_next_nav_point`:

- the `[4]` multiple-valid-navlinks branch is dead on Iter paths, because no
  node has a fourth field — and it is dead without Iter too: LIES declares
  `has_multiple_navlink_elements` but never assigns it
  (`mods/LIES/lua/managers/navigationmanager.lua:2161`) and only reads
  `seg.multiple_nav_links` when building the path
  (`mods/LIES/lua/managers/navigationmanager.lua:2192`, `:2205`), so the value
  is always `nil`. Iter did not kill that branch;
- the `[3]` branch still sees the one navlink Iter's streamliner chose and
  honours that link's own `delay_time()`, but it only reads a delay — it never
  arbitrates between units.

Decision (Option 1): accept the coexistence instead of trying to keep LIES's
timing fields alive. Iter's reservation queue is the authority for nav-link
ordering and congestion; LIES's `[3]` read is a passive delay hint on the link
Iter already selected, so it does not fight the queue. Making it fully inert
would mean stripping `[3]`, which Iter's own streamline bookkeeping and
`itr_simplify_coarse_path` use.

What is **not** affected: LIES's squad push coordination
(`CopLogicTravel.chk_group_ready_to_move`, rewritten by LIES at
`lua/coplogics/coplogictravel.lua:494` on rank and nav-tracker distance, called
from `CopLogicTravel._chk_start_pathing_to_next_nav_point` in the game source).
Iter never overrides that function, so it still runs.

## `_chk_stop_for_follow_unit`: Iter supersedes LIES

Iter replaces the whole function (`lua/coplogictravel.lua:267-316`), not just a
nav-link wait. LIES's body
(`mods/LIES/lua/coplogics/coplogictravel.lua:1702-1764`) decides whether a
following unit should stop in place, set `objective.in_place`, publish a
`relocate_pos` or re-path toward the followed unit's nav segment, gated on
`TeamAILogicIdle._check_should_relocate` and area/segment distance checks.
Because Iter loads after LIES (40 vs 100 — lower priority loads later), Iter's
definition wins outright: the LIES stop/relocate policy no longer runs.

Iter's body keeps the two things that matter for the port: it snaps the coarse
path when the follower's target segment is the follower's own segment, and it
re-routes through `itr_get_door_between` when the followed unit changes segment
(`data.itr_follow_unit_nav_seg`). It does not call
`TeamAILogicIdle._check_should_relocate` and does not set
`objective.relocate_pos`, so the LIES-only "stop if a squadmate is in an
adjacent area" heuristic is gone. This is a behavioural difference, accepted
for the AI suite: Iter's body is the r200 follow handling and is what the port
restores, so no runtime evidence contradicts it. If the LIES stop heuristic is
wanted back, it has to be re-implemented on top of Iter's body.

## Hard conflicts / recommendations

1. **NavFixes + Iter:** recommend not installing together until Iter absorbs
   the nav-link guard. The missing piece is `register_anim_nav_link`; Iter's
   wrapper must remain outermost.
2. **The Fixes + Iter:** `CopActionWalk._init` is replaced. Iter re-wraps
   the winning function after all mods load, so host-side path expansion and
   nav-link prepare still run; client expansion is left to The Fixes to avoid
   duplicating the current position. Tested: T5 PASS with The Fixes and
   `path_extender=true`.
3. **LIES + Iter:** optional pair, not a dependency. Iter runs standalone on
   vanilla cover registration; LIES's own cover generation/search is separate.
   When both run, Iter owns the coarse search and LIES cover search still
   works. Keep both only if the T7 smoke stays clean.
4. **Keepers:** direct-to-pos is live again; run a converted-keeper smoke
   before release.
5. **Useful Bots:** keep UB untouched; the compatibility shim lives on the
   Iter side only (see Phase 1 below).

## Phase 1 (200.2)

- Iter publishes a legacy runtime key after `Iter:load()`:
  `Iter.settings.streamline_path = (Iter.settings.nav_overlay and Iter.settings.nav_streamline) or nil`
  (`lua/corecode.lua`).
- Why: Useful Bots 2.4.3 checks
  `if Iter and Iter.settings and Iter.settings.streamline_path then` /
  `return` at load time in its `lua/teamailogictravel.lua` (upstream copy:
  `D:\Programowanie\payday\2\old_mods\mods\New folder\pd2-useful-bots-master\lua\teamailogictravel.lua:47-48`,
  exact line 47 as quoted, `return` on 48). Iter's `load()` nils the legacy
  key, so without the mirror UB's guard is dead and UB installs a post-walk
  path re-check on top of Iter's streamliner. That upstream copy is not
  installed in the live game (the live `mods` folder has no Useful Bots), and
  the released 2.4.3 may differ — the guard line is the one quoted above.
- No navigation behaviour change: nothing in Iter reads the mirror. It reflects
  the *effective* state: with pathing off, the mirror is nil/false (falsy for
  UB/r200), so UB's own re-check is harmless.
- Save-file hygiene: `load()` nils the saved value (`lua/corecode.lua`, after
  the pre-port migration) and then rebuilds the mirror. `save()` recomputes the
  mirror from the live switches before writing and **persists** it
  (`true`/`false`, never nil once written), so a menu toggle cannot leave a
  stale in-memory mirror. The persisted value is the effective state: with
  `nav_overlay=false` the file carries `streamline_path=false`, and a downgrade
  to upstream r200 reads that instead of its own `true` default. Re-loading is
  safe because the pre-port migration only fires when `nav_overlay` is absent.
- Restart semantics: Useful Bots reads the key once, at its load. A menu toggle
  updates `iter.txt` and Iter's in-memory mirror immediately, but UB keeps the
  decision from launch until the next game restart.

## Phase 2: Santa's Workshop nav-link crash (200.3)

Found by the AI-suite Santa's Workshop (`cane`) card (`skip_nopatch`, heavy
assault, 276 nav-link elements) — release blocker, crash in the live game:

```
core/lib/utils/corecode.lua:100: attempt to call method 'alive' (a nil value)
itr_find_best_navlink()      lua/navigationmanager.lua:961
itr_get_alternate_navlink()  lua/copactionwalk.lua:179
itr_switch_to_sibling_navlink() lua/copactionwalk.lua:226
update()                     lib/units/enemies/cop/copmovement.lua:842
```

Cause: the game's `alive(obj)` calls `obj:alive()` unconditionally
(`core/lib/utils/corecode.lua:86-92`). Door and nav-link userdata is not a
unit, and Santa's Workshop's nav-link objects have no `alive()` method, so the
helper raised instead of returning false.

Fix: `itr_alive` (`lua/navigationmanager.lua`, next to `is_vec3`, so Vector3
userdata is still rejected) and `itr_alive_navpoint`
(`lua/copactionwalk.lua`). Both delegate to `alive()` only when the userdata
exposes the method and otherwise treat the object as existing. Five door
call sites in `navigationmanager.lua` and three nav-point/nav-link sites in
`copactionwalk.lua` were switched; unit checks (`alive(user)`,
`alive(element.itr_reserved_by_unit)`) keep using the game helper.

**Retest pending:** Santa's Workshop (`cane`) loud, 10+ minutes of heavy
assault, no crash and no `[ITER-ERR]` in `mods/logs/`. The other cards are
unaffected by this change; re-run them with the same build before release.

## Phase 3: dead nav-link reservation (200.4)

Found by the AI-suite Counterfeit (`pal`) card with harness v0.2 on build
200.3 — release blocker, no crash but a session-long stall that matches the
reported FPS drop:

```
[ITER-TEST] diag link action=e_nl_over_and_fwd_1m from=458 to=365 interval=1.00 queue=1 reserved=dead wait=363.7 pos=-3809,6945,16
[ITER-TEST] diag link action=e_nl_up_1_75m from=270 to=271 interval=2.00 queue=1 reserved=dead wait=15.0 pos=-4669,3327,-100
[ITER-TEST] diag link action=e_nl_jump_over_1m_var1 from=268 to=265 interval=1.00 queue=5 reserved=dead wait=12.2 pos=-4106,1600,50
```

71 `reserved=dead` samples, max wait **375.8 s**; the `e_nl_up_1_75m` sample at
`z=-100` is the basement stairs/lift, the `e_nl_jump_over_1m_var1` one at
`queue=5` is the stairs fence. Iter summary over the same run:
`navlink_reserve_busy=282373`, `navlink_switch_fail=282194`,
`navlink_reserve_ok=1283` — every waiting cop retried the same blocked link
every update.

Cause: a destroyed unit never runs `CopActionWalk:on_exit`, so
`itr_clear_navlink_reservation` is never called for it. Two fields outlive the
unit:

- `itr_reserved_by_unit` points at the dead unit, so the link is never free
  (`reserved=dead` in `diag link`);
- `itr_navlink_queue_previous_oldest_t` is stale, and `itr_reserve_navlink`'s
  r200 queue-order check (`if not oldest_t or wait_since_t <= oldest_t`) then
  rejects every later unit: the dead reservation made the link permanently
  unreservable instead of merely rate-limited.

Fix:

- `lua/copactionwalk.lua` `itr_reserve_navlink` — clear-then-reserve. The
  guard is `user and (not alive(user) or user:id() == -1)`; the reservation and
  `itr_navlink_queue_frame_t` / `_oldest_t` / `_previous_oldest_t` are dropped
  (`navlink_dead_reservation_cleared`), then the normal reserve path runs. The
  queue-order check stays: with the stale timestamps gone it either passes at
  once or defers to a live waiter that really is older, so T3 behaviour is
  preserved.
- `lua/navigationmanager.lua` `NavigationManager.update` posthook
  `Iter_navlink_dead_sweep` — once per second of sim time, walk the registered
  nav-link elements and clear dead reservations nobody walks up to again.
  Live reservations are never touched. Emits `[ITER-NAV] evt=navlink_dead
  action=… from=… to=… wait=…` per cleared link and
  `navlink_dead_reservation_cleared` for the summary; the sweep deadline
  resets in the `_clear` posthook so a level timer that restarts at 0 cannot
  starve it. 145 links max per pass, so the cost is negligible.
- `user` is always a unit here (set from `self._unit`), so both sites keep the
  game `alive()` helper; the door/nav-link `itr_alive` guard does not apply.

Static gates: `dev/tools/test/navlink-dead-reservation.test.mjs` (dead guard,
four cleared fields, clear-before-reserve order, sweep throttle, `navlink_dead`
fields, predicate truth table) plus the updated
`dev/tools/test/navlink-alive.test.mjs`.

**Retest pending:** Counterfeit (`pal`) loud, basement and stairs, 10+ minutes
of heavy assault: no `reserved=dead` in `diag link`, `evt=navlink_dead` present
when cops die holding a link, `navlink_reserve_busy` in the same order of
magnitude as `navlink_reserve_ok`, cops reaching the basement via
`e_nl_up_1_75m`, and FPS holding late in the heist. Known limitation: the
sweep clears the reservation and the queue timestamps but leaves
`itr_navlink_queue_length` / `_length_in_progress`, so `diag link` can still
print a stale `queue=N` line for a swept link until a live unit touches it;
that field only feeds sibling-link selection, not reservations.

## Load order

LIES (100) -> Monkeepers (99) -> Iter (40) -> Keepers (10) -> NavFixes/UB (0)
-> The Fixes (-10). Iter's wrappers are designed to capture the previous
definition, so they compose with LIES; bare replacements loaded after Iter win.
