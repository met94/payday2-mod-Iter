# Opaque-userdata shape assumptions in Iter's nav code (2026-11-05)

Design + proof note. **No Lua logic changed.** The five probes the handoff
listed are rejection guards over value domains that are pinned below; they are
kept, documented, allowlisted, and pinned by tests. The only runtime risk this
work removes is the LIES class (opaque userdata indexed as a table/Vector3)
arriving through a *new* probe added later, which the new static gate flags.

- **Target:** PAYDAY 2 248.2 (`e3a8b616`), SuperBLT
- **Iter:** `205.2` → `205.3` on `feat/opaque-userdata-shapes`
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

```
lua/copactionwalk.lua:19: type() used as a shape proof: if not obj or type(obj) ~= 'userdata' then
lua/coplogictravel.lua:221: type() used as a shape proof: if type(coarse_path[j][2]) ~= 'userdata' then
lua/navigationmanager.lua:179: type() used as a shape proof: if type(value) ~= 'userdata' then
lua/navigationmanager.lua:196: type() used as a shape proof: if type(obj) ~= 'userdata' or is_vec3(obj) then
lua/navigationmanager.lua:1668: type() used as a shape proof: if type(navlink) == 'userdata' and itr_alive(navlink) ...
```

Five sites, matching the handoff §2.1-§2.5, plus one site found during the
audit (§3.6).

## 3. Per-site verdict

| # | Site | Verdict | Why |
| --- | --- | --- | --- |
| 2.1 | `navigationmanager.lua:178-186` `is_vec3` | PROVEN | every argument source enumerated in §4; all are engine Vector3 or a value handled by an earlier branch |
| 2.2 | `navigationmanager.lua:191-206` `itr_alive` | PROVEN | callers §4.1; Vector3 rejected by `is_vec3`, nav links fall through |
| 2.3 | `copactionwalk.lua:18-29` `itr_alive_navpoint` | PROVEN | callers §4.2; same domain as 2.2 |
| 2.4 | `coplogictravel.lua:219-224` coarse-path slot 2 | PROVEN + rejection guard retained | slot 2 is Vector3 or nil at every writer (§4.3). The `type() ~= 'userdata'` test stays: it also rejects tables/numbers, which a nil check would not |
| 2.5 | `navigationmanager.lua:1668` nav-link filter | PROVEN + rejection guard retained | `door_list` entries are Vector3 / nav link / numeric patch id (§3.5); `itr_alive` already rejects non-userdata, the `type()` term stays as a second barrier |
| 2.6 | `copactionwalk.lua:130` `nav_point.x` | PROVEN (found by the audit) | vanilla does the identical read on the same path entries: game `copbrain.lua:594` (`if not nav_point.x and (not alive(nav_point) ...`) |

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

- game `on_simulation_ended` iterates every neighbour list and drops entries
  without `.x`: `lib/managers/navigationmanager.lua:1731-1737` (`:1734`);
- game `copbrain.lua:594` reads `nav_point.x` before calling `alive(nav_point)`
  on path entries;
- upstream Iter dispatches with `i_door.x`
  (`dev/reports/upstream-parity.md:31`).

An Idstring in one of these lists would crash vanilla `on_simulation_ended`
(and every `_upd_path` iteration) before Iter ever saw it. Numeric patch ids
are handled by the `type(i_door) == 'number'` branch that precedes every
`is_vec3` call on a door entry.

## 4. Argument audit for `is_vec3`

### 4.1 `is_vec3(obj)` from `itr_alive` (`:196`)

| Caller | `obj` source | Domain |
| --- | --- | --- |
| `:1234` `itr_add_door_pos_to` | keys of `door_flood_levels` | `itr_flood` only records `type(door_id) == 'number'` (`:1156-1161`), and its input `door_list` is built from numbers only (`:1278-1284`) or from `itr_shim_door_by_pair` (numeric ids, `iter_nav_v6_shim.lua:306-326`). The `itr_alive` branch is unreachable; number otherwise |
| `:1360` `important_doors` | `room_to_doors` ← `_room_doors` keys | numeric door ids from the shim (`iter_nav_v6_shim.lua:384-387`); unreachable branch |
| `:1573`, `:1855` `i_door` | `door_list` | §3.5; number handled by the preceding `type(i_door) == 'number'` branch |
| `:1668` `navlink` | `door_list` | §3.5; Vector3 rejected by `is_vec3`, nav link has `__index` |

### 4.2 `is_vec3` called from `itr_alive_navpoint` paths

`copactionwalk.lua` callers `:132` (`nav_point`), `:157`, `:180`
(`navlink`). `nav_point` is a path entry; vanilla reads `nav_point.x` on the
same list (game `copbrain.lua:594`). `navlink` comes from
`_next_is_nav_link` / the nav-link element table. No Idstring producer.

### 4.3 `is_vec3` called on positions

| Call site | Arguments | Writer |
| --- | --- | --- |
| `:1524` / `:1529` | `pos_to`, `pos_from` | callers `:1650` (`near_pos` of `itr_get_door_between`), `:1767` (`near_pos` of `itr_get_coarse_pos_between`), `:1825` (`proxy` = path slot 2 or proxy position) |
| `:1739` | `near_pos` | `itr_get_coarse_pos_between` callers `:2029`, `:2073` pass `from.pos`; `from.pos` is `search_data.from_pos` (game `CopBrain:search_for_path_from_pos`, set from `self._logic_data.m_pos`, game `copbrain.lua:519-521`) or `start_segment.pos` (converter Vector3) or a `through_pos` from this same function |
| `:1777` / `:1788` | `path[#path][2]`, `step1[2]` | `itr_streamline` callers: `copbrain.lua:34`, `:127` (path slot 2 rewritten from `objective.follow_unit:position()`, Vector3, guarded by `alive`), `coplogictravel.lua:259` (coarse path, §4.4), `navigationmanager.lua:1953`, `:2160` (engine coarse search results) |

`itr_get_door_between(..., follow_unit:position())`
(`coplogictravel.lua:300`) and `to_pos` sources (`objective.pos`,
`nav_tracker:field_position()`, cover positions,
`find_random_position_in_segment`) are engine positions by API contract. No
external caller of `itr_streamline` exists in the workspace mods; the legacy
`streamline_path` key is a settings mirror, not a callable alias
(`lua/corecode.lua:108-115`).

### 4.4 Coarse-path slot 2 (`coplogictravel.lua:219-224`)

| Writer | Value |
| --- | --- |
| game `_begin_coarse_pathing` precise path | `mvector3.copy(end_pos)` (`coplogictravel.lua:91-101`) |
| game coarse path from `path_data` | `mvector3.copy(point.position)` (`:114-122`) |
| game `complete_coarse_path` | `mvector3.copy(all_nav_segs[first_seg_id].pos)` when slot 2 is missing (`:1088-1096`) |
| engine `search_coarse` result | Vector3 entries (`:128-129`) |
| Iter `deep_clone` | returns userdata unchanged (`core/lib/utils/coretable.lua:17-20`) |

`type(coarse_path[j][2]) ~= 'userdata'` therefore rejects `nil` and non-Vector3
junk; it is not a proof that userdata is a Vector3 (an Idstring would pass),
which is why the domain table above is the actual proof.

## 5. Tests

- `dev/tools/test/userdata-shape.test.mjs` — static gate: rules 1-2, allowlist
  scoped to the enclosing function, stale-entry assertion, plus an assertion
  that the five guards keep their rejection shape. Baseline output in §2.
- `dev/tests/lua/test_userdata_shape.lua` — slices `is_vec3`, `itr_alive`,
  `itr_alive_navpoint` from the shipped files and pins the truth table with
  `newproxy` stand-ins (Vector3-like, nav-link-like, nil, number, table).
- `dev/tests/lua/test_coarse_path_slots.lua` — slices
  `check_turn_back_on_axis`/`get_turn_back_index`; pins nil/table/number
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
  load; a parallel map would create a second source of truth — see
  `dev/reports/upstream-parity.md` §2.2); `pcall` probes (not needed: no site
  lacked a proof); the handoff's nil-check shortcut for 2.4 (would widen
  acceptance to truthy non-Vector3 values).
- **Artifacts:** branch `feat/opaque-userdata-shapes`, worktree
  `.worktrees/Iter-opaque-userdata-shapes`; gate
  `dev/tools/test/userdata-shape.test.mjs`; tests
  `dev/tests/lua/test_userdata_shape.lua`,
  `dev/tests/lua/test_coarse_path_slots.lua`; this report.
- **Deploy/test split:** the branch was built and deployed for the user's
  in-game test; release (merge + changelog) follows the user's approval.
