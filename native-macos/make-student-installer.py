#!/usr/bin/env python3
"""Maintainer utility: produce a single-file installer containing the build recipe."""
import base64
import gzip
import hashlib
import io
from pathlib import Path
import tarfile

source = Path(__file__).resolve().parent
destination = source.parent / 'dist'
destination.mkdir(exist_ok=True)
files = ['student-bootstrap.sh', 'setup.sh', 'package-app.sh', 'app-main.m', 'install-command.sh',
         'launcher.sh', 'sources.tsv', 'swl-arm64.patch']
payload = io.BytesIO()
with tarfile.open(fileobj=payload, mode='w') as archive:
    for name in files:
        data = (source / name).read_bytes()
        info = tarfile.TarInfo(name)
        info.size, info.mode, info.mtime = len(data), 0o644, 0
        archive.addfile(info, io.BytesIO(data))
data = gzip.compress(payload.getvalue(), mtime=0)
digest = hashlib.sha256(data).hexdigest()
header = '''#!/bin/bash
# SWL / Chez Scheme student installer for Apple Silicon.
# Contains the pinned build recipe, not preinstalled third-party dependencies.
set -euo pipefail
export PATH=/usr/bin:/bin:/usr/sbin:/sbin
umask 077
payload_dir=$(mktemp -d /private/tmp/swl-installer.XXXXXXXX)
trap 'rm -rf "$payload_dir"' EXIT
payload_line=$(awk '/^__SWL_PAYLOAD_BELOW__$/ {print NR + 1; exit}' "$0")
tail -n +"$payload_line" "$0" | base64 -D > "$payload_dir/recipe.tar.gz"
actual=$(shasum -a 256 "$payload_dir/recipe.tar.gz" | awk '{print $1}')
[[ "$actual" == '__DIGEST__' ]] || { echo 'Installer payload checksum failed.' >&2; exit 1; }
tar -xzf "$payload_dir/recipe.tar.gz" -C "$payload_dir"
if [[ "${1:-}" == --extract-only ]]; then
    [[ $# == 2 ]] || { echo 'Usage: Install-SWL.command --extract-only DIRECTORY' >&2; exit 1; }
    mkdir -p "$2"
    for file in "$payload_dir"/*; do
        [[ "$file" == *.tar.gz ]] || cp "$file" "$2/"
    done
    exit 0
fi
/bin/bash "$payload_dir/student-bootstrap.sh"
exit 0
__SWL_PAYLOAD_BELOW__
'''.replace('__DIGEST__', digest)
installer = destination / 'Install-SWL.command'
installer.write_text(header + base64.encodebytes(data).decode('ascii'))
installer.chmod(0o755)
(destination / 'Install-SWL.command.sha256').write_text(
    hashlib.sha256(installer.read_bytes()).hexdigest() + '  Install-SWL.command\n')
print(installer)
