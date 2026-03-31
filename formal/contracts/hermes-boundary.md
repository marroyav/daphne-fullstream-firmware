# Contract: Hermes Boundary

## Purpose

Keep Hermes transport behavior unchanged while making the handoff point
explicit for the fullstream variant.

## Assumptions

- Hermes datapath, MAC handling, and transport behavior are preserved.

## Guarantees

- The boundary documents where fullstream lane arrays become transport input.
- The boundary owns the transport-facing readiness gate through a typed
  `ready` status bit.
- Board/network identity remains a software/platform concern, not a PL refactor.

## Evidence target

- boundary-level formal on the `ready` gate and lane handoff now
- deeper transport/protocol proofs later around the imported Hermes path
