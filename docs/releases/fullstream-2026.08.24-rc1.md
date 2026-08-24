# Full-stream 2026.08.24 release candidate

This candidate is for one K26C DAPHNE board at a time. It builds the
full-stream firmware and enables the four streaming links in the design.

It is a test candidate, not a production image.

## Before you use it

Check the downloaded files:

```bash
sha256sum -c SHA256SUMS
```

Every line must end in `OK`. Stop if a checksum fails.

The FPGA artifact was built with Vivado 2026.1 on Cooper. Keep the bitstream,
XSA, overlay ZIP, reports, and `SHA256SUMS` together. Do not mix files from
another release.

## Build it again

On Cooper, from a clean checkout of this tag:

```bash
source /tools/2026.1/Vitis/settings64.sh

BUILD_SHA=$(git rev-parse --short=7 HEAD)
export DAPHNE_GIT_SHA="$BUILD_SHA"
export DAPHNE_MAX_THREADS=8
export DAPHNE_OUTPUT_DIR="$PWD/xilinx/output-$BUILD_SHA"

./scripts/fusesoc/refresh_cores.sh
./scripts/fusesoc/preflight_vivado_build.sh
./scripts/fusesoc/build_platform.sh
./scripts/fusesoc/package_fullstream_overlay.sh "$DAPHNE_OUTPUT_DIR" "$BUILD_SHA"
./scripts/fusesoc/check_build_outputs.sh "$DAPHNE_OUTPUT_DIR" "$BUILD_SHA"
```

Good result: the final checker line starts with `RESULT: PASS`.

## What has been checked

- the fan monitor and all implemented board-control register write/readback
  paths pass GHDL smoke tests
- all seven checked-in formal jobs pass
- the source manifest and build preflight pass
- synthesis, implementation, timing, DRC, power reporting, and overlay
  packaging are checked by the Cooper release build

Formal verification covers the modular boundaries and extracted selector. It
does not prove the complete imported full-stream datapath.

Run both vendor-neutral suites with:

```bash
./scripts/fusesoc/run_logic_test.sh
./scripts/formal/run_formal.sh
```

## What still needs a board

Before promotion, test on a DAPHNE board:

1. Configure all front-end settings and read them back.
2. Enable all four streaming links together.
3. Confirm link-up and continuous data at the receiver.
4. Exercise the timing endpoint and timing commands.
5. Measure board power before streaming and with all links active.
6. Capture waveforms, RMS statistics, packet counters, and error counters.

Record the board asset number, firmware SHA, timing source, receiver setup,
power readings, and evidence directory.

## Known limitation

Vivado 2026.1 on Cooper currently reports the XXV Ethernet feature keys as
unlicensed. A bitstream may still be generated, but this candidate must not be
called production-qualified until the entitlement is confirmed and all four
links pass the hardware test.

## Easy recovery notes

- **Checksum failed:** download or copy the release again.
- **Preflight failed:** stop before the long build and keep the first
  `ERROR:` line.
- **Timing failed:** do not deploy; search the timing report for `VIOLATED`.
- **Overlay packaging failed after bit generation:** keep the `.bit` and
  `.xsa`, then rerun only `package_fullstream_overlay.sh`.
- **A link stays down:** return to a known self-trigger image, check the
  receiver and fiber, then test one link before enabling all four.
