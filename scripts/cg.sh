#!/bin/zsh
# cachegrind on linux binaries in out/: D1 = 64K/4w/128B, "LL" = L2 4M/16w/128B
cd "${0:A:h}/.."
mkdir -p results
: > results/cachegrind.jsonl
for c in 0 12 28 60 124; do
  for v in oop dod; do
    r=$(docker run --rm -v $PWD/out:/w -w /w cg valgrind --tool=cachegrind --cache-sim=yes \
      --I1=65536,4,128 --D1=65536,4,128 --LL=4194304,16,128 --cachegrind-out-file=/dev/null ./$v-$c 2>&1)
    refs=$(print -r -- "$r" | awk '/D refs/{print $4}')
    d1=$(print -r -- "$r" | awk '/D1  misses/{print $4}')
    l2=$(print -r -- "$r" | awk '/LL misses/{print $4}')
    print "$v cold=$c  Drefs=$refs  D1miss=$d1  L2miss=$l2"
    print "{\"variant\":\"$v\",\"cold\":$c,\"drefs\":${refs//,/},\"d1_misses\":${d1//,/},\"l2_misses\":${l2//,/}}" >> results/cachegrind.jsonl
  done
done
