# Dependency Transition Plan

## Intended Runtime Order

The fullstream branch should converge toward the same readiness-driven startup
model used in `daphne-firmware`:

1. `control-plane`
2. `analog-control`
3. `timing-subsystem`
4. `frontend-boundary`
5. `stream-pipeline`
6. `spy-buffer-boundary`
7. `hermes-boundary`

## Readiness Conditions

- `config_ready`
  - analog configuration is applied and the frontend may trust AFE/DAC setup
- `timing_ready`
  - the selected clocking path is locked and, in endpoint-clock mode, the
    timing endpoint is ready with valid timestamps
- `alignment_ready`
  - frontend alignment is valid only after configuration, timing, training, and
    format checks all pass

## Boundary Enables

- `frontend-boundary`
  - may assert `alignment_valid` only when `config_ready` and `timing_ready`
    are already true
- `stream-pipeline`
  - may assert `stream_enable` only when `config_ready`, `timing_ready`, and
    `alignment_ready` are all true
- `spy-buffer-boundary`
  - should eventually gate capture under the same readiness contract

## Current Scope

This document defines the target dependency model for the additive wrappers and
formal harnesses. It does not change the imported streaming RTL behavior on its
own.
