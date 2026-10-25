# Iter menu options

Menu path: **Options → Mod Options → Iter**.

The release defaults match original Iter: navigation, path extender, map
patches and the idle cosmetic are on. The menu only exposes the player-facing
switches; the subsystem flags live in the settings file for troubleshooting.

## Player options

### Improve NPC pathing (`nav_overlay`)

Master switch for the restored r200 navigation core (v6 geometry shim,
streamline, coarse search, nav-link queue, AI wrappers, direct-to-pos, path
extender).

- Default: **ON**.
- Off: Iter behaves like Iter Lite; no nav rebuild or nav hooks.
- Takes effect on the next heist load.

### Rebuild NavLinks (`rebuild_navlinks`)

The r200 SO nav-link vector rebuild kept from the Lite build.

- Default: **ON**.
- Takes effect on the next heist load.

### Map toggles (`map_change_<level>`)

One toggle per level, grouped after a divider. They only apply when the
internal `map_patches` flag is on (release default: on).

- Default: **ON** for every level.
- Levels whose patch is dead at v6 log `skip_dead`; CRC mismatches log
  `mismatch` and skip safely.
- Current status: 21 clean blocks (22 level ids), 2 accepted losses (moon,
  peta), 1 dead (`skm_mallcrasher`), dinner/flat no-ops. The standard Vlad
  Mallcrasher is a different heist and is not patched.

## Settings-only (troubleshooting)

These are not in the menu. Edit `mods\saves\iter.txt` with the game closed,
then relaunch. Missing keys fall back to the defaults below.

| Setting | Default | Meaning |
|---|---|---|
| `nav_streamline` | `true` | choke-point proxies + path streamliner |
| `nav_search` | `true` | Iter weighted coarse search + cache |
| `nav_ai` | `true` | Iter AI wrappers |
| `navlink_queue` | `true` | nav-link intervals/queue/reservations/alternates |
| `path_extender` | `true` | live path appending + shortcut finder |
| `direct_to_pos` | `true` | whisper-mode straight-line objectives |
| `map_patches` | `true` | master gate for every `map_change_*` toggle |
| `cop_idle_fix` | `true` | cosmetic idle animation variant |
| `debug_log` | `1` | 0 errors only, 1 summaries/errors, 2 verbose |

`streamline_path` is a legacy original-Iter key. It is removed on load; an
old file with `streamline_path=false` and no `nav_overlay` key is migrated to
`nav_overlay=false` so a player who disabled original Iter stays disabled.

## Notes

- Changing a toggle takes effect on the next heist load.
- `map_patches` can be turned off in `iter.txt` to disable every map fix while
  keeping the nav core.
- The `!iter` chat commands are a dev harness and are not shipped.
