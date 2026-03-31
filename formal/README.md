# Formal Verification

This repository now has the first boundary-oriented formal layer around the
additive modular scaffolding, plus the earlier stream-specific selector proof.

Boundary jobs:

- `formal/sby/timing_subsystem_boundary_contract.sby`
- `formal/sby/frontend_boundary_gate.sby`
- `formal/sby/stream_pipeline_boundary_gate.sby`
- `formal/sby/spy_buffer_boundary_gate.sby`

Leaf datapath job:

- `formal/sby/stream_mux_select_decode.sby`

The imported fullstream RTL remains the active implementation. These proofs are
focused on the additive wrappers and one extracted leaf selector.

## Running

Use SymbiYosys:

```sh
./scripts/formal/run_formal.sh
```

Or run an individual job:

```sh
cd formal/sby
sby -f stream_mux_select_decode.sby
```
