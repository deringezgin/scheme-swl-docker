#!/bin/bash
# Build an isolated, native ARM64 SWL installation. No sudo or Homebrew needed.
set -euo pipefail
# Chez's zlib bootstrap needs Apple's Mach-O archive tools. Homebrew binutils
# earlier in PATH can silently produce archives that Apple's linker rejects.
export PATH=/usr/bin:/bin:/usr/sbin:/sbin
script_dir=$(cd "$(dirname "$0")" && pwd)
repo_dir=$(cd "$script_dir/.." && pwd)
root=${SWL_MACOS_ROOT:-"$repo_dir/.native-macos"}
case "$root" in /*) ;; *) echo 'SWL_MACOS_ROOT must be an absolute path.' >&2; exit 1;; esac
case "$root" in *[[:space:]]*) echo 'The legacy SWL build requires an installation path without spaces.' >&2; exit 1;; esac
[[ $(uname -s) == Darwin && $(uname -m) == arm64 ]] || { echo 'Run this script in a native Apple Silicon terminal (not Rosetta).' >&2; exit 1; }
xcrun --find clang >/dev/null 2>&1 || { echo 'Install Apple Command Line Tools with: xcode-select --install' >&2; exit 1; }
for tool in curl tar shasum patch make; do command -v "$tool" >/dev/null || { echo "Missing tool: $tool" >&2; exit 1; }; done
mkdir -p "$root/downloads" "$root/build" "$root/runtime"
root=$(cd "$root" && pwd)
prefix="$root/runtime"
jobs=${SWL_BUILD_JOBS:-$(sysctl -n hw.ncpu 2>/dev/null || echo 4)}
[[ "$jobs" =~ ^[1-9][0-9]*$ ]] || { echo 'SWL_BUILD_JOBS must be a positive integer.' >&2; exit 1; }
if (( jobs > 8 )); then jobs=8; fi
export MACOSX_DEPLOYMENT_TARGET=11.0
export SWL_NATIVE_PREFIX="$prefix"
log="$root/setup.log"
trap 'echo "Build failed. See $log" >&2; tail -n 35 "$log" >&2' ERR
: > "$log"
while IFS=$'\t' read -r name digest url; do
    file="$root/downloads/$name"
    if [[ ! -f "$file" ]]; then
        echo "Downloading $name"
        curl --fail --location --retry 3 --output "$file.part" "$url"
        mv "$file.part" "$file"
    fi
    actual=$(shasum -a 256 "$file" | awk '{print $1}')
    [[ "$actual" == "$digest" ]] || { echo "Checksum mismatch: $file" >&2; exit 1; }
done < "$script_dir/sources.tsv"

if [[ ! -f "$root/.chez-10.4.1-arm64osx" || ! -x "$prefix/bin/scheme" ]]; then
    echo 'Building Chez Scheme 10.4.1 (nonthreaded ARM64); first build can take several minutes.'
    tar -xzf "$root/downloads/csv10.4.1.tar.gz" -C "$root/build"
    (
        cd "$root/build/csv10.4.1"
        ./configure --machine=arm64osx --disable-x11 --installprefix="$prefix"
        make -j"$jobs"
        make install
    ) >> "$log" 2>&1
    touch "$root/.chez-10.4.1-arm64osx"
fi
if [[ ! -f "$root/.tcl-8.6.18-arm64" || ! -f "$prefix/lib/libtcl8.6.dylib" ]]; then
    echo 'Building Tcl 8.6.18.'
    tar -xzf "$root/downloads/tcl8.6.18.tar.gz" -C "$root/build"
    (
        cd "$root/build/tcl-core-8-6-18/unix"
        ./configure --prefix="$prefix" --enable-shared --enable-64bit CFLAGS='-O2 -arch arm64 -mmacosx-version-min=11.0'
        make -j"$jobs"
        make install
    ) >> "$log" 2>&1
    touch "$root/.tcl-8.6.18-arm64"
fi
if [[ ! -f "$root/.tk-8.6.18-arm64" || ! -f "$prefix/lib/libtk8.6.dylib" ]]; then
    echo 'Building Tk 8.6.18 with the native Aqua window system.'
    tar -xzf "$root/downloads/tk8.6.18.tar.gz" -C "$root/build"
    (
        cd "$root/build/tk-core-8-6-18/unix"
        ./configure --prefix="$prefix" --with-tcl="$prefix/lib" --enable-aqua --enable-shared --enable-64bit CFLAGS='-O2 -arch arm64 -mmacosx-version-min=11.0'
        make -j"$jobs"
        make install
    ) >> "$log" 2>&1
    touch "$root/.tk-8.6.18-arm64"
fi

echo 'Building patched SWL 1.3 for Apple Silicon.'
# A fresh extraction prevents old Scheme objects or a previously applied patch
# from contaminating a rebuild. Only this script's disposable build tree is removed.
if [[ -d "$root/build/swl1.3" ]]; then rm -rf "$root/build/swl1.3"; fi
tar -xzf "$root/downloads/swl1.3-src-patched-macOS.tgz" -C "$root/build"
(
    cd "$root/build/swl1.3"
    patch -p1 < "$script_dir/swl-arm64.patch"
    make Scheme="$prefix/bin/scheme" Tclsh="$prefix/bin/tclsh8.6"
    make -f Mf-install I=./installsh InstallBin="$prefix/bin" InstallLib="$prefix/lib/swl1.3"
    cp Notice "$prefix/lib/swl1.3/Notice"
) >> "$log" 2>&1
# Replace the historical launcher, which lacks a shebang and loses quoted args.
chmod u+w "$prefix/bin/swl"
cp "$script_dir/launcher.sh" "$prefix/bin/swl"
chmod 755 "$prefix/bin/swl"

{
    date -u '+Built: %Y-%m-%dT%H:%M:%SZ'
    sw_vers
    xcrun clang --version | head -n 1
    printf '(printf "~a ~s threaded=~s\\n" (scheme-version) (machine-type) (threaded?))\n' | "$prefix/bin/scheme" -q
    shasum -a 256 "$script_dir/swl-arm64.patch"
    cat "$script_dir/sources.tsv"
} > "$root/build-info.txt"
/bin/bash "$script_dir/package-app.sh" "$root/SWL.app" >> "$log" 2>&1
echo "Installed: $prefix/bin/swl"
echo "Launch: $prefix/bin/swl [your-program.ss]"
echo "App: $root/SWL.app"
printf 'Verify: SWL_MACOS_ROOT=%q %q\n' "$root" "$script_dir/verify.sh"
