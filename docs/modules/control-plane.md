# Control Plane

## Scope

Neutral name for the PS-visible control and status plane:

- register decode
- AXI-Lite leaf adapters
- safe response policy for missing or disabled features
- aggregation of subsystem status into a stable software contract

## Imported sources currently involved

- `ip_repo/daphne3_ip/rtl/config/`
- `ip_repo/daphne3_ip/rtl/frontend/fe_axi.vhd`
- `ip_repo/daphne3_ip/rtl/timing/ep_axi.vhd`

## Current Scaffold

- `ip_repo/daphne3_ip/rtl/isolated/subsystems/control/control_plane_boundary.vhd`

## Isolation objective

Keep the external register map unchanged while making the internal control API
typed, explicit, and proof-friendly.
