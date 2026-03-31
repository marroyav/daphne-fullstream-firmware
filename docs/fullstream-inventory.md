# Fullstream Inventory

This repository is a direct clone of the original streaming source branch and
still uses the legacy `daphne3` naming. It has not yet been aligned with the
renamed `daphne-firmware` tree.

## Active Build Entry Points

- Top RTL: `ip_repo/daphne3_ip/rtl/daphne3.vhd`
- Top package: `ip_repo/daphne3_ip/rtl/daphne3_package.vhd`
- Main build script: `xilinx/vivado_batch.tcl`
- Block design generator: `xilinx/daphne_fullstream_bd_gen.tcl`
- IP packager: `xilinx/daphne_fullstream_ip_gen.tcl`
- DT overlay helper: `xilinx/daphne_fullstream_dtbo_gen.tcl`
- Constraints: `xilinx/daphne_fullstream_pin_map.xdc`

## Build/Product Names In This Source

The imported streaming branch originally produced legacy names such as:

- `DAPHNE_MEZ_STREAMING_V1`
- `DAPHNE_MEZ_STREAMING_V1_wrapper`
- `daphne3_str_<sha>.bit`
- `daphne3_str_<sha>.bin`
- `daphne3_str_<sha>.xsa`
- `daphne3_str_OL_<sha>/`

The public/build surface on this branch now uses:

- `daphne_fullstream_bd`
- `daphne_fullstream_bd_wrapper`
- `daphne_fullstream_<sha>.bit`
- `daphne_fullstream_<sha>.bin`
- `daphne_fullstream_<sha>.xsa`
- `daphne_fullstream_ol_<sha>/`

## Streaming-Specific RTL

The streaming-specific datapath is real and local to this tree. The key files
are:

- `ip_repo/daphne3_ip/rtl/stream/stream_input_mux.vhd`
- `ip_repo/daphne3_ip/rtl/stream/stream_core.vhd`
- `ip_repo/daphne3_ip/rtl/stream/stream4.vhd`
- `ip_repo/daphne3_ip/rtl/stream/stream8.vhd`
- `ip_repo/daphne3_ip/rtl/stream/stream_top_wrapper.vhd`

Within `ip_repo/daphne3_ip/rtl/daphne3.vhd` the current dataflow is:

1. frontend data is reduced to the 14-bit stream payload
2. `stream_input_mux` selects/multiplexes channel input
3. `stream_core` formats eight output streams
4. `daphne_streaming_top` hands those streams to the Hermes/10G side
5. `outspybuff` captures debug/output buffer data

Important internal signals in the top:

- `channel_id`
- `stream_core_dout`
- `stream_core_valid`
- `stream_core_last`
- `ext_mac_addr_[0..3]`
- `ext_ip_addr_[0..3]`
- `ext_port_addr_[0..3]`

## Shared vs Variant-Specific View

Likely shared with the renamed selftrigger repository:

- timing endpoint subsystem
- analog control
- frontend alignment
- low-level board I/O
- much of the Hermes/IPBus infrastructure
- DT/packaging/PetaLinux integration strategy

Clearly streaming-specific here:

- stream datapath in `rtl/stream/`
- top-level wiring in `rtl/daphne3.vhd`
- streaming build/product names in `xilinx/vivado_batch.tcl`
- streaming block-design naming in `xilinx/daphne_fullstream_bd_gen.tcl`

## Immediate Refactor Direction

The safe order for this repository is:

1. keep this branch as the imported streaming baseline
2. classify shared modules versus fullstream-only modules
3. rename the public/build surface
4. only then decide how much of the deep RTL naming should change
5. preserve behavioral parity before attempting modular convergence with
   `daphne-firmware`
