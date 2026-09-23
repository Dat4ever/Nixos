/* api.c - implements every endpoint of docs/CONTRACT.md plus static
 * frontend serving (whitelist-based, traversal-rejecting). */
#include "api.h"

#include "jobs.h"
#include "main.h"
#include "playlist.h"
#include "util.h"
#include "ytdlp.h"

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#define FRONTEND_DIR "frontend"

/* ---------- small helpers ---------- */

static void send_json_obj(int fd, int status, cJSON *obj) {
    char *s = obj ? cJSON_PrintUnformatted(obj) : NULL;
    cJSON_Delete(obj);
    http_respond_json(fd, status, s ? s : "{}");
    free(s);
}

static void send_error(int fd, int status, const char *msg) {
    cJSON *o = cJSON_CreateObject();
    if (o)
        cJSON_AddStringToObject(o, "error", msg);
    send_json_obj(fd, status, o);
}

static cJSON *parse_body(const http_request *req, int fd) {
    if (!req->body || req->body_len == 0) {
        send_error(fd, 400, "invalid JSON body");
        return NULL;
    }
    cJSON *b = cJSON_Parse(req->body);
    if (!b) {
        send_error(fd, 400, "invalid JSON body");
        return NULL;
    }
    return b;
}

static const char *body_str(cJSON *b, const char *key, const char *def) {
    const cJSON *v = cJSON_GetObjectItemCaseSensitive(b, key);
    if (v && cJSON_IsString(v) && v->valuestring[0])
        return v->valuestring;
    return def;
}

/* ---------- endpoint handlers ---------- */

static void handle_health(int fd) {
    cJSON *o = cJSON_CreateObject();
    if (!o) {
        send_error(fd, 500, "out of memory");
        return;
    }
    cJSON_AddBoolToObject(o, "ok", 1);
    cJSON_AddBoolToObject(o, "ffmpeg", ffmpeg_available());
    if (ytdlp_available())
        cJSON_AddStringToObject(o, "yt_dlp", ytdlp_version());
    else
        cJSON_AddNullToObject(o, "yt_dlp");
    send_json_obj(fd, 200, o);
}

static void handle_info(int fd, cJSON *body) {
    const char *url = body_str(body, "url", NULL);
    if (!url || !url[0]) {
        send_error(fd, 400, "url is required");
        return;
    }
    if (!ytdlp_available()) {
        send_error(fd, 500, "yt-dlp not found");
        return;
    }
    char err[256];
    cJSON *info = ytdlp_info(url, err, sizeof err);
    if (!info) {
        send_error(fd, 400, err[0] ? err : "yt-dlp failed");
        return;
    }
    send_json_obj(fd, 200, info);
}

static int in_list(const char *v, const char *const list[], int n) {
    for (int i = 0; i < n; i++)
        if (strcmp(v, list[i]) == 0)
            return 1;
    return 0;
}

static void handle_download(int fd, cJSON *body) {
    const char *url = body_str(body, "url", NULL);
    const char *kind = body_str(body, "kind", NULL);
    if (!url || !url[0]) {
        send_error(fd, 400, "url is required");
        return;
    }
    if (!kind) {
        send_error(fd, 400, "kind is required");
        return;
    }

    static const char *const qualities[] = {
        "best", "2160", "1440", "1080", "720", "480", "360",
    };
    static const char *const audio_formats[] = { "mp3", "m4a", "flac", "opus" };
    static const char *const sub_modes[] = { "none", "embed", "file" };

    char quality[16] = "", subs[16] = "", audio_format[16] = "";
    if (strcmp(kind, "video") == 0) {
        str_copy(quality, sizeof quality, body_str(body, "quality", "best"));
        if (!in_list(quality, qualities, 7)) {
            send_error(fd, 400, "invalid quality");
            return;
        }
        str_copy(subs, sizeof subs, body_str(body, "subtitles", "none"));
        if (!in_list(subs, sub_modes, 3)) {
            send_error(fd, 400, "invalid subtitles");
            return;
        }
    } else if (strcmp(kind, "audio") == 0) {
        str_copy(audio_format, sizeof audio_format,
                 body_str(body, "audio_format", "mp3"));
        if (!in_list(audio_format, audio_formats, 4)) {
            send_error(fd, 400, "invalid audio_format");
            return;
        }
    } else {
        send_error(fd, 400, "kind must be video or audio");
        return;
    }

    char folder[768];
    str_copy(folder, sizeof folder, body_str(body, "folder", g_download_dir));
    if (!dir_exists(folder) && mkdir_p(folder) != 0) {
        send_error(fd, 400, "folder does not exist and cannot be created");
        return;
    }

    /* optional playlist flag: true downloads the whole playlist */
    int playlist = 0;
    const cJSON *pl = cJSON_GetObjectItemCaseSensitive(body, "playlist");
    if (pl) {
        if (!cJSON_IsBool(pl)) {
            send_error(fd, 400, "playlist must be a boolean");
            return;
        }
        playlist = cJSON_IsTrue(pl) ? 1 : 0;
    }

    /* optional archive flag: when absent, playlist downloads record into the
     * download archive (default true); false skips --download-archive */
    int archive = 1;
    const cJSON *ar = cJSON_GetObjectItemCaseSensitive(body, "archive");
    if (ar) {
        if (!cJSON_IsBool(ar)) {
            send_error(fd, 400, "archive must be a boolean");
            return;
        }
        archive = cJSON_IsTrue(ar) ? 1 : 0;
    }

    const char *id = jobs_enqueue(url, body_str(body, "title", ""), kind,
                                  quality, audio_format, subs, folder, playlist,
                                  archive);
    if (!id) {
        send_error(fd, 500, "could not enqueue job");
        return;
    }
    cJSON *o = cJSON_CreateObject();
    if (o)
        cJSON_AddStringToObject(o, "id", id);
    send_json_obj(fd, 202, o);
}

/* /api/jobs/{id}/cancel or /api/jobs/{id}/remove */
static int parse_job_path(const char *path, char *id, size_t cap,
                          const char **action) {
    if (!str_starts(path, "/api/jobs/"))
        return -1;
    const char *rest = path + 10;
    const char *slash = strchr(rest, '/');
    if (!slash)
        return -1;
    size_t n = (size_t)(slash - rest);
    if (n == 0 || n >= cap)
        return -1;
    memcpy(id, rest, n);
    id[n] = '\0';
    *action = slash + 1;
    return 0;
}

static void handle_config_get(int fd) {
    cJSON *o = cJSON_CreateObject();
    if (!o) {
        send_error(fd, 500, "out of memory");
        return;
    }
    cJSON_AddStringToObject(o, "download_dir", g_download_dir);
    cJSON_AddNumberToObject(o, "max_concurrent", jobs_get_max_concurrent());
    send_json_obj(fd, 200, o);
}

static void handle_config_post(int fd, cJSON *body) {
    const cJSON *dd = cJSON_GetObjectItemCaseSensitive(body, "download_dir");
    if (dd) {
        if (!cJSON_IsString(dd) || !dd->valuestring[0]) {
            send_error(fd, 400, "download_dir must be a non-empty string");
            return;
        }
        if (!dir_exists(dd->valuestring)) {
            send_error(fd, 400, "download_dir does not exist");
            return;
        }
    }
    const cJSON *mc = cJSON_GetObjectItemCaseSensitive(body, "max_concurrent");
    if (mc && (!cJSON_IsNumber(mc) || mc->valueint < 1 || mc->valueint > 8)) {
        send_error(fd, 400, "max_concurrent must be 1-8");
        return;
    }

    if (dd)
        str_copy(g_download_dir, 768, dd->valuestring);
    if (mc)
        jobs_set_max_concurrent(mc->valueint);
    config_save();
    handle_config_get(fd);
}

/* ---------- saved playlists ---------- */

static int hex_val(int c) {
    if (c >= '0' && c <= '9')
        return c - '0';
    if (c >= 'a' && c <= 'f')
        return c - 'a' + 10;
    if (c >= 'A' && c <= 'F')
        return c - 'A' + 10;
    return -1;
}

/* Decode %XX escapes from src into dst. '+' is left as-is: playlist URLs
 * never legitimately contain spaces and browsers encodeURIComponent the
 * value, so only %-escapes need decoding. Never reads past src's NUL. */
static void percent_decode(const char *src, char *dst, size_t cap) {
    size_t o = 0;
    if (cap == 0)
        return;
    for (size_t i = 0; src && src[i] && o + 1 < cap; i++) {
        if (src[i] == '%' && hex_val((unsigned char)src[i + 1]) >= 0 &&
            hex_val((unsigned char)src[i + 2]) >= 0) {
            dst[o++] = (char)(hex_val((unsigned char)src[i + 1]) * 16 +
                              hex_val((unsigned char)src[i + 2]));
            i += 2;
        } else {
            dst[o++] = src[i];
        }
    }
    dst[o] = '\0';
}

/* Value of key in an "a=1&b=2" query string, percent-decoded. 1 found. */
static int query_param(const char *query, const char *key, char *out,
                       size_t cap) {
    size_t klen = strlen(key);
    const char *p = query ? query : "";
    while (*p) {
        const char *amp = strchr(p, '&');
        size_t seglen = amp ? (size_t)(amp - p) : strlen(p);
        if (seglen > klen && strncmp(p, key, klen) == 0 && p[klen] == '=') {
            char raw[2048];
            size_t vlen = seglen - (klen + 1);
            if (vlen >= sizeof raw)
                vlen = sizeof raw - 1;
            memcpy(raw, p + klen + 1, vlen);
            raw[vlen] = '\0';
            percent_decode(raw, out, cap);
            return 1;
        }
        if (!amp)
            break;
        p = amp + 1;
    }
    return 0;
}

static void handle_playlists_post(int fd, cJSON *body) {
    const char *url = body_str(body, "url", NULL);
    if (!url || !url[0]) {
        send_error(fd, 400, "url is required");
        return;
    }
    const char *title = body_str(body, "title", "");
    playlist_status_t st = PLAYLIST_ERROR;
    cJSON *pl = playlist_add(url, title, &st);
    if (!pl) {
        send_error(fd, st == PLAYLIST_BAD_URL ? 400 : 500,
                   st == PLAYLIST_BAD_URL
                       ? "url must start with http:// or https://"
                       : "could not save playlist");
        return;
    }
    cJSON *o = cJSON_CreateObject();
    if (!o) {
        cJSON_Delete(pl);
        send_error(fd, 500, "out of memory");
        return;
    }
    cJSON_AddBoolToObject(o, "ok", 1);
    if (st == PLAYLIST_DUPLICATE)
        cJSON_AddBoolToObject(o, "duplicate", 1);
    cJSON_AddItemToObject(o, "playlist", pl); /* transfers ownership */
    send_json_obj(fd, st == PLAYLIST_DUPLICATE ? 200 : 201, o);
}

/* ---------- static frontend serving ---------- */

static const char *const whitelist[] = {
    "index.html", "app.js", "style.css", "favicon.ico", "favicon.svg", "favicon.png",
};

/* last path segment */
static const char *basename_of(const char *path) {
    const char *slash = strrchr(path, '/');
    return slash ? slash + 1 : path;
}

static void serve_static(const http_request *req, int fd) {
    if (strcmp(req->method, "GET") != 0 && strcmp(req->method, "HEAD") != 0) {
        send_error(fd, 405, "method not allowed");
        return;
    }
    if (strstr(req->path, "..")) {
        send_error(fd, 400, "bad path");
        return;
    }

    int index_ready = file_exists(FRONTEND_DIR "/index.html");
    const char *base = basename_of(req->path);

    /* "/" and any extensionless path -> SPA index.html */
    if (req->path[0] == '\0' || strchr(base, '.') == NULL) {
        if (!index_ready) {
            send_error(fd, 503, "frontend not ready yet");
            return;
        }
        if (http_send_file(fd, FRONTEND_DIR "/index.html") != 0)
            send_error(fd, 404, "not found");
        return;
    }

    /* whitelist match */
    int allowed = 0;
    for (size_t i = 0; i < sizeof whitelist / sizeof whitelist[0]; i++) {
        if (strcmp(base, whitelist[i]) == 0) {
            allowed = 1;
            break;
        }
    }
    if (!allowed) {
        send_error(fd, 404, "not found");
        return;
    }
    if (!index_ready) {
        /* whole frontend missing: parallel build in progress */
        send_error(fd, 503, "frontend not ready yet");
        return;
    }
    char full[1024];
    snprintf(full, sizeof full, "%s/%s", FRONTEND_DIR, base);
    if (!file_exists(full)) {
        send_error(fd, 404, "not found");
        return;
    }
    http_send_file(fd, full); /* MIME derived from extension */
}

/* ---------- dispatcher ---------- */

void api_route(const http_request *req, int fd, void *ud) {
    (void)ud;
    const char *p = req->path;

    if (!str_starts(p, "/api/") && strcmp(p, "/api") != 0) {
        serve_static(req, fd);
        return;
    }

    if (strcmp(p, "/api/health") == 0) {
        if (strcmp(req->method, "GET") == 0)
            handle_health(fd);
        else
            send_error(fd, 405, "method not allowed");
        return;
    }

    if (strcmp(p, "/api/info") == 0) {
        if (strcmp(req->method, "POST") != 0) {
            send_error(fd, 405, "method not allowed");
            return;
        }
        cJSON *b = parse_body(req, fd);
        if (!b)
            return;
        handle_info(fd, b);
        cJSON_Delete(b);
        return;
    }

    if (strcmp(p, "/api/download") == 0) {
        if (strcmp(req->method, "POST") != 0) {
            send_error(fd, 405, "method not allowed");
            return;
        }
        cJSON *b = parse_body(req, fd);
        if (!b)
            return;
        handle_download(fd, b);
        cJSON_Delete(b);
        return;
    }

    if (strcmp(p, "/api/jobs") == 0) {
        if (strcmp(req->method, "GET") != 0) {
            send_error(fd, 405, "method not allowed");
            return;
        }
        send_json_obj(fd, 200, jobs_to_json());
        return;
    }

    if (str_starts(p, "/api/jobs/")) {
        char id[24];
        const char *action = NULL;
        if (parse_job_path(p, id, sizeof id, &action) != 0) {
            send_error(fd, 404, "not found");
            return;
        }
        if (strcmp(req->method, "POST") != 0) {
            send_error(fd, 405, "method not allowed");
            return;
        }
        if (strcmp(action, "cancel") == 0) {
            if (jobs_cancel(id) != 0) {
                send_error(fd, 404, "job not found");
                return;
            }
            cJSON *o = cJSON_CreateObject();
            if (o)
                cJSON_AddBoolToObject(o, "ok", 1);
            send_json_obj(fd, 200, o);
            return;
        }
        if (strcmp(action, "remove") == 0) {
            if (jobs_remove(id) != 0) {
                send_error(fd, 404, "job not found");
                return;
            }
            cJSON *o = cJSON_CreateObject();
            if (o)
                cJSON_AddBoolToObject(o, "ok", 1);
            send_json_obj(fd, 200, o);
            return;
        }
        send_error(fd, 404, "not found");
        return;
    }

    if (strcmp(p, "/api/config") == 0) {
        if (strcmp(req->method, "GET") == 0) {
            handle_config_get(fd);
            return;
        }
        if (strcmp(req->method, "POST") != 0) {
            send_error(fd, 405, "method not allowed");
            return;
        }
        cJSON *b = parse_body(req, fd);
        if (!b)
            return;
        handle_config_post(fd, b);
        cJSON_Delete(b);
        return;
    }

    if (strcmp(p, "/api/playlists") == 0) {
        if (strcmp(req->method, "GET") == 0) {
            cJSON *o = playlist_to_json();
            if (o)
                send_json_obj(fd, 200, o);
            else
                send_error(fd, 500, "out of memory");
            return;
        }
        if (strcmp(req->method, "DELETE") == 0) {
            char url[2048];
            if (!query_param(req->query, "url", url, sizeof url) || !url[0]) {
                send_error(fd, 400, "url query parameter is required");
                return;
            }
            if (playlist_remove(url) != 0) {
                send_error(fd, 404, "not found");
                return;
            }
            cJSON *o = cJSON_CreateObject();
            if (o)
                cJSON_AddBoolToObject(o, "ok", 1);
            send_json_obj(fd, 200, o);
            return;
        }
        if (strcmp(req->method, "POST") != 0) {
            send_error(fd, 405, "method not allowed");
            return;
        }
        cJSON *b = parse_body(req, fd);
        if (!b)
            return;
        handle_playlists_post(fd, b);
        cJSON_Delete(b);
        return;
    }

    if (strcmp(p, "/api/playlists/downloaded") == 0) {
        if (strcmp(req->method, "POST") != 0) {
            send_error(fd, 405, "method not allowed");
            return;
        }
        cJSON *b = parse_body(req, fd);
        if (!b)
            return;
        const char *url = body_str(b, "url", NULL);
        if (!url || !url[0]) {
            send_error(fd, 400, "url is required");
            cJSON_Delete(b);
            return;
        }
        if (playlist_mark_downloaded(url) != 0) {
            send_error(fd, 404, "not found");
            cJSON_Delete(b);
            return;
        }
        cJSON_Delete(b);
        cJSON *o = cJSON_CreateObject();
        if (o)
            cJSON_AddBoolToObject(o, "ok", 1);
        send_json_obj(fd, 200, o);
        return;
    }

    /* unknown /api endpoint */
    send_error(fd, 404, "not found");
}
