# Contract: Fullstream Boundary Top

## Purpose

Compose the additive subsystem wrappers into a single variant-local modular top
without changing the imported streaming implementation.

## Assumptions

- The imported `daphne3.vhd` path remains the active implementation.
- Boundary wrappers remain the authoritative source for readiness semantics.

## Guarantees

- `analog_status_i.ready` drives the configuration-ready side of the composed
  readiness chain.
- `timing_ready`, `alignment_valid`, `stream_enable`, `spy_enable`, and
  Hermes-ready semantics are propagated through one explicit wrapper top.
- Stream and Hermes lane handoffs remain null while their respective gates are
  disabled.

## Evidence target

- boundary-level formal on the composed readiness chain now
- future integration simulation once the wrapper starts owning real top wiring
