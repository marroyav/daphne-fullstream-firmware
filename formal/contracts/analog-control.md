# Contract: Analog Control

## Purpose

Document the configuration-ready boundary for AFE and DAC programming without
changing the imported control implementation.

## Assumptions

- Control-plane writes obey the existing register ABI.
- Analog configuration is a prerequisite for frontend alignment.

## Guarantees

- The boundary owns the meaning of `config_ready`.
- Downstream logic can distinguish "configured" from merely "powered".

## Evidence target

- contract documentation now
- boundary-level formal once the wrapper carries explicit ready signals
