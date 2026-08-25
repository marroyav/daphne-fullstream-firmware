# Build full-stream firmware on Cooper

This is the short, repeatable path for the K26C DAPHNE board. The build creates
the FPGA bitstream, hardware handoff, device-tree overlay, reports, and a zipped
overlay.

## Log in

On the Linux workstation:

```bash
FNAL_USER=REPLACE_WITH_FNAL_USERNAME
kinit "$FNAL_USER@FNAL.GOV"
ssh -K -tt fnal-workstation-bridge \
  "ssh -K $FNAL_USER@cooper.dhcp.fnal.gov"
```

If SSH says `Permission denied (gssapi...)`, the FNAL ticket is missing or has
expired. Run `kinit "$FNAL_USER@FNAL.GOV"` again on the workstation, then
retry.

## Prepare the build shell

On Cooper, enter a clean detached checkout of the approved full commit or tag.
Do not release a build from a moving branch:

```bash
cd /path/to/daphne-fullstream-firmware
git status --short
source /tools/2026.1/Vitis/settings64.sh
source /tools/petalinux/settings.sh
```

Use a `tmux` session if the workstation connection may close:

```bash
tmux new -s daphne-fullstream
```

Detach with `Ctrl-b d`. Return later with:

```bash
tmux attach -t daphne-fullstream
```

## Run the quick checks

```bash
./scripts/fusesoc/refresh_cores.sh
git diff --exit-code -- cores/generated/daphne-fullstream-ip.core
python3 scripts/check_documentation.py
python3 scripts/check_register_map.py
./scripts/fusesoc/build_platform.sh --dry-run
./scripts/fusesoc/preflight_vivado_build.sh
```

Do not start the long build if one of these commands fails. Keep the complete
error text; the first `ERROR:` line is usually the useful one.

## Build

```bash
BUILD_SHA=$(git rev-parse --short=7 HEAD)
export DAPHNE_GIT_SHA="$BUILD_SHA"
export DAPHNE_MAX_THREADS=8
export DAPHNE_OUTPUT_DIR="$PWD/xilinx/output-$BUILD_SHA"
./scripts/fusesoc/build_platform.sh 2>&1 | tee "build-$BUILD_SHA.log"
```

This is a complete Vivado synthesis and implementation run. It can take a long
time and use several gigabytes of memory. A successful run ends with:

```text
INFO: Finished design building.
```

## Check the result

Run the checker with the same shell variables:

```bash
./scripts/fusesoc/check_build_outputs.sh \
  "$DAPHNE_OUTPUT_DIR" "$BUILD_SHA"
```

The Linux build packages the overlay and creates `SHA256SUMS` automatically.
The checker verifies those checksums and the implementation gates.

The final line must start with `RESULT: PASS`. The important files are:

```text
xilinx/output-<sha>/daphne_fullstream_<sha>.bit
xilinx/output-<sha>/daphne_fullstream_<sha>.xsa
xilinx/output-<sha>/daphne_fullstream_ol_<sha>.zip
xilinx/output-<sha>/SHA256SUMS
xilinx/output-<sha>/post_route_timing_summary.rpt
xilinx/output-<sha>/post_route_bus_skew.rpt
xilinx/output-<sha>/post_route_cdc.rpt
xilinx/output-<sha>/post_route_methodology.rpt
xilinx/output-<sha>/post_route_status.rpt
xilinx/output-<sha>/post_route_power.rpt
xilinx/output-<sha>/post_route_util.rpt
xilinx/output-<sha>/post_imp_drc.rpt
xilinx/output-<sha>/release_cells.rpt
```

The `.bit` file is for FPGA programming. The overlay `.zip` contains the `.bin`,
`.dtbo`, and `shell.json` files used by Linux.

## Easy recovery notes

- SSH failed: renew the FNAL ticket on the workstation with
  `kinit "$FNAL_USER@FNAL.GOV"`.
- The terminal closed: reconnect to Cooper and run
  `tmux attach -t daphne-fullstream`.
- The preflight failed: stop there. Save its full output before changing files.
- The long build failed: keep `build-<sha>.log` and the output directory. Start
  the next attempt with a different `DAPHNE_OUTPUT_DIR` so the evidence is not
  overwritten.
- Timing failed: do not deploy that bitstream. Open
  `post_route_timing_summary.rpt` and search for `VIOLATED`.
- Device-tree generation failed after the bitstream was written: keep the `.bit`
  and `.xsa`. With the Vivado/Vitis environment still loaded, package those
  completed files without rebuilding the FPGA:

  ```bash
  ./scripts/fusesoc/package_fullstream_overlay.sh "$DAPHNE_OUTPUT_DIR" "$BUILD_SHA"
  ./scripts/fusesoc/check_build_outputs.sh "$DAPHNE_OUTPUT_DIR" "$BUILD_SHA"
  ```

  Vivado 2026.1 uses `sdtgen`; the retired XSCT command is not required.
