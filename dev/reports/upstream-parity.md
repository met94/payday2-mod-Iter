# Upstream parity ledger

Every upstream Iter revision is evaluated against this fork. This file records
what was **adopted**, what was **not**, and **why** — so the next upstream
update is a diff against a known state instead of a re-litigation.

- **Current base:** upstream Iter **r205** (TdlQ, "code maintenance by BangL"),
  adopted in fork release `205.1`.
- **Nav core:** this fork's own v6 port of r200 (`98940fb`, pristine import).
  The base moved for versioning and for the adopted fixes; the core was not
  rebased and must not be "rebased" without a deliberate A/B project (see
  §2.1).
- **Upstream source of truth:** `http://pd2mods.z77.fr/update/Iter.zip`; the
  package's `mod.txt` `version` is the revision. The site is static — there is
  no upstream git repo, so every revision is compared as an archive.
- **Workspace assessment of the r200 → r205 step** (full evidence, commands):
  `docs/investigations/iter-upstream-r205-assessment.md` in the workspace repo.

## 1. Name map: upstream function ↔ this fork

The two trees solve the same problems with different shapes. Before comparing a
future upstream hunk, find the counterpart here:

| upstream (r205) | this fork | note |
|---|---|---|
| `NavigationManager:send_nav_field_to_engine` override | `Hooks:PostHook(NavigationManager, '_send_nav_field_to_engine', 'Iter_nav_shim_rebuild')` + `lua/iter_nav_v6_shim.lua` | upstream runs before the vanilla call and restores `navseg.neighbours` afterwards; ours runs after and keeps a persistent door index |
| `itr_load_room_data` / `itr_unload_room_data` | `IterNavShim.rebuild` / `IterNavShim.clear` | same rebuild of `_rooms` / `_room_doors` / `_visibility_groups` from `quad_*` + `visibility_groups` |
| `itr_match_door_data` (engine door position → door data) | `itr_shim_door_by_pair` (segment pair → door ids) + the `is_vec3` branch of `itr_get_closest_door_to_pos` | upstream needs a position→door map because its flood receives engine positions; ours never does |
| `NavigationManager:_resolve_segment_neighbours` override | `Hooks:PostHook(..., '_resolve_segment_neighbours', 'Iter_nav_prepare')` → `itr_prepare_nav_data` | proxies/choke points, neighbour lists, door copy |
| `NavigationManager:_execute_coarce_search` override | `NavigationManager:itr_execute_coarce_search`, assigned to `_execute_coarce_search` when `Iter.settings.nav_search` | same algorithm lineage; ours has the FIFO frontier and the diag counters |
| `itr_get_closest_door_to_pos`, `itr_find_best_navlink`, `itr_get_accessibility`, `itr_flood`, `itr_find_proxies`, `itr_streamline` | same names | ours dispatch on `type(i_door) == 'number'` / `is_vec3`, upstream on `i_door.x` |
| `CopActionWalk`, `CopBrain`, `CopLogicTravel` hooks | same names | plus this fork's reservation sweep / queue-cache expiry / follow-unit guard |
| `CivilianLogicTravel._optimize_path` override | **dropped** (`lua/civilianlogictravel.lua` is `return`-only) | see §2.4 |
| `TeamAIBrain` / `CivilianBrain` overrides | **dropped** (`return`-only, not in `mod.txt`) | see §2.5 |
| `MissionScript:load` full replacement | wrapper that filters ids without `load` and then delegates to 248.2 vanilla | see §2.3 |

## 2. Not adopted from r200 → r205 (and why)

### 2.1 Full rebase onto the r205 tree

**Verdict: rejected.** r205's whole delta over r200 is 9 files / +285 / −82; our
port is +2508 / −569 and carries the diagnostics that produced the 200.x fixes
(watch channel, diag events, P7 map-patch audits, gates, offline tests) plus
~10 fixes r205 does not have: dead/stale nav-link reservation sweep, queue-cache
expiry on a free link, follow-unit `alive()` guard, FIFO coarse frontier,
`streamline_path` alias for Useful Bots.

Both trees rebuild the v5 geometry from the v6 load data and run the r200
algorithms on top, so a rebase would swap a tested implementation for an
untested-here one and re-open every T1–T5 card plus the LIES/Keepers/Monkeepers/
The Fixes matrix — for a delta that ports in eleven small patches.

**Revisit when:** upstream lands something structural (not a fix), or the shim
starts failing on new nav data. Then run it as an explicit A/B on the same
cards, not as a "merge".

### 2.2 `itr_load_room_data` / `itr_unload_room_data` neighbour swap, `itr_match_door_data`

**Verdict: not ported — equivalent exists.** Our shim builds the same three
tables and keeps `itr_shim_door_by_pair` (segment pair → door ids) permanently,
which the flood, `itr_get_door_between` and `itr_get_closest_door_to_pos`
consume. Upstream instead swaps `navseg.neighbours` to door-id lists for the
duration of the streamline preparation and matches engine door positions back by
grid key, because its flood expects door ids. Ours never hands engine positions
to the flood, so the swap and the position matching are unnecessary.

**Do not port the swap** without deleting `door_by_pair` in the same change —
running both would mean two sources of truth for door topology.

### 2.3 `coremissionmanager` `element.load` guard (r203)

**Verdict: not applicable.** Our `MissionScript:load` filters state ids whose
element has no `load` function and then calls the original. 248.2 vanilla
already guards the `ElementInstancePoint` loop
(`core/lib/managers/mission/coremissionmanager.lua`, `if self._elements[id].load then`).
Upstream needs its own guard because it *replaces* the body (r200 lineage).

### 2.4 `CivilianLogicTravel._optimize_path` wrapper (r205)

**Verdict: not applicable.** Nothing in this tree calls it: the team-AI caller
was dropped with `TeamAIBrain` (see §2.5), and `dev/reports/drop-log.md` records
the r200 body as predating the U242 statics/raycast improvements. 248.2's own
`_optimize_path` is the newer one and is what civilians already run. Upstream's
wrapper delegates to the same vanilla body unless `allow_out_of_graph` is set —
a parameter only Iter's own dropped callers pass.

**Revisit when:** we restore team-AI path optimization. Then port the wrapper
*and* the caller together.

### 2.5 `TeamAIBrain` / `CivilianBrain` bodies

**Verdict: not applicable.** Their hook target `clbk_pathing_results` does not
exist at 248.2 (checked in `lib/units/player_team/teamaibrain.lua` and
`lib/units/civilians/civilianbrain.lua`); nothing calls it. The files stay
`return`-only stubs and are absent from `mod.txt` hooks. Upstream still ships
the r200 bodies, which are dead code there too.

### 2.6 `data.nav_segments[...].neighbours` writes inside map blocks

**Verdict: not ported.** The v5→v6 converter always builds v6 segments with an
empty `neighbours` table, so those writes are discarded at 248.2. r205 keeps
them (it also targets older games); our P7 audit removed them from the cleaned
blocks and pins the invariant in `dev/tools/test/p7-dead-writes.test.mjs`.
`moon` and `peta` keep theirs as documented accepted losses.

### 2.7 `mod.txt` `simple_update_url` and the upstream update endpoint

**Verdict: not ported.** The fork points SuperBLT at
`releases/latest/download/meta.json` in the fork repo. Referencing upstream's
endpoint would let it overwrite the fork with an r2xx package (README,
"Auto-updates and versioning").

### 2.8 Items already present (listed so a future diff does not look new)

| upstream item | where it already lives here |
|---|---|
| nil guard in `itr_make_neighbours_list` | `lua/navigationmanager.lua` `itr_make_neighbours_list` (also guards a missing segment) |
| nil guards in `clbk_navfield` | `lua/navigationmanager.lua` `clbk_navfield` |
| string segment ids in the coarse search result | `lua/navigationmanager.lua` `itr_execute_coarce_search` (`'[^;]+'` parse) |
| FIFO frontier instead of `table_remove(list, 1)` | same function (ours is ahead of r205 here) |
| `local processed_path`, `local pos` in `CopActionWalk` | `lua/copactionwalk.lua` |
| `e_so_ntl_idle_look3` workaround | `lua/coplogicidle.lua` |
| `GroupAIStateBase:on_nav_seg_neighbour_state` refresh | `lua/groupaistatebase.lua` |

### 2.9 Deviations inside adopted items (deliberate, from code review)

These are places where we adopted an upstream item but did **not** copy its code
verbatim. Each one is pinned by a test, so a future merge cannot silently
"restore" the upstream shape:

| item | upstream | ours | why |
|---|---|---|---|
| A2 `append_vis_group` | also self-references the new group (`vg.vis_groups[i_vg]`) | no self-reference | the game's own builder never lists a group in its own list (`lib/managers/navfieldbuilder.lua:283, 442, 3293`) |
| A4 cache hit | always answers from the cache | falls through to a real search (`search_cache_unusable`) when `to_pos` and the end segment are both unavailable | answering with the cached endpoint would keep the stale destination this fix removes |
| A5 `set_nav_segment_state` | one loop | one loop (no redundant pre-call) | the loop already covers `navseg_id == unique_id`; the pre-call rebuilt the list twice |
| A6 `itr_find_best_navlink` | indexes `self._nav_segments[segment1_id]` directly | guards a missing segment | a link whose `start_nav_segment()` could not be read leaves `itr_from_navseg` nil; upstream would index nil |
| A6 `itr_get_wait_pos` | — | returns the wall fallback when `navseg_id` is nil | `{[nil] = true}` raises "table index is nil" inside the cop action update |
| A7 dead nav link | plays the animation | same, plus the `navlink_play_dead` counter | vanilla `_upd_nav_link` reads `_nav_link.c_class` in the branch taken only when the animation never started; the counter is the signal to check it in a log |

**A7 residual risk (known, accepted):** playing the animation with a destroyed
nav-link `c_class` keeps the cop moving (the animation only needs the mission
element), but if the animation fails to start, vanilla's `_upd_nav_link` calls
`c_class:end_position()` / `c_class:set_delay_time(0)` unguarded
(`lib/units/enemies/cop/actions/lower_body/copactionwalk.lua:2498, 2508, 2555`).
The alternative — dropping the link and letting the path continue — trades a
certain stall for a cop walking into geometry it cannot traverse, so upstream's
behaviour was kept. In-game check: a level where a nav link's blocker is removed
mid-heist (Counterfeit `pal` is the recorded case) with `navlink_play_dead` in
the digest and no Lua error in the log.


## 3. Adopted in 205.1 (for reference)

Eleven items, all from r201-r205, each pinned by a test:

| item | upstream | test |
|---|---|---|
| four map patches resynced (signatures + ids) | r204 | `dev/tools/test/upstream-r205-mapdata.test.mjs` |
| `append_vis_group` uses the group index, not the segment id | r204 | same |
| `ElementAINavSeg` string keys | r201 | `dev/tests/lua/test_missionmanager_navseg.lua` |
| coarse cache keeps the current destination; streamline gets `access_pos` | r205 | `dev/tools/test/upstream-r205-navcore.test.mjs` |
| `set_nav_segment_state` refreshes every referencing segment | r205 | same |
| `register_anim_nav_link` uses `start/end_nav_segment()` | r205 | same |
| dead nav link no longer stalls the cop | r201/r202 | same |
| wait-start stamp cleared when the animation plays | r205 | same |
| `CopBrain:search_for_coarse_path` id check | r205 | `dev/tests/lua/test_copbrain_search_start.lua` |
| nav-link accounting clock fallback | r205 | `dev/tools/test/upstream-r205-navcore.test.mjs` |
| congestion risk is a local; `check_access(pos, 0)` | r205 | same |

## 4. Checklist for the next upstream revision

1. Download `http://pd2mods.z77.fr/update/Iter.zip`, read `mod.txt` `version`
   (call it `rN`).
2. Unpack to `_staging/upstream-iter/x` (gitignored).
3. Extract the recorded base as an archive:
   `git -C mods/Iter archive --format=zip -o _staging/upstream-iter/base.zip <r205 tree of the fork>`
   — the "base" is the fork commit whose `mod.txt` version is `<last adopted revision>.1`.
4. `git -c core.autocrlf=false diff --no-index --ignore-cr-at-eol base new`.
5. Classify every hunk:
   - **adopt** — applies to our shape; port it, pin it with a test in the
     `upstream-rNNN-*.test.mjs` pattern (values, not prose);
   - **already present** — find the counterpart in §1; no work;
   - **not applicable** — cite the section of §2 (add a new one if it is new);
   - **needs in-game check** — CRCs, nav-data ids, engine-facing behaviour that
     cannot be exercised offline; list the level/heist to load.
6. Land as one worktree branch, run `dev/tools/gates.ps1`, bump `mod.txt` to
   `<rN>.1`, add a `changelog.txt` block, then append a section to this ledger
   with the same three lists (adopted / not adopted / already present).
