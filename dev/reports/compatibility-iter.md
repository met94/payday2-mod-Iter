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
| The Fixes | -10 (supermod) | `CopActionWalk._init` (bare replace) | The Fixes loads last and replaces `_init`; Iter's path expansion and the `_init` nav-link prepare are lost. The prepare also runs from `_advance_simplified_path`, so queue tracking survives; path expansion does not. **Dormant by default:** path extender is OFF in RC defaults. Document or re-hook. |
| Monkeepers | 100 | `CopLogicIdle`, `TeamAILogicIdle`, `CopLogicBase` | LIES docs already pin Monkeepers to 99 for LIES. Iter only uses `cop_idle_fix` (off); no extra action. |
| Useful Bots | 0 | bot path/AI hooks | Not tested. Iter's `nav_ai` and UB both touch travel/idle; UB should own bot behaviour. |
| Anticrash, HopLib, HUD/menu mods | 0-500 | `menumanager`, tweak data | Disjoint (`Iter:*` helpers, `MenuCallbackHandler` settings). Live logs show no Iter errors. |

## Hard conflicts / recommendations

1. **NavFixes + Iter:** recommend not installing together until Iter absorbs
   the nav-link guard. The missing piece is `register_anim_nav_link`; Iter's
   wrapper must remain outermost.
2. **The Fixes + Iter:** `CopActionWalk._init` is replaced. Path extender
   expansion is lost; nav-link queue still works. Path extender is OFF by
   default, so the conflict stays dormant until T5 enables it. Accept or
   re-apply Iter's `_init` from a later hook.
3. **LIES + Iter:** tested. Iter owns the coarse search; LIES cover search
   still works. Keep both only if the T7 smoke stays clean.
4. **Keepers:** direct-to-pos is live again; run a converted-keeper smoke
   before release.

## Load order

LIES (100) -> Iter (40) -> NavFixes/Keepers/UB (0) -> The Fixes (-10).
Iter's wrappers are designed to capture the previous definition, so they
compose with LIES; bare replacements loaded after Iter win.
