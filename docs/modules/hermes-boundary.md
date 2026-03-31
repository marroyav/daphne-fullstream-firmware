# Hermes Boundary

## Scope

Boundary around the unchanged Hermes/network transport path:

- transport handoff
- packet emission readiness
- preservation of the existing network-facing contract

## Imported sources currently involved

- `ip_repo/daphne3_ip/src/`
- `ip_repo/daphne3_ip/rtl/daphne3.vhd`

## Current Scaffold

- `ip_repo/daphne3_ip/rtl/isolated/subsystems/hermes/hermes_boundary.vhd`

## Isolation objective

Keep the transport implementation untouched while creating a neutral wrapper
name for future stream and control convergence work.
