#!/bin/sh
set -eu

ROOT_DIR="${DAPHNE_FULLSTREAM_ROOT:-$(CDPATH= cd -- "$(dirname -- "$0")/../.." && pwd)}"
DEFAULT_CORE="dune-daq:daphne-fullstream:k26c-platform:0.1.0"
DEFAULT_MODULAR_CORE="dune-daq:daphne-fullstream:k26c-modular-platform:0.1.0"

DRY_RUN=0
PLATFORM_CORE="${DAPHNE_PLATFORM_CORE:-$DEFAULT_CORE}"
DAPHNE_MAKE="${DAPHNE_MAKE:-make}"

usage() {
  cat <<EOF
Usage: $(basename "$0") [options]

Build the fullstream firmware through the repo-local FuseSoC platform layer.

Options:
  --platform-core <VLNV>  Use an explicit platform core
  --modular               Use $DEFAULT_MODULAR_CORE
  --dry-run               Resolve the platform core and print what would run
  -h, --help              Show this help text
EOF
}

while [ "$#" -gt 0 ]; do
  case "$1" in
    --platform-core)
      shift
      [ "$#" -gt 0 ] || {
        echo "ERROR: --platform-core requires a VLNV argument." >&2
        exit 2
      }
      PLATFORM_CORE="$1"
      ;;
    --modular)
      PLATFORM_CORE="$DEFAULT_MODULAR_CORE"
      ;;
    --dry-run)
      DRY_RUN=1
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "ERROR: unknown argument '$1'." >&2
      usage >&2
      exit 2
      ;;
  esac
  shift
done

case "$PLATFORM_CORE" in
  dune-daq:daphne-fullstream:k26c-platform:0.1.0|dune-daq:daphne-fullstream:k26c-modular-platform:0.1.0)
    BOARD="k26c"
    ;;
  *)
    echo "ERROR: unsupported platform core '$PLATFORM_CORE'." >&2
    echo "Supported cores today are:" >&2
    echo "  $DEFAULT_CORE" >&2
    echo "  $DEFAULT_MODULAR_CORE" >&2
    exit 2
    ;;
esac

CORE_BUILD_ID=$(printf '%s' "$PLATFORM_CORE" | tr ':' '_')
FUSESOC_WORK_ROOT="${DAPHNE_FUSESOC_IMPL_WORK_ROOT:-$ROOT_DIR/build/$CORE_BUILD_ID/impl-vivado}"

cd "$ROOT_DIR"
"$ROOT_DIR/scripts/fusesoc/refresh_cores.sh" >/dev/null
"$ROOT_DIR/scripts/fusesoc/fusesoc.sh" core-info "$PLATFORM_CORE" >/dev/null

echo "INFO: Selected FuseSoC platform core: $PLATFORM_CORE"
echo "INFO: Resolved board profile: $BOARD"
echo "INFO: Build mode: impl"
echo "INFO: FuseSoC stage: setup"
echo "INFO: Generated Make target: pre_build"
echo "INFO: FuseSoC work root: $FUSESOC_WORK_ROOT"

export DAPHNE_BOARD="$BOARD"
export DAPHNE_PLATFORM_CORE="$PLATFORM_CORE"

if [ "$DRY_RUN" -eq 1 ]; then
  echo "INFO: Dry-run only, stopping before Vivado."
  exit 0
fi

"$ROOT_DIR/scripts/fusesoc/fusesoc.sh" run \
  --setup \
  --work-root "$FUSESOC_WORK_ROOT" \
  --target impl \
  "$PLATFORM_CORE"

if [ ! -s "$FUSESOC_WORK_ROOT/Makefile" ]; then
  echo "ERROR: FuseSoC setup did not generate $FUSESOC_WORK_ROOT/Makefile." >&2
  exit 2
fi

# The qualified Vivado flow is the pre_build hook.  Do not ask Edalize to run
# its generic build/post_build stage: that stage creates a second Vivado
# project and launches a redundant synth_1 after the repo-owned flow has
# already produced and packaged the release artifacts.
echo "INFO: Running the repo-owned fullstream build hook."
exec "$DAPHNE_MAKE" -C "$FUSESOC_WORK_ROOT" pre_build
