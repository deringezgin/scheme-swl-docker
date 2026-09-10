#!/bin/bash
set -euo pipefail
repo_dir=$(cd "$(dirname "$0")/.." && pwd)
root=${SWL_MACOS_ROOT:-"$repo_dir/.native-macos"}
[[ -x "$root/runtime/bin/swl" ]] || { echo "Run $repo_dir/native-macos/setup.sh first." >&2; exit 1; }
exec "$root/runtime/bin/swl" "$@"
