#!/usr/bin/env bash
#
# Build GP2040-CE firmware for a single board.
# Configuration lives in .env (copy .env.example -> .env and edit).
#
set -euo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$REPO"

# --- load config ---
if [ ! -f .env ]; then
  echo "ERROR: .env not found. Copy .env.example to .env and edit it." >&2
  exit 1
fi
set -a; . ./.env; set +a

: "${GP2040_BOARDCONFIG:?set GP2040_BOARDCONFIG in .env}"
: "${PICO_SDK_PATH:?set PICO_SDK_PATH in .env}"
export SKIP_WEBBUILD="${SKIP_WEBBUILD:-TRUE}"

# Prefer the pinned Arm toolchain (bundles newlib) when provided.
if [ -n "${ARM_TOOLCHAIN_BIN:-}" ] && [ -d "$ARM_TOOLCHAIN_BIN" ]; then
  export PATH="$ARM_TOOLCHAIN_BIN:$PATH"
fi

# --- preflight ---
command -v arm-none-eabi-gcc >/dev/null || { echo "ERROR: arm-none-eabi-gcc not on PATH (set ARM_TOOLCHAIN_BIN in .env)." >&2; exit 1; }
[ -d "$PICO_SDK_PATH" ] || { echo "ERROR: PICO_SDK_PATH not found: $PICO_SDK_PATH" >&2; exit 1; }
if [ "$SKIP_WEBBUILD" = "TRUE" ] && [ ! -f lib/httpd/fsdata.c ]; then
  echo "ERROR: SKIP_WEBBUILD=TRUE but lib/httpd/fsdata.c is missing." >&2
  echo "       Run once with SKIP_WEBBUILD=FALSE to generate it." >&2
  exit 1
fi

echo "Board: $GP2040_BOARDCONFIG | SDK: $PICO_SDK_PATH | SkipWeb: $SKIP_WEBBUILD | Branch: $(git branch --show-current)"

# --- build ---
rm -rf build
mkdir build && cd build
cmake ..
make -j"$(nproc 2>/dev/null || sysctl -n hw.ncpu)"

echo "Done:"
ls -1 GP2040-CE_*_"$GP2040_BOARDCONFIG".uf2
