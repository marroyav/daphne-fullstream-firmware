# Fullstream Transition Plan

This repository started as a direct import of the original streaming branch.
The goal is to turn it into a maintainable fullstream project while preserving
behavior and reusing the shared subsystem boundaries already established in
`daphne-firmware`.

## Immediate Baseline

Current branch state:

- build-facing Tcl/XDC names use the `daphne_fullstream_*` surface
- internal RTL still uses the imported `daphne3` naming
- the stream datapath is still the original validated logic

The current build-facing entry points are:

- `xilinx/daphne_fullstream_bd_gen.tcl`
- `xilinx/daphne_fullstream_ip_gen.tcl`
- `xilinx/daphne_fullstream_dtbo_gen.tcl`
- `xilinx/daphne_fullstream_xgui_gen.tcl`
- `xilinx/daphne_fullstream_pin_map.xdc`
- `xilinx/vivado_batch.tcl`

## Shared Subsystems To Reuse

These should converge toward the same conceptual boundaries as
`daphne-firmware`:

- timing subsystem
- analog control
- frontend alignment
- low-level board I/O
- Hermes/network boundary
- packaging / DT overlay / PetaLinux integration strategy

## Fullstream-Specific Subsystems

These are specific to the streaming mode and should remain variant-local:

- `ip_repo/daphne3_ip/rtl/stream/stream_input_mux.vhd`
- `ip_repo/daphne3_ip/rtl/stream/stream_core.vhd`
- `ip_repo/daphne3_ip/rtl/stream/stream4.vhd`
- `ip_repo/daphne3_ip/rtl/stream/stream8.vhd`
- top-level stream wiring in `ip_repo/daphne3_ip/rtl/daphne3.vhd`
- downstream transport-facing lane gate in `ip_repo/daphne3_ip/rtl/isolated/subsystems/hermes/hermes_boundary.vhd`

The current top-level streaming flow is:

1. frontend data capture
2. input selection through `stream_input_mux`
3. formatting into eight stream lanes in `stream_core`
4. handoff to `daphne_streaming_top`
5. debug capture through `outspybuff`

## Recommended Refactor Order

1. Keep the imported fullstream RTL behavior intact.
2. Continue renaming only the public/build surface.
3. Document the shared subsystem boundaries in this repository using the same
   language as `daphne-firmware`.
4. Add typed readiness contracts and boundary proofs for timing, frontend, and
   stream gating.
5. Isolate the stream datapath behind a variant-local boundary.
6. Add a transport-facing Hermes lane gate boundary without changing the
   imported transport implementation.
7. Only then start converging common timing / analog / frontend / Hermes
   wrappers with the selftrigger repository.
8. Delay deep internal RTL renames until the build path is re-qualified.

## Next Concrete Steps

1. Run a first synth/impl qualification from this renamed fullstream build
   surface.
2. Add a fullstream module inventory that classifies:
   - shared and reusable
   - variant-specific
   - obsolete / legacy names only
3. Introduce a neutral top-level plan:
   - public top name: `daphne_fullstream_top`
   - internal imported top may remain `daphne3.vhd` until requalification
4. Align the fullstream register/config story with the software-side fullstream
   mode settings from `daphne_interface`.
