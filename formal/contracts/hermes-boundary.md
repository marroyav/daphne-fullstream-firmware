# Contract: Hermes Boundary

## Purpose

Keep Hermes transport behavior unchanged while making the handoff point
explicit for the fullstream variant.

## Assumptions

- Hermes datapath, MAC handling, and transport behavior are preserved.

## Guarantees

- The boundary documents where fullstream data becomes transport input.
- Board/network identity remains a software/platform concern, not a PL refactor.

## Evidence target

- contract documentation now
- boundary formal later if the wrapper gains explicit handshake state
