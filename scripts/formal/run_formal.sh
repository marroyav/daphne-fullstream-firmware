#!/bin/sh
set -eu

ROOT_DIR="${DAPHNE_FULLSTREAM_ROOT:-$(CDPATH= cd -- "$(dirname -- "$0")/../.." && pwd)}"

if ! command -v sby >/dev/null 2>&1; then
  echo "ERROR: symbiyosys (sby) is not installed." >&2
  exit 2
fi

if [ "$#" -eq 0 ]; then
  set -- \
    "$ROOT_DIR/formal/sby/timing_subsystem_boundary_contract.sby" \
    "$ROOT_DIR/formal/sby/frontend_boundary_gate.sby" \
    "$ROOT_DIR/formal/sby/stream_pipeline_boundary_gate.sby" \
    "$ROOT_DIR/formal/sby/stream_mux_select_decode.sby"
fi

for job in "$@"; do
  echo "Running formal scaffold $job"
  job_dir=$(dirname "$job")
  job_file=$(basename "$job")
  (
    cd "$job_dir"
    sby -f "$job_file"
  )
done
