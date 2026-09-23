/* ytdlp.c - drives yt-dlp/ffmpeg as subprocesses. */
#include "ytdlp.h"

#include "util.h"

#include <ctype.h>
#include <fcntl.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/stat.h>
#include <unistd.h>

/* ---------- tool detection (cached at startup) ---------- */

static char g_ytdlp_ver[64];
static char g_ffmpeg_ver[64];
static int  g_has_ytdlp;
static int  g_has_ffmpeg;

/* Resolved absolute paths for spawning; empty means "not resolved, keep
 * using the bare name" (see resolve_tool below). */
static char g_ytdlp_path[768];
static char g_ffmpeg_path[768];

static void first_line(const char *s, char *out, size_t cap) {
    if (!s) {
        out[0] = '\0';
        return;
    }
    const char *nl = strchr(s, '\n');
    size_t n = nl ? (size_t)(nl - s) : strlen(s);
    if (n >= cap)
        n = cap - 1;
    memcpy(out, s, n);
    out[n] = '\0';
    str_trim(out);
}

/* Fallback directories probed when the bare tool name is not on PATH. Covers
 * NixOS/home-manager profiles, macOS Homebrew/MacPorts, generic Unix and
 * common per-user install locations, so the binary also works when it is
 * started without the flake/devshell (which sets PATH). */
static const char *const tool_dirs[] = {
    /* NixOS / home-manager */
    "$HOME/.nix-profile/bin",
    "/etc/profiles/per-user/$USER/bin",
    "/nix/profile/bin",
    "$HOME/.local/state/nix/profile/bin",
    "/nix/var/nix/profiles/default/bin",
    "/run/current-system/sw/bin",
    /* macOS Homebrew / MacPorts */
    "/opt/homebrew/bin",
    "/opt/local/bin",
    /* generic Unix */
    "/usr/local/bin",
    "/usr/bin",
    "/bin",
    /* user installs */
    "$HOME/.local/bin",
    "$HOME/bin",
};

/* Expand "$HOME"/"$USER" placeholders in dir, then append "/<name>". */
static int tool_dir_join(const char *dir, const char *name, char *out,
                         size_t cap) {
    const char *val;
    size_t n;
    char expanded[640];

    size_t path_cap = sizeof expanded;
    char *dst = expanded;
    for (const char *p = dir; *p; p++) {
        if (p[0] == '$' && strncmp(p, "$HOME", 5) == 0) {
            val = getenv("HOME");
            n = val ? strlen(val) : 0;
            if (n >= path_cap)
                return -1;
            memcpy(dst, val, n);
            dst += n;
            path_cap -= n;
            p += 4; /* for-loop ++ skips the last char */
            continue;
        }
        if (p[0] == '$' && strncmp(p, "$USER", 5) == 0) {
            val = getenv("USER");
            n = val ? strlen(val) : 0;
            if (n >= path_cap)
                return -1;
            memcpy(dst, val, n);
            dst += n;
            path_cap -= n;
            p += 4;
            continue;
        }
        *dst++ = *p;
    }
    *dst = '\0';
    int wr = snprintf(out, cap, "%s/%s", expanded, name);
    return wr < 0 || (size_t)wr >= cap ? -1 : 0;
}

/* 1 when path exists and is a regular file we could execute directly. */
static int tool_executable(const char *path) {
    struct stat st;
    /* stat() follows symlinks, so a symlink to a regular executable passes */
    return path && access(path, X_OK) == 0 && stat(path, &st) == 0 &&
           S_ISREG(st.st_mode);
}

/* Resolve the absolute path of an external tool at startup, so the binary
 * works even when it is started without the devshell that normally provides
 * PATH. Order:
 *   1. env override (OLTA_YTDLP / OLTA_FFMPEG) pointing at an executable file
 *   2. bare name via run_capture (execvp + inherited PATH; current behavior)
 *   3. first "<dir>/<name>" that exists and is executable in tool_dirs[]
 * On total failure the cache stays empty and callers fall back to the bare
 * name (unchanged behavior; the UI shows the honest "not found"). */
static void resolve_tool(const char *name, const char *env_name,
                         const char *probe_arg, char *cache, size_t cap) {
    char cand[768];

    /* 1. environment override wins */
    const char *env = getenv(env_name);
    if (env && env[0] && strlen(env) < cap && tool_executable(env)) {
        str_copy(cache, cap, env);
        return;
    }

    /* 2. normal PATH lookup, verified by actually running the tool */
    {
        strbuf out, err;
        sb_init(&out);
        sb_init(&err);
        char *argv[3] = { (char *)name, (char *)probe_arg, NULL };
        int rc = run_capture(argv, &out, &err, 15000);
        sb_free(&out);
        sb_free(&err);
        if (rc == 0) {
            cache[0] = '\0'; /* bare name works; keep using it */
            return;
        }
    }

    /* 3. well-known bin directories */
    for (size_t i = 0; i < sizeof tool_dirs / sizeof tool_dirs[0]; i++) {
        if (tool_dir_join(tool_dirs[i], name, cand, sizeof cand) != 0)
            continue;
        if (tool_executable(cand)) {
            str_copy(cache, cap, cand);
            return;
        }
    }

    cache[0] = '\0';
}

/* argv[0] for every yt-dlp/ffmpeg spawn: the resolved absolute path when
 * available, otherwise the bare name (unchanged execvp/PATH behavior). */
static const char *ytdlp_exe(void) {
    return g_ytdlp_path[0] ? g_ytdlp_path : "yt-dlp";
}

static const char *ffmpeg_exe(void) {
    return g_ffmpeg_path[0] ? g_ffmpeg_path : "ffmpeg";
}

void ytdlp_detect(void) {
    resolve_tool("yt-dlp", "OLTA_YTDLP", "--version", g_ytdlp_path,
                 sizeof g_ytdlp_path);
    resolve_tool("ffmpeg", "OLTA_FFMPEG", "-version", g_ffmpeg_path,
                 sizeof g_ffmpeg_path);

    strbuf out, err;
    sb_init(&out);
    sb_init(&err);

    char *a1[] = { (char *)ytdlp_exe(), "--version", NULL };
    int rc = run_capture(a1, &out, &err, 15000);
    if (rc == 0) {
        first_line(out.data, g_ytdlp_ver, sizeof g_ytdlp_ver);
        g_has_ytdlp = g_ytdlp_ver[0] != '\0';
    }
    sb_free(&out);
    sb_free(&err);
    sb_init(&out);
    sb_init(&err);

    char *a2[] = { (char *)ffmpeg_exe(), "-version", NULL };
    rc = run_capture(a2, &out, &err, 15000);
    if (rc == 0) {
        /* first line looks like "ffmpeg version 9.0.1 ..." */
        char line[256];
        first_line(out.data, line, sizeof line);
        const char *v = strstr(line, "version ");
        if (v) {
            v += 7;
            const char *sp = strchr(v, ' ');
            size_t n = sp ? (size_t)(sp - v) : strlen(v);
            if (n >= sizeof g_ffmpeg_ver)
                n = sizeof g_ffmpeg_ver - 1;
            memcpy(g_ffmpeg_ver, v, n);
            g_ffmpeg_ver[n] = '\0';
        }
        g_has_ffmpeg = 1;
    }
    sb_free(&out);
    sb_free(&err);
}

int ytdlp_available(void) {
    return g_has_ytdlp;
}

const char *ytdlp_version(void) {
    return g_has_ytdlp ? g_ytdlp_ver : NULL;
}

int ffmpeg_available(void) {
    return g_has_ffmpeg;
}

/* ---------- /api/info ---------- */

/* "yt-dlp -J" dumps full metadata for the URL. For playlists this means
 * fetching the whole playlist's metadata, which can easily take well over
 * 30 s, so allow 2 minutes for the info fetch. */
#define INFO_TIMEOUT_MS 120000

static void add_str_opt(cJSON *dst, const char *key, const cJSON *src,
                        const char *srckey) {
    const cJSON *v = src ? cJSON_GetObjectItemCaseSensitive(src, srckey) : NULL;
    if (v && cJSON_IsString(v) && v->valuestring && v->valuestring[0])
        cJSON_AddStringToObject(dst, key, v->valuestring);
    else
        cJSON_AddNullToObject(dst, key);
}

static void add_num_opt(cJSON *dst, const char *key, const cJSON *src,
                        const char *srckey) {
    const cJSON *v = src ? cJSON_GetObjectItemCaseSensitive(src, srckey) : NULL;
    if (v && cJSON_IsNumber(v))
        cJSON_AddNumberToObject(dst, key, v->valuedouble);
    else
        cJSON_AddNullToObject(dst, key);
}

/* yt-dlp emits "none" for absent codecs; contract prefers null there. */
static int codec_is_none(const cJSON *v) {
    return v && cJSON_IsString(v) && v->valuestring &&
           strcmp(v->valuestring, "none") == 0;
}

static void add_codec(cJSON *dst, const char *key, const cJSON *src) {
    const cJSON *v = cJSON_GetObjectItemCaseSensitive(src, key);
    if (codec_is_none(v))
        cJSON_AddNullToObject(dst, key);
    else if (v && cJSON_IsString(v))
        cJSON_AddStringToObject(dst, key, v->valuestring);
    else
        cJSON_AddNullToObject(dst, key);
}

static cJSON *trim_formats(const cJSON *src_formats) {
    cJSON *arr = cJSON_CreateArray();
    if (!arr)
        return NULL;
    const cJSON *f = NULL;
    cJSON_ArrayForEach(f, src_formats) {
        if (!cJSON_IsObject(f))
            continue;
        const cJSON *id = cJSON_GetObjectItemCaseSensitive(f, "format_id");
        if (!id || !cJSON_IsString(id) || !id->valuestring[0])
            continue;
        cJSON *o = cJSON_CreateObject();
        if (!o)
            break;
        cJSON_AddStringToObject(o, "id", id->valuestring);
        add_str_opt(o, "ext", f, "ext");
        add_num_opt(o, "height", f, "height");
        add_num_opt(o, "fps", f, "fps");
        add_codec(o, "vcodec", f);
        add_codec(o, "acodec", f);
        /* exact filesize when known, else the approximate size */
        const cJSON *fs = cJSON_GetObjectItemCaseSensitive(f, "filesize");
        if (!fs || !cJSON_IsNumber(fs))
            fs = cJSON_GetObjectItemCaseSensitive(f, "filesize_approx");
        if (fs && cJSON_IsNumber(fs))
            cJSON_AddNumberToObject(o, "filesize", fs->valuedouble);
        else
            cJSON_AddNullToObject(o, "filesize");
        cJSON_AddItemToArray(arr, o);
    }
    return arr;
}

static cJSON *trim_subtitles(const cJSON *src_subs) {
    cJSON *obj = cJSON_CreateObject();
    if (!obj)
        return NULL;
    const cJSON *lang = NULL;
    cJSON_ArrayForEach(lang, src_subs) {
        if (!cJSON_IsArray(lang))
            continue;
        cJSON *exts = cJSON_CreateArray();
        if (!exts)
            break;
        const cJSON *entry = NULL;
        cJSON_ArrayForEach(entry, lang) {
            if (!cJSON_IsObject(entry))
                continue;
            const cJSON *ext = cJSON_GetObjectItemCaseSensitive(entry, "ext");
            if (!ext || !cJSON_IsString(ext) || !ext->valuestring[0])
                continue;
            /* skip duplicate extensions */
            const cJSON *prev = NULL;
            int seen = 0;
            cJSON_ArrayForEach(prev, exts) {
                if (strcmp(prev->valuestring, ext->valuestring) == 0) {
                    seen = 1;
                    break;
                }
            }
            if (!seen)
                cJSON_AddItemToArray(exts, cJSON_CreateString(ext->valuestring));
        }
        if (cJSON_GetArraySize(exts) > 0)
            cJSON_AddItemToObject(obj, lang->string, exts);
        else
            cJSON_Delete(exts);
    }
    return obj;
}

/* "channel" for both videos and playlists: prefer the display channel name,
 * then the uploader, then the uploader id; null when none is present. */
static void add_channel(cJSON *dst, const cJSON *src) {
    static const char *keys[] = { "channel", "uploader", "uploader_id" };
    size_t i;
    for (i = 0; i < sizeof keys / sizeof keys[0]; i++) {
        const cJSON *v = cJSON_GetObjectItemCaseSensitive(src, keys[i]);
        if (v && cJSON_IsString(v) && v->valuestring && v->valuestring[0]) {
            cJSON_AddStringToObject(dst, "channel", v->valuestring);
            return;
        }
    }
    cJSON_AddNullToObject(dst, "channel");
}

/* Playlist thumbnail: prefer the playlist-level one, else the first entry's
 * (flat entries still carry a thumbnail URL); null when neither exists. */
static void add_playlist_thumbnail(cJSON *dst, const cJSON *src) {
    const cJSON *t = cJSON_GetObjectItemCaseSensitive(src, "thumbnail");
    if (t && cJSON_IsString(t) && t->valuestring && t->valuestring[0]) {
        cJSON_AddStringToObject(dst, "thumbnail", t->valuestring);
        return;
    }
    const cJSON *entries = cJSON_GetObjectItemCaseSensitive(src, "entries");
    const cJSON *first = (entries && cJSON_IsArray(entries))
                             ? cJSON_GetArrayItem(entries, 0) : NULL;
    if (first)
        t = cJSON_GetObjectItemCaseSensitive(first, "thumbnail");
    if (t && cJSON_IsString(t) && t->valuestring && t->valuestring[0])
        cJSON_AddStringToObject(dst, "thumbnail", t->valuestring);
    else
        cJSON_AddNullToObject(dst, "thumbnail");
}

static cJSON *build_info_root(cJSON *src, int is_playlist) {
    cJSON *root = cJSON_CreateObject();
    if (!root)
        return NULL;
    add_str_opt(root, "title", src, "title");
    add_str_opt(root, "uploader", src, "uploader");
    add_channel(root, src);
    add_num_opt(root, "duration", src, "duration");
    if (is_playlist) {
        add_playlist_thumbnail(root, src);
        const cJSON *entries = cJSON_GetObjectItemCaseSensitive(src, "entries");
        int n = (entries && cJSON_IsArray(entries))
                    ? cJSON_GetArraySize(entries) : 0;
        cJSON_AddNumberToObject(root, "n_entries", n);
    } else {
        add_str_opt(root, "thumbnail", src, "thumbnail");
    }
    cJSON_AddBoolToObject(root, "is_playlist", is_playlist);

    cJSON *formats;
    if (!is_playlist) {
        const cJSON *sf = cJSON_GetObjectItemCaseSensitive(src, "formats");
        formats = (sf && cJSON_IsArray(sf)) ? trim_formats(sf) : cJSON_CreateArray();
    } else {
        formats = cJSON_CreateArray();
    }
    if (!formats || cJSON_AddItemToObject(root, "formats", formats) == 0) {
        cJSON_Delete(formats);
        cJSON_Delete(root);
        return NULL;
    }
    return root;
}

static void attach_subtitles(cJSON *root, const cJSON *src) {
    const cJSON *subs = src ? cJSON_GetObjectItemCaseSensitive(src, "subtitles") : NULL;
    cJSON *trimmed = trim_subtitles(cJSON_IsObject(subs) ? subs : NULL);
    if (!trimmed)
        trimmed = cJSON_CreateObject();
    if (trimmed)
        cJSON_AddItemToObject(root, "subtitles", trimmed);
}

cJSON *ytdlp_info(const char *url, char *err, size_t errcap) {
    /* --flat-playlist returns playlist-level metadata (title, channel/uploader,
     * thumbnails, a flat entry list) in seconds without extracting full
     * metadata for each entry; single-video URLs are unaffected. */
    char *argv[] = { (char *)ytdlp_exe(), "-J", "--no-playlist", "--flat-playlist",
                     (char *)url, NULL };
    strbuf out, errb;
    sb_init(&out);
    sb_init(&errb);
    int rc = run_capture(argv, &out, &errb, INFO_TIMEOUT_MS);
    if (rc != 0) {
        if (rc == -2)
            snprintf(err, errcap, "yt-dlp timed out after %d s",
                     INFO_TIMEOUT_MS / 1000);
        else if (rc == 127)
            snprintf(err, errcap, "yt-dlp not found");
        else
            ytdlp_error_message(errb.data ? errb.data : "", rc, err, errcap);
        sb_free(&out);
        sb_free(&errb);
        return NULL;
    }
    sb_free(&errb);

    cJSON *full = out.data ? cJSON_Parse(out.data) : NULL;
    if (full) {
        const cJSON *type = cJSON_GetObjectItemCaseSensitive(full, "_type");
        int playlist = (type && cJSON_IsString(type) &&
                        strcmp(type->valuestring, "playlist") == 0) ||
                       cJSON_GetObjectItemCaseSensitive(full, "entries") != NULL;
        cJSON *root = build_info_root(full, playlist);
        if (root)
            attach_subtitles(root, full);
        cJSON_Delete(full);
        sb_free(&out);
        if (!root)
            snprintf(err, errcap, "out of memory");
        return root;
    }

    /* Whole-buffer parse failed: yt-dlp likely dumped one compact JSON object
     * per playlist entry. Fall back to playlist summary, keeping the
     * playlist title when the first entry carries one. */
    cJSON *root = cJSON_CreateObject();
    if (!root) {
        sb_free(&out);
        snprintf(err, errcap, "out of memory");
        return NULL;
    }
    char title[512] = "";
    char channel[256] = "";
    const char *p = out.data ? out.data : "";
    while (*p) {
        const char *nl = strchr(p, '\n');
        size_t n = nl ? (size_t)(nl - p) : strlen(p);
        cJSON *item = cJSON_ParseWithLength(p, n);
        if (item) {
            const cJSON *t = cJSON_GetObjectItemCaseSensitive(item, "playlist_title");
            if (t && cJSON_IsString(t) && t->valuestring[0])
                str_copy(title, sizeof title, t->valuestring);
            const cJSON *ch = cJSON_GetObjectItemCaseSensitive(item, "channel");
            if (!ch || !cJSON_IsString(ch) || !ch->valuestring[0])
                ch = cJSON_GetObjectItemCaseSensitive(item, "uploader");
            if (ch && cJSON_IsString(ch) && ch->valuestring[0])
                str_copy(channel, sizeof channel, ch->valuestring);
            cJSON_Delete(item);
            break;
        }
        p = nl ? nl + 1 : p + n;
    }
    sb_free(&out);

    if (title[0])
        cJSON_AddStringToObject(root, "title", title);
    else
        cJSON_AddNullToObject(root, "title");
    cJSON_AddNullToObject(root, "uploader");
    if (channel[0])
        cJSON_AddStringToObject(root, "channel", channel);
    else
        cJSON_AddNullToObject(root, "channel");
    cJSON_AddNullToObject(root, "duration");
    cJSON_AddNullToObject(root, "thumbnail");
    cJSON_AddBoolToObject(root, "is_playlist", 1);
    cJSON_AddNumberToObject(root, "n_entries", 0);
    cJSON_AddItemToObject(root, "formats", cJSON_CreateArray());
    cJSON_AddItemToObject(root, "subtitles", cJSON_CreateObject());
    return root;
}

/* ---------- download argv ---------- */

static int push_arg(char **argv, int *count, const char *s) {
    if (*count >= 62)
        return -1;
    char *dup = strdup(s);
    if (!dup)
        return -1;
    argv[(*count)++] = dup;
    argv[*count] = NULL;
    return 0;
}

char **ytdlp_build_argv(const job_t *j) {
    char **argv = malloc(64 * sizeof *argv);
    if (!argv)
        return NULL;
    int c = 0;
    argv[0] = NULL;
    int bad = 0;
    bad |= push_arg(argv, &c, ytdlp_exe());
    bad |= push_arg(argv, &c, "--newline");
    /* playlist mode downloads every item; otherwise pin to a single video */
    if (!j->playlist)
        bad |= push_arg(argv, &c, "--no-playlist");

    char fmt[128], outtmpl[1152], archive_path[sizeof j->folder + 32];
    if (strcmp(j->kind, "video") == 0) {
        if (strcmp(j->quality, "best") == 0)
            str_copy(fmt, sizeof fmt, "bv*+ba/b"); /* best = template without height cap */
        else
            snprintf(fmt, sizeof fmt, "bv*[height<=%s]+ba/b[height<=%s]",
                     j->quality, j->quality);
        bad |= push_arg(argv, &c, "-f");
        bad |= push_arg(argv, &c, fmt);
        bad |= push_arg(argv, &c, "--merge-output-format");
        bad |= push_arg(argv, &c, "mkv");
        bad |= push_arg(argv, &c, "--embed-metadata");
        if (strcmp(j->subtitles, "embed") == 0) {
            bad |= push_arg(argv, &c, "--embed-subs");
            bad |= push_arg(argv, &c, "--sub-langs");
            bad |= push_arg(argv, &c, "tr,en.*");
            bad |= push_arg(argv, &c, "--convert-subs");
            bad |= push_arg(argv, &c, "srt");
        } else if (strcmp(j->subtitles, "file") == 0) {
            /* same language handling, subs written as files instead of embedded */
            bad |= push_arg(argv, &c, "--write-subs");
            bad |= push_arg(argv, &c, "--sub-langs");
            bad |= push_arg(argv, &c, "tr,en.*");
            bad |= push_arg(argv, &c, "--convert-subs");
            bad |= push_arg(argv, &c, "srt");
        }
    } else { /* audio */
        bad |= push_arg(argv, &c, "-x");
        bad |= push_arg(argv, &c, "--audio-format");
        bad |= push_arg(argv, &c, j->audio_format);
        bad |= push_arg(argv, &c, "--audio-quality");
        bad |= push_arg(argv, &c, "0");
        bad |= push_arg(argv, &c, "--embed-thumbnail");
        bad |= push_arg(argv, &c, "--embed-metadata");
    }

    /* When ffmpeg was resolved to an absolute path (it may not be reachable
     * by bare name outside the devshell), point yt-dlp at it so merging,
     * embedding and audio extraction work regardless of PATH. */
    if (g_ffmpeg_path[0]) {
        bad |= push_arg(argv, &c, "--ffmpeg-location");
        bad |= push_arg(argv, &c, g_ffmpeg_path);
    }

    if (j->playlist) {
        /* one subfolder per playlist; item names use the plain single-video
         * pattern (no index prefix) — [%(id)s] keeps duplicate titles apart */
        snprintf(outtmpl, sizeof outtmpl,
                 "%s/%%(playlist_title)s/%%(title)s [%%(id)s].%%(ext)s",
                 j->folder);
        /* Optional per-job download archive (default on): yt-dlp records each
         * successfully downloaded (and post-processed) item's video ID in the
         * archive file, and on re-run it checks the archive before fetching,
         * so partial/failed runs resume cleanly and only missing items are
         * downloaded. When the user unchecks it, the flag is omitted and
         * everything re-downloads. Single-video jobs never use the archive. */
        if (j->archive) {
            snprintf(archive_path, sizeof archive_path, "%s/.olta-archive.txt",
                     j->folder);
            bad |= push_arg(argv, &c, "--download-archive");
            bad |= push_arg(argv, &c, archive_path);
        }
    } else {
        snprintf(outtmpl, sizeof outtmpl, "%s/%%(title)s [%%(id)s].%%(ext)s", j->folder);
    }
    bad |= push_arg(argv, &c, "-o");
    bad |= push_arg(argv, &c, outtmpl);
    bad |= push_arg(argv, &c, j->url);
    argv[c] = NULL;

    if (bad) {
        argv_free(argv);
        return NULL;
    }
    return argv;
}

/* ---------- spawn ---------- */

int ytdlp_spawn(char *const argv[], pid_t *pid_out, int *out_fd, int *err_fd) {
    int op[2], ep[2];
    if (pipe(op) != 0 || pipe(ep) != 0) {
        close(op[0]); close(op[1]);
        close(ep[0]); close(ep[1]);
        return -1;
    }
    pid_t pid = fork();
    if (pid < 0) {
        close(op[0]); close(op[1]);
        close(ep[0]); close(ep[1]);
        return -1;
    }
    if (pid == 0) {
        setpgid(0, 0); /* own group so cancel can SIGTERM the whole tree */
        dup2(op[1], STDOUT_FILENO);
        dup2(ep[1], STDERR_FILENO);
        int devnull = open("/dev/null", O_RDONLY);
        if (devnull >= 0)
            dup2(devnull, STDIN_FILENO);
        for (int fd = 3; fd < 4096; fd++)
            close(fd);
        execvp(argv[0], argv);
        _exit(127);
    }
    close(op[1]);
    close(ep[1]);
    *pid_out = pid;
    *out_fd = op[0];
    *err_fd = ep[0];
    return 0;
}

/* ---------- line parsing ---------- */

void ytdlp_parse_progress(const char *line, job_t *j) {
    const char *p = strstr(line, "[download]");
    if (!p)
        return;

    /* playlist position: "[download] Downloading item 3 of 15" */
    const char *item = strstr(p, " item ");
    if (item) {
        int n = 0, m = 0;
        if (sscanf(item + 6, "%d of %d", &n, &m) == 2 && n >= 1 && m >= 1) {
            jobs_lock();
            j->pl_index = n;
            j->pl_total = m;
            jobs_unlock();
        }
    }

    const char *pct = strchr(p, '%');
    if (!pct)
        return;

    /* token right before '%' */
    const char *tok = pct;
    while (tok > p + 10 && tok[-1] != ' ')
        tok--;
    size_t tlen = (size_t)(pct - tok);

    double prog = -1.0;
    if (tlen > 0 && (isdigit((unsigned char)tok[0]) || tok[0] == '.'))
        prog = strtod(tok, NULL); /* "unknown%" -> no leading digit -> skip */

    char speed[32] = "";
    const char *at = strstr(pct, " at ");
    if (at) {
        const char *s = at + 4;
        const char *e = strchr(s, ' ');
        size_t n = e ? (size_t)(e - s) : strlen(s);
        if (n > 0 && n < sizeof speed) {
            memcpy(speed, s, n);
            speed[n] = '\0';
            if (strcmp(speed, "unknown") == 0)
                speed[0] = '\0';
        }
    }

    int eta = -1;
    const char *et = strstr(pct, "ETA ");
    if (et) {
        int a, b, c2;
        if (sscanf(et + 4, "%d:%d:%d", &a, &b, &c2) == 3)
            eta = a * 3600 + b * 60 + c2;
        else if (sscanf(et + 4, "%d:%d", &a, &b) == 2)
            eta = a * 60 + b;
    }

    jobs_lock();
    if (prog >= 0.0) {
        /* inside a playlist: fold the per-item percent into overall progress */
        if (j->pl_total >= 1 && j->pl_index >= 1)
            j->progress = ((j->pl_index - 1) + prog / 100.0) / j->pl_total * 100.0;
        else
            j->progress = prog;
    }
    if (speed[0])
        str_copy(j->speed, sizeof j->speed, speed);
    if (eta >= 0)
        j->eta = eta;
    jobs_unlock();
}

void ytdlp_scan_dest(const char *line, char *dest, size_t cap) {
    char tmp[1024];

    const char *d = strstr(line, "Destination: ");
    if (d) {
        d += 13;
        size_t n = strlen(d);
        if (n >= sizeof tmp)
            n = sizeof tmp - 1;
        memcpy(tmp, d, n);
        tmp[n] = '\0';
        str_trim(tmp);
        if (tmp[0])
            str_copy(dest, cap, tmp);
        return;
    }
    if (strstr(line, " has already been downloaded")) {
        const char *start = strstr(line, "[download] ");
        if (start) {
            start += 11;
            const char *e = strstr(start, " has already been downloaded");
            if (e && e > start) {
                size_t n = (size_t)(e - start);
                if (n >= sizeof tmp)
                    n = sizeof tmp - 1;
                memcpy(tmp, start, n);
                tmp[n] = '\0';
                str_trim(tmp);
                if (tmp[0])
                    str_copy(dest, cap, tmp);
            }
        }
        return;
    }
    const char *m = strstr(line, "Merging formats into \"");
    if (m) {
        m += strlen("Merging formats into \"");
        const char *e = strchr(m, '"');
        if (e && e > m) {
            size_t n = (size_t)(e - m);
            if (n >= sizeof tmp)
                n = sizeof tmp - 1;
            memcpy(tmp, m, n);
            tmp[n] = '\0';
            if (tmp[0])
                str_copy(dest, cap, tmp);
        }
    }
}

void ytdlp_error_message(const char *stderr_text, int exit_code,
                         char *out, size_t cap) {
    char last_nonempty[160] = "";
    char last_error[160] = "";
    const char *p = stderr_text;
    while (p && *p) {
        const char *nl = strchr(p, '\n');
        size_t n = nl ? (size_t)(nl - p) : strlen(p);
        char linebuf[160];
        if (n >= sizeof linebuf)
            n = sizeof linebuf - 1;
        memcpy(linebuf, p, n);
        linebuf[n] = '\0';
        str_trim(linebuf);
        if (linebuf[0]) {
            str_copy(last_nonempty, sizeof last_nonempty, linebuf);
            const char *ep = strstr(linebuf, "ERROR: ");
            if (ep)
                str_copy(last_error, sizeof last_error, ep + 7);
        }
        p = nl ? nl + 1 : NULL;
    }
    if (last_error[0])
        str_copy(out, cap, last_error);
    else if (last_nonempty[0])
        str_copy(out, cap, last_nonempty);
    else
        snprintf(out, cap, "yt-dlp exited with code %d", exit_code);
}

/* Conservative per-entry "video not downloadable" classes: private,
 * unavailable, members-only, login-walled, removed by the uploader.
 * Unknown error classes still fail the job (no blanket --ignore-errors);
 * WARNING lines are irrelevant here. */
static const char *const skippable_errors[] = {
    "Private video",
    "Video unavailable",
    "This video is unavailable",
    "Sign in to confirm",
    "Join this channel",
    "Members-only",
    "members on this channel",
    "removed by the uploader",
    "account associated with this video has been terminated",
};

int ytdlp_errors_all_skippable(const char *err) {
    int error_count = 0;
    const char *p = err;
    while (p && *p) {
        const char *nl = strchr(p, '\n');
        size_t n = nl ? (size_t)(nl - p) : strlen(p);
        char linebuf[256];
        if (n >= sizeof linebuf)
            n = sizeof linebuf - 1;
        memcpy(linebuf, p, n);
        linebuf[n] = '\0';
        str_trim(linebuf);
        if (strncmp(linebuf, "ERROR:", 6) == 0) {
            error_count++;
            int skippable = 0;
            for (size_t i = 0; i < sizeof skippable_errors / sizeof skippable_errors[0]; i++) {
                if (strstr(linebuf, skippable_errors[i])) {
                    skippable = 1;
                    break;
                }
            }
            if (!skippable)
                return 0;
        }
        p = nl ? nl + 1 : NULL;
    }
    return error_count > 0;
}
