#!/bin/zsh
# usage: scripts/asm.sh   (extracts the timed update region from out/*.s into results/asm.jsonl; run after scripts/run.sh)
cd "${0:A:h}/.."
mkdir -p results
: > results/asm.jsonl
for c in 0 12 28 60 124; do
  for v in oop dod; do
    # lines between the two clock_gettime calls, minus assembler directives and debug labels
    awk -v v=$v -v c=$c '
      /bl\tclock_gettime/ { n++; next }
      n == 1 && !/^\t\./ && !/^\.Ltmp/ { gsub(/\t/, " "); sub(/^ +/, ""); a[++m] = $0 }
      END {
        printf "{\"variant\":\"%s\",\"cold\":%d,\"lines\":[", v, c
        for (i = 1; i <= m; i++) printf "%s\"%s\"", (i > 1 ? "," : ""), a[i]
        print "]}"
      }' out/$v-$c.s >> results/asm.jsonl
  done
done
