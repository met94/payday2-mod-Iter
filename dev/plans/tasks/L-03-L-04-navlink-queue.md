# L-03/L-04 — nav-link reservation, queue, and alternates

Status: designed, blocked on T2 (streamline/proxy runtime data).
Depends on: L-01/L-02 (element map, intervals), S-01/S-02 (proxies).
Unblocks: T3, P6 path extender.

## Intent

Reduce queues and conga lines at ladders/jumps/climbs:

- reserve a nav link for one unit at a time;
- estimate wait from the interval, current queue, planned use, and the
  current holder's distance;
- switch to a sibling link when the current one is busy;
- release the reservation when the animation starts or the action ends.

## r200 mechanism (to reimplement, not copy)

`lua/copactionwalk.lua` (r200, commit `98940fb`):

- `itr_prepare_for_upcoming_navlink` (server block) — initialise reservation
  and queue fields on the nav-link element.
- `itr_reserve_navlink` — compare `itr_wait_for_navlink_availability_t` with
  `itr_navlink_queue_previous_oldest_t`; set `itr_reserved_by_unit`.
- `itr_switch_to_sibling_navlink` — 0.5 s reroute guard; use
  `itr_get_alternate_navlink`; rebuild `_simplified_path`.
- `_play_nav_link_anim` wrapper — `itr_check_navlink_delay` +
  `itr_set_navlink_delay` + clear reservation.
- `itr_clear_navlink_reservation` — nil the holder; update queue timestamps.
- `itr_get_alternate_navlink` — delegates to
  `NavigationManager:itr_find_best_navlink`.

`lua/navigationmanager.lua`:

- `_navlink_planned_use` — per-link timestamps of planned use.
- `itr_find_best_navlink` — interval + queue + holder distance estimate.
- `itr_get_accessibility` — congestion cost for the coarse search.

## 248.2 constraints

- Element map now exists (`NavigationManager.itr_navlink_elements`).
- `delay_time`/`set_delay_time` still exist on the link object.
- `CopActionWalk` internals changed; `_init`, `_play_nav_link_anim`,
  `_upd_nav_link_first_frame` are stable wrapper points (dossiers).
- The nav-link prepare call is server-only; `_init` now guards it (R9).
- `_simplified_path` entries are `{element=..., c_class=...}` for links.

## Target design

1. Add a `IterNavLinks` table on the nav manager:
   - `queue_length`, `reserved_by_unit`, `previous_oldest_t`,
     `planned_use` per key;
   - `reserve(key, unit, t)`, `release(key, unit)`, `wait_estimate(key, unit, near_pos, t)`.
2. Gate the whole subsystem on `navlink_queue` (default false); AI cluster
   remains behind `nav_ai`.
3. In `CopActionWalk`:
   - `_init` wrapper calls prepare when `navlink_queue` is on and the method
     exists;
   - `_play_nav_link_anim` wrapper checks the delay and releases on start;
   - `_upd_nav_link_first_frame` keeps the r200 wrapper;
   - switch only when the sibling is strictly better and the reroute guard
     (0.5 s) has elapsed.
4. Use `nav:itr_find_best_navlink` for alternates; it must return a link and
   element, or nil.
5. Counters: `navlink_wait`, `navlink_switch_ok`, `navlink_switch_fail`,
   `navlink_queue_max`.

## Acceptance (T3)

- `navlink_queue=true, nav_ai=true` on Hotline Miami D1 / Biker Heist D2:
  - `evt=navlink` elements>0;
  - `navlink_queue_max` bounded (initial threshold: <= 4; tune);
  - no unit waiting > 2 intervals without switching or moving;
  - no `[ITER-ERR]`, no stuck AI, no crash.
- With `navlink_queue=false`, T1/T2 behaviour unchanged.
- Offline tests for reserve/release/wait estimate with stub links.

## Cost if wrong

Units can still queue (vanilla), or a bad estimate can cause unnecessary
switches. The flag turns the subsystem off; T3 catches stuck units.
