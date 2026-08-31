#!/bin/sh
set -eu

ROOT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")/../.." && pwd)
TEST_ROOT=$(mktemp -d)
BUILD_SHA=abcdef0
BUILD_NAME="daphne_fullstream_$BUILD_SHA"
OVERLAY_NAME="daphne_fullstream_ol_$BUILD_SHA"
OUTPUT_DIR="$TEST_ROOT/output"
OVERLAY_DIR="$OUTPUT_DIR/$OVERLAY_NAME"
FAKE_BIN="$TEST_ROOT/fake-bin"

cleanup() {
  rm -rf -- "$TEST_ROOT"
}
trap cleanup EXIT HUP INT TERM

mkdir -p "$FAKE_BIN" "$OVERLAY_DIR"

for tool in sha256sum unzip dtc python3; do
  printf '#!/bin/sh\nexit 0\n' >"$FAKE_BIN/$tool"
  chmod +x "$FAKE_BIN/$tool"
done

write_fixture() {
  path="$1"
  mkdir -p "$(dirname -- "$path")"
  printf 'fixture\n' >"$path"
}

for relative_path in \
  "$BUILD_NAME.bit" \
  "$BUILD_NAME.bin" \
  "$BUILD_NAME.xsa" \
  probes.ltx \
  "$OVERLAY_NAME.zip" \
  "$OVERLAY_NAME/$OVERLAY_NAME.bin" \
  "$OVERLAY_NAME/$OVERLAY_NAME.dtbo" \
  "$OVERLAY_NAME/shell.json" \
  post_route_timing_summary.rpt \
  post_route_bus_skew.rpt \
  post_route_cdc.rpt \
  post_route_methodology.rpt \
  post_route_status.rpt \
  post_route_power.rpt \
  post_route_util.rpt \
  post_imp_drc.rpt \
  release_cells.rpt
do
  write_fixture "$OUTPUT_DIR/$relative_path"
done

: >"$OUTPUT_DIR/SHA256SUMS"
for relative_path in \
  "$BUILD_NAME.bit" \
  "$BUILD_NAME.bin" \
  "$BUILD_NAME.xsa" \
  probes.ltx \
  "$OVERLAY_NAME.zip" \
  "$OVERLAY_NAME/$OVERLAY_NAME.bin" \
  "$OVERLAY_NAME/$OVERLAY_NAME.dtbo" \
  "$OVERLAY_NAME/shell.json" \
  post_route_timing_summary.rpt \
  post_route_bus_skew.rpt \
  post_route_cdc.rpt \
  post_route_methodology.rpt \
  post_route_status.rpt \
  post_route_power.rpt \
  post_route_util.rpt \
  post_imp_drc.rpt \
  release_cells.rpt
do
  printf '0000000000000000000000000000000000000000000000000000000000000000  %s\n' \
    "$relative_path" >>"$OUTPUT_DIR/SHA256SUMS"
done

printf 'All user specified timing constraints are met.\n' \
  >"$OUTPUT_DIR/post_route_timing_summary.rpt"
printf 'Slack (MET)\n' >"$OUTPUT_DIR/post_route_bus_skew.rpt"
printf '# of nets with routing errors : 0\n' \
  >"$OUTPUT_DIR/post_route_status.rpt"
printf 'GT_CHANNEL_COUNT=4\nMUX_ASYNC_REG_COUNT=6\n' \
  >"$OUTPUT_DIR/release_cells.rpt"
printf 'No error-level DRC violations.\n' >"$OUTPUT_DIR/post_imp_drc.rpt"

run_checker() {
  log_path="$1"
  set +e
  PATH="$FAKE_BIN:$PATH" DAPHNE_FULLSTREAM_ROOT="$ROOT_DIR" \
    sh "$ROOT_DIR/scripts/fusesoc/check_build_outputs.sh" \
      "$OUTPUT_DIR" "$BUILD_SHA" >"$log_path" 2>&1
  checker_rc=$?
  set -e
  return "$checker_rc"
}

printf 'CDC report contains no critical classifications.\n' \
  >"$OUTPUT_DIR/post_route_cdc.rpt"
printf 'Methodology report contains no elevated warnings.\n' \
  >"$OUTPUT_DIR/post_route_methodology.rpt"
if ! run_checker "$TEST_ROOT/clean.log"; then
  echo "ERROR: clean implementation reports did not pass." >&2
  cat "$TEST_ROOT/clean.log" >&2
  exit 1
fi
grep -Fq 'RESULT: PASS.' "$TEST_ROOT/clean.log"

printf 'CDC-1 Critical unsafe clock-domain crossing\n' \
  >"$OUTPUT_DIR/post_route_cdc.rpt"
if run_checker "$TEST_ROOT/cdc-critical.log"; then
  echo "ERROR: a critical CDC classification did not fail the release gate." >&2
  exit 1
fi
grep -Fq 'FAIL  Vivado reports unwaived critical CDC classifications' \
  "$TEST_ROOT/cdc-critical.log"
grep -Fq 'RESULT: FAILED.' "$TEST_ROOT/cdc-critical.log"

printf 'CDC report contains no critical classifications.\n' \
  >"$OUTPUT_DIR/post_route_cdc.rpt"
printf 'Critical Warning: unsafe implementation methodology\n' \
  >"$OUTPUT_DIR/post_route_methodology.rpt"
if run_checker "$TEST_ROOT/methodology-critical.log"; then
  echo "ERROR: a critical methodology warning did not fail the release gate." >&2
  exit 1
fi
grep -Fq 'FAIL  Vivado reports unwaived critical methodology warnings' \
  "$TEST_ROOT/methodology-critical.log"
grep -Fq 'RESULT: FAILED.' "$TEST_ROOT/methodology-critical.log"

echo "RESULT: PASS - critical CDC and methodology findings fail closed"
