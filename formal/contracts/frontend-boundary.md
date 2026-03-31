# Contract: Frontend Boundary

## Purpose

Capture the alignment and ingress-format assumptions that must hold before the
fullstream datapath may trust frontend samples.

## Assumptions

- The AFE is configured for `16-bit`, `LSb-first` transmission.
- IDELAY programming occurs only while `idelay_en_vtc = 0`.
- Alignment depends on timing readiness and analog configuration readiness.

## Guarantees

- `alignment_valid` is a qualified state, not a raw internal flag.
- `alignment_valid` must not assert unless:
  - frontend reset is deasserted
  - configuration is ready
  - timing is ready
  - `idelayctrl_ready = 1`
  - format and training checks are both good
  - IDELAYCTRL and ISERDES resets are deasserted

## Evidence target

- boundary-level formal on the `alignment_valid` gate now
- simulation and deeper assertions on the imported alignment path later
