# Follow-unit use-after-free in the coarse-path streamliner (2026-11-01)

Crash report + fix note. Iter Lua was edited for this (one guard), plus the
matching guard on the drill interaction path.

- **Target:** PAYDAY 2 248.2 (`e3a8b616`), SuperBLT, build `1.0.0-159028`
- **Iter:** fork `200.20` (`f896b61`, the line the live install is built from) →
  release `200.21` on `feat/ai-suite-compat`
- **Found by:** LIES V8.79 door-watch test play, heist `auc`
- **Crash:** 2026-11-01 12:39:26, `%LOCALAPPDATA%\PAYDAY 2\crash.txt` +
  `crash.dmp`, rolling `crashlog.txt` entry 228

## 1. Symptom

Engine access violation, no Lua error. Script stack:

```
results_callback()  @mods/Iter/lua/copbrain.lua:115
_commence_coarce_searches()  lib/managers/navigationmanager.lua:1346
original()  lib/managers/navigationmanager.lua:197
update()  @mods/base/req/core/Hooks.lua:293
```

Native callstack is generic (`vsnprintf_s`, `AK::WriteBytesCount::WriteBytes`),
so the Lua frame is the only usable anchor.

## 2. Root cause

`CopBrain:clbk_coarse_pathing_results` (nav_ai branch) rewrote the coarse path's
final point from the objective's followed unit:

```lua
if objective and objective.follow_unit then            -- nil check only
    path[#path][2] = objective.follow_unit:position()  -- :115 before the fix
end
```

A coarse search is queued and its results callback fires later. If the followed
unit is destroyed in between (criminal downed and removed, player husk cleared),
the attention/objective tables still hold the handle: `follow_unit` is not nil,
but the engine object is gone. `position()` on it faults.

Evidence that the mod already knew the rule: the streamline-only branch of the
same file guards the identical line with `alive(objective.follow_unit)`
(`lua/copbrain.lua:30`), and `CopLogicTravel._chk_stop_for_follow_unit` guards
with `alive` before touching the unit (`lua/coplogictravel.lua:277`). The nav_ai
copy simply missed it.

Why it had not been seen before: `crashlog.txt` (228 entries since 2024) has no
earlier entry with this stack. It needs a coarse search to be in flight exactly
when the followed unit is destroyed — rare, timing-dependent, not tied to a
specific heist.

## 3. Not LIES

The LIES door-watch work was the test load, not the cause:

- no LIES frame in the script stack;
- LIES's new `_get_expected_pos` reuses `NavigationManager:search_coarse` in its
  **synchronous** form (`results_clbk` nil, `navigationmanager.lua:1452/1501`);
  only `CopBrain:search_for_coarse_path` queues a `results_clbk`
  (`navigationmanager.lua:1499`);
- LIES's change reduces vanilla coarse-path kicks (a watch position short-circuits
  the vanilla call), so it cannot increase this callback's rate.

Control runs after the crash: LIES V8.79 with door watch gated off (~6 min) and
LIES removed entirely (~5 min) — neither crashed, but with a one-in-many chance
event neither run is proof. The mechanism above is.

## 4. Fix

`lua/copbrain.lua` (nav_ai branch): add `alive()` to the existing nil check, so a
destroyed follow unit leaves the streamline endpoint at the nav-segment position
and the callback proceeds normally.

`lua/drill.lua`: `Drill:on_investigate_SO_administered` dereferenced
`receiver_unit:brain()` with no liveness check on a mod-added line; same guard
class as the surrounding functions (`:37`, `:43`).

## 5. Verification

- `dev/tests/lua/test_copbrain_follow_unit.lua` — offline LuaJIT test that loads
  the real hook file with stubbed engine globals and asserts: a destroyed follow
  unit is never dereferenced (a `position()` that raises is never called), a live
  unit still sets the streamline endpoint, an absent objective leaves the
  endpoint alone, and the drill guard is present.
- Mutation check: removing the `alive()` term makes the test fail with
  `freed unit dereferenced`; restoring it passes (15 checks).
- `dev/tools/gates.ps1`: all sections PASS (Node tests, harness parser, Lua unit
  tests, LuaJIT syntax 71 files, free identifiers, function ledger, API audit).

## 6. Player impact

No gameplay change. It stops a rare crash that could happen when a coarse path
finished at the moment the unit a cop was following (a teammate being downed or
husked) was removed.

## 7. Unknowns

- Not reproduced on demand; the fix is inferred from the stack and the API
  contract. Confirmation is "no recurrence in normal play", not a targeted test.
- Other `follow_unit:` dereferences were audited (`lua/copbrain.lua:59`,
  `lua/coplogictravel.lua:277/281/300`); the remaining sites are either guarded
  or unreachable from a queued callback.

## 8. Commands

```powershell
# deploy target for a live test (user action)
#   dist\Iter -> <game>\mods\Iter

D:\Programowanie\payday\2\v2\tools\luajit\luajit.exe -bl lua\copbrain.lua
D:\Programowanie\payday\2\v2\tools\luajit\luajit.exe dev\tests\lua\test_copbrain_follow_unit.lua
powershell -NoProfile -ExecutionPolicy Bypass -File dev\tools\gates.ps1
Get-Content "$env:LOCALAPPDATA\PAYDAY 2\crashlog.txt" | Select-String 'results_callback'
```

## 9. Decision & artifacts

Freeze the crash line rather than leave it to chance: the guard is the smallest
change that removes the fault and matches the file's own existing pattern.
Artifacts: worktree `.worktrees\Iter-ai-suite-compat` on branch
`feat/ai-suite-compat`, release commit on this branch (guard, drill guard, offline test,
release). The same change was first prepared as `ea7732a`/`aa6211c` on the stale
`master` line and replayed here, because the live install is built from this
branch (`200.20` at `f896b61`). `changelog.txt` `Revision 200.21`, `mod.txt`
`200.21`. Not deployed at the time of writing; the user deploys.
