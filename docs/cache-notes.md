# Understanding caches through the OOP vs DOD experiment

Memory is slow, caches hide that by moving whole lines of nearby data, and
your data layout decides how much of each line is useful.

## Core ideas, mapped to this experiment

1. **Memory is far slower than the CPU.** A DRAM access costs hundreds of
   cycles, an L1 hit a few. Caches exist to bridge that gap.
2. **Data moves in lines (64 or 128 B), not bytes.** Touching `health` loads
   its whole line.
3. **Locality makes caches work.** Sequential access means one miss pays for
   many hits. A cache only helps if the rest of each loaded line gets used.
4. **Layout decides line utilization.**
   - OOP: one useful 4-byte `health` per 16-128 byte entity, so most of each
     line is wasted.
   - DOD: every byte of the line is `health`, so 32 values per 128 B line.
5. **Capacity decides which level serves you.** Once the working set exceeds
   L2, misses go to DRAM (the `cold>=12` OOP rows).
6. **Prefetchers and parallelism soften the penalty.** That is why the
   slowdown was about 20x and not the raw latency ratio.

## Ways to build the understanding

- **Predict, then measure.** Before changing `cold`, `n`, or line assumptions,
  write down the expected D1 and L2 misses (`n * k * size / line`), then
  compare with `scripts/cg.sh`.
- **Vary one thing at a time:**
  - Shrink `n` so the OOP array fits in L2, and see the cliff disappear.
  - Change the simulated line size in `scripts/cg.sh` to 64 B and watch the
    saturation point move.
  - Try stride-N access over a flat array, for a pure line-size experiment.
  - Randomize the access order to defeat the prefetcher.
- **Read:**
  - Drepper, *What Every Programmer Should Know About Memory* (2007), free and
    software-focused.
  - Hennessy & Patterson, *Computer Architecture: A Quantitative Approach*,
    cache chapters.
  - Mike Acton's data-oriented design talks, for the layout argument.
  - Handy, *The Cache Memory Book*, for fundamentals only; it predates
    multicore, prefetchers and modern hierarchies.
- **Measure real hardware** with Instruments, or `perf` on Linux, to see where
  the simulation and the chip differ.

## Notes on this repo's setup

- `scripts/cg.sh` simulates 64 KB 4-way L1 and a 4 MB 16-way last level, both with
  128 B lines, approximating Apple Silicon. Canonical x86 is 64 B lines,
  32-48 KB 8-12-way L1, private L2, shared L3. These figures are an
  approximation, not checked against Apple's specs.
- `page_allocator` hints each mmap below the previous block. Under valgrind the
  first block sits at a low address, so the hint wraps and mmap fails with
  EINVAL. `dod.zig` allocates `cold` first to avoid it.
