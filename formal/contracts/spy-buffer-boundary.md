# Contract: Spy Buffer Boundary

## Purpose

Define the observation/capture boundary without changing the imported spy path.

## Assumptions

- Spy capture should not be interpreted as valid before upstream readiness is
  satisfied.

## Guarantees

- The boundary is the future home for safe capture gating.

## Evidence target

- contract documentation now
- readiness-gate formal after the wrapper carries explicit enables
