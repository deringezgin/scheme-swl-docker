#!/bin/bash
# This file is embedded in the standalone installer. Use only stock Mac tools.
set -euo pipefail
export PATH=/usr/bin:/bin:/usr/sbin:/sbin

swl_tools_ready() {
    xcrun --find clang >/dev/null 2>&1 &&
        xcrun --find make >/dev/null 2>&1 &&
        xcrun --sdk macosx --show-sdk-path >/dev/null 2>&1
}

swl_require_tools() {
    if swl_tools_ready; then return; fi
    echo "Apple's Command Line Tools are needed to build Scheme."
    echo 'Click Install in the Apple dialog and finish its installation.'
    echo 'This window will continue automatically when the tools are ready.'
    xcode-select --install || true
    local elapsed=0
    while ! swl_tools_ready; do
        if (( elapsed >= 3600 )); then
            echo 'Developer tools are still unavailable. Finish the Apple installation, then run this installer again.' >&2
            return 1
        fi
        sleep 5
        elapsed=$((elapsed + 5))
        if (( elapsed % 60 == 0 )); then echo 'Waiting for the Apple developer-tools installation...'; fi
    done
}

swl_student_install() {
    [[ $(uname -s) == Darwin ]] || { echo 'This installer is for macOS.' >&2; return 1; }
    if [[ $(uname -m) != arm64 ]]; then
        echo 'Use an Apple Silicon Mac and a native Terminal session (not Rosetta).' >&2
        return 1
    fi
    [[ $(id -u) != 0 ]] || { echo 'Run this as the student, without sudo.' >&2; return 1; }
    swl_require_tools || return 1
    local payload_dir="$1"
    local destination=${SWL_INSTALL_APP:-"$HOME/Applications/SWL.app"}
    local cache=${SWL_INSTALL_CACHE:-"$HOME/Library/Caches/SWL"}
    local logs=${SWL_INSTALL_LOG_DIR:-"$HOME/Library/Logs/SWL"}
    [[ "$destination" == /* && "$destination" == *.app ]] || { echo 'SWL_INSTALL_APP must be an absolute .app path.' >&2; return 1; }
    if [[ -e "$destination" ]]; then
        local identifier
        identifier=$(/usr/libexec/PlistBuddy -c 'Print :CFBundleIdentifier' "$destination/Contents/Info.plist" 2>/dev/null || true)
        [[ "$identifier" == local.scheme.swl.arm64 ]] || { echo "An unrelated app already exists at $destination. It was not changed." >&2; return 1; }
    fi
    mkdir -p "$cache/downloads" "$logs"
    local build_root
    build_root=$(mktemp -d /private/tmp/swl-student-build.XXXXXXXX)
    local log="$logs/install-$(date +%Y%m%d-%H%M%S).log"
    mkdir -p "$build_root/downloads"
    cp -R "$cache/downloads/." "$build_root/downloads/"
    echo 'Building SWL and Chez Scheme from verified source downloads.'
    echo 'The first build takes several minutes. No Homebrew or Docker is needed.'
    echo "Build log: $log"
    if ! SWL_MACOS_ROOT="$build_root" /bin/bash "$payload_dir/setup.sh" > "$log" 2>&1; then
        cp -R "$build_root/downloads/." "$cache/downloads/"
        echo "Installation failed. Build files were kept at $build_root" >&2
        tail -n 35 "$log" >&2
        return 1
    fi
    cp -R "$build_root/downloads/." "$cache/downloads/"
    cp "$build_root/setup.log" "$logs/build-$(date +%Y%m%d-%H%M%S).log"
    mkdir -p "$(dirname "$destination")"
    local staging
    staging=$(mktemp -d "$(dirname "$destination")/.swl-install.XXXXXXXX")
    ditto "$build_root/SWL.app" "$staging/SWL.app"
    "$staging/SWL.app/Contents/MacOS/SWL" --check-runtime >> "$log" 2>&1
    if [[ -e "$destination" ]]; then
        local backup="$destination.backup.$(date +%Y%m%d-%H%M%S).$$"
        mv "$destination" "$backup"
        echo "Previous SWL app preserved: $backup"
    fi
    mv "$staging/SWL.app" "$destination"
    rmdir "$staging"
    rm -rf "$build_root"
    echo
    echo "Installed: $destination"
    echo 'Open SWL.app from your Applications folder to start Scheme.'
    echo 'You can delete the installer after setup. The app contains its own runtime.'
    printf 'Terminal Scheme: %q\n' "$destination/Contents/Resources/bin/scheme"
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    swl_student_install "$(cd "$(dirname "$0")" && pwd)"
fi
