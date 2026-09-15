#!/bin/bash
# Install a command for an existing native SWL.app without changing shell profiles.
set -euo pipefail
app=${1:-"$HOME/Applications/SWL.app"}
bin_dir=${SWL_COMMAND_BIN_DIR:-"$HOME/.local/bin"}
[[ -d "$app" ]] || { echo "SWL app not found: $app" >&2; exit 1; }
app=$(cd "$app" && pwd)
[[ -x "$app/Contents/MacOS/SWL" ]] || { echo "SWL executable not found in $app" >&2; exit 1; }
identifier=$(/usr/libexec/PlistBuddy -c 'Print :CFBundleIdentifier' "$app/Contents/Info.plist")
[[ "$identifier" == local.scheme.swl.arm64 ]] || { echo "Not a native SWL app: $app" >&2; exit 1; }
mkdir -p "$bin_dir"
bin_dir=$(cd "$bin_dir" && pwd)
command_path="$bin_dir/swl"
marker='# Installed by the native SWL command installer.'
if [[ -e "$command_path" || -L "$command_path" ]]; then
    if [[ -L "$command_path" ]] || ! /usr/bin/grep -Fqx "$marker" "$command_path"; then
        echo "An unrelated command already exists at $command_path; it was not changed." >&2
        exit 1
    fi
fi
temporary=$(mktemp "$bin_dir/.swl.XXXXXXXX")
trap 'rm -f "$temporary"' EXIT
{
    printf '#!/bin/bash\n%s\n' "$marker"
    printf 'exec %q "$@"\n' "$app/Contents/MacOS/SWL"
} > "$temporary"
chmod 755 "$temporary"
mv "$temporary" "$command_path"
echo "Installed command: $command_path"
echo 'Usage: swl file.ss'
case ":$PATH:" in
    *":$bin_dir:"*) ;;
    *)
        echo 'Add this directory to PATH in your shell configuration, then open a new Terminal:'
        printf 'export PATH=%q:"$PATH"\n' "$bin_dir"
        ;;
esac
