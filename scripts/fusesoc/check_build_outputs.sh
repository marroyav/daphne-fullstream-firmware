#!/bin/sh
set -eu

ROOT_DIR="${DAPHNE_FULLSTREAM_ROOT:-$(CDPATH= cd -- "$(dirname -- "$0")/../.." && pwd)}"
GIT_SHA="${2:-${DAPHNE_GIT_SHA:-}}"

if [ -z "$GIT_SHA" ]; then
  GIT_SHA=$(git -C "$ROOT_DIR" rev-parse --short=7 HEAD)
fi

OUTPUT_DIR="${1:-${DAPHNE_OUTPUT_DIR:-$ROOT_DIR/xilinx/output-$GIT_SHA}}"
BUILD_NAME="daphne_fullstream_$GIT_SHA"
OVERLAY_NAME="daphne_fullstream_ol_$GIT_SHA"
OVERLAY_DIR="$OUTPUT_DIR/$OVERLAY_NAME"
failed=0

check_file() {
  label="$1"
  path="$2"
  if [ -s "$path" ]; then
    size=$(du -h "$path" | awk '{print $1}')
    printf 'PASS  %-18s %8s  %s\n' "$label" "$size" "$path"
  else
    printf 'FAIL  %-18s %s\n' "$label" "$path" >&2
    failed=1
  fi
}

echo "Checking fullstream build $GIT_SHA"
echo "Output directory: $OUTPUT_DIR"

check_file "FPGA bitstream" "$OUTPUT_DIR/$BUILD_NAME.bit"
check_file "FPGA binary" "$OUTPUT_DIR/$BUILD_NAME.bin"
check_file "hardware XSA" "$OUTPUT_DIR/$BUILD_NAME.xsa"
check_file "debug probes" "$OUTPUT_DIR/probes.ltx"
check_file "overlay bitstream" "$OVERLAY_DIR/$OVERLAY_NAME.bin"
check_file "device-tree blob" "$OVERLAY_DIR/$OVERLAY_NAME.dtbo"
check_file "overlay metadata" "$OVERLAY_DIR/shell.json"
check_file "overlay archive" "$OUTPUT_DIR/$OVERLAY_NAME.zip"
check_file "route timing" "$OUTPUT_DIR/post_route_timing_summary.rpt"
check_file "power report" "$OUTPUT_DIR/post_route_power.rpt"
check_file "DRC report" "$OUTPUT_DIR/post_imp_drc.rpt"

timing_report="$OUTPUT_DIR/post_route_timing_summary.rpt"
if [ -s "$timing_report" ]; then
  if grep -Fq 'All user specified timing constraints are met.' "$timing_report"; then
    echo "PASS  timing constraints met"
  elif grep -Eq 'Timing constraints are not met|VIOLATED' "$timing_report"; then
    echo "FAIL  timing violations are present in $timing_report" >&2
    grep -E 'WNS\(ns\)|TNS\(ns\)|VIOLATED|Timing constraints are not met' "$timing_report" | head -12 >&2 || true
    failed=1
  else
    echo "FAIL  timing result was not recognized in $timing_report" >&2
    failed=1
  fi
fi

if command -v unzip >/dev/null 2>&1 && [ -s "$OUTPUT_DIR/$OVERLAY_NAME.zip" ]; then
  if unzip -tqq "$OUTPUT_DIR/$OVERLAY_NAME.zip"; then
    echo "PASS  overlay archive integrity"
  else
    echo "FAIL  overlay archive is corrupt" >&2
    failed=1
  fi
fi

if command -v unzip >/dev/null 2>&1 && [ -s "$OUTPUT_DIR/$BUILD_NAME.xsa" ]; then
  if unzip -tqq "$OUTPUT_DIR/$BUILD_NAME.xsa"; then
    echo "PASS  hardware XSA integrity"
  else
    echo "FAIL  hardware XSA is corrupt" >&2
    failed=1
  fi
fi

if command -v dtc >/dev/null 2>&1 && [ -s "$OVERLAY_DIR/$OVERLAY_NAME.dtbo" ]; then
  if dtc -I dtb -O dts -o /dev/null "$OVERLAY_DIR/$OVERLAY_NAME.dtbo" 2>/dev/null; then
    echo "PASS  device-tree blob parses"
  else
    echo "FAIL  device-tree blob does not parse" >&2
    failed=1
  fi
fi

drc_report="$OUTPUT_DIR/post_imp_drc.rpt"
if [ -s "$drc_report" ]; then
  if grep -Eq '^[A-Z0-9-]+#[0-9]+[[:space:]]+(Error|Critical)' "$drc_report"; then
    echo "FAIL  error-level DRC violations are present in $drc_report" >&2
    failed=1
  else
    echo "PASS  no error-level DRC violations"
  fi
fi

if [ "$failed" -ne 0 ]; then
  echo "RESULT: FAILED. Keep the output directory and inspect the reported file." >&2
  exit 1
fi

echo "RESULT: PASS. Bitstream, hardware handoff, overlay, and implementation reports are present."
