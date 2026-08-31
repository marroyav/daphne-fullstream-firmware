#!/bin/sh
set -eu

ROOT_DIR="${DAPHNE_FULLSTREAM_ROOT:-$(CDPATH= cd -- "$(dirname -- "$0")/../.." && pwd)}"
GIT_SHA="${2:-${DAPHNE_GIT_SHA:-}}"

if [ -z "$GIT_SHA" ]; then
  GIT_SHA=$(git -C "$ROOT_DIR" rev-parse --short=7 HEAD)
fi

case "$GIT_SHA" in
  *[!0-9a-fA-F]*|'')
    echo "ERROR: git SHA must contain only hexadecimal characters: '$GIT_SHA'." >&2
    exit 2
    ;;
esac

if [ "${#GIT_SHA}" -lt 7 ]; then
  echo "ERROR: git SHA must contain at least seven characters: '$GIT_SHA'." >&2
  exit 2
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
check_file "checksums" "$OUTPUT_DIR/SHA256SUMS"
check_file "route timing" "$OUTPUT_DIR/post_route_timing_summary.rpt"
check_file "bus skew" "$OUTPUT_DIR/post_route_bus_skew.rpt"
check_file "CDC report" "$OUTPUT_DIR/post_route_cdc.rpt"
check_file "methodology" "$OUTPUT_DIR/post_route_methodology.rpt"
check_file "route status" "$OUTPUT_DIR/post_route_status.rpt"
check_file "power report" "$OUTPUT_DIR/post_route_power.rpt"
check_file "utilization" "$OUTPUT_DIR/post_route_util.rpt"
check_file "DRC report" "$OUTPUT_DIR/post_imp_drc.rpt"
check_file "release cells" "$OUTPUT_DIR/release_cells.rpt"

checksum_manifest="$OUTPUT_DIR/SHA256SUMS"
if [ -s "$checksum_manifest" ]; then
  if command -v sha256sum >/dev/null 2>&1; then
    if (CDPATH= cd -- "$OUTPUT_DIR" && sha256sum -c SHA256SUMS); then
      echo "PASS  checksums"
    else
      echo "FAIL  a packaged-file checksum does not match" >&2
      failed=1
    fi
  elif command -v shasum >/dev/null 2>&1; then
    if (CDPATH= cd -- "$OUTPUT_DIR" && shasum -a 256 -c SHA256SUMS); then
      echo "PASS  checksums"
    else
      echo "FAIL  a packaged-file checksum does not match" >&2
      failed=1
    fi
  else
    echo "FAIL  sha256sum or shasum is required to verify SHA256SUMS" >&2
    failed=1
  fi

  for checksum_path in \
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
    if ! grep -Fq "  $checksum_path" "$checksum_manifest"; then
      echo "FAIL  checksum manifest does not cover $checksum_path" >&2
      failed=1
    fi
  done
fi

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

if command -v unzip >/dev/null 2>&1; then
  if [ -s "$OUTPUT_DIR/$OVERLAY_NAME.zip" ]; then
    if unzip -tqq "$OUTPUT_DIR/$OVERLAY_NAME.zip"; then
      echo "PASS  overlay archive integrity"
    else
      echo "FAIL  overlay archive is corrupt" >&2
      failed=1
    fi
  fi

  if [ -s "$OUTPUT_DIR/$BUILD_NAME.xsa" ]; then
    if unzip -tqq "$OUTPUT_DIR/$BUILD_NAME.xsa"; then
      echo "PASS  hardware XSA integrity"
    else
      echo "FAIL  hardware XSA is corrupt" >&2
      failed=1
    fi

  fi
else
  echo "FAIL  unzip is required to verify the XSA and overlay archive" >&2
  failed=1
fi

if command -v dtc >/dev/null 2>&1; then
  if [ -s "$OVERLAY_DIR/$OVERLAY_NAME.dtbo" ]; then
    if dtc -I dtb -O dts -o /dev/null "$OVERLAY_DIR/$OVERLAY_NAME.dtbo" 2>/dev/null; then
      echo "PASS  device-tree blob parses"
    else
      echo "FAIL  device-tree blob does not parse" >&2
      failed=1
    fi

  fi
else
  echo "FAIL  dtc is required to verify the device-tree blob" >&2
  failed=1
fi

if command -v python3 >/dev/null 2>&1; then
  if [ -s "$OUTPUT_DIR/$BUILD_NAME.xsa" ] && [ -s "$OVERLAY_DIR/$OVERLAY_NAME.dtbo" ]; then
    if python3 "$ROOT_DIR/scripts/check_fullstream_artifact_map.py" \
      --xsa "$OUTPUT_DIR/$BUILD_NAME.xsa" \
      --dtbo "$OVERLAY_DIR/$OVERLAY_NAME.dtbo"
    then
      echo "PASS  generated full-stream address map"
    else
      echo "FAIL  generated full-stream address map does not match the release ABI" >&2
      failed=1
    fi
  fi
else
  echo "FAIL  python3 is required to verify the generated full-stream address map" >&2
  failed=1
fi

drc_report="$OUTPUT_DIR/post_imp_drc.rpt"
if [ -s "$drc_report" ]; then
  if grep -Eq '^[[:space:]]*[A-Z0-9-]+#[0-9]+[[:space:]]+(Error|Critical)' "$drc_report"; then
    echo "FAIL  error-level DRC violations are present in $drc_report" >&2
    failed=1
  else
    echo "PASS  no error-level DRC violations"
  fi
fi

bus_skew_report="$OUTPUT_DIR/post_route_bus_skew.rpt"
if [ -s "$bus_skew_report" ]; then
  if grep -Fq 'Slack (VIOLATED)' "$bus_skew_report"; then
    echo "FAIL  a bus-skew constraint is violated in $bus_skew_report" >&2
    failed=1
  else
    echo "PASS  no violated bus-skew constraints"
  fi
fi

route_status_report="$OUTPUT_DIR/post_route_status.rpt"
if [ -s "$route_status_report" ]; then
  if grep -Eq '# of nets with routing errors.*:[[:space:]]+0' "$route_status_report"; then
    echo "PASS  no routing errors"
  else
    echo "FAIL  routed-net status is not clean in $route_status_report" >&2
    failed=1
  fi
fi

release_cells_report="$OUTPUT_DIR/release_cells.rpt"
if [ -s "$release_cells_report" ]; then
  if grep -Fxq 'GT_CHANNEL_COUNT=4' "$release_cells_report"; then
    echo "PASS  four GTHE4 channels are present"
  else
    echo "FAIL  routed design does not contain exactly four GTHE4 channels" >&2
    failed=1
  fi
  if grep -Fxq 'MUX_ASYNC_REG_COUNT=6' "$release_cells_report"; then
    echo "PASS  six mux CDC/reset synchronizer cells are preserved"
  else
    echo "FAIL  routed design does not preserve exactly six mux synchronizer cells" >&2
    failed=1
  fi
fi

cdc_report="$OUTPUT_DIR/post_route_cdc.rpt"
if [ -s "$cdc_report" ]; then
  if grep -Eq 'CDC-[0-9]+.*Critical' "$cdc_report"; then
    echo "FAIL  Vivado reports unwaived critical CDC classifications in $cdc_report" >&2
    failed=1
  else
    echo "PASS  no unwaived critical CDC classifications"
  fi
fi

methodology_report="$OUTPUT_DIR/post_route_methodology.rpt"
if [ -s "$methodology_report" ]; then
  if grep -Fq 'Critical Warning' "$methodology_report"; then
    echo "FAIL  Vivado reports unwaived critical methodology warnings in $methodology_report" >&2
    failed=1
  else
    echo "PASS  no unwaived critical methodology warnings"
  fi
fi

if [ "$failed" -ne 0 ]; then
  echo "RESULT: FAILED. Keep the output directory and inspect the reported file." >&2
  exit 1
fi

echo "RESULT: PASS. Artifact integrity and implementation gates passed."
