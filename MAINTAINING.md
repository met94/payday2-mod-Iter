# Maintaining the Iter 248.2 x64 port

Public-facing documentation is [`README.md`](README.md) and
[`MENU_OPTIONS.md`](MENU_OPTIONS.md). This file is for whoever works on the
port: acceptance state, upstream provenance, gates and the release procedure.

## What this repository is

The 248.2 fork of the r200 nav-v6 port. Upstream Iter (TdlQ, code maintenance by
BangL) was written against the v5 nav model; the nav core here is reimplemented
on the v6 load data (`98940fb`), and the base moved to upstream r205 in 205.1
without rebasing the core.

Target: PAYDAY 2 248.2 (`e3a8b616`), 64-bit, SuperBLT.

## Acceptance state

| Subsystem | State |
|---|---|
| v6 geometry shim | working (T1 PASS) |
| Path streamline | working (T2/T2b PASS) |
| Nav-link queue/reservations | working (T3 PASS) |
| Iter coarse search + cache | working (T4 PASS) |
| Direct-to-pos | working (T4 PASS) |
| Path extender | working (T5 PASS on counters; no visible slide/stuck) |
| Map patches | 21 clean blocks (22 level ids), 2 accepted losses, 1 dead, 2 no-op |
| Upstream parity | r201-r205 reviewed: adopted or consciously skipped |

Engineering history (per-release fixes and their measurements) lives in
`changelog.txt`; port decisions and their evidence live in
`dev/reports/decisions.md` and `dev/port-ledger.md`.

## Upstream parity

`dev/reports/upstream-parity.md` is the durable ledger of what each upstream
revision changed and whether it was adopted, skipped or re-implemented. Read it
before comparing a new upstream package.

205.1 moved the base to upstream r205 and adopted every r201-r205 fix that
applies: stale map CRC signatures and remapped ids (`branchbank`,
`firestarter_1`, `gallery`/`framing_frame_1`, `mex`), the visibility-group index
contract in `append_vis_group`, string nav segment ids in `ElementAINavSeg`, the
coarse-cache destination, the asymmetric neighbour refresh,
`start_nav_segment()`/`end_nav_segment()`, the dead-nav-link stall, and the
queue start-position/timestamp fixes. Deliberately not taken: r204's
visibility-group self-reference (the game's own builder never lists a group in
its own list).

## Compose rules

Load order is fixed and ships in each `mod.txt`; never change a `priority`, and
never rename the folder (the name is the SuperBLT dependency key).

- Iter is the navigation owner: it supersedes
  `NavigationManager._execute_coarce_search`,
  `CopLogicTravel._check_start_path_ahead` and
  `CopLogicTravel._chk_stop_for_follow_unit`, and wraps LIES'
  `NavigationManager` entry points plus `CopBrain:clbk_pathing_results` and the
  `CopLogicTravel` path functions.
- `Iter.settings.streamline_path` is published as a runtime mirror of
  `nav_overlay and nav_streamline` for Useful Bots, recomputed in `Iter:save()`.
  Useful Bots reads it once at load — a menu toggle only reaches it after a
  restart. Keep that contract: see
  `dev/reports/compatibility-iter.md` for the function matrix.
- The map patches are data-only and gate on their CRC signatures; a changed
  level logs `mismatch` and the block is skipped.

## Repository layout

```text
lua/        nav core, cop/bot hooks, map patch data, shim, diag/watch
menu/       SuperBLT options menu definition
loc/        translations
dev/        reports, ledgers, build script, gates, lua + node tests
mod.txt     hooks, version, priority
```

## Gates

From the repository root (LuaJIT is provisioned in the workspace, not here):

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File dev\tools\gates.ps1
node --test dev\tools\test\compat.test.mjs
tools\luajit\luajit.exe -bl <changed .lua files>
```

`dev\tools\gates.ps1` runs the static gates plus the Lua tests in
`dev/tests/lua/`. The compat test also pins this README: the `- Version:`
line, a `## Compatibility` section (before `## Options`) that explains the
Useful Bots mirror, and the absence of the dead LIES `[4]` claim.

## Release checklist

1. Fix/port the code; keep `changelog.txt` newest-first with
   `Revision <version> (...)` blocks ending in a `Player notes:` line.
2. Bump `version` in `mod.txt` and the `- Version:` line in `README.md`; update
   `dev/reports/static-gates.md`.
3. Run the gates above; all green.
4. `dev/build.ps1` -> `dist/Iter`; verify `mod.txt` at its root and no `dev/`,
   `dist/`, `.git`, `MAINTAINING.md`.
5. Tag `v<version>`, publish the zip and a `meta.json` asset
   (`ident` `Iter`, `version` equal to `mod.txt`, `download_url`, optional
   `patchnotes_url`) from the release.
6. The user deploys; agents never copy mods into the install.

## Licensing

Fork changes: Unlicense (see [`LICENSE`](LICENSE)). Upstream Iter, retained code,
localization and assets remain credited to TdlQ and BangL.
