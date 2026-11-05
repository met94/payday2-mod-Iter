# Opaque-userdata shape assumptions in Iter's nav code (2026-11-05)

Design + proof note. **No Lua logic changed.** The five probes the handoff
listed are rejection guards over value domains that are pinned below; they are
kept, documented, allowlisted, and pinned by tests. The only runtime risk this
work removes is the LIES class (opaque userdata indexed as a table/Vector3)
arriving through a *new* probe added later, which the new static gate flags.

- **Target:** PAYDAY 2 248.2 (`e3a8b616`), SuperBLT
- **Iter:** `205.2` on `feat/opaque-userdata-shapes`. The release version bump
  and `changelog.txt` entry land after the user's in-game test (205.3 never
  shipped without it; user asked for test-before-release on 2026-11-05).
- **Handoff:** `docs/investigations/iter-opaque-userdata-handoff.md`
- **Origin:** LIES 2026-11-05 taser crash
  (`mods/LIES/dev/reports/watch-settle-attention-unit-type-crash.md`)
- **Gate:** `dev/tools/test/userdata-shape.test.mjs`

## 1. The mistake class

An Idstring (`unit:key()`, `attention_obj.u_key`, nav-link ids) is userdata
with no `__index`. `type()` answers `"userdata"` for it exactly as for a
Vector3, but `value.field` raises `attempt to index ... (a userdata value)`.
`type(x) == 'userdata'` proves none of Vector3 / table / unit / Idstring /
nav link.

## 2. Baseline (gate with an empty allowlist)

The gate parses the Lua AST (luaparse), so wrapped expressions are found too:

```
lua/copactionwalk.lua:24: type() used as a shape proof in itr_alive_navpoint (~=)
lua/coplogictravel.lua:225: type() used as a shape proof in get_turn_back_index (~=)
lua/navigationmanager.lua:191: type() used as a shape proof in is_vec3 (~=)
lua/navigationmanager.lua:211: type() used as a shape proof in itr_alive (~=)
lua/navigationmanager.lua:1683: type() used as a shape proof in NavigationManager.itr_find_best_navlink (==)
```

Five sites, matching the handoff §2.1-§2.5. The audit also covered
`copactionwalk.lua:137` (`nav_point.x`, site 2.6), a field read rather than a
`type()` comparison, so the gate does not list it.

## 3. Per-site verdict

| # | Site (tip) | Verdict | Why |
| --- | --- | --- | --- |
| 2.1 | `navigationmanager.lua:190` `is_vec3` | PROVEN | every argument source enumerated in §4; all are engine Vector3 or a value handled by an earlier branch |
| 2.2 | `navigationmanager.lua:206` `itr_alive` | PROVEN | callers §4.1; Vector3 rejected by `is_vec3`, nav links fall through |
| 2.3 | `copactionwalk.lua:23` `itr_alive_navpoint` | PROVEN | callers §4.2; same domain as 2.2 |
| 2.4 | `coplogictravel.lua:219-231` coarse-path slot 2 (type test at `:225`) | PROVEN + rejection guard retained | slot 2 is Vector3 or nil at every writer (§4.4). The `type() ~= 'userdata'` test stays: it also rejects tables/numbers, which a nil check would not |
| 2.5 | `navigationmanager.lua:1683` nav-link filter | PROVEN + rejection guard retained | `door_list` entries are Vector3 / nav link / numeric patch id (§3.5). `itr_alive` already implies userdata, so the `type()` term is redundant; it is kept as a cheap filter and its exact expression is pinned by the gate's shape assertion |
| 2.6 | `copactionwalk.lua:137` `nav_point.x` | PROVEN (found by the audit) | vanilla reads the same field on every path entry: game `CopLogicIdle._nav_point_pos` (`lib/units/enemies/cop/logics/coplogicidle.lua:1027-1029`, unconditional) |

No site needed the GUARDED variant. `is_vec3` keeps R12's numeric x/y/z rule
(`dev/reports/decisions.md`).

## 3.5 Value domain of `nav_seg.neighbours[seg]` lists

Writers:

| Writer | Inserts | Evidence |
| --- | --- | --- |
| game `_resolve_segment_neighbours` | `mvec3_copy(door_pos)` → Vector3 | `lib/managers/navigationmanager.lua:326-350` (`:335`, `:345`) |
| game `register_anim_nav_link` | nav-link userdata | `lib/managers/navigationmanager.lua:891-935` (`:929`) |
| game `clbk_navfield` (enable neighbours) | re-inserts entries that pass `.x` | `lib/managers/navigationmanager.lua:2069-2088` (`:2084`) |
| Iter map patches | numeric door ids | `lua/_navdatapatches.lua:517-577` (`{201}`, `{did}`) |

Readers that already assume the domain:

- game `_sort_nav_segs_after_pos` calls `door:is_obstructed()` /
  `door:check_access()` on every entry while answering a search
  (`lib/managers/navigationmanager.lua:1362-1368`);
- game `find_segment_doors` reads `door.x` on every entry per call
  (`:1211-1213`);
- game `on_simulation_ended` drops entries without `.x`
  (`:1731-1737`) - end-of-simulation backstop, not the per-search barrier;
- game `CopLogicIdle._nav_point_pos` reads `nav_point.x` unconditionally on
  path entries (`lib/units/enemies/cop/logics/coplogicidle.lua:1027-1029`);
- upstream Iter dispatches with `i_door.x`
  (`dev/reports/upstream-parity.md:31`).

An Idstring in one of these lists would break vanilla `find_segment_doors` or
`_sort_nav_segs_after_pos` before Iter ever saw it. Numeric patch ids are
handled by the `type(i_door) == 'number'` branch that precedes every `is_vec3`
call on a door entry.

## 4. Argument audit for `is_vec3`

### 4.1 `is_vec3(obj)` from `itr_alive` (`:211`)

| Caller (tip) | `obj` source | Domain |
| --- | --- | --- |
| `:1249` `itr_add_door_pos_to` | keys of `door_flood_levels` | `itr_flood` only records `type(door_id) == 'number'` (`:1172`), and its input `door_list` is built from numbers only (`:1293-1297`) or from `itr_shim_door_by_pair` (numeric ids, `iter_nav_v6_shim.lua:306-326`). The `itr_alive` branch is unreachable; number otherwise |
| `:1375` `important_doors` | `room_to_doors` ← `_room_doors` keys | numeric door ids from the shim (`iter_nav_v6_shim.lua:384-387`); unreachable branch |
| `:1588`, `:1870` `i_door` | `door_list` | §3.5; number handled by the preceding `type(i_door) == 'number'` branch |
| `:1683` `navlink` | `door_list` | §3.5; Vector3 rejected by `is_vec3`, nav link has `__index` |

`is_vec3(i_door)` in `itr_get_door_in_alignment` (`:1735`, fed by
`itr_streamline` at `:1840`) reads the same `door_list` and is covered by the
same row.

### 4.2 `is_vec3` called on nav points (`copactionwalk.lua`)

`itr_alive_navpoint` callers `:139` (`nav_point`), `:164`, `:187` (`navlink`).
`nav_point` is a path entry; vanilla reads `nav_point.x` on the same list (game
`coplogicidle.lua:1027-1029`). `navlink` comes from `_next_is_nav_link` / the
nav-link element table. No Idstring producer.

### 4.3 `is_vec3` called on positions

| Call site (tip) | Arguments | Writer |
| --- | --- | --- |
| `:1539` / `:1544` | `pos_to`, `pos_from` | callers `:1665` (`near_pos` of `itr_get_door_between`), `:1782` (`near_pos` of `itr_get_coarse_pos_between`), `:1840` (`proxy` = path slot 2 or proxy position) |
| `:1754` | `near_pos` | `itr_get_coarse_pos_between` callers `:2044`, `:2088` pass `from.pos`; `from.pos` is `search_data.from_pos` (game `CopBrain:search_for_path_from_pos`, set from `self._logic_data.m_pos`, game `copbrain.lua:519-521`) or `start_segment.pos` (converter Vector3) or a `through_pos` from this same function |
| `:1792` / `:1803` | `path[#path][2]`, `step1[2]` | `itr_streamline` callers: `copbrain.lua:34`, `:127` (path slot 2 rewritten from `objective.follow_unit:position()`, Vector3, guarded by `alive`), `coplogictravel.lua:259` (coarse path, §4.4), `navigationmanager.lua:1967`, `:2174` (engine coarse search results) |

`itr_get_door_between(..., follow_unit:position())`
(`coplogictravel.lua:304`) and `to_pos` sources (`objective.pos`,
`nav_tracker:field_position()`, cover positions,
`find_random_position_in_segment`) are engine positions by API contract. No
external caller of `itr_streamline` exists in the workspace mods; the legacy
`streamline_path` key is a settings mirror, not a callable alias
(`lua/corecode.lua:108-115`).

### 4.4 Coarse-path slot 2 (`coplogictravel.lua:219-231`)

| Writer | Value |
| --- | --- |
| game `_begin_coarse_pathing` precise path | `mvector3.copy(end_pos)` (`coplogictravel.lua:91-101`) |
| game coarse path from `path_data` | `mvector3.copy(point.position)` (`:114-122`) |
| game `coarse_complete` branch | `deep_clone(objective.path_data)` (`:126-129`); `deep_clone` returns userdata unchanged (`core/lib/utils/coretable.lua:17-20`) |
| game `complete_coarse_path` | `mvector3.copy(all_nav_segs[first_seg_id].pos)` when slot 2 is missing (`:1088-1096`) |
| engine coarse search | `{seg_id, pos}` entries built from `to_pos` / `seg.pos` in game `_execute_coarce_search` (`lib/managers/navigationmanager.lua:1268-1291`, reached from `search_coarse` at `:1410`) |

`type(coarse_path[j][2]) ~= 'userdata'` therefore rejects `nil` and non-Vector3
junk; it is not a proof that userdata is a Vector3 (an Idstring would pass),
which is why the domain table above is the actual proof.

## 5. Tests

- `dev/tools/test/userdata-shape.test.mjs` - static gate over the Lua AST
  (luaparse): rules 1-2, allowlist scoped by file + enclosing function +
  comparison direction (`~=` guards, one `==` filter), stale-entry assertion,
  plus a source assertion that all five guards keep their rejection shape.
  Two self-tests cover three cases: `.type_name` and `["type_name"]` are both
  flagged, a wrapped/multi-line `type(...) == 'userdata'` is flagged, and a
  probe inside an anonymous function cannot inherit an allowlisted name.
  Each allowlist entry must match exactly one probe, so a copy inside the same
  guard also fails. Baseline output in §2.
- `dev/tests/lua/test_userdata_shape.lua` - slices `is_vec3`, `itr_alive`,
  `itr_alive_navpoint` and `itr_find_best_navlink` from the shipped files and
  pins the truth table with `newproxy(true)` stand-ins (Vector3-like,
  nav-link-like, nil, number, table). The nav-link filter case feeds a list
  holding a Vector3, a table and a link, and asserts only the link is chosen.
  `newproxy(false)` (opaque Idstring stand-in) is deliberately not fed: these
  guards index userdata, and the domain proof - not a pcall guard - is the fix.
- `dev/tests/lua/test_coarse_path_slots.lua` - slices
  `check_turn_back_on_axis`/`get_turn_back_index`; pins nil/table/number/string
  rejection and the Vector3-like path.

Both Lua tests run in `dev/tools/gates.ps1` (`dev/tests/lua/test_*.lua`) and are
part of the branch's gates.

## 6. Player POV

No gameplay change. Same route choice, same nav-link queueing, same door
picking as 205.2. The work removes the risk that a future nav probe crashes
the game when it meets an engine key instead of a vector, and it documents why
the current probes are safe.

## 7. Unknowns / in-game test

Static evidence only; engine userdata shapes only exist in-game. Test card:
play a loud heist with heavy nav-link traffic for 10+ minutes, then scan
`mods/logs/*.txt` for `FATAL ERROR` / `attempt to index ... (a userdata value)`
and check `crash.txt`. The branch changes no runtime logic, so the expected
result is indistinguishable from 205.2.

## 8. Commands

```powershell
tools\luajit\luajit.exe dev\tests\lua\test_userdata_shape.lua
tools\luajit\luajit.exe dev\tests\lua\test_coarse_path_slots.lua
node --test dev\tools\test\userdata-shape.test.mjs
dev\tools\gates.ps1
```

## 9. Decision & artifacts

- **Decision:** keep all five probes; no Lua logic change. PROVEN for the
  Idstring class (domain pinned by game writers and by vanilla readers that
  already index the same values), and retain the cheap rejection guards so
  tables/numbers stay rejected exactly as in 205.2.
- **Rejected:** structural kind-tagging of `door_list` (game-owned, rebuilt at
  load; a parallel map would create a second source of truth - see
  `dev/reports/upstream-parity.md` §2.2); `pcall` probes (not needed: no site
  lacked a proof); the handoff's nil-check shortcut for 2.4 (would widen
  acceptance to truthy non-Vector3 values).
- **Artifacts:** branch `feat/opaque-userdata-shapes`, worktree
  `.worktrees/Iter-opaque-userdata-shapes`; gate
  `dev/tools/test/userdata-shape.test.mjs`; tests
  `dev/tests/lua/test_userdata_shape.lua`,
  `dev/tests/lua/test_coarse_path_slots.lua`; this report.
- **Deploy/test split:** the branch is built and deployed for the user's
  in-game test; release (version bump, changelog, merge) follows the user's
  approval. The user deploys; the agent copies the build only on request.
