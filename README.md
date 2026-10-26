# oop-dod

A small Zig benchmark showing how memory layout affects cache behaviour.

The same loop increments a `health` field on 1M entities, 100 passes. Each
entity also carries `cold` bytes of data the loop never reads.

- **OOP** (`src/oop.zig`): array of structs. `health` and the cold bytes share
  an entity, so every cache line loaded for `health` is mostly cold data.
- **DOD** (`src/dod.zig`): struct of arrays. `health` is packed in its own
  array and the cold data lives in a separate one that the loop never touches.

The benchmark repeats this for `cold` = 0, 12, 28, 60 and 124 bytes. OOP slows
down as `cold` grows (about 20x at 124 bytes). DOD stays flat.

See [docs/cache-notes.md](docs/cache-notes.md) for the cache concepts behind it.

## Requirements

- [Zig](https://ziglang.org/) (developed with 0.17-dev)
- Docker
- Python 3 (only to serve the results page)
- macOS with zsh. The scripts use macOS `sed -i ''` and `open`.

## Usage

Build the container image once. It is Ubuntu plus valgrind:

```
docker build -t cg docker
```

Run everything:

```
scripts/run.sh
```

For each `cold` size this cross-compiles both variants for
`aarch64-linux-gnu` into `out/`, runs each 3 times in the container for
wall-clock time, then runs `scripts/cg.sh`. That runs both variants under
cachegrind and reports data references, L1 data misses and last-level misses.
`scripts/cg.sh` can also be run on its own to reuse the binaries in `out/`.

Results are written to `results/` as JSON Lines, one datapoint per line,
overwritten on each run:

| File | Fields |
|---|---|
| `timing.jsonl` | `variant`, `cold`, `run`, `ms` |
| `cachegrind.jsonl` | `variant`, `cold`, `drefs`, `d1_misses`, `ll_misses` |

View the results as charts:

```
scripts/start.sh [port]
```

This serves the repo and opens `http://localhost:8000/site/` (or the port you
give). The page reads `results/*.jsonl` when it loads, so after a new benchmark
run just reload it; there is no build step.

## Layout

```
src/       oop.zig  dod.zig  config.zig   benchmark programs and parameters
scripts/   run.sh  cg.sh  start.sh        run, cachegrind, view
docker/    Dockerfile                     valgrind image
site/      index.html                     static results page (reads results/)
results/   *.jsonl                        benchmark datapoints
docs/      cache-notes.md                 background notes
out/       build outputs (ignored)
```

## Notes

- `src/config.zig` holds `cold`, `n` (entities) and `k` (passes). `run.sh`
  rewrites `cold` for each build and resets it to 60 at the end.
- The cachegrind cache model is a typical x86-style one: 32 KB 8-way L1, 8 MB
  16-way last level (standing in for L3, no L2 modeled), 64 B lines. The
  wall-clock runs happen on the real host CPU (Apple Silicon, 128 B lines), so
  the two measurements use different cache designs.
- `dod.zig` allocates `cold` before `health` on purpose. Under valgrind, Zig's
  `page_allocator` hints each mmap below the previous block, and that hint
  wraps and fails when a large allocation follows a small one.
