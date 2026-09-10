# Native SWL on Apple Silicon

Build SWL 1.3 as an ARM64 macOS application with native Aqua windows.
The installer builds its own nonthreaded Chez Scheme and Tcl/Tk. Docker,
Homebrew, XQuartz, and Rosetta are not needed.

## Student installation

Give students the standalone `dist/Install-SWL.command` produced by
`python3 native-macos/make-student-installer.py`. It contains the complete build
recipe and downloads pinned sources; it does not need a repository checkout,
Git, Homebrew, Docker, Python, or an existing Scheme installation. It requests
Apple's Command Line Tools when missing, then builds a self-contained app in
`~/Applications/SWL.app`. See [the student instructions](STUDENT-SETUP.md).

The prebuilt `dist/SWL-Apple-Silicon.zip` is a second option that needs no compiler.
Neither artifact is published automatically. The app is ad-hoc signed and has
not been notarized by Apple.

## Build from this repository

Use an Apple Silicon Mac with a logged-in desktop session and Apple's Command
Line Tools (or Xcode). The build targets macOS 11 or later; validation on other
macOS versions must be reported separately rather than assumed.

If the developer tools are missing, run `xcode-select --install` and finish
Apple's installer. Clone or download this repository into a path without
spaces, then run from the repository root:

```sh
./native-macos/setup.sh
```

The first build takes several minutes. Sources, build files, logs, the private
runtime, and `SWL.app` are kept in `.native-macos/`. No `sudo`, global Scheme
replacement, shell-profile edit, or system-framework change is performed.
Downloads are checked against the SHA-256 hashes in `sources.tsv` before use.
Rerunning setup reuses completed dependency builds and rebuilds SWL from a fresh
extraction plus `swl-arm64.patch`.
The script uses Apple's build tools explicitly; Homebrew GNU binutils earlier
in your usual `PATH` can otherwise break the Chez bootstrap archive.

## Open SWL or run an assignment

```sh
./native-macos/swl.sh
```

You can also open `.native-macos/SWL.app` in Finder or copy that self-contained app to another folder.

To run AI1 from this repository:

```sh
./native-macos/swl.sh \
  COM316-ArtificialIntelligence/programming_assignments/ai_01_bfs_dfs/grid-main.ss
```

The assignment folder is local course material and is not included in the SWL
setup. Any Scheme source file can be passed in the same way. With one filename,
the launcher sets the working directory to that file's folder so relative helper
loads work. In `grid-main.ss`, select `grid-BFS.ss` or `grid-DFS.ss` rather than
the missing `grid-BEST.ss`.

For manual loading from an already open REPL, set the directory first:

```scheme
(current-directory "/absolute/path/to/ai_01_bfs_dfs")
(load "grid-main.ss")
```

SWL keeps its own preferences under `.native-macos/preferences`. Normal
launches use SWL's existing per-user localhost server to open files in a running
session. Closing the app does not stop a container or service; reopen it with
the same launcher.

## Verify the installation

Run from a normal Mac terminal while logged into the desktop:

```sh
./native-macos/verify.sh
```

This checks the architecture of the Scheme executable, Tcl, Tk, and the SWL C
library, then opens a temporary Aqua window and exercises file-channel pointers
across the Scheme/C interface. The test session is isolated from the regular
SWL session and exits automatically. Success prints:

```text
ARM64_SWL_AQUA_GUI_AND_CHANNEL_OK
Native SWL verification passed.
```

To additionally exercise both AI1 searches without editing assignment files:

```sh
./native-macos/verify.sh \
  COM316-ArtificialIntelligence/programming_assignments/ai_01_bfs_dfs
```

These checks seed the grid generator, select each search implementation in
memory, and verify that the resulting path connects the start and goal using
adjacent steps. They use the assignment's other settings, so a highly blocked
or otherwise modified assignment may legitimately fail. Runtime logs are saved
as `.native-macos/verify-*.log`. A successful run also records the host version,
architectures, and checks in `.native-macos/verification.txt`.

Verified on 2026-09-10 with macOS 26.6.2 on Apple Silicon: all four runtime
components were ARM64, the native Aqua window and Tcl channel read/write check
passed, and the local AI1 BFS and DFS programs completed. With random seed 42,
a 30-by-30 grid, and obstacle density 20, their valid paths contained 9 and 13
nodes respectively. The tests selected each algorithm in memory without editing
the assignment files. Other macOS versions and Rosetta have not been tested.

For results across all 15 course assignment folders, including long-running
programs and reference-file issues, see [the assignment check report](assignment-checks.md).
Repeat the full entry-point check with:

```sh
python3 native-macos/check-assignments.py --timeout 45
```

The report explains the separate bounded checks for minimax and MCTS programs.

## Sources and port changes

The starting point is the [Metacat project's macOS SWL patch](https://science.slc.edu/~jmarshall/metacat/),
credited there to Frank Sinapsi, with macOS packaging changes by James Marshall.
SWL's original copyright notice is preserved in the installed library.

Pinned inputs:

- Chez Scheme 10.4.1, built as `arm64osx` (nonthreaded).
- Tcl 8.6.18 and Tk 8.6.18, compiled for ARM64 with Aqua Tk.
- `swl1.3-src-patched-macOS.tgz`, identified by its checksum in `sources.tsv`.

`swl-arm64.patch` adds the ARM64 build target; replaces 32-bit declarations for
Tcl channel and Tk window pointers with pointer-sized foreign types; enables
macOS event, menu, console, and file-opening behavior for ARM64; and adds
`SWL_NO_SERVER` for isolated verification sessions. The C bridge also retains
`const` on Tcl result strings. The shell launcher preserves quoted arguments
and sets the correct runtime library paths. The app embeds Chez in its native
executable and loads its bundled Tcl/Tk at runtime.

This is a port of SWL to a newer Scheme runtime. It is not the exact Petite
Chez 8.4 environment used by the course container. Validate any assignment
features with the verification commands above and exercise your own programs
before relying on full compatibility with the older runtime.

## Build controls and troubleshooting

- `SWL_BUILD_JOBS=4 ./native-macos/setup.sh` limits parallel compilation.
- `SWL_MACOS_ROOT=/absolute/path ./native-macos/setup.sh` selects another private
  installation location. Use the same variable with `swl.sh` and `verify.sh`.
- Use paths without spaces because upstream SWL makefiles split path arguments.
- The build runtime stays at its configured location. The packaged `SWL.app` is
  relocatable: it embeds its runtime and resolves libraries relative to the app.
- Build failures print the tail of `setup.log`. Versions, source hashes, and the
  port-patch hash are recorded in `build-info.txt`.
- `SWL.app` writes startup messages to `~/Library/Logs/SWL/swl.log`; it keeps
  preferences in `~/Library/Application Support/SWL`. The repository terminal
  launcher keeps using its private build preferences.
- Graphical checks require access to macOS's window server. A restricted tool
  sandbox or a headless SSH session can fail even when the native build is valid.
- If a download fails, retry setup. An interrupted `.part` download is replaced;
  a checksum mismatch stops the build rather than using the file.

## How difficult would Rosetta be?

The Metacat patch already contains an Intel 64-bit (`a6osx`) target, so Rosetta
can reduce the architecture-porting work. It still requires a consistent Intel
stack: Chez Scheme, SWL's C library, and Tcl/Tk must all be x86_64. ARM64
Homebrew libraries cannot be mixed into that process. The old hard-coded
framework paths and compiler settings also need attention.

That is a separate compatibility route, not a one-command guarantee. This
repository's setup targets native ARM64; it does not install Rosetta or claim
to have tested a Rosetta build. Apple's [Rosetta documentation](https://developer.apple.com/documentation/apple-silicon/about-the-rosetta-translation-environment)
explains the process-wide architecture constraint.

## Build and verify student artifacts

`setup.sh` now calls `package-app.sh` to create the self-contained app. To rebuild
only the app from an existing runtime:

```sh
bash native-macos/package-app.sh
python3 native-macos/make-student-installer.py
```

The bootstrap uses stock macOS shell tools; Python is only needed by the
maintainer utilities and optional verification scripts. The single-file installer
can unpack its embedded recipe for review without installing anything:

```sh
bash dist/Install-SWL.command --extract-only /tmp/swl-recipe
```

For testing the student installer without touching your Applications folder, set
`SWL_INSTALL_APP` to an absolute `.app` destination; `SWL_INSTALL_CACHE` and
`SWL_INSTALL_LOG_DIR` can select test cache and log directories. Builds take place
in a temporary path without spaces; the final app destination may contain spaces.

To exercise a packaged app through its actual native executable:

```sh
SWL_VERIFY_RUNTIME="$PWD/.native-macos/SWL.app/Contents/Resources/runtime" \
SWL_VERIFY_LAUNCHER="$PWD/.native-macos/SWL.app/Contents/MacOS/SWL" \
  ./native-macos/verify.sh
```

`bash native-macos/test-student-bootstrap.sh` simulates the missing/present
Command Line Tools branches without uninstalling developer tools from the host.
This simulation is not a test on a freshly erased Mac.
