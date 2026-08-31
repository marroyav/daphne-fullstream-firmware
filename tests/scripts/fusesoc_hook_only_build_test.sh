#!/bin/sh
set -eu

ROOT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")/../.." && pwd)
TEST_ROOT=$(mktemp -d)
cleanup() {
  rm -rf -- "$TEST_ROOT"
}
trap cleanup EXIT HUP INT TERM

"$ROOT_DIR/scripts/fusesoc/refresh_cores.sh" >/dev/null
for core in \
  dune-daq:daphne-fullstream:k26c-platform:0.1.0 \
  dune-daq:daphne-fullstream:k26c-modular-platform:0.1.0
do
  core_id=$(printf '%s' "$core" | tr ':' '_')
  work_root="$TEST_ROOT/$core_id/impl-vivado"
  plan="$TEST_ROOT/$core_id.pre-build-plan.log"
  setup_log="$TEST_ROOT/$core_id.setup.log"

  "$ROOT_DIR/scripts/fusesoc/fusesoc.sh" run \
    --setup \
    --work-root "$work_root" \
    --target impl \
    "$core" >"$setup_log" 2>&1

  if [ ! -s "$work_root/Makefile" ]; then
    echo "ERROR: FuseSoC did not generate the Vivado Makefile for $core." >&2
    cat "$setup_log" >&2
    exit 1
  fi

  make -n -C "$work_root" pre_build >"$plan"
  if ! grep -Fq 'sh scripts/fusesoc/vivado_batch_hook.sh' "$plan"; then
    echo "ERROR: $core pre_build does not invoke the qualified fullstream hook." >&2
    cat "$plan" >&2
    exit 1
  fi

  if grep -Eq '_synth\.tcl|_run\.tcl|post_build|synth_1' "$plan"; then
    echo "ERROR: $core pre_build reaches Edalize's redundant synthesis stage." >&2
    cat "$plan" >&2
    exit 1
  fi
done

if ! grep -Fq "\"\$DAPHNE_MAKE\" -C \"\$FUSESOC_WORK_ROOT\" pre_build" \
  "$ROOT_DIR/scripts/fusesoc/build_platform.sh"; then
  echo "ERROR: build_platform.sh does not select the generated pre_build target." >&2
  exit 1
fi

dry_run_output=$(DAPHNE_FUSESOC_IMPL_WORK_ROOT="$TEST_ROOT/dry-run" \
  "$ROOT_DIR/scripts/fusesoc/build_platform.sh" --dry-run)
printf '%s\n' "$dry_run_output" | grep -Fq 'INFO: FuseSoC stage: setup'
printf '%s\n' "$dry_run_output" | grep -Fq 'INFO: Generated Make target: pre_build'
printf '%s\n' "$dry_run_output" | grep -Fq 'INFO: Dry-run only, stopping before Vivado.'

echo "RESULT: PASS - FuseSoC setup feeds only the repo-owned pre_build hook"
