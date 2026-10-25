# Iter full-nav port — decisions

Each ruling records what was decided, why, and what it costs if wrong. This is
the review trail; the intent map carries the feature-level rationale.

## R1. Old baseline for parsing

Use `a3180fc` (246.1 restyle) as the `--old` baseline for `fn-ledger` and
dossiers. `b36f5fbb` (pre-restyle) fails luaparse in `coremissionmanager` and
`groupaistatebase`; the code content is the same.

Cost if wrong: dossier bodies show restyled text; function identities and
semantics are unchanged.

## R2. Harness provenance

The dev harness is derived from the LIES 248.2 port tooling in
`mods/LIES/dev/` (same workspace author). Labels, prefixes, commands, and
card checks were adapted for Iter.

Cost if wrong: none; this is a tooling reuse decision, not runtime code.

## R3. Overlay default and inertness

`nav_overlay` is the internal master switch. It defaults to **true** in the
202-dev line because the v6 geometry shim and bookkeeping are the tested
foundation (T1/T2/T3/T4). Behaviour is still controlled by the individual
feature flags; the overlay alone only rebuilds geometry and guarded
bookkeeping. The menu toggle remains the emergency off switch.

Early in the port the default was false to keep unported v5 code inert; that
is no longer the case.

Cost if wrong: a bad shim build runs on every heist; the toggle and the
fallback event are the escape hatches.

## R4. v6 geometry shim before any feature work

Build the `_rooms` / `_room_doors` / `_visibility_groups` shim from the v5 load
data in `_send_nav_field_to_engine`, and compute proxies after
`_resolve_segment_neighbours`.

Why: every streamline feature depends on this data, and the vanilla
`get_nav_seg_from_i_room` is already broken at 248.2 because the tables are not
built.

Cost if wrong: if the game ships v6 data without v5 arrays, the shim logs
`fallback` and the feature is disabled; map patches are skipped. No crash.

## R5. LIES coexistence is an explicit ownership decision

At 248.2 both mods override `_execute_coarce_search` (last definition wins) and
share three wrapper points. Iter will not silently inherit LIES's search
contract; the search phase (P5) must either replicate the path shape LIES
consumes or delegate to LIES when it is present.

Cost if wrong: LIES cover approach could degrade when both mods are installed;
the T7 card catches it.

## R6. API-audit baseline 11 -> 12

`itr_get_door_between` now reads `self._room_doors[door_id]` from the N-01
shim. The audit symbol is still an error until S-04 removes the v5 numeric
branch, so the recorded baseline is 12.

Cost if wrong: one expected error can mask a regression in that file; the
review and ledger cover the line, and the baseline drops again when the v5
branch is deleted.

## R7. Search path ids stay strings

The r200 search built its result with `string.gmatch(..., '%d+')` +
`tonumber`, which is incompatible with 248.2 string segment keys and makes
`itr_streamline` index nil. The port keeps the ids as strings and normalises
only display values.

Cost if wrong: path steps point at missing segments; T4 would fail with nil
segment errors.

## R8. Search does not require proxy data

`nav_search` can run with `nav_streamline` off. `itr_get_coarse_pos_between`
and `itr_streamline` now treat missing proxies as empty and fall back to
door selection.

Cost if wrong: coarser step positions and longer paths when proxies are not
built; no crash.

## R9. Client-side nav-link prep is guarded

`CopActionWalk:_init` calls `itr_prepare_for_upcoming_navlink`, which is
defined only inside the server block. The wrapper checks for the method
before calling it.

Cost if wrong: the prepare step is skipped on a client that somehow reaches
the wrapper; vanilla path init still runs.

## R10. Civilian/team-AI overrides are dropped

`CivilianBrain.clbk_pathing_results` and `TeamAIBrain.clbk_pathing_results`
do not exist at 248.2 (both inherit `CopBrain:clbk_pathing_results`).
`CivilianLogicTravel._optimize_path` predates the 242 statics improvements.
The files are inert and unhooked; hook count 17 -> 14.

Cost if wrong: a civilian/team-AI nav behaviour from r200 is lost; vanilla
248.2 pathing is the fallback and is considered better.

## R11. AI features require the overlay

Every AI file now checks `nav_overlay` as well as its own flag
(`nav_ai`/`cop_idle_fix`). Enabling AI without the shim cannot call missing
`itr_*` helpers.

Cost if wrong: a test that enables only `nav_ai` behaves as vanilla; no crash.

## R12. Vector checks require numeric x/y/z

248.2 neighbour lists mix engine Vector3 userdata with nav-link userdata.
`i_door.x` alone is not enough to prove a Vector3; passing a nav-link object
to `mvector3` caused an access violation on Big Bank (probe path). `is_vec3`
now requires userdata with numeric `x`, `y`, `z`, and all position arguments
are validated before vector math.

Cost if wrong: a legitimate Vector3 whose components are not exposed as
numbers would be treated as a nav-link and skipped; paths fall back to
distance-only picks. No crash.

## R13. Map patches deferred

P7 is a separate phase: the r200 file selects its level at file-load time and
69 patch writes target neighbour lists the v6 converter discards. Doing it
inside the core-port session would mix a data migration with a working AI
port. `map_patches` stays false and the overlay does not load the file.

Cost if wrong: map-specific nav fixes (bus, biker counter, vault access) are
not active yet; core AI pathing is unaffected.

## R14. Release defaults match original Iter

r200 had `streamline_path=true` and loaded `_navdatapatches` unconditionally,
so path extender, shortcut finder, map patches and the cop idle cosmetic were
all on by default. The port kept them behind development flags while cards
were pending. All three cards are now satisfied:

- path extender: T5 PASS, including with The Fixes installed (late `_init`
  re-wrap, `path_extend_ok=45`, no slide/stuck);
- map patches: P7 complete at 21 clean blocks (22 level ids), 2 accepted
  losses, 1 dead, CRC-gated; map toggle smoke PASS;
- cop idle: cosmetic animation variant only.

Release defaults become `path_extender=true`, `map_patches=true`,
`cop_idle_fix=true`. Each remains a menu/runtime toggle (cop idle only via the
setting file).

Cost if wrong: path extender is exercised on fewer maps than the full heist
set; the toggle is the escape hatch. Map patches may hit an undetected level
drift, but the CRC gate skips safely. Cop idle is cosmetic.

## R15. Player-facing menu surface

The port menu had eight `Dev:` subsystem toggles mixed with the map toggles.
Original Iter only exposed the master pathing switch, Rebuild NavLinks and the
per-map toggles. Release menu:

- `nav_overlay` titled **Improve NPC pathing** (master kill switch);
- `rebuild_navlinks`;
- divider, then every `map_change_*` toggle, contiguous.

`nav_streamline`, `nav_search`, `nav_ai`, `navlink_queue`, `path_extender`,
`direct_to_pos`, `map_patches` and `cop_idle_fix` are settings-only in
`mods\saves\iter.txt`, default true. The legacy `streamline_path` key is
removed on load; an original-Iter file with `streamline_path=false` and no
`nav_overlay` migrates to `nav_overlay=false`. Eight map toggles that were
missing from the port menu (alex_2, chas, crojob2, escape_park,
jewelry_store, pbr, roberts, watchdogs_1) are restored.

Cost if wrong: players lose in-menu access to individual subsystems; the
settings file is documented in `MENU_OPTIONS.md`, and the master switch
remains in the menu. A menu test pins the separation and the full map set.





