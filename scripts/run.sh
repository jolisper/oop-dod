#!/bin/zsh
# usage: scripts/run.sh   (builds linux binaries into out/, times them in the cg container, then runs cachegrind on them via scripts/cg.sh; needs the image: docker build -t cg docker)
set -e
cd "${0:A:h}/.."
mkdir -p out results
: > results/timing.jsonl
for c in 0 12 28 60 124; do
  sed -i '' "s/^pub const cold = [0-9]*;/pub const cold = $c;/" src/config.zig
  for v in oop dod; do
    zig build-exe -OReleaseFast -lc -target aarch64-linux-gnu -femit-bin=out/$v-$c -femit-asm=out/$v-$c.s src/$v.zig
    for i in 1 2 3; do
      r=$(docker run --rm -v $PWD/out:/w -w /w cg ./$v-$c 2>&1)
      print -r -- $r
      print -r -- $r | awk -v v=$v -v c=$c -v i=$i '{sub("ms=","",$4); printf "{\"variant\":\"%s\",\"cold\":%d,\"run\":%d,\"ms\":%d}\n", v, c, i, $4}' >> results/timing.jsonl
    done
  done
done
sed -i '' "s/^pub const cold = [0-9]*;/pub const cold = 60;/" src/config.zig
rm -f out/*.o(N)
scripts/cg.sh
scripts/asm.sh
