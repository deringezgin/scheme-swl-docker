#!/bin/bash
# Package the built runtime into a relocatable application. System tools only.
set -euo pipefail
export PATH=/usr/bin:/bin:/usr/sbin:/sbin
script_dir=$(cd "$(dirname "$0")" && pwd)
root=${SWL_MACOS_ROOT:-"$(cd "$script_dir/.." && pwd)/.native-macos"}
root=$(cd "$root" && pwd)
prefix="$root/runtime"
output=${1:-"$root/SWL.app"}
[[ -f "$prefix/lib/swl1.3/arm64osx/swl.boot" ]] || { echo 'Run setup.sh first.' >&2; exit 1; }
mkdir -p "$(dirname "$output")"
stage=$(mktemp -d "$(dirname "$output")/.swl-package.XXXXXXXX")
trap 'rm -rf "$stage"' EXIT
app="$stage/SWL.app"
contents="$app/Contents"
resources="$contents/Resources"
mkdir -p "$contents/MacOS" "$resources/bin" "$resources/Notices"
cp -R "$prefix" "$resources/runtime"
bundle_runtime="$resources/runtime"

# Remove every link back to the build machine. Libraries resolve relative to
# the Mach-O file loading them; Scheme boot paths are set by the launchers.
while IFS= read -r -d '' binary; do
    kind=$(file -b "$binary")
    [[ "$kind" == *Mach-O* ]] || continue
    [[ "$kind" == *arm64* && "$kind" != *x86_64* ]] || { echo "Wrong architecture: $binary" >&2; exit 1; }
    chmod u+w "$binary"
    if [[ "$kind" == *'dynamically linked shared library'* ]]; then
        install_name_tool -id "@rpath/$(basename "$binary")" "$binary"
    fi
    relative_dir=${binary%/*}
    relative_dir=${relative_dir#"$bundle_runtime"}
    upward=''
    while [[ -n "$relative_dir" ]]; do
        upward="../$upward"
        relative_dir=${relative_dir%/*}
    done
    while IFS= read -r dependency; do
        case "$dependency" in
            "$prefix/"*)
                install_name_tool -change "$dependency" "@loader_path/$upward${dependency#"$prefix/"}" "$binary" ;;
            /System/*|/usr/lib/*|@*) ;;
            *) echo "Unexpected external library in $binary: $dependency" >&2; exit 1 ;;
        esac
    done < <(otool -L "$binary" | awk 'NR>1 {sub(/^[ \t]+/, ""); sub(/ \(compatibility.*/, ""); print}')
    codesign --force --sign - --timestamp=none "$binary"
done < <(find "$bundle_runtime" -type f -print0)

kernel="$prefix/lib/csv10.4.1/arm64osx"
xcrun clang -O2 -arch arm64 -mmacosx-version-min=11.0 -fobjc-arc \
    -I"$kernel" "$script_dir/app-main.m" "$kernel/libkernel.a" \
    "$kernel/libz.a" "$kernel/liblz4.a" -liconv -lncurses -framework Cocoa \
    -o "$contents/MacOS/SWL"

cat > "$contents/Info.plist" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
<key>CFBundleExecutable</key><string>SWL</string>
<key>CFBundleIdentifier</key><string>local.scheme.swl.arm64</string>
<key>CFBundleName</key><string>SWL</string>
<key>CFBundleDisplayName</key><string>SWL</string>
<key>CFBundlePackageType</key><string>APPL</string>
<key>CFBundleVersion</key><string>1.3.2</string>
<key>CFBundleShortVersionString</key><string>1.3.2</string>
<key>LSMinimumSystemVersion</key><string>11.0</string>
<key>LSArchitecturePriority</key><array><string>arm64</string></array>
<key>NSHighResolutionCapable</key><true/>
<!-- SWL uses fixed white text backgrounds; keep system text/cursor colors dark. -->
<key>NSRequiresAquaSystemAppearance</key><true/>
</dict></plist>
PLIST
cat > "$resources/bin/scheme" <<'SCHEME'
#!/bin/bash
set -euo pipefail
runtime=$(cd "$(dirname "$0")/../runtime" && pwd)
export SCHEMEHEAPDIRS="$runtime/lib/csv10.4.1/arm64osx"
exec "$runtime/bin/scheme" "$@"
SCHEME
cat > "$resources/bin/swl" <<'SWL'
#!/bin/bash
set -euo pipefail
contents=$(cd "$(dirname "$0")/../.." && pwd)
exec "$contents/MacOS/SWL" "$@"
SWL
chmod 755 "$resources/bin/scheme" "$resources/bin/swl"
cp "$root/build-info.txt" "$resources/build-info.txt"
cp "$script_dir/sources.tsv" "$script_dir/swl-arm64.patch" "$resources/"
cp "$prefix/lib/swl1.3/Notice" "$resources/Notices/SWL.txt"
cp "$root/build/csv10.4.1/LICENSE" "$resources/Notices/Chez-Scheme.txt"
cp "$root/build/csv10.4.1/NOTICE" "$resources/Notices/Chez-Scheme-NOTICE.txt"
cp "$root/build/csv10.4.1/lz4/lib/LICENSE" "$resources/Notices/LZ4.txt"
cp "$root/build/csv10.4.1/zlib/LICENSE" "$resources/Notices/zlib.txt"
cp "$root/build/tcl-core-8-6-18/license.terms" "$resources/Notices/Tcl.txt"
cp "$root/build/tk-core-8-6-18/license.terms" "$resources/Notices/Tk.txt"
printf 'Built by the SWL Apple Silicon student installer.\n' > "$resources/student-installer.txt"
plutil -lint "$contents/Info.plist"
codesign --force --sign - --timestamp=none "$app"
codesign --verify --deep --strict "$app"
if [[ -e "$output" ]]; then
    identifier=$(/usr/libexec/PlistBuddy -c 'Print :CFBundleIdentifier' "$output/Contents/Info.plist" 2>/dev/null || true)
    [[ "$identifier" == local.scheme.swl.arm64 ]] || { echo "Refusing to replace an unrelated app: $output" >&2; exit 1; }
    backup="$output.backup.$(date +%Y%m%d-%H%M%S).$$"
    mv "$output" "$backup"
    echo "Previous app preserved: $backup"
fi
mv "$app" "$output"
echo "Packaged: $output"
