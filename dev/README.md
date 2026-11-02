# Iter dev harness

Dev-only. Not shipped; `dev/build.ps1` excludes it from `dist/Iter`.

Provenance: copied and adapted from the LIES 248.2 port tooling in
`mods/LIES/dev/` (same workspace author). Labels, prefixes, chat commands,
cards, and baselines are Iter-specific.

## Layout

| Path | Purpose |
|---|---|
| `plans/full-nav-port.md` | authoritative plan |
| `progress.md` | session ledger, recovery map |
| `port-ledger.md` | generated per-function inventory |
| `tools/` | ledger, workbench, audit, log scan, gates, build |
| `test-harness/` | separate dev mod with `!iter` chat commands |
| `test/cards/` | acceptance JSON for `log-scan --card` |
| `reports/` | intent map, decisions, drop log, dossiers, reviews, smoke reports |
| `reports/upstream-parity.md` | upstream revision ledger: adopted / not adopted / already present, with reasons |
| `build.ps1` | package `dist/Iter`; never touches the game |

## Daily loop

```powershell
# static gates
powershell -NoProfile -ExecutionPolicy Bypass -File dev\tools\gates.ps1

# build for a test
powershell -NoProfile -ExecutionPolicy Bypass -File dev\build.ps1

# scan the log the user sends
node dev\tools\log-scan.mjs <path-to-log> --mod . --card dev\test\cards\T0-load.json
```

## Baselines

- Iter source: `98940fb` (r200); upstream base for versioning: r205 (`205.1`).
- Old vanilla: `a3180fc` (246.1; parseable restyle).
- Target vanilla: `e3a8b616` (248.2).

Upstream revisions are tracked in `reports/upstream-parity.md` — read it before
comparing a new upstream package, it records what was deliberately not adopted.

## Chat commands

`!iter help | nav | patch | probe [n] | path | ai | links | alarm | assault |
state | setting <key> <value> | dump | reset`

All test output is prefixed `[ITER-TEST]`; runtime telemetry is `[ITER-NAV]`;
caught failures are `[ITER-ERR]`.

## Runtime gates

- T0 load, T1 nav graph, T2 streamline, T3 navlink, T4 search, T5 AI,
  T6 patches, T7 compatibility. Cards live in `test/cards/`.
