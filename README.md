# Iter — PAYDAY 2 248.2 x64 navigation port

Iter improves NPC navigation: long-path weighting, path streamlining, nav-link
queueing, direct-to-pos, path extension, and a set of per-level nav fixes.

This repository is the 248.2 fork of the r200 port (Diesel 3 / nav-v6). The
original mod was written against the v5 nav model; the core has been
reimplemented on the v6 load data, with the subsystem switches documented in
`MENU_OPTIONS.md`.

- Version: `200.1`
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

- **LIES:** optional, not a dependency. Iter runs standalone on vanilla cover
  registration. Tested together; Iter owns the coarse search, LIES's own
  cover generation/search still runs.
- **NavFixes:** do not run together. NavFixes replaces
  `register_anim_nav_link` and would break Iter's nav-link map.
- **The Fixes:** replaces `CopActionWalk._init`; Iter re-wraps the winning
  function after all mods load, so path expansion and nav-link prepare still
  run. Tested with `path_extender=true` and The Fixes: T5 PASS.
- **Keepers:** direct-to-pos is live again; needs a converted-keeper smoke.

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
