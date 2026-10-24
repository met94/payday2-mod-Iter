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

## R3. Overlay stays inert until its flag is enabled

The restored r200 overlay is gated by `Iter.settings.nav_overlay`, an internal
master switch that defaults to false. `streamline_path` remains the future
user-facing toggle. `groupaistatebase` and the nav overlay return before
installing anything.

Why: a saved Iter Lite settings file may contain `streamline_path=true`; without
a new internal key, the next build would run unported v5 code on 248.2 and crash
on heist load. The new key cannot be enabled accidentally by an old save file.

Cost if wrong: a test session that forgets `nav_overlay` behaves like Iter Lite;
no crash, just no nav changes.

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



