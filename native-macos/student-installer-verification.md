# Student installer verification

Verified on September 10, 2026, on Apple Silicon running macOS 26.6.2.

- Built Chez Scheme, Tcl, Tk, SWL, and the native app from an empty source-download
  cache, without using Homebrew tools. Repeated the complete build and exercised
  replacement of an existing app; the previous app was preserved as a backup.
- The installed app booted Scheme and passed the Aqua GUI and Tcl file-channel
  checks after its temporary build directory had been removed.
- Packaged `dist/SWL-Apple-Silicon.zip`, extracted it into a different path
  containing spaces, and passed the same GUI checks plus the AI1 BFS and DFS
  checks. The searches returned valid paths of 9 and 13 nodes, respectively.
- The relocated terminal Scheme launcher evaluated `(+ 20 22)` as `42`.
- The default app launch remained running after the splash-screen timeout.
- Verified ARM64 binaries, internal symlinks, relative library dependencies,
  and the app's ad-hoc signature. Included SWL, Chez, Tcl, Tk, LZ4, and zlib
  notices. The final installer payload exactly matches the maintained scripts.
- Checked shell syntax, reproducible installer generation, rejection of a
  corrupted payload, and simulated both missing and existing Apple developer
  tools. The missing-tools simulation requested installation and waited for
  readiness; it did not uninstall this Mac's actual developer tools.
- Installed and opened the finished app at `~/Applications/SWL.app`.

This was not a test on a freshly erased Mac. The macOS 11 deployment target has
not been verified on every supported macOS release. Apple Silicon is required;
Intel and Rosetta builds are outside this installer. The distributed ZIP is
ad-hoc signed, not Apple-notarized. Automated screen capture of the final
installed window failed in the capture service; executable GUI checks passed.
These checks do not establish native REPL menu parity with the Docker version.

Reproduce the checks using `verify.sh`, `test-student-bootstrap.sh`, and the
artifact instructions in [README.md](README.md). Artifact checksums are in
`dist/SHA256SUMS.txt`.
