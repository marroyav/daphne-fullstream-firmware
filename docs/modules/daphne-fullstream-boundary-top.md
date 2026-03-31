# Fullstream Boundary Top

## Scope

Variant-local compositional top built from the additive subsystem wrappers:

- timing readiness
- frontend qualification
- stream lane gating
- spy capture gating
- Hermes-facing lane handoff

## Current Scaffold

- `ip_repo/daphne3_ip/rtl/isolated/top/daphne_fullstream_boundary_top.vhd`
- `cores/features/daphne-fullstream-boundary-top.core`

## Isolation objective

Provide a real compositional top for the modular fullstream boundary layer
without replacing the imported `daphne3.vhd` build path yet.

## Current behavior

- `analog_status_i.ready` feeds the configuration-ready side of the readiness
  chain
- `timing_subsystem_boundary` derives `timing_ready`
- `frontend_boundary` derives `alignment_valid`
- `stream_pipeline_boundary` gates ingress lanes into a transport-facing lane
  array
- `spy_buffer_boundary` gates capture enable
- `hermes_boundary` owns the downstream lane handoff into the unchanged
  transport path
