#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
export PATH="${HOME}/.local/bin:${HOME}/.local/lib/fpc/3.2.2:${PATH}"
mkdir -p "$ROOT/bin"
fpc -O2 -Fu"$ROOT/src" -FE"$ROOT/bin" "$ROOT/src/pascalanything.lpr"
ln -sfn "$ROOT/bin/pascalanything" "${HOME}/.local/bin/pascal-anything"
echo "built $ROOT/bin/pascalanything"
