# Iter — PAYDAY 2 248.2 x64 navigation port

Iter improves NPC navigation: long-path weighting, path streamlining, nav-link
queueing, direct-to-pos, path extension, and a set of per-level nav fixes.

This branch is the r200 port to the Diesel 3 / nav-v6 game build (248.2). The
original mod was written against the v5 nav model; the core has been
reimplemented on the v6 load data, with development gates for each subsystem.

- Version: `202-dev`
- Base: Iter r200 (`98940fb`) by TdlQ
- Target: PAYDAY 2 248.2 (`e3a8b616`), SuperBLT

## Status

| Subsystem | State |
|---|---|
| v6 geometry shim | working (T1 PASS) |
| Path streamline | working (T2/T2b PASS) |
| Nav-link queue/reservations | working (T3 PASS) |
| Iter coarse search + cache | working (T4 PASS) |
| Direct-to-pos | working (T4 PASS) |
| Path extender | implemented; T5 pending |
| Map patches | framework working; 16 levels survive, 4 need a v6 rewrite, 1 dead |

## Requirements

- PAYDAY 2 248.2 x64 (Diesel 3)
- SuperBLT
- No BeardLib requirement

## Compatibility

- **LIES:** tested together; Iter owns the coarse search, LIES cover search
  still runs.
- **NavFixes:** do not run together. NavFixes replaces
  `register_anim_nav_link` and would break Iter's nav-link map.
- **The Fixes:** replaces `CopActionWalk._init`; path expansion is lost,
  nav-link queue still works.
- **Keepers:** direct-to-pos is live again; needs a converted-keeper smoke.

See `dev/reports/compatibility-iter.md` for the function-level matrix.

## Options

See `MENU_OPTIONS.md`. The menu toggles are development gates. Defaults enable
the overlay, streamline, search, the AI cluster, nav-link queue and
direct-to-pos; path extender and map patches stay off until their cards pass.

## Credits

- Original mod and AI design: TdlQ
- 248.2 x64 navigation port: workspace
- Decompiled game reference: steam-test1/Payday-2-LuaJIT-Complete
