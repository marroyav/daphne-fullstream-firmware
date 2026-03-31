# Stream Pipeline

## Scope

Variant-local fullstream datapath:

- stream input selection
- stream formatting
- stream lane handoff
- debug capture interaction

## Imported sources currently involved

- `ip_repo/daphne3_ip/rtl/stream/stream_input_mux.vhd`
- `ip_repo/daphne3_ip/rtl/stream/stream_core.vhd`
- `ip_repo/daphne3_ip/rtl/stream/stream4.vhd`
- `ip_repo/daphne3_ip/rtl/stream/stream8.vhd`
- `ip_repo/daphne3_ip/rtl/stream/stream_top_wrapper.vhd`

## Current Scaffold

- `ip_repo/daphne3_ip/rtl/isolated/subsystems/stream/stream_pipeline_boundary.vhd`

## Isolation objective

Keep the existing stream implementation intact while marking the place where a
future stream datapath wrapper can own the boundary between capture and
Hermes/transport handoff.
