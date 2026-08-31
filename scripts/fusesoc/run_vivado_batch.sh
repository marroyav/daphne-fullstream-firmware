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

if [ -z "${DAPHNE_GIT_SHA:-}" ]; then
  DAPHNE_GIT_SHA=$(git -C "$ROOT_DIR" rev-parse --short=7 HEAD)
fi
: "${DAPHNE_OUTPUT_DIR:=$ROOT_DIR/xilinx/output-$DAPHNE_GIT_SHA}"

export DAPHNE_GIT_SHA
export DAPHNE_OUTPUT_DIR

cd "$ROOT_DIR/xilinx"
vivado -mode batch -source vivado_batch.tcl

echo "INFO: Vivado exited successfully; packaging the Linux overlay in a clean process."
sh "$ROOT_DIR/scripts/fusesoc/package_fullstream_overlay.sh" \
  "$DAPHNE_OUTPUT_DIR" "$DAPHNE_GIT_SHA"
