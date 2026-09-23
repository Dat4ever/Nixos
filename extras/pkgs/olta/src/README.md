# olta

Minimal video/audio downloader for Linux — a local web app written in C.

- **Dependencies:** `yt-dlp` and `ffmpeg` (runtime tools only) — zero external C libraries (cJSON is vendored).
- **UI:** Single-page web UI in the browser at `http://127.0.0.1:8077` (vanilla JS, dark/light theme).
- **Saved playlists:** playlists you save in the UI are kept in `~/Downloads/olta/.olta-playlists.txt` (one URL per line) for one-click re-downloads.

## Running
```sh
make                # -> ./olta
./olta              # open http://127.0.0.1:8077 (also opens it in your browser)
```
`nix develop` is only needed to build (gcc/make) or to get pinned yt-dlp/ffmpeg on PATH — running the binary does not require it.

- Tools are resolved at startup: `OLTA_YTDLP` / `OLTA_FFMPEG` env override → PATH → well-known bin dirs (NixOS profiles, `/run/current-system/sw/bin`, Homebrew, `/usr/local/bin`, `/usr/bin`, `~/.local/bin`). Resolved paths are also passed to yt-dlp via `--ffmpeg-location`.
- If the UI reports ffmpeg as missing, install it once (e.g. `nix profile install nixpkgs#ffmpeg-headless` on NixOS) or point `OLTA_FFMPEG` at the binary.

## Layout
```
src/       C sources (http, api, jobs, playlist, ytdlp, main, util)
vendor/    cJSON (MIT)
frontend/  Single-page UI (index.html, style.css, app.js)
docs/      API contract (CONTRACT.md)
```
