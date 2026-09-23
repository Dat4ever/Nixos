/* main.c - entry point: CLI args, config load/save, tool checks, server. */
#include "api.h"
#include "jobs.h"
#include "util.h"
#include "ytdlp.h"

#include <cJSON.h>

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/wait.h>
#include <unistd.h>

char g_download_dir[768];

/* ---------- config ---------- */

static const char *config_path(void) {
    /* static buffer: single-threaded call sites at startup / api config POST */
    static char path[2048];
    const char *home = getenv("HOME");
    if (!home || !home[0])
        home = "."; /* no HOME: fall back to CWD */
    snprintf(path, sizeof path, "%s/.config/olta", home);
    mkdir_p(path);
    snprintf(path, sizeof path, "%s/.config/olta/config.json", home);
    return path;
}

static char *read_file(const char *path) {
    FILE *fp = fopen(path, "rb");
    if (!fp)
        return NULL;
    fseek(fp, 0, SEEK_END);
    long size = ftell(fp);
    fseek(fp, 0, SEEK_SET);
    if (size < 0 || size > 1024 * 1024) {
        fclose(fp);
        return NULL;
    }
    char *buf = malloc((size_t)size + 1);
    if (!buf) {
        fclose(fp);
        return NULL;
    }
    size_t got = fread(buf, 1, (size_t)size, fp);
    fclose(fp);
    buf[got] = '\0';
    return buf;
}

void config_load(void) {
    /* defaults */
    const char *home = getenv("HOME");
    if (!home || !home[0])
        home = ".";
    snprintf(g_download_dir, sizeof g_download_dir, "%s/Downloads/olta", home);
    jobs_set_max_concurrent(2);

    char *text = read_file(config_path());
    if (text) {
        cJSON *cfg = cJSON_Parse(text);
        if (cfg) {
            const cJSON *dd = cJSON_GetObjectItemCaseSensitive(cfg, "download_dir");
            if (dd && cJSON_IsString(dd) && dd->valuestring[0])
                str_copy(g_download_dir, sizeof g_download_dir, dd->valuestring);
            const cJSON *mc = cJSON_GetObjectItemCaseSensitive(cfg, "max_concurrent");
            if (mc && cJSON_IsNumber(mc) && mc->valueint >= 1 && mc->valueint <= 8)
                jobs_set_max_concurrent(mc->valueint);
            /* out-of-range values silently keep the default */
            cJSON_Delete(cfg);
        }
        free(text);
    }
    mkdir_p(g_download_dir); /* default dir (and its parents) if missing */
}

void config_save(void) {
    cJSON *cfg = cJSON_CreateObject();
    if (!cfg)
        return;
    cJSON_AddStringToObject(cfg, "download_dir", g_download_dir);
    cJSON_AddNumberToObject(cfg, "max_concurrent", jobs_get_max_concurrent());
    char *s = cJSON_Print(cfg);
    cJSON_Delete(cfg);
    if (!s)
        return;
    FILE *fp = fopen(config_path(), "w");
    if (fp) {
        fputs(s, fp);
        fputc('\n', fp);
        fclose(fp);
    }
    free(s);
}

/* ---------- CLI + startup ---------- */

static int parse_port(const char *s, int *out) {
    char *end = NULL;
    long v = strtol(s, &end, 10);
    if (!end || *end != '\0' || v < 1 || v > 65535)
        return -1;
    *out = (int)v;
    return 0;
}

/* Best-effort "open the UI in the default browser" at startup. Detached via
 * double-fork so no zombie is left behind. Skipped when headless (no
 * DISPLAY/WAYLAND_DISPLAY), when OLTA_NO_OPEN is set, or via --no-open. */
static volatile int g_no_open;

static void open_browser(int port) {
    if (g_no_open)
        return;
    {
        const char *no = getenv("OLTA_NO_OPEN");
        if (no && no[0] && strcmp(no, "0") != 0)
            return;
    }
    if (!getenv("DISPLAY") && !getenv("WAYLAND_DISPLAY"))
        return; /* headless: nothing to open */

    char url[64];
    snprintf(url, sizeof url, "http://127.0.0.1:%d", port);

    pid_t pid = fork();
    if (pid < 0)
        return;
    if (pid == 0) {
        pid_t inner = fork();
        if (inner == 0) {
            sleep(1); /* give the server a moment to bind */
            /* xdg-open on Linux; "open" on macOS. Replaces the image. */
            execlp("xdg-open", "xdg-open", url, (char *)NULL);
            execlp("open", "open", url, (char *)NULL);
            _exit(127);
        }
        _exit(0); /* intermediate exits immediately -> grandchild re-parents */
    }
    int st;
    waitpid(pid, &st, 0); /* reap the intermediate, avoid a zombie */
    fprintf(stderr, "[olta] opening %s\n", url);
}

int main(int argc, char **argv) {
    int port = 8077;
    for (int i = 1; i < argc; i++) {
        if (strcmp(argv[i], "--port") == 0 && i + 1 < argc) {
            if (parse_port(argv[++i], &port) != 0) {
                fprintf(stderr, "olta: invalid port value\n");
                return 1;
            }
        } else if (str_starts(argv[i], "--port=")) {
            if (parse_port(argv[i] + 7, &port) != 0) {
                fprintf(stderr, "olta: invalid port value\n");
                return 1;
            }
        } else if (strcmp(argv[i], "--no-open") == 0) {
            g_no_open = 1;
        } else {
            fprintf(stderr, "usage: olta [--port N] [--no-open]\n");
            return 1;
        }
    }

    mkdir_p("frontend"); /* frontend lives next to the CWD (repo root) */

    config_load();
    ytdlp_detect();

    fprintf(stderr, "[olta] yt-dlp: %s | ffmpeg: %s\n",
            ytdlp_available() ? ytdlp_version() : "NOT FOUND",
            ffmpeg_available() ? "found" : "NOT FOUND");
    if (!ytdlp_available())
        fprintf(stderr, "[olta] warning: yt-dlp missing, downloads will fail\n");

    jobs_init();
    config_save(); /* materialize the effective config on first run */

    open_browser(port); /* best effort; skipped when headless/--no-open */

    /* blocks until killed */
    if (http_serve(port, api_route, NULL) != 0)
        return 1;
    return 0;
}
