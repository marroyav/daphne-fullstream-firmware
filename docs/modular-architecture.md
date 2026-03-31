# Modular Architecture

## Intent

This repository is still on the imported fullstream build path, but it now
gains a modular scaffold that mirrors the boundary style used in
`daphne-firmware`.

- The existing `ip_repo/daphne3_ip/rtl/daphne3.vhd` flow remains the active
  streaming implementation.
- The new `docs/modules/*.md` pages describe the intended subsystem split
  without changing the current behavior.
- The new `rtl/isolated/...` files are additive wrappers and shared types that
  capture readiness and handoff contracts without changing the imported top
  level.

## Initial Boundary Set

- `control-plane`: PS-visible register and status contract.
- `analog-control`: AFE/DAC configuration readiness boundary.
- `timing-subsystem`: timing endpoint and readiness propagation boundary.
- `frontend-boundary`: alignment and sample-format contract before downstream
  logic consumes the data.
- `stream-pipeline`: streaming datapath boundary around the existing
  `stream_*` implementation.
- `hermes-boundary`: handoff boundary around the unchanged Hermes transport
  path.
- `spy-buffer-boundary`: capture readiness and observation boundary for the
  spy buffer path.

## Shared Package

- `daphne_fullstream_subsystem_types_pkg` now provides the typed readiness
  records used by the timing, frontend, and stream boundary wrappers.

## Dependency Model

The current target dependency chain is documented in
`docs/dependency-transition-plan.md`:

1. `control-plane`
2. `analog-control`
3. `timing-subsystem`
4. `frontend-boundary`
5. `stream-pipeline`
6. `spy-buffer-boundary`
7. `hermes-boundary`

## Formal Layer

Boundary-oriented contracts live under `formal/contracts/`, and the first proof
jobs now cover:

- timing readiness derivation
- frontend alignment qualification
- stream enable gating
- spy capture gating
- stream selector decode at the extracted leaf level

## What This Does Not Do Yet

- It does not rewrite the imported streaming RTL.
- It does not wire the new boundary wrappers into the current top level.
- It does not change register maps, transport behavior, or sample formatting.
- It does not replace the Vivado batch flow with a FuseSoC build.
