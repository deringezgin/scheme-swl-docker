# Install Scheme and SWL on an Apple Silicon Mac

Use a Mac with an M-series chip and an internet connection. You do not need to
install Scheme, Homebrew, Docker, Git, Python, or XQuartz first.

1. Download `Install-SWL.command` into Downloads.
2. Open Terminal and run:

   ```sh
   bash "$HOME/Downloads/Install-SWL.command"
   ```

3. If Apple's developer-tools dialog appears, click **Install** and finish the
   Apple installation. Leave Terminal open; SWL setup continues automatically.
4. Wait for **Installed:** in Terminal. The first build takes several minutes.
5. Open **SWL.app** in your home folder's **Applications** folder. You can also run:

   ```sh
   open "$HOME/Applications/SWL.app"
   ```

The installer builds Chez Scheme 10.4.1, Tcl/Tk 8.6.18, and SWL 1.3 from checked
source downloads. The app contains everything needed to run afterward. You can
delete the installer and move the app without keeping a project checkout.

## Load an assignment

Keep all the assignment's helper files together. In the SWL REPL, enter:

```scheme
(current-directory "/Users/your-name/Downloads/ai_01_bfs_dfs")
(load "grid-main.ss")
```

Use the folder and main filename for your assignment; some assignments start
with `grid-boss.ss` or another file. Or launch a file from Terminal:

```sh
"$HOME/Applications/SWL.app/Contents/Resources/bin/swl" "/path/to/grid-main.ss"
```

For a text-only Chez Scheme REPL:

```sh
"$HOME/Applications/SWL.app/Contents/Resources/bin/scheme"
```

## If setup needs attention

- If Apple asks for an administrator's approval, complete that dialog or ask
  your computer administrator. The script cannot accept Apple's terms for you.
- If the developer-tools installation fails, finish it and rerun the same SWL
  installer. Downloads are cached, and an existing SWL app is preserved as a
  timestamped backup when replaced.
- Setup and app logs are in `~/Library/Logs/SWL`. Preferences are in
  `~/Library/Application Support/SWL`; source downloads are cached in
  `~/Library/Caches/SWL`. The installer does not change your shell profile.
- The optional prebuilt `SWL-Apple-Silicon.zip` needs no compiler installation:
  unzip it and copy `SWL.app` into your Applications folder. It is locally signed,
  not Apple-notarized. If macOS blocks a download you trust, follow Apple's
  [Open Anyway instructions](https://support.apple.com/en-ie/102445); do not disable
  Gatekeeper. The source installer builds its app locally.

Apple documents the prerequisite installation at
[Installing the command-line tools](https://developer.apple.com/documentation/xcode/installing-the-command-line-tools).
This package targets macOS 11 or newer on Apple Silicon; testing so far used
macOS 26.6.2. It does not support Intel Macs or Windows.
