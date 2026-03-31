# Contract: Timing Subsystem

## Purpose

Bridge timing endpoint control and status into the fullstream design without
changing the imported timing behavior.

## Assumptions

- Vendor clocking primitives remain trusted black boxes for formal purposes.
- Downstream logic must not consume timing-dependent behavior until the timing
  boundary reports readiness.

## Guarantees

- Raw timing status passes through a documented boundary.
- `timing_ready` is derived explicitly from the selected clock mode and lock
  state.
- In endpoint-clock mode, `timing_ready` requires endpoint readiness and valid
  timestamps.
- In local-clock mode, `timing_ready` requires only reset deassertion and both
  MMCM locks.

## Evidence target

- boundary-level formal on the `timing_ready` derivation now
- integration simulation later for endpoint reset and lock behavior
