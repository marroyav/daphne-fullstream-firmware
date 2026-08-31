#!/bin/sh
set -eu

ROOT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")/../.." && pwd)
TEST_ROOT=$(mktemp -d)

cleanup() {
  rm -rf -- "$TEST_ROOT"
}
trap cleanup EXIT HUP INT TERM

mkdir -p \
  "$TEST_ROOT/fake-bin" \
  "$TEST_ROOT/scripts/fusesoc" \
  "$TEST_ROOT/xilinx"

cp "$ROOT_DIR/scripts/fusesoc/vivado_batch_hook.sh" \
  "$TEST_ROOT/scripts/fusesoc/vivado_batch_hook.sh"

cat >"$TEST_ROOT/fake-bin/vivado" <<'FAKE_VIVADO'
#!/bin/sh
set -eu
: >"$DAPHNE_TEST_VIVADO_LOCK"
trap 'rm -f "$DAPHNE_TEST_VIVADO_LOCK"' EXIT HUP INT TERM
printf '%s\n' vivado >>"$DAPHNE_TEST_TRACE"
exit "${DAPHNE_TEST_VIVADO_RC:-0}"
FAKE_VIVADO

cat >"$TEST_ROOT/scripts/fusesoc/package_fullstream_overlay.sh" <<'FAKE_PACKAGE'
#!/bin/sh
set -eu
if [ -e "$DAPHNE_TEST_VIVADO_LOCK" ]; then
  echo "ERROR: packaging started before Vivado exited." >&2
  exit 1
fi
printf 'package|%s|%s\n' "$1" "$2" >>"$DAPHNE_TEST_TRACE"
FAKE_PACKAGE

chmod +x \
  "$TEST_ROOT/fake-bin/vivado" \
  "$TEST_ROOT/scripts/fusesoc/package_fullstream_overlay.sh"

trace="$TEST_ROOT/trace.log"
lock="$TEST_ROOT/vivado.lock"
output="$TEST_ROOT/xilinx/output-abcdef0"

run_hook() {
  (
    cd "$TEST_ROOT"
    PATH="$TEST_ROOT/fake-bin:$PATH" \
      DAPHNE_GIT_SHA=abcdef0 \
      DAPHNE_OUTPUT_DIR="$output" \
      DAPHNE_TEST_TRACE="$trace" \
      DAPHNE_TEST_VIVADO_LOCK="$lock" \
      DAPHNE_TEST_VIVADO_RC="${1:-0}" \
      sh scripts/fusesoc/vivado_batch_hook.sh
  )
}

run_hook
expected=$(printf 'vivado\npackage|%s|abcdef0' "$output")
actual=$(cat "$trace")
if [ "$actual" != "$expected" ]; then
  echo "ERROR: unexpected successful-build call order:" >&2
  printf '%s\n' "$actual" >&2
  exit 1
fi

if find "$TEST_ROOT/xilinx" -maxdepth 1 \
  -name '.daphne-fullstream-vivado-shim.*.tcl' | grep -q .; then
  echo "ERROR: the Vivado environment shim was not removed." >&2
  exit 1
fi

: >"$trace"
set +e
run_hook 9
failure_rc=$?
set -e

if [ "$failure_rc" -ne 9 ]; then
  echo "ERROR: expected Vivado failure 9, got $failure_rc." >&2
  exit 1
fi

if [ "$(cat "$trace")" != vivado ]; then
  echo "ERROR: packaging ran after Vivado failed." >&2
  exit 1
fi

if grep -q 'package_fullstream_overlay.sh' \
  "$ROOT_DIR/xilinx/daphne_fullstream_vivado_flow.tcl"; then
  echo "ERROR: overlay packaging must not run inside Vivado Tcl." >&2
  exit 1
fi

echo "RESULT: PASS - overlay packaging starts only after Vivado exits"
