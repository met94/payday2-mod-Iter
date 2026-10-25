# Iter — PAYDAY 2 248.2 x64 navigation port

Iter improves NPC navigation: long-path weighting, path streamlining, nav-link
queueing, direct-to-pos, path extension, and a set of per-level nav fixes.

This repository is the 248.2 fork of the r200 port (Diesel 3 / nav-v6). The
original mod was written against the v5 nav model; the core has been
reimplemented on the v6 load data, with the subsystem switches documented in
`MENU_OPTIONS.md`.

- Version: `200.2`
- Base: upstream Iter r200 (`98940fb`) by TdlQ
- Fork maintenance: met94
- Target: PAYDAY 2 248.2 (`e3a8b616`), SuperBLT

## Status

| Subsystem | State |
|---|---|
| v6 geometry shim | working (T1 PASS) |
| Path streamline | working (T2/T2b PASS) |
| Nav-link queue/reservations | working (T3 PASS) |
| Iter coarse search + cache | working (T4 PASS) |
| Direct-to-pos | working (T4 PASS) |
| Path extender | working (T5 PASS on counters; no visible slide/stuck) |
| Map patches | 21 clean blocks (22 level ids), 2 accepted losses, 1 dead, 2 no-op |

## Requirements

- PAYDAY 2 248.2 x64 (Diesel 3)
- SuperBLT
- No BeardLib requirement

## Auto-updates and versioning

Versions use `<upstream revision>.<fork release>`:

- `200.1` is the first full-nav fork release on upstream r200;
- `200.2`, `200.3`, ... are later fork releases on the same upstream base;
- after merging a new upstream revision the base changes (`201.1`).

Upstream integer revisions are never reused, so a future TdlQ release cannot
collide with a fork build. Release tags mirror the version (`v200.1`).
`mod.txt` points SuperBLT's updater at
`releases/latest/download/meta.json` in this repository. Upstream's own update
endpoint is not referenced: it only knows its own package and would overwrite
the fork.

Release checklist: bump `version` in `mod.txt`, prepend a `Revision <version>:`
block to `changelog.txt`, build a zip whose single root folder is `Iter`, and
publish it with a `meta.json` asset from a release tagged `v<version>`.

## Compatibility

- **LIES:** optional, not a dependency. LIES owns enemy AI; Iter owns
  navigation — congestion control, the coarse search and the nav-link queue.
  Iter never fills LIES's `[4]` multi-navlink slot, so that LIES branch stays
  idle; its `[3]` wait still reads the single navlink Iter chose, but ordering
  and congestion belong to Iter's queue. LIES's squad push coordination
  (`CopLogicTravel.chk_group_ready_to_move`) still runs. Iter is standalone on
  vanilla cover registration; when both are installed LIES's own cover
  generation/search still runs. Iter owns `_execute_coarce_search`,
  `CopLogicTravel:_check_start_path_ahead` and
  `CopLogicTravel:_chk_stop_for_follow_unit`; it wraps LIES's
  `register_anim_nav_link`, `set_nav_segment_state`, `add_obstacle`,
  `register_cover_units`, `_clear` and `update`.
- **NavFixes:** do not run together. NavFixes replaces
  `register_anim_nav_link` and would break Iter's nav-link map.
- **The Fixes:** priority -10; owns `CopActionWalk._init` in the full profile.
  Iter re-wraps the winning function after all mods load, so path expansion
  and nav-link prepare still run. Tested with `path_extender=true` and The
  Fixes: T5 PASS.
- **Keepers:** priority 10. Direct-to-pos is live again; needs a
  converted-keeper smoke.
- **Monkeepers:** priority 99, matching the LIES documentation. Iter's
  `cop_idle_fix` only changes an idle animation variant, so the two do not
  collide.
- **Useful Bots:** priority 0. Iter publishes the legacy `streamline_path`
  alias at load, so Useful Bots 2.4.3's load-time guard recognises Iter's
  streamliner and skips its own path re-check. Useful Bots itself is
  untouched.

See `dev/reports/compatibility-iter.md` for the function-level matrix.

## Options

See `MENU_OPTIONS.md`. The menu exposes the master **Improve NPC pathing**
switch, **Rebuild NavLinks**, and the per-map toggles. Subsystem flags
(streamline, search, AI, nav-link queue, path extender, direct-to-pos, map
patches, idle cosmetic) are settings-only for troubleshooting and default on.

## Credits

- Original mod and AI design: TdlQ
- 248.2 x64 navigation port: workspace
- Decompiled game reference: steam-test1/Payday-2-LuaJIT-Complete

## License

The original Iter archive (r200) ships no license file, and the original mod
page states none. The fork changes in this repository are released under the
**Unlicense** (public-domain dedication); see [LICENSE](LICENSE).

The original mod name, code, localization files, icons and any retained
original content remain credited to their original authors. No ownership is
claimed over those parts. If you are an original author and want different
terms, open an issue.
