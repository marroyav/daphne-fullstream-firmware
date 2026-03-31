# Frontend Boundary

## Scope

Boundary for the data alignment point before downstream processing:

- 16-bit ingress validity
- sample-format expectations
- alignment and framing preconditions
- readiness qualification before the stream pipeline may consume samples

## Imported sources currently involved

- `ip_repo/daphne3_ip/rtl/frontend/`

## Current Scaffold

- `ip_repo/daphne3_ip/rtl/isolated/subsystems/frontend/frontend_boundary.vhd`

## Isolation objective

Preserve the current frontend behavior while making the data contract explicit
before it reaches stream formatting or transport logic.

## Current readiness contract

- Alignment depends on both:
  - analog configuration readiness
  - timing readiness
- `alignment_valid` is only trusted when:
  - resets are deasserted
  - `idelayctrl_ready = 1`
  - format and training checks are both good
