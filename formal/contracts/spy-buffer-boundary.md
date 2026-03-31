# Contract: Spy Buffer Boundary

## Purpose

Define the observation/capture boundary without changing the imported spy path.

## Assumptions

- Spy capture should not be interpreted as valid before upstream readiness is
  satisfied.

## Guarantees

- `spy_enable` is entirely determined by the shared acquisition-readiness
  contract.
- The boundary must not declare capture enabled before configuration, timing,
  and alignment are all valid.

## Evidence target

- boundary-level formal on the `spy_enable` gate now
- deeper capture-path proofs later
