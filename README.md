# Iter — navigation fixes for PAYDAY 2

Iter keeps NPCs moving. Ladders, doors, vaults and jumps are queued instead of
piled onto one link, paths are streamlined and reused, and a few maps that lost
their routing after U247 work again.

- Version: `205.7`
- Requires: PAYDAY 2 249 x64 (Diesel 3) and SuperBLT

## Part of the AI suite

Tested as one stack and meant to run with it. One download for all four:
[**AI Suite**](https://github.com/met94/payday2-ai-suite/releases).

| Mod | Repo | Role |
| --- | --- | --- |
| **LIES** | [met94/Little-Intelligence-Enhancements-x64](https://github.com/met94/Little-Intelligence-Enhancements-x64) | enemy AI |
| **Iter** (this mod) | [met94/payday2-mod-Iter](https://github.com/met94/payday2-mod-Iter) | navigation and pathing |
| **Keepers** | [met94/payday2-mod-Keepers](https://github.com/met94/payday2-mod-Keepers) | bot orders and revives |
| **Monkeepers** | [met94/payday2-mod-Monkeepers](https://github.com/met94/payday2-mod-Monkeepers) | bot bag handling |
| **Useful Bots** 2.6.4 + HopLib 2.1.2 (by Hoppip, not part of this set) | [ModWorkshop #31221](https://modworkshop.net/mod/31221) | bot combat and utility |
| The Fixes (optional) | [ModWorkshop #23732](https://modworkshop.net/mod/23732) | general game fixes |

## What it changes in-game

- Cops, bots and civilians queue for ladders, doors and vaults instead of
  clumping on one link.
- Paths are streamlined and reused, so repeated pathing is cheaper.
- Units can be sent straight to a position and keep extending their path while
  they walk.
- Navigation is repaired on maps that broke after U247 (Branch Bank, Firestarter
  day 1, Gallery/Framing Frame day 1, Met).
- An optional watch log (`[ITER-WATCH]`) can help with bug reports; off by
  default.

## Requirements

- PAYDAY 2 249 x64 (Diesel 3)
- SuperBLT
- No BeardLib requirement

## Installation

1. Close PAYDAY 2.
2. Remove or rename an older `Iter` folder in `...\PAYDAY 2\mods\`.
3. Extract `Iter_v205.7.zip` so the result is exactly
   `...\PAYDAY 2\mods\Iter\mod.txt`.
4. Launch the game and open **Mod Options → Iter**.

If you download the GitHub source ZIP instead, rename the extracted
`payday2-mod-Iter-master` folder to `Iter`.

> Do not install two folders with the same `mod.txt` name. SuperBLT treats the
> name as the dependency key and one copy will win unpredictably.

## Auto-updates

Iter updates through SuperBLT: `mod.txt` points the updater at this repository's
`releases/latest/download/meta.json`, not upstream's feed. Versions are
`<upstream revision>.<fork release>` and tags match (`v205.7`).

## Compatibility

- **LIES** — recommended together. LIES does enemy AI, Iter does navigation;
  they split the work and run fine side by side.
- **Keepers**, **Monkeepers** — compatible; neither touches navigation.
- **Useful Bots** — compatible. Iter keeps the legacy `streamline_path`
  setting Useful Bots reads, and that mirror is recomputed and saved when Iter
  saves its settings. Useful Bots only reads it at load, so a menu toggle
  reaches it after a game restart.
- **The Fixes** — optional and compatible; it patches narrow game bugs and Iter
  keeps working with its walk-action changes.

Function-level matrix and the acceptance log: [`MAINTAINING.md`](MAINTAINING.md).

## Options

See [MENU_OPTIONS.md](MENU_OPTIONS.md). The menu exposes the master **Improve
NPC pathing** switch, **Rebuild NavLinks**, and per-map toggles. The remaining
subsystem flags are troubleshooting switches and default on.

## Credits

- Original mod and AI design: TdlQ
- 248.2 x64 navigation port and maintenance: met94
- Decompiled game reference: steam-test1/Payday-2-LuaJIT-Complete

## License

The original Iter archive (r200) ships no license file, and the original mod
page states none. The fork changes in this repository are released under the
**Unlicense** (public-domain dedication); see [LICENSE](LICENSE).

The original mod name, code, localization files, icons and any retained
original content remain credited to their original authors. No ownership is
claimed over those parts. If you are an original author and want different
terms, open an issue.
