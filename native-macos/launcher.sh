#!/bin/bash
set -euo pipefail
prefix=$(cd "$(dirname "$0")/.." && pwd)
export SWL_RUNTIME_ROOT="$prefix"
export SCHEMEHEAPDIRS="$prefix/lib/csv10.4.1/arm64osx"
export TCL_LIBRARY="$prefix/lib/tcl8.6"
export TK_LIBRARY="$prefix/lib/tk8.6"
export SWL_ROOT="$prefix/lib/swl1.3/lib"
export SWL_LIBRARY="$prefix/lib/swl1.3/arm64osx"
export SWL_PREFS_DIR=${SWL_PREFS_DIR:-"$prefix/../preferences"}
mkdir -p "$SWL_PREFS_DIR"
# SWL's helper loads are relative to the process working directory.
if [[ $# == 1 && -f "$1" ]]; then
    program_dir=$(cd "$(dirname "$1")" && pwd)
    program_name=$(basename "$1")
    cd "$program_dir"
    set -- "$program_dir/$program_name"
fi
exec "$prefix/bin/scheme" -b "$SWL_LIBRARY/swl.boot" "$@"
