# Frontend Boundary

## Scope

Boundary for the data alignment point before downstream processing:

- 16-bit ingress validity
- sample-format expectations
- alignment and framing preconditions

## Imported sources currently involved

- `ip_repo/daphne3_ip/rtl/frontend/`

## Current Scaffold

- `ip_repo/daphne3_ip/rtl/isolated/subsystems/frontend/frontend_boundary.vhd`

## Isolation objective

Preserve the current frontend behavior while making the data contract explicit
before it reaches stream formatting or transport logic.
