# Contract: Stream Pipeline

## Purpose

Define the boundary from aligned frontend samples to the variant-local
fullstream datapath and downstream transport handoff.

## Assumptions

- Sample ingress obeys the frontend alignment contract.
- Upstream timing and analog configuration are already ready.

## Guarantees

- `stream_enable` is entirely determined by the readiness contract.
- The boundary must not declare the pipeline enabled before configuration,
  timing, and alignment are all valid.

## Evidence target

- boundary-level formal on the `stream_enable` gate now
- deeper datapath proofs later around stream formatting and handoff
