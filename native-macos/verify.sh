#!/bin/bash
# Requires a logged-in macOS graphical session. Optional argument: AI1 folder.
set -euo pipefail
script_dir=$(cd "$(dirname "$0")" && pwd)
repo_dir=$(cd "$script_dir/.." && pwd)
root=${SWL_MACOS_ROOT:-"$repo_dir/.native-macos"}
python3 - "$root" "$script_dir" "${1:-}" <<'PY'
from pathlib import Path
from datetime import datetime, timezone
import os
import subprocess
import sys
import tempfile

root, scripts = (Path(p).resolve() for p in sys.argv[1:3])
prefix = Path(os.environ.get('SWL_VERIFY_RUNTIME', str(root / 'runtime'))).resolve()
launcher = Path(os.environ.get('SWL_VERIFY_LAUNCHER', str(prefix / 'bin/swl'))).resolve()
report = []
def record(message):
    report.append(message)
    print(message, flush=True)

record('Verified at: ' + datetime.now(timezone.utc).isoformat())
record(subprocess.check_output(['sw_vers'], text=True).strip())
for rel in ['bin/scheme', 'lib/libtcl8.6.dylib', 'lib/libtk8.6.dylib', 'lib/swl1.3/arm64osx/swl.so']:
    info = subprocess.check_output(['file', '-L', str(prefix / rel)], text=True).strip()
    if 'arm64' not in info or 'x86_64' in info:
        raise SystemExit('Wrong architecture: ' + info)
    record(info)

def run_check(name, script, cwd, extra=None):
    with tempfile.TemporaryDirectory(prefix='swl-verify-', dir=root) as directory:
        env = dict(os.environ, SWL_NO_SERVER='1', SWL_VERIFY_DIR=directory, SWL_PREFS_DIR=directory, SWL_STDIO='1')
        env.update(extra or {})
        log = root / (name + '.log')
        driver = Path(directory) / 'driver.ss'
        driver.write_text('(guard (c [else\n  (with-output-to-file (string-append (getenv "SWL_VERIFY_DIR") "/failure.txt")\n    (lambda () (display-condition c)) \'replace)\n  ((foreign-procedure "_exit" (int) void) 1)])\n  (load (getenv "SWL_VERIFY_SCRIPT")))\n')
        env['SWL_VERIFY_SCRIPT'] = str(script)
        with log.open('w') as out:
            try:
                result = subprocess.run([str(launcher), str(driver)],
                                        cwd=cwd, env=env, stdout=out, stderr=subprocess.STDOUT,
                                        timeout=45)
            except subprocess.TimeoutExpired:
                raise SystemExit(f'{name} timed out; see {log}')
        sentinel = Path(directory) / 'success.txt'
        if result.returncode != 0 or not sentinel.exists():
            failure = Path(directory) / 'failure.txt'
            if failure.exists():
                with log.open('a') as out:
                    out.write(failure.read_text())
            print(log.read_text())
            raise SystemExit(f'{name} failed ({result.returncode}); see {log}')
        record(sentinel.read_text().strip())

run_check('verify-gui', scripts / 'smoke-test.ss', scripts)
if sys.argv[3]:
    assignment = Path(sys.argv[3]).resolve()
    for algorithm in ['BFS', 'DFS']:
        run_check('verify-ai1-' + algorithm.lower(), scripts / 'verify-ai1.ss', assignment,
                  {'SWL_AI1_ALGORITHM': algorithm, 'SWL_AI1_DIR': str(assignment)})
record('Native SWL verification passed.')
(root / 'verification.txt').write_text('\n'.join(report) + '\n')
PY
