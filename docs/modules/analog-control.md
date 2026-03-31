# Analog Control

## Scope

Boundary for the AFE and DAC configuration path:

- SPI setup and board programming flow
- safe enable sequencing
- readiness reporting before downstream acquisition uses the analog path

## Imported sources currently involved

- `ip_repo/daphne3_ip/rtl/afe/`
- `ip_repo/daphne3_ip/rtl/cm/spim_cm.vhd`
- `ip_repo/daphne3_ip/rtl/dac/spim_dac.vhd`

## Current Scaffold

- `ip_repo/daphne3_ip/rtl/isolated/subsystems/analog/analog_control_boundary.vhd`

## Isolation objective

Separate "can be configured" from "safe to use" so future refactoring can add
typed readiness contracts without touching the analog programming behavior.
