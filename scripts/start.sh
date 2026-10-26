#!/bin/zsh
# usage: scripts/start.sh [port]   (rebuilds the site from results/*.jsonl and serves it; default port 8000)
set -e
cd "${0:A:h}/.."
P=${1:-8000}
node site/build.mjs
open "http://localhost:$P/"
python3 -m http.server $P --bind 127.0.0.1 -d site/dist
