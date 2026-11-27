#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
mkdir -p "$ROOT/bin"

# Prefer user-local FPC when present (Linux/macOS installs).
if [[ -d "${HOME}/.local/bin" ]]; then
  export PATH="${HOME}/.local/bin:${PATH}"
fi
if [[ -d "${HOME}/.local/lib/fpc" ]]; then
  # Newest or common 3.2.x layout
  for d in "${HOME}/.local/lib/fpc/"*/; do
    export PATH="${d%/}:${PATH}"
  done
fi

command -v fpc >/dev/null || { echo "fpc not found on PATH" >&2; exit 1; }

fpc -O2 -Fu"$ROOT/src" -FE"$ROOT/bin" "$ROOT/src/pascalanything.lpr"

BIN="$ROOT/bin/pascalanything"
LINK_NAME="pascal-anything"
echo "built $BIN"

install_link() {
  local dest="$1"
  mkdir -p "$(dirname "$dest")"
  ln -sfn "$BIN" "$dest" 2>/dev/null || cp -f "$BIN" "$dest"
  echo "installed $dest"
}

case "$(uname -s)" in
  Darwin|Linux)
    if [[ -d "${HOME}/.local/bin" ]] || mkdir -p "${HOME}/.local/bin" 2>/dev/null; then
      install_link "${HOME}/.local/bin/${LINK_NAME}"
    fi
    ;;
  *)
    echo "On this OS, add $ROOT/bin to PATH (binary: pascalanything)."
    ;;
esac
