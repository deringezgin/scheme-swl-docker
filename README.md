# Scheme and SWL

Install Scheme and SWL as a native app on an **Apple Silicon Mac** (M-series).
You need an internet connection. No existing Scheme installation, Homebrew,
Docker, or Python is required.

## Install SWL.app

1. Download [Install-SWL.command](https://github.com/deringezgin/scheme-swl-docker/raw/refs/heads/main/dist/Install-SWL.command)
   into your **Downloads** folder.
2. Open **Terminal** and run:

   ```sh
   bash "$HOME/Downloads/Install-SWL.command"
   ```

3. If Apple's developer-tools dialog appears, click **Install** and finish that
   installation. Leave Terminal open; SWL setup continues automatically.
4. Wait for **Installed:** in Terminal. The first build takes several minutes.

The installer builds Scheme and SWL and installs the self-contained app at
`~/Applications/SWL.app`. You can delete the installer afterward.

## Open SWL

Double-click **SWL.app** in your home folder's **Applications** folder, or run:

```sh
open "$HOME/Applications/SWL.app"
```

You only need to run the installer once. Open the app directly for later sessions.

## Run from Terminal

Install the `swl` command once:

```sh
bash "$HOME/Applications/SWL.app/Contents/Resources/bin/install-command.sh"
```

Then run a Scheme file from any directory:

```sh
swl file.ss
swl "/path/to/my assignment/grid-main.ss"
```

SWL loads the file with its containing folder as the working directory, so
relative helper loads work. `swl` by itself opens the REPL. The command is installed
in `~/.local/bin`; if setup prints a PATH instruction, add that line to `~/.zshrc`
and open a new Terminal window.

## Load an assignment

Keep the assignment's helper files together. In the SWL REPL, set the working
directory and load the main file:

```scheme
(current-directory "/Users/your-name/Downloads/ai_01_bfs_dfs")
(load "grid-main.ss")
```

Replace the folder and filename with those for your assignment.

## Other setup options

- **Prebuilt app:** download [SWL-Apple-Silicon.zip](https://github.com/deringezgin/scheme-swl-docker/raw/refs/heads/main/dist/SWL-Apple-Silicon.zip),
  unzip it, and copy `SWL.app` into your home folder's **Applications** folder.
  This skips compilation. The app is locally signed, not Apple-notarized; see
  [the student guide](native-macos/STUDENT-SETUP.md#if-setup-needs-attention) for
  help opening it.
- **Docker:** follow [DOCKER.md](DOCKER.md) to run the original SWL environment
  in your browser.
- **Troubleshooting and terminal Scheme:** see [the student guide](native-macos/STUDENT-SETUP.md).
- **Build details and verification:** see [the native macOS guide](native-macos/README.md).
