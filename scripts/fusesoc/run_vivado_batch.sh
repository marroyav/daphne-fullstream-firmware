#!/bin/sh
set -eu

ROOT_DIR="${DAPHNE_FULLSTREAM_ROOT:-$(CDPATH= cd -- "$(dirname -- "$0")/../.." && pwd)}"
BOARD="${DAPHNE_BOARD:-k26c}"
PLATFORM_CORE="${DAPHNE_PLATFORM_CORE:-}"

case "$BOARD" in
  k26c)
    ;;
  *)
    echo "ERROR: unknown board '$BOARD'." >&2
    echo "The imported fullstream Tcl flow is currently qualified only for DAPHNE_BOARD=k26c." >&2
    exit 2
    ;;
esac

if ! command -v vivado >/dev/null 2>&1; then
  echo "ERROR: vivado is not installed or not on PATH." >&2
  exit 2
fi

if [ -n "$PLATFORM_CORE" ]; then
  echo "INFO: Building via FuseSoC platform core $PLATFORM_CORE"
fi

cd "$ROOT_DIR/xilinx"
exec vivado -mode batch -source vivado_batch.tcl
