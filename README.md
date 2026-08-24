# DAPHNE full-stream firmware

This repository builds the K26C DAPHNE full-stream firmware. The imported
streaming datapath remains the active hardware implementation; the FuseSoC and
formal layers make that implementation easier to build, inspect, and evolve.

## Start here

The supported release build uses:

- board: K26C DAPHNE V3/MEZZ
- toolchain: Vivado and Vitis 2026.1
- build host: Cooper
- build mode: non-project Vivado, launched through the repo-owned FuseSoC
  wrapper

Use the short operator guide:

- [Build full-stream firmware on Cooper](docs/build-fullstream-on-cooper.md)
- [Current full-stream release candidate](docs/releases/fullstream-2026.08.24-rc1.md)

From an initialized Vivado/Vitis 2026.1 shell, the core commands are:

```bash
./scripts/fusesoc/refresh_cores.sh
./scripts/fusesoc/build_platform.sh --dry-run
./scripts/fusesoc/preflight_vivado_build.sh

BUILD_SHA=$(git rev-parse --short=7 HEAD)
export DAPHNE_GIT_SHA="$BUILD_SHA"
export DAPHNE_OUTPUT_DIR="$PWD/xilinx/output-$BUILD_SHA"
./scripts/fusesoc/build_platform.sh
./scripts/fusesoc/package_fullstream_overlay.sh "$DAPHNE_OUTPUT_DIR" "$BUILD_SHA"
./scripts/fusesoc/check_build_outputs.sh "$DAPHNE_OUTPUT_DIR" "$BUILD_SHA"
```

Do not deploy unless the checker ends with `RESULT: PASS` and the release
notes list the intended board and test status.

## What the build produces

The output directory contains:

```text
daphne_fullstream_<sha>.bit
daphne_fullstream_<sha>.bin
daphne_fullstream_<sha>.xsa
daphne_fullstream_ol_<sha>.zip
post_route_timing_summary.rpt
post_route_power.rpt
```

The `.bit` file programs the FPGA directly. The overlay ZIP contains the
`.bin`, `.dtbo`, and `shell.json` files used by Linux.

## Run the formal checks

The formal suite covers the modular boundaries and the extracted stream
selector. It does not prove the complete imported full-stream implementation.

```bash
./scripts/formal/run_formal.sh
```

The runner uses `sby` from the current shell. If present, it also recognizes
`$OSS_CAD_SUITE_ENV` or `$HOME/tools/oss-cad-suite/environment`.

See [formal/README.md](formal/README.md) for the exact proof scope and
[formal/contracts/](formal/contracts/) for the checked contracts.

## Repository map

- `xilinx/`: supported Vivado build and packaging Tcl
- `ip_repo/daphne3_ip/rtl/`: imported full-stream implementation
- `ip_repo/daphne3_ip/rtl/isolated/`: additive modular boundaries
- `cores/`: FuseSoC core descriptions
- `formal/`: proof jobs, harnesses, and contracts
- `scripts/fusesoc/`: build, package, and result-checking commands
- `docs/`: architecture, transition, and operator guides

The active board build still uses the imported
`ip_repo/daphne3_ip/rtl/daphne3.vhd` top. The modular boundary top is a
verification and migration surface; it does not replace the deployed datapath.

## Getting help

Use the `#daphne` channel in the DUNE Slack workspace. When reporting a
failure, include:

- the full commit SHA
- the Vivado version
- the first `ERROR:` line
- the build log
- the output checker result

The broader DAPHNE V3 firmware overview is maintained in
[jamieson-olsen/daphne3](https://github.com/jamieson-olsen/daphne3).
