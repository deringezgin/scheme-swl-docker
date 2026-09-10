#!/bin/bash
# Exercise prerequisite handling without removing this Mac's developer tools.
set -euo pipefail
script_dir=$(cd "$(dirname "$0")" && pwd)
source "$script_dir/student-bootstrap.sh"
test_dir=$(mktemp -d /private/tmp/swl-bootstrap-test.XXXXXXXX)
trap 'rm -rf "$test_dir"' EXIT

swl_tools_ready() { [[ -f "$test_dir/ready" ]]; }
xcode-select() {
    [[ "$1" == --install ]]
    echo requested >> "$test_dir/requests"
}
sleep() {
    echo waited >> "$test_dir/waits"
    if [[ $(wc -l < "$test_dir/waits") -eq 2 ]]; then touch "$test_dir/ready"; fi
}
swl_require_tools
[[ $(wc -l < "$test_dir/requests") -eq 1 ]]
[[ $(wc -l < "$test_dir/waits") -eq 2 ]]
swl_require_tools
[[ $(wc -l < "$test_dir/requests") -eq 1 ]]
echo 'PASS: missing tools request Apple installation and wait; existing tools skip installation.'
