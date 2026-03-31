# Hermes Boundary

## Scope

Boundary around the unchanged Hermes/network transport path:

- transport-facing lane handoff
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

## Current readiness contract

- `ready` must remain low until:
  - analog configuration is ready
  - timing is ready
  - frontend alignment is valid
- disabled handoff forces a null lane array
- enabled handoff passes each lane through unchanged
