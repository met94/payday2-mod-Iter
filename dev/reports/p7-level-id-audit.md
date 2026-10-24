# P7 level-id audit

Question: are the patch keys the same heists the game actually loads, or was
`mallcrasher` / `skm_mallcrasher` confused? Method: compare every level id in
the mod against the game's level tables.

Sources:

- `game-data/Payday-2-LuaJIT-Complete/lib/tweak_data/narrativetweakdata.lua`
  (`stages.*.level_id` — what `Global.game_settings.level_id` gets).
- `game-data/Payday-2-LuaJIT-Complete/lib/tweak_data/levelstweakdata.lua`
  (`self.<id>` keys and `world_name`).
- `lua/_navdatapatches.lua`, `lua/corecode.lua`, `menu/options.txt`,
  `lua/coreworlddefinition.lua`, `lua/coremissionmanager.lua`.

## Result

- Every `level_id == '...'` branch in the mod resolves to a real level key,
  except `gallery`, which is real but defined as
  `self.gallery = deep_clone(self.framing_frame_1)` (the regex for `{}` keys
  misses it). `gallery` has its own CRC (`1380658305`) and its own stage
  (`narrativetweakdata` line 2586), so the shared `framing_frame_1 or gallery`
  block is intentional.
- Every `map_change_*` setting maps to a real level key; `gallery` is the only
  one the `{}` scan misses, for the same reason.
- Every patched level has a `map_change_*` setting.
- `_day` / `_night` variants are intentional: `Iter:get_level_id()` strips the
  suffix, so `escape_park_day` uses `escape_park` and `watchdogs_1_night`
  uses `watchdogs_1`.
- `skm_big2` has a `coremissionmanager` branch and a `map_change_skm_big2`
  setting but no nav patch; it is a mission fix, not a nav-data patch.
- `peta`/`peta2`, `mia_1`/`mia_2`, `pbr`/`pbr2`, `alex_2`/`alex_3`,
  `firestarter_1/2/3` are separate level ids; only the named one is patched.
  No cross-application.

## The one real mismatch

`mallcrasher` and `skm_mallcrasher` are **different heists**:

| Level id | World | Group AI | Nav data CRC |
|---|---|---|---|
| `mallcrasher` | `narratives/vlad/mallcrasher` | default | `75811735` |
| `skm_mallcrasher` | `narratives/skm/skm_mallcrasher` | `skirmish` | `598935744` (r200 sig) |

r200 patched the skirmish heist only. The earlier `level_aliases` change made
the standard Vlad job select the skirmish block; the CRC gate then logged
`mismatch` (observed at 18:42:54, `outdated navigation patch! (75811735)`).
Reverted:

- `_navdatapatches.lua`: `skm_mallcrasher` block only, no `mallcrasher` sig.
- `coreworlddefinition.lua` / `coremissionmanager.lua`: `skm_mallcrasher`
  branches only (door blocker + obstacle stay skirmish-only).
- `corecode.lua`: no `map_change_mallcrasher` key.
- Harness P7 plan: no `mallcrasher` auto-dump; only `skm_mallcrasher`.

The standard Vlad job is now unpatched (`skip_nopatch` when map patches are
on). The skirmish block is dead at v6 (`skip_dead`): its 8<->11 link is
carried by 2 navlinks, not a door, and the skirmish quad ids differ from the
standard job (door 1343 quads 844/61; quad 943 belongs to segment 37). A
navlink seal needs an engine-side expression. A separate standard-Mallcrasher
fix would need its own nav data pass and mission-element ids; it is out of
r200 scope.

## Player POV

The standard Mallcrasher keeps vanilla AI behaviour. The r200 vase-store
blocker and seal remain a skirmish (Crime Spree) feature; at v6 the seal is
dead because the link is navlink-only, so skirmish cops can still cross it.
