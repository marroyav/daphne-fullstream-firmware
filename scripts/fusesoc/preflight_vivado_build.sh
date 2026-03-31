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
  echo "INFO: Preflighting via FuseSoC platform core $PLATFORM_CORE"
fi

cd "$ROOT_DIR/xilinx"

shim_tcl=".daphne-fullstream-preflight.$$.tcl"
trap 'rm -f "$shim_tcl"' EXIT INT TERM HUP

cat >"$shim_tcl" <<'EOF'
create_project -in_memory -part "xck26-sfvc784-2LV-c"
source -notrace ./daphne_fullstream_ip_gen.tcl
exit
EOF

echo "INFO: Running fullstream IP packaging preflight for board=$BOARD."
vivado -mode batch -source "$shim_tcl"

component_xml="$ROOT_DIR/ip_repo/daphne3_ip/component.xml"
eth_xci="$ROOT_DIR/ip_repo/daphne3_ip/src/dune.daq_user_hermes_daphne_1.1/src/xxv_ethernet_0/xxv_ethernet_0.xci"
eth_xci_ref='src/dune.daq_user_hermes_daphne_1.1/src/xxv_ethernet_0/xxv_ethernet_0.xci'
eth_binding='hermes_module_inst/daphne_streaming_top_inst/mux/pcs_pma/phy_gen[0].phy_10gbe'

if [ ! -f "$component_xml" ]; then
  echo "ERROR: Expected packaged component.xml at $component_xml" >&2
  exit 2
fi

if [ ! -f "$eth_xci" ]; then
  echo "ERROR: Expected Ethernet XCI at $eth_xci" >&2
  exit 2
fi

if ! grep -Fq "$eth_xci_ref" "$component_xml"; then
  echo "ERROR: component.xml is missing Ethernet XCI reference: $eth_xci_ref" >&2
  exit 2
fi

if ! grep -Fq "$eth_binding" "$component_xml"; then
  echo "ERROR: component.xml is missing Ethernet cell binding: $eth_binding" >&2
  exit 2
fi

echo "INFO: Preflight passed."
echo "INFO: Ethernet XCI and phy_10gbe binding are present in component.xml."
