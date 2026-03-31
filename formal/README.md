# Formal Verification

This repository does not yet have the broader boundary-oriented formal layer
present in `daphne-firmware`, but it now has an initial stream-specific proof
target:

- `formal/sby/stream_mux_select_decode.sby`

That proof checks the decode table for the per-lane stream selector extracted
from `stream_input_mux.vhd`.

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
