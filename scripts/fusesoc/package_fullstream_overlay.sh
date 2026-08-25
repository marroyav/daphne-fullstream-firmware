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

OUTPUT_ARG="${1:-${DAPHNE_OUTPUT_DIR:-$ROOT_DIR/xilinx/output-$GIT_SHA}}"
if [ ! -d "$OUTPUT_ARG" ]; then
  echo "ERROR: output directory does not exist: $OUTPUT_ARG" >&2
  exit 2
fi
OUTPUT_DIR=$(CDPATH= cd -- "$OUTPUT_ARG" && pwd)

case "$OUTPUT_DIR" in
  /|'')
    echo "ERROR: refusing unsafe output directory '$OUTPUT_DIR'." >&2
    exit 2
    ;;
esac

BUILD_NAME="daphne_fullstream_$GIT_SHA"
OVERLAY_NAME="daphne_fullstream_ol_$GIT_SHA"
XSA="$OUTPUT_DIR/$BUILD_NAME.xsa"
BIN="$OUTPUT_DIR/$BUILD_NAME.bin"
SDT_DIR="$OUTPUT_DIR/$BUILD_NAME"
OVERLAY_DIR="$OUTPUT_DIR/$OVERLAY_NAME"
OVERLAY_ZIP="$OUTPUT_DIR/$OVERLAY_NAME.zip"

for required_file in "$XSA" "$BIN"; do
  if [ ! -s "$required_file" ]; then
    echo "ERROR: required build artifact is missing or empty: $required_file" >&2
    exit 2
  fi
done

if [ -n "${XILINX_VIVADO:-}" ] && [ -x "$XILINX_VIVADO/bin/sdtgen" ]; then
  SDTGEN="$XILINX_VIVADO/bin/sdtgen"
elif command -v sdtgen >/dev/null 2>&1; then
  SDTGEN=$(command -v sdtgen)
else
  echo "ERROR: sdtgen was not found. Source the Vivado/Vitis settings first." >&2
  exit 2
fi

if [ -n "${XILINX_VIVADO:-}" ] && [ -x "$XILINX_VIVADO/bin/dtc" ]; then
  DTC="$XILINX_VIVADO/bin/dtc"
elif command -v dtc >/dev/null 2>&1; then
  DTC=$(command -v dtc)
else
  echo "ERROR: dtc was not found. Source the Vivado/Vitis settings first." >&2
  exit 2
fi

if ! command -v zip >/dev/null 2>&1; then
  echo "ERROR: zip is required to package the overlay." >&2
  exit 2
fi

if command -v sha256sum >/dev/null 2>&1; then
  SHA256_TOOL=sha256sum
elif command -v shasum >/dev/null 2>&1; then
  SHA256_TOOL=shasum
else
  echo "ERROR: sha256sum or shasum is required to checksum the overlay." >&2
  exit 2
fi

SDT_STAGE=$(mktemp -d "$OUTPUT_DIR/.${BUILD_NAME}.sdt.XXXXXX")
PACKAGE_STAGE=$(mktemp -d "$OUTPUT_DIR/.${OVERLAY_NAME}.package.XXXXXX")
ZIP_STAGE="$PACKAGE_STAGE/$OVERLAY_NAME.zip"

cleanup() {
  if [ -n "${SDT_STAGE:-}" ]; then
    rm -rf -- "$SDT_STAGE"
  fi
  if [ -n "${PACKAGE_STAGE:-}" ]; then
    rm -rf -- "$PACKAGE_STAGE"
  fi
  if [ -n "${ZIP_STAGE:-}" ]; then
    rm -f -- "$ZIP_STAGE"
  fi
}
trap cleanup 0 1 2 15

echo "INFO: Generating system device tree from $XSA"
"$SDTGEN" -xsa "$XSA" -dir "$SDT_STAGE" -zocl enable

PL_DTSI="$SDT_STAGE/pl.dtsi"
OVERLAY_DTSI="$SDT_STAGE/pl.overlay.dtsi"
if [ ! -s "$PL_DTSI" ]; then
  echo "ERROR: sdtgen did not create $PL_DTSI" >&2
  exit 2
fi

# SDTGen 2026.1 emits a complete amba_pl node. Convert its contents to the
# plugin fragment expected by the K26 FPGA manager and PYNQ overlay loader.
awk '
BEGIN {
  found = 0
  closed = 0
  depth = 0
  print "/dts-v1/;"
  print "/plugin/;"
  print "/ {"
  print "\tfragment@0 {"
  print "\t\ttarget-path = \"/axi\";"
  print "\t\t__overlay__ {"
}
{
  line = $0
  if (!found) {
    if (line ~ /^[[:space:]]*amba_pl:[[:space:]]+amba_pl[[:space:]]*\{[[:space:]]*$/) {
      found = 1
      depth = 1
    }
    next
  }

  if (!closed) {
    scan = line
    opens = gsub(/\{/, "", scan)
    scan = line
    closes = gsub(/\}/, "", scan)

    if (depth == 1 && line ~ /^[[:space:]]*};[[:space:]]*$/) {
      depth += opens - closes
      closed = 1
      next
    }

    print "\t" line
    depth += opens - closes
  }
}
END {
  if (!found || !closed || depth != 0) {
    print "ERROR: could not isolate the amba_pl node in sdtgen pl.dtsi" > "/dev/stderr"
    exit 2
  }
  print "\t\t};"
  print "\t};"
  print "};"
}
' "$PL_DTSI" > "$OVERLAY_DTSI"

mv "$PL_DTSI" "$SDT_STAGE/pl.sdtgen.dtsi"
mv "$OVERLAY_DTSI" "$PL_DTSI"
sed -i -f "$ROOT_DIR/xilinx/scripts/axi_quad_spi_dtbo_patch.sed" "$PL_DTSI"

DTBO_STAGE="$SDT_STAGE/$OVERLAY_NAME.dtbo"
echo "INFO: Compiling device-tree overlay."
"$DTC" -@ -O dtb -o "$DTBO_STAGE" "$PL_DTSI"

PACKAGE_OVERLAY_DIR="$PACKAGE_STAGE/$OVERLAY_NAME"
mkdir -p "$PACKAGE_OVERLAY_DIR"
cp "$BIN" "$PACKAGE_OVERLAY_DIR/$OVERLAY_NAME.bin"
cp "$DTBO_STAGE" "$PACKAGE_OVERLAY_DIR/$OVERLAY_NAME.dtbo"
printf '%s\n' '{ "shell_type" : "XRT_FLAT", "num_slots": "1" }' > "$PACKAGE_OVERLAY_DIR/shell.json"

(CDPATH= cd -- "$PACKAGE_STAGE" && zip -qr "$ZIP_STAGE" "$OVERLAY_NAME")

if command -v unzip >/dev/null 2>&1; then
  unzip -tqq "$ZIP_STAGE"
fi

rm -rf -- "$SDT_DIR" "$OVERLAY_DIR"
rm -f -- "$OVERLAY_ZIP"
mv "$SDT_STAGE" "$SDT_DIR"
SDT_STAGE=""
mv "$PACKAGE_OVERLAY_DIR" "$OVERLAY_DIR"
mv "$ZIP_STAGE" "$OVERLAY_ZIP"
ZIP_STAGE=""
rmdir "$PACKAGE_STAGE"
PACKAGE_STAGE=""

(
  CDPATH= cd -- "$OUTPUT_DIR"
  set --
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
    if [ -s "$checksum_path" ]; then
      set -- "$@" "$checksum_path"
    fi
  done

  if [ "$SHA256_TOOL" = sha256sum ]; then
    sha256sum "$@" > SHA256SUMS
  else
    shasum -a 256 "$@" > SHA256SUMS
  fi
)

echo "INFO: Device-tree overlay package is ready: $OVERLAY_ZIP"
echo "INFO: Checksums are ready: $OUTPUT_DIR/SHA256SUMS"
