#!/bin/zsh
# cachegrind on linux binaries in out/: typical x86-style cache, 64B lines: I1/D1 = 32K/8w, LL = 8M/16w (stands in for L3, no L2 modeled)
cd "${0:A:h}/.."
mkdir -p results
: > results/cachegrind.jsonl
for c in 0 12 28 60 124; do
  for v in oop dod; do
    r=$(docker run --rm -v $PWD/out:/w -w /w cg valgrind --tool=cachegrind --cache-sim=yes \
      --I1=32768,8,64 --D1=32768,8,64 --LL=8388608,16,64 --cachegrind-out-file=/dev/null ./$v-$c 2>&1)
    refs=$(print -r -- "$r" | awk '/D refs/{print $4}')
    d1=$(print -r -- "$r" | awk '/D1  misses/{print $4}')
    ll=$(print -r -- "$r" | awk '/LL misses/{print $4}')
    print "$v cold=$c  Drefs=$refs  D1miss=$d1  LLmiss=$ll"
    print "{\"variant\":\"$v\",\"cold\":$c,\"drefs\":${refs//,/},\"d1_misses\":${d1//,/},\"ll_misses\":${ll//,/}}" >> results/cachegrind.jsonl
  done
done
