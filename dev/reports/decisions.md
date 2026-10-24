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

The restored r200 overlay is gated by `Iter.settings.streamline_path`, and a
dev-only `nav_core_dev` guard forces the master gate off at load unless a test
session explicitly enables it (`!iter setting nav_core_dev true`).
`groupaistatebase` and the nav overlay return before installing anything.

Why: a saved Iter Lite settings file may contain `streamline_path=true`; without
the guard, the next build would run unported v5 code on 248.2 and crash on heist
load.

Cost if wrong: a test session that forgets the flag behaves like Iter Lite; no
crash, just no nav changes.

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
