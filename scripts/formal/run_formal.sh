#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="${DAPHNE_FULLSTREAM_ROOT:-$(CDPATH= cd -- "$(dirname -- "$0")/../.." && pwd)}"
OSS_CAD_ENV="${OSS_CAD_SUITE_ENV:-$HOME/tools/oss-cad-suite/environment}"

if ! command -v sby >/dev/null 2>&1 && [ -f "$OSS_CAD_ENV" ]; then
  # shellcheck disable=SC1090
  . "$OSS_CAD_ENV"
fi

if ! command -v sby >/dev/null 2>&1; then
  echo "ERROR: symbiyosys (sby) is not installed." >&2
  echo "Hint: source an OSS CAD Suite environment or set OSS_CAD_SUITE_ENV." >&2
  exit 2
fi

if [ "$#" -eq 0 ]; then
  set -- \
    "$ROOT_DIR/formal/sby/daphne_fullstream_boundary_top_contract.sby" \
    "$ROOT_DIR/formal/sby/timing_subsystem_boundary_contract.sby" \
    "$ROOT_DIR/formal/sby/frontend_boundary_gate.sby" \
    "$ROOT_DIR/formal/sby/stream_pipeline_boundary_gate.sby" \
    "$ROOT_DIR/formal/sby/spy_buffer_boundary_gate.sby" \
    "$ROOT_DIR/formal/sby/hermes_boundary_contract.sby" \
    "$ROOT_DIR/formal/sby/stream_mux_select_decode.sby"
fi

passed=0
failed=0

for job in "$@"; do
  echo "Running formal scaffold $job"
  job_dir=$(dirname "$job")
  job_file=$(basename "$job")
  if (
    cd "$job_dir"
    sby -f "$job_file"
  ); then
    passed=$((passed + 1))
  else
    failed=$((failed + 1))
  fi
done

printf '\nFormal summary: %s passed, %s failed\n' "$passed" "$failed"
test "$failed" -eq 0
