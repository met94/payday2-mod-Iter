# P1 nav dossier annotations — summary

Scope: `## Port notes (P1)` appended to ten `NavigationManager.*` dossiers in
`dev/reports/dossiers/`. Generated body/diff sections untouched; no code,
ledger, or report edits outside this file.

Sources: overlay `lua/navigationmanager.lua` (r200 + N-01/N-02/S-01/S-02),
game 248.2 `e3a8b616`, old baseline 246.1 `a3180fc`.

| Function | Decision | Key evidence | Open question |
| --- | --- | --- | --- |
| `_execute_coarce_search` | REIMPLEMENT | game `:1231`, `:1502`; overlay `:1054`, gate `:1229`; `search_data` `:1479-1497` has no `from_pos` | Does the `tonumber(idseg)` path (`:1208`) break every 248.2 string id? |
| `itr_streamline` | PORT | callers `copbrain.lua:34`, `:116`, `coplogictravel.lua:256`; path shape game `:1268-1291` | Is `step2[3]` navlink marker still consumed by `coplogictravel.lua:170`? |
| `itr_find_proxies` | PORT | `:634`; pair index shim `:306-343`, `:387`; `evt=proxy` `:691` | Is shim first-owner `vis_group` equal to 246.1 `room_vis_groups`? |
| `itr_flood` | PORT | `:512`; shim door ids only | Does level-1 `#from_doors` overcount filtered nav-links? |
| `itr_find_choke_point` | PORT | `:591`; `_rooms` shim `:164-180` | Does sparse `room_level_counts` nullify `#` at `:427`? |
| `itr_get_closest_door_to_pos` | PORT (guards) | callers `:842`, `:939`, `:975`; Vector3 branch `:758-765` | Is `nav_link:key()` valid at 248.2? Any vanilla caller: none. |
| `itr_get_accessibility` | PORT (partial) | `:1122`, `:1151`; `coplogictravel.lua:177` | P4 fields absent → distance-only today; is that acceptable for T4? |
| `itr_find_best_navlink` | DEFER (P4/L-03) | `copactionwalk.lua:129`, gated `nav_ai` `:4-6` | Which L-03 counters prove a switch happened? |
| `itr_get_door_between` | PORT | `coplogictravel.lua:296`; S-01 `:814-838` | No follow-unit card (T5) exists yet. |
| `itr_get_coarse_pos_between` | PORT (after T1/T2) | `:1124`, `:1153`; proxies `:665-698` | Host-only proxy build (`:666`) — can a client reach this? |

## Concerns

1. **String ids are not preserved by the Iter search.** `path = tostring(...)`
   then `tonumber(idseg)` (`:1105`, `:1162`, `:1208`) produces numeric path
   steps; `_nav_segments` keys are strings (`game :312`), so `itr_streamline`
   `:950` and `coplogictravel` lookups nil-index. Fix before enabling
   `nav_search`.
2. **`nav_search` depends on `nav_streamline`.** `itr_enabled_neighbours_i`
   is only filled by `itr_prepare_nav_data` (`:673-675`), which is gated by
   `nav_streamline`; `nav_search` alone hits `#nil` at `:1143`.
3. **Missing diagnostics for acceptance.** Plan §7 requires `search` and
   `streamline` events; neither is emitted. T4 has no card. T1/T2 currently
   prove the geometry and probe paths only.
4. **Dossier drift.** Four bodies predate S-01/S-02 (`itr_find_proxies`,
   `itr_get_door_between`, `itr_get_closest_door_to_pos`,
   `itr_get_accessibility`); the notes cite current lines.
5. **Unverified engine surface.** `nav_link:key()` (no vanilla 248.2 caller),
   `create_nav_tracker` returning nil for mid-door centres, and client-side
   proxy availability are marked as evidence gaps, not facts.
