#!/bin/zsh
# usage: scripts/start.sh [port]   (serves the repo so site/index.html can read results/*.jsonl; default port 8000)
set -e
cd "${0:A:h}/.."
P=${1:-8000}
open "http://localhost:$P/site/"
python3 -m http.server $P --bind 127.0.0.1
