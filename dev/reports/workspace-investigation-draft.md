# Draft — Iter full-nav port (workspace investigation)

Copy to `docs/investigations/iter-full-nav-port.md` on merge.

## Verdict

Iter's r200 navigation core was ported to PAYDAY 2 248.2 (nav v6) by
reconstructing the runtime geometry from the v5 arrays the 248.2 converter
still forwards. LIES was not a source for the feature set: its nav layer is
cover search/generation plus v6 compatibility, with no streamline/nav-link
queue code. LIES's v6 idioms (string ids, `door.x` vs nav-link userdata,
coarse-search plumbing) were used as reference only.

## Key facts

- Iter r200 `98940fb`; 248.2 `e3a8b616`; last-compatible content `a3180fc`.
- 248.2 `_convert_nav_data_v5_to_v6` drops `neighbours` and
  `room_vis_groups`, but keeps quad borders/heights, door position pairs,
  door quad ids and `visibility_groups[].quads`.
- `NavFieldBuilder._VERSION` is still 5, and every tested heist reports
  `data_version=5`.
- `_rooms`/`_room_doors`/`_visibility_groups` are rebuilt in a post-hook of
  `_send_nav_field_to_engine`; proxies are computed after
  `_resolve_segment_neighbours`.
- Engine neighbour entries are Vector3 or nav-link userdata. A truthy `.x`
  is not enough to identify a Vector3; passing a nav-link to `mvector3`
  caused an access violation. `is_vec3` requires userdata + numeric x/y/z.
- v6 discards explicit neighbour writes; a map patch survives only if its
  rooms/doors/quads express the connection. Static audit:
  16 levels survive, 4 need rewrites, `skm_mallcrasher` is a no-op.

## Evidence

- `mods/Iter/dev/progress.md`, `dev/reports/` (intent map, decisions,
  ledger, smoke reports, P7 audits).
- Runtime: T1 nav graph PASS; T2 streamline PASS; T3 AI/nav-link queue PASS;
  T4 search/direct-to-pos PASS; RC patches `big`, `born`, `kenaz` applied;
  no Iter errors.
- API audit baseline 12 expected errors (unported v5 branches), 12 scoped
  suppressions, 0 unused.

## Remaining

- T5 path extender not exercised (needs a converted cop/Joker or chase).
- P7 rewrites: `escape_street`, `jolly`, `moon`, `peta`; `skm_mallcrasher`
  dead. `arm_for` and `crojob2` (Dockyard) were confirmed by dumps.
- Probe length metric needed a `raw_positions` counter; added.
- Compatibility: NavFixes must not run with Iter (replaces the nav-link
  register wrapper); The Fixes replaces `CopActionWalk._init`.
