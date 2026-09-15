#!/bin/bash
# Open a source file for editing; --load explicitly evaluates it instead.
set -euo pipefail
contents=$(cd "$(dirname "$0")/../.." && pwd)
executable="$contents/MacOS/SWL"
if [[ $# == 0 ]]; then exec "$executable"; fi
mode=edit
case "$1" in
    --load) mode=load; shift ;;
    --edit) shift; if [[ $# == 0 ]]; then exec "$executable" --edit; fi ;;
    --) shift ;;
    -h|--help)
        echo 'Usage: swl [--load] FILE.ss'
        echo 'Open FILE.ss in the editor, using its directory for helper loads.'
        echo 'Use --load to evaluate the file immediately; use swl alone for a REPL.'
        exit 0 ;;
esac
[[ $# == 1 ]] || { echo 'Usage: swl [--load] FILE.ss' >&2; exit 2; }
[[ -f "$1" ]] || { echo "Scheme file not found: $1" >&2; exit 1; }
directory=$(cd "$(dirname "$1")" && pwd)
filename=$(basename "$1")
cd "$directory"
if [[ "$mode" == edit ]]; then
    exec "$executable" --edit "$directory/$filename"
fi
exec "$executable" "$directory/$filename"
