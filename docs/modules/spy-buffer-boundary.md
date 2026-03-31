# Spy Buffer Boundary

## Scope

Boundary for capture and observation gating:

- readiness before capture enable
- debug path isolation
- future observation-contract cleanup

## Imported sources currently involved

- `ip_repo/daphne3_ip/rtl/spy/`
- `ip_repo/daphne3_ip/rtl/misc/outspybuff.vhd`

## Current Scaffold

- `ip_repo/daphne3_ip/rtl/isolated/subsystems/spy/spy_buffer_boundary.vhd`

## Isolation objective

Keep the current spy-buffer behavior intact while carving out the place where
readiness and capture semantics can be typed later.
