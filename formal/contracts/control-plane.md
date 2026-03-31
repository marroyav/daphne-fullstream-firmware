# Contract: Control Plane

## Purpose

Provide a stable PS-visible register and status contract while the imported
streaming implementation remains intact.

## Assumptions

- The established register ABI is preserved.
- Disabled or absent blocks must fail safely.

## Guarantees

- Register semantics remain explicit at the subsystem boundary.
- Configuration intent is separated from datapath behavior.

## Evidence target

- contract documentation now
- AXI-Lite boundary formal later
