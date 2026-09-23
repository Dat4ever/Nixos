# olta — API Contract (v1, changes only with orchestrator approval)

Single app: the C backend serves `frontend/` at `http://127.0.0.1:8077`.
All JSON endpoints return `application/json; charset=utf-8`. Errors: HTTP status + `{"error":"message"}`.
The frontend does **not** use SSE/WebSocket for live state; it polls `GET /api/jobs` every 500 ms.

## Endpoints

### GET /api/health
```json
{"ok": true, "ffmpeg": true, "yt_dlp": "2026.09.14"}
```
`ffmpeg` / `yt_dlp` are `false` / `null` when the tool is missing. At startup run `ffmpeg -version` and `yt-dlp --version` once and cache the result.

### POST /api/info  `{"url":"https://..."}`
Backend runs `yt-dlp -J --no-playlist --flat-playlist URL` (captures stdout, 120 s timeout). `--flat-playlist` returns playlist-level metadata (title, channel/uploader, thumbnails, a flat entry list) in seconds without extracting full metadata per entry — large playlists stay fast. For single-video URLs behavior is unchanged. Response is a trimmed JSON:
```json
{
  "title": "...", "uploader": "...", "channel": "...", "duration": 123, "thumbnail": "https://...",
  "is_playlist": false, "n_entries": 0,
  "formats": [
    {"id":"137","ext":"mp4","height":720,"fps":30,"vcodec":"avc1.64001f","acodec":"mp4a.40.2","filesize":1234567}
  ],
  "subtitles": {"tr": ["srt","vtt"], "en": ["srt","vtt"]}
}
```
- `height` / `filesize` / `fps` may be null (audio-only formats have null height).
- `channel` is present for both single videos and playlists: yt-dlp's `channel`, falling back to `uploader`, then `uploader_id`; `null` when none is present.
- If the URL is a playlist: `{"is_playlist": true, "title": "...", "channel": "...", "n_entries": 70, ...}` — flat-playlist JSON omits per-entry `formats`/`subtitles`/`duration`, so those come back empty/null; `thumbnail` is the playlist thumbnail or the first entry's; `n_entries` is the number of playlist entries (`0` when not a playlist). /api/info stays single-video via `--no-playlist` — full playlist support lives in /api/download via the `playlist` flag.
- yt-dlp failure → 400 `{"error": "..."}` (short message derived from yt-dlp stderr).

### POST /api/download
Request:
```json
{
  "url": "https://...",
  "kind": "video" | "audio",
  "quality": "best" | "2160" | "1440" | "1080" | "720" | "480" | "360",   // kind=video
  "audio_format": "mp3" | "m4a" | "flac" | "opus",                        // kind=audio
  "subtitles": "none" | "embed" | "file",                                 // kind=video
  "folder": "/abs/path",       // optional; defaults to config.download_dir
  "title": "...",              // optional; title from /api/info (job.title fills immediately)
  "playlist": true | false,    // optional; default false — true downloads the whole playlist
  "archive": true | false      // optional; default true — false omits --download-archive (full re-download); playlist jobs only
}
```
Response: `202` + `{"id": "<job-id>"}` — job enters the list as `queued`.

### GET /api/jobs
```json
{"jobs": [{
  "id": "...", "url": "...", "title": "...", "kind": "video",
  "state": "queued" | "running" | "done" | "error" | "canceled",
  "progress": 42.1,        // 0-100 float
  "playlist": false,       // echoed from the download request
  "pl_index": 3,           // current playlist item (1-based); 0 unless playlist
  "pl_total": 15,          // total playlist items; 0 unless playlist
  "speed": "2.50MiB/s",    // may be null
  "eta": 12,               // seconds, may be null
  "filepath": "/abs/path", // filled when done
  "error": null,           // error message (state=error)
  "created_at": 1758440000
}]}
```
Ordering: newest first.

### POST /api/jobs/{id}/cancel → `{"ok": true}` (kills the process; state→canceled)
### POST /api/jobs/{id}/remove → `{"ok": true}` (drops from the list; file stays on disk)

### GET /api/playlists
```json
{"playlists": [{"url": "https://...", "title": "...", "added_at": 1758440000, "last_downloaded_at": null}]}
```
File-backed saved-playlists store. Source of truth is `{download_dir}/.olta-playlists.txt` — one URL per line; `#` comment and blank lines are preserved verbatim, order kept, new entries appended at the end. Titles and timestamps live in a sidecar `{download_dir}/.olta-playlists.meta.json` keyed by URL (entries without a matching line are dropped on save). Lazily loaded on first use; reloaded if `download_dir` changes. 0/absent timestamps serialize as `null`.

### POST /api/playlists `{"url": "https://...", "title": "..."}` → `201 {"ok": true, "playlist": {...}}`
- `title` optional (default `""`). URL must start with `http://` or `https://`, else 400.
- Duplicate URL (exact match after trim) → `200 {"ok": true, "duplicate": true, "playlist": {...}}` (no second copy; existing entry returned).

### DELETE /api/playlists?url=<percent-encoded> → `{"ok": true}` (removes only that line; unknown url → 404 `{"error":"not found"}`).

### POST /api/playlists/downloaded `{"url": "..."}` → `{"ok": true}` (sets `last_downloaded_at`; unknown url → 404). Kept for API completeness; the current frontend no longer calls it (saved rows load the URL into the input field instead of starting downloads directly).

### GET /api/config → `{"download_dir": "/...", "max_concurrent": 2}`
### POST /api/config `{"download_dir": "/...", "max_concurrent": 2}` → validated (folder must exist, 1-8), persisted, full config returned.

## Static files
- `/` → `frontend/index.html`; `/app.js`, `/style.css` → served from `frontend/`; MIME: `.html=text/html`, `.js=text/javascript`, `.css=text/css`, `.svg/.png/.ico=image/*`.
- Path traversal must be blocked (`..` rejected; whitelist-based matching).
- Any extensionless GET path → index.html (SPA behavior). Unknown `/api/*` → 404 JSON.

## Backend behavior
- Binds **127.0.0.1 only**; port default 8077 (overridable via `--port N`). On startup the UI URL is opened in the default browser (best effort; skipped when headless — no `DISPLAY`/`WAYLAND_DISPLAY`, `OLTA_NO_OPEN` set, or `--no-open` given).
- Config file: `~/.config/olta/config.json`; `download_dir` defaults to `~/Downloads/olta` (created if missing), `max_concurrent` defaults to 2.
- One pthread per connection (detached); jobs array guarded by mutex+cond; workers wait while `max_concurrent` slots are busy (queued → running).
- Tool resolution (startup, cached): `OLTA_YTDLP` / `OLTA_FFMPEG` env override pointing at an executable → bare-name PATH probe → first hit in well-known bin dirs (NixOS/home-manager profiles, `/run/current-system/sw/bin`, macOS Homebrew/MacPorts, `/usr/local/bin`, `/usr/bin`, `/bin`, `~/.local/bin`, `~/bin`). Every yt-dlp/ffmpeg spawn uses the resolved absolute path (bare-name fallback when unresolved); download argv also gets `--ffmpeg-location <resolved>` so yt-dlp finds ffmpeg regardless of its own PATH.
- yt-dlp is launched via fork/execvp, stdout read from a pipe:
  - **video**: `yt-dlp --newline --no-playlist -f "bv*[height<=H]+ba/b[height<=H]" --merge-output-format mkv --embed-metadata [--embed-subs --sub-langs "tr,en.*" --convert-subs srt] -o "{folder}/%(title)s [%(id)s].%(ext)s" URL`
  - **audio**: `yt-dlp --newline --no-playlist -x --audio-format F --audio-quality 0 --embed-thumbnail --embed-metadata -o "{folder}/%(title)s [%(id)s].%(ext)s" URL`
  - With `"playlist": true` the argv drops `--no-playlist` and the `-o` template becomes `{folder}/%(playlist_title)s/%(title)s [%(id)s].%(ext)s` (one subfolder per playlist; item names use the plain single-video pattern, no index prefix). Playlist downloads also pass `--download-archive {folder}/.olta-archive.txt` **only when `archive` is true** (the default; `archive: false` omits the flag so everything re-downloads): yt-dlp records each successfully downloaded (and post-processed) item's video ID in that file, and on re-run it checks the archive before fetching — so re-running the same playlist skips already-downloaded items by video ID and only downloads the missing ones (partial/failed runs resume cleanly). Single-video downloads are not affected. Playlist jobs whose yt-dlp stderr contains ONLY per-entry "video not downloadable" errors (private, unavailable, members-only, login-walled, removed) finalize as done; any other error class still marks the job error. Failed entries are not recorded in the download archive, so the next run retries them.
- Progress: parse stdout lines like `[download]  42.1% of ~12.34MiB at 2.50MiB/s ETA 00:12` (percent can be `unknown` → skip progress update); also parse `[download] Downloading item 3 of 15` into `pl_index`/`pl_total` — while a playlist is downloading, progress is the overall percent `((pl_index-1)+item%/100)/pl_total*100`; process exit 0 → state=done, otherwise error (short message from stderr).
- Cancel: process starts with `setpgid(0,0)`; SIGTERM to `-pid`, SIGKILL after 3 s.
- Memory hygiene matters in a long-running server (cJSON_Delete everywhere; close file handles in static responses).

## Frontend (mock mode)
- If the URL contains `?mock=1`, fetch is replaced by canned fake data in `app.js` (health, an info sample, a jobs list with 2 sample jobs whose progress advances over time + 1 error sample, a saved-playlists sample). This allows testing the UI via `file://` or a static server without the backend. The flag only swaps the data source; prod logic is unchanged.
