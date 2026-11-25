# Cache Hunt (Zig)

A grid deduction game for the terminal, written in Zig (0.13, standard
library only).

Three supply caches are hidden on a 6x6 grid and you have 12 probes.
Probe a cell by typing its coordinates; a miss reports the Manhattan
distance to the nearest remaining cache, so every probe narrows the
search. Find all three before the probes run out.

## Build

```sh
zig build -Doptimize=ReleaseSafe
# binary lands in zig-out/bin/cache-hunt
```

## Play

```sh
./zig-out/bin/cache-hunt              # random hiding places
./zig-out/bin/cache-hunt --seed 42    # reproducible hiding places
```

Type `x y` to probe a cell, `quit` to stop.

## Tested envelope

- Builds clean with Zig 0.13.0 (`zig build -Doptimize=ReleaseSafe`).
- Verified end to end with scripted stdin playthroughs on `--seed 42`:
  a full win (all three caches recovered) and an out-of-probes path,
  both reaching the game-over screen.
