# T5 path extender card

Goal: exercise `itr_append_next_step` while a cop is running. Every earlier
run had `path_ahead=0` because no test cop ever entered the extensible state
(`_haste == 'run'`, not curved, not `path_simplified`).

## Setup

1. Menu: **Dev: v6 navigation overlay** ON, **Dev: AI cluster** ON,
   **Dev: path extender** ON. Restart the heist after toggling.
2. Start a heist where a cop will run for several seconds:
   - convert a cop with a Joker (it becomes friendly and follows you), or
   - trigger chase mode (`!iter assault` also works), or
   - use a long assault wave on a big level.

## Run

1. Every ~30 s, one command per chat line:
   - `!iter ai`
   - `!iter dump`
2. Watch the `!iter ai` counters:
   - `path_ahead` > 0: at least one cop is in the extensible state;
   - `extend(ok=N skip=M)`: `ok` must rise, `skip` may rise (not extensible).
3. Watch the cop on screen: it must not slide, stop, or replay an animation at
   the append point. The action should continue straight through the join.
4. At the end of the run, note the summary counters:
   `!iter dump` and the `[ITER-NAV] evt=summary` line.

## Pass

Log scan with `dev/test/cards/T5-extender.json`:

```powershell
node dev\tools\log-scan.mjs "<game log>" --mod . --card dev\test\cards\T5-extender.json
```

Expect `summary.path_extend_ok > 0`, `iterErrors 0`, `fatal 0`,
`fallback 0`. A run with `path_ahead=0` everywhere does not test the extender
and does not count.
