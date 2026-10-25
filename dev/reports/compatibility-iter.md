# Iter full-nav port — compatibility matrix

Scope: Iter (`priority 40`) against the installed/workspace mods. Static
analysis plus the live runs so far (LIES installed in the game during T1-T4).
No new runtime claims beyond the tests listed.

## Function ownership

| Mod | Priority | Shared surface with Iter | Verdict |
|---|---:|---|---|
| LIES | 100 | `_execute_coarce_search`, `register_anim_nav_link`, `register_cover_units`, `set_nav_segment_state` | Tested together (T1-T4): no Iter errors, AI/search/streamline working. Iter loads later, so Iter owns the coarse search; LIES's cover search still runs. LIES's extra path metadata is unused by vanilla, so the override is tolerable. |
| NavFixes | 0 | `find_segment_doors`, `_sort_nav_segs_after_pos`, `register_anim_nav_link`, `remove_obstacle` | **Do not run together.** NavFixes loads after Iter and replaces `register_anim_nav_link`; Iter's nav-link element map would stop receiving new links, breaking the queue subsystem. Iter does not override the other three functions. Needs an absorption pass or exclusion. |
| Keepers | 0 | `CopLogicTravel.enter`, `_get_exact_move_pos` consumers, `CopLogicAttack`, `TeamAILogic*`, nav | Keepers writes `itr_direct_to_pos` for converted keepers; that field is live again with `direct_to_pos=true`. Needs a T7 smoke; no function collision found in the dossiers. |
| The Fixes | -10 (supermod) | `CopActionWalk._init` (bare replace) | The Fixes loads last and replaces `_init`. Iter re-wraps whatever function won after all mods load (`LocalizationManagerPostInit`/`GameSetupUpdate`), so host-side one-point path expansion and the `_init` nav-link prepare still run. On clients Iter skips its own expansion because The Fixes already prepends the current position. Tested: T5 PASS with The Fixes and `path_extender=true`. |
| Monkeepers | 100 | `CopLogicIdle`, `TeamAILogicIdle`, `CopLogicBase` | LIES docs already pin Monkeepers to 99 for LIES. Iter now enables `cop_idle_fix` by default; it only changes an idle animation variant, no function collision. |
| Useful Bots | 0 | bot path/AI hooks | Not tested. Iter's `nav_ai` and UB both touch travel/idle; UB should own bot behaviour. |
| Anticrash, HopLib, HUD/menu mods | 0-500 | `menumanager`, tweak data | Disjoint (`Iter:*` helpers, `MenuCallbackHandler` settings). Live logs show no Iter errors. |

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

## Load order

LIES (100) -> Iter (40) -> NavFixes/Keepers/UB (0) -> The Fixes (-10).
Iter's wrappers are designed to capture the previous definition, so they
compose with LIES; bare replacements loaded after Iter win.
