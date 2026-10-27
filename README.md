# Iter — PAYDAY 2 248.2 x64 navigation port

Iter improves NPC navigation: long-path weighting, path streamlining, nav-link
queueing, direct-to-pos, path extension, and a set of per-level nav fixes.

This repository is the 248.2 fork of the r200 port (Diesel 3 / nav-v6). The
original mod was written against the v5 nav model; the core has been
reimplemented on the v6 load data, with the subsystem switches documented in
`MENU_OPTIONS.md`.

- Version: `200.14`
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

**200.13** reports the real player speed (`pspd_max`) and the `game`/`player`/
`game_animation` timer multipliers, so a leftover multiplier (Time Speed touches
exactly those three) is visible instead of an unexplained heaviness.

**200.12** measures the simulation/wall ratio and a real frame rate with
`os.time()` (the engine's `Application:time()` is itself scaled by a time
multiplier), and raises an always-on `sim_timescale` alarm when a multiplier is
active.

**200.11** reports the Lua heap (`lua_kb`) in the digest, so a long-heist
slowdown can be told apart from a leak, and makes the teardown summary actually
fire by emitting it from a `MenuManager.open` hook (PD2 does not clear the nav
manager when a heist is quit to the menu).

**200.10** adds frame pacing to the digest (`fps`, `hitch_n`, `hitch_ms`,
`sim_ratio` from `Application:time()`) and emits the final digest on level
teardown, so a heist quit to the menu still gets a summary. See `changelog.txt`.

**200.9** adds live population counts to the watch digest (`cops=`, `crims=`),
so "more cops with mods" can be compared against a vanilla run instead of felt.
LIES has no working population multiplier in this port: `coplimit` and
`spawngroupdelays` are stored but nothing reads them.

**200.8** expires the nav-link queue cache on a link with no owner: the queue
fields are per-frame scratch data, and when the waiting cop stops polling they
froze (Counterfeit 2026-10-26 reported `queue=1 reserved=none wait=239.4` on a
link nobody held). Cleared after 2 s, so digests and alarms describe the real
queue. See `changelog.txt`.

**200.7** adds the watch channel: an opt-in `[ITER-WATCH]` digest (one line per
minute of play, `"watch_log": true` in `iter.txt`) plus always-on hard-failure
alarms that stay silent on a healthy heist (queue over 20, a cop waiting over
120 s, a burst of stale reservations). The Counterfeit fault of 2026-10-26 was
only visible because the dev harness was installed; this makes a repeat visible
in any log. See `changelog.txt` and `MENU_OPTIONS.md`.

**200.6** stops the wait-start stamp from leaking between links: a unit that
waited once kept `itr_wait_for_navlink_availability_t` for the whole level, and
`itr_update_navlink_queue_data` copied it into
`itr_navlink_queue_oldest_t`, so `!iter links` showed phantom waits (579 s on a
`queue=1` link while the longest real cop wait was 74.7 s) and the queue-order
check ran on a level-old timestamp. The stamp is now dropped when the wait ends
and on exit, and `[ITER-NAV] evt=navlink_stale` logs the real reservation age
(`hold=`) instead of the queue wait. See `changelog.txt`.

**200.5** fixes stale **live** nav-link reservations: a cop could take the token
and then stop using the link (repath, stagger, blocked behind another link,
stuck in combat), and nothing released it until that cop died — on Counterfeit
one cop held the basement stairs link for 204.8 s of sim time. Reservations now
carry `itr_reserved_t`, refreshed in `_play_nav_link_anim` only while the owner
is at the link, and the sweep releases a live holder older than 15 s
(`[ITER-NAV] evt=navlink_stale`). See `changelog.txt`.

**200.4** fixes dead nav-link reservations: a destroyed cop never runs
`CopActionWalk:on_exit`, so its reservation and queue timestamps could block a
nav link forever. `itr_reserve_navlink` now drops a dead reservation before
reserving, and a once-per-second `NavigationManager.update` sweep clears links
nobody walks up to again (`[ITER-NAV] evt=navlink_dead`). See `changelog.txt`.

**200.3** fixes the Santa's Workshop (`cane`) nav-link crash: door and nav-link
userdata that does not implement `alive()` (Santa's Workshop's sibling-nav-link
switch on a heavy assault) now goes through `itr_alive` / `itr_alive_navpoint`
instead of the game helper. See `changelog.txt`.

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
  LIES never fills its own `[4]` multi-navlink slot: it declares
  `has_multiple_navlink_elements` without ever assigning it and only reads
  `seg.multiple_nav_links`, so that branch is dead on any path, Iter or vanilla.
  Its `[3]` wait still reads the single navlink Iter's streamliner chose
  (`lua/navigationmanager.lua:1125`), but ordering and congestion belong to
  Iter's queue. LIES's squad push coordination
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
- **Keepers:** target priority 10 in the AI suite contract (the current
  checkout has no `priority` key, so it loads at 0). Direct-to-pos is live
  again; needs a converted-keeper smoke.
- **Monkeepers:** target priority 99 in the AI suite contract (the current
  checkout still ships 100), matching the LIES documentation. Iter's
  `cop_idle_fix` only changes an idle animation variant, so the two do not
  collide.
- **Useful Bots:** priority 0. Iter publishes the legacy `streamline_path`
  runtime mirror (`nav_overlay and nav_streamline`), so Useful Bots 2.4.3's
  load-time guard recognises Iter's streamliner and skips its own path
  re-check. `Iter:save()` recomputes the mirror from the live switches and
  persists it (`true` when pathing is on, `false` when it is off), so the
  in-memory value never goes stale and a downgrade to upstream r200 keeps the
  effective setting. Useful Bots reads the key once, at load: a menu toggle
  only reaches it after a game restart. Useful Bots itself is untouched.

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
