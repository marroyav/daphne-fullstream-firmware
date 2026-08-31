# TCL script to build DAPHNE3 vivado design
# Daniel Avila Gomez <daniel.avila@eia.edu.co - daniel.avila.gomez@cern.ch> and Jamieson Olsen <jamieson@fnal.gov>
#
# Prefer scripts/fusesoc/run_vivado_batch.sh. It waits for Vivado to exit before
# starting SDTGen, which avoids sharing Vivado's live hardware-platform state.

set script_dir [file dirname [file normalize [info script]]]
source -notrace [file join $script_dir "daphne_fullstream_vivado_flow.tcl"]
daphne_fullstream_run_full_build $script_dir
