# Iter — PAYDAY 2 248.2 x64 navigation port

Iter improves NPC navigation: long-path weighting, path streamlining, nav-link
queueing, direct-to-pos, path extension, and a set of per-level nav fixes. NPCs
use ladders, doors and jumps without piling up on the same link, and levels
whose nav data broke after U247 path again.

- Version: `205.3`
- Target: PAYDAY 2 248.2 x64 (Diesel 3), SuperBLT

## Part of the AI suite

Tested as one stack and meant to run with it. One download for all four:
[**AI Suite**](https://github.com/met94/payday2-ai-suite/releases).

| Mod | Repo | Role |
| --- | --- | --- |
| **LIES** | [met94/Little-Intelligence-Enhancements-x64](https://github.com/met94/Little-Intelligence-Enhancements-x64) | enemy AI: detection, aim, cover, travel |
| **Iter** (this mod) | [met94/payday2-mod-Iter](https://github.com/met94/payday2-mod-Iter) | navigation, coarse search, nav-link queue, level nav fixes |
| **Keepers** | [met94/payday2-mod-Keepers](https://github.com/met94/payday2-mod-Keepers) | bot orders, revives, jokers |
| **Monkeepers** | [met94/payday2-mod-Monkeepers](https://github.com/met94/payday2-mod-Monkeepers) | bot bag logistics |
| **Useful Bots** 2.6.3 (by Hoppip, not part of this set) | [ModWorkshop #31221](https://modworkshop.net/mod/31221) | bot combat and utility; requires HopLib |
| The Fixes (optional) | [ModWorkshop #23732](https://modworkshop.net/mod/23732) | general game fixes |

## What it changes in-game

- Cops, bots and civilians queue for ladders, doors and vaults instead of
  clumping on one link.
- Paths are streamlined and shortened where the nav mesh allows it, with cached
  coarse searches so repeated pathing is cheaper.
- Units can be sent directly to a position, and their path can be extended
  ahead while they walk.
- Per-level nav fixes restore routing on maps whose nav data changed after
  U247 (Branch Bank, Firestarter day 1, Gallery/Framing Frame day 1, Met).
- A watch digest (`[ITER-WATCH]`) can log queue health; off by default.

## Requirements

- PAYDAY 2 248.2 x64 (Diesel 3)
- SuperBLT
- No BeardLib requirement

## Installation

1. Close PAYDAY 2.
2. Remove or rename an older `Iter` folder in `...\PAYDAY 2\mods\`.
3. Extract `Iter_v205.3.zip` so the result is exactly
   `...\PAYDAY 2\mods\Iter\mod.txt`.
4. Launch the game and open **Mod Options → Iter**.

If you download the GitHub source ZIP instead, rename the extracted
`payday2-mod-Iter-master` folder to `Iter`.

> Do not install two folders with the same `mod.txt` name. SuperBLT treats the
> name as the dependency key and one copy will win unpredictably.

## Auto-updates

`mod.txt` points SuperBLT's updater at
`releases/latest/download/meta.json` in this repository; upstream's own update
endpoint is not referenced (it only knows the upstream package). Versions are
`<upstream revision>.<fork release>` and tags mirror them (`v205.3`).

## Compatibility

- **LIES** — optional. LIES owns enemy AI; Iter owns navigation: congestion
  control, the coarse search and the nav-link queue. LIES' squad push
  coordination still runs, and its navlink-delay setting feeds Iter's queue.
- **Keepers**, **Monkeepers** — compatible; they run after LIES and do not
  touch Iter's navigation functions.
- **Useful Bots** — compatible. Iter publishes the legacy `streamline_path`
  runtime mirror (`nav_overlay and nav_streamline`), so Useful Bots 2.6.3's
  load-time guard recognises Iter's streamliner and skips its own path
  re-check. `Iter:save()` recomputes the mirror from the live switches and
  persists the result, so a menu toggle only reaches Useful Bots after a game
  restart.
- **The Fixes** — optional and compatible; it loads last and owns the cop
  walk-action initialisation, and Iter re-wraps the winning function so path
  expansion and nav-link preparation still run.

Function-level matrix and the acceptance log: [`MAINTAINING.md`](MAINTAINING.md).

## Options

See [MENU_OPTIONS.md](MENU_OPTIONS.md). The menu exposes the master **Improve
NPC pathing** switch, **Rebuild NavLinks**, and per-map toggles. The remaining
subsystem flags are troubleshooting switches and default on.

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
