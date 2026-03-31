# Timing Subsystem

## Scope

Boundary for the imported timing endpoint path:

- endpoint setup and reset behavior
- timestamp propagation
- readiness and lock status visibility

## Imported sources currently involved

- `ip_repo/daphne3_ip/rtl/timing/`

## Current Scaffold

- `ip_repo/daphne3_ip/rtl/isolated/subsystems/timing/timing_subsystem_boundary.vhd`

## Isolation objective

Keep the timing endpoint behavior intact while creating a typed place for
future readiness and status contracts.
