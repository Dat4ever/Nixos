#include "modules.h"

static char *res_from_line(const char *line) {
    char *x = strchr(line, 'x');
    if (!x) return NULL;
    char *s = x;
    while (s > line && isdigit((unsigned char)s[-1])) s--;
    int w = atoi(s);
    int h = atoi(x + 1);
    if (w <= 0 || h <= 0) return NULL;
    char buf[64];
    snprintf(buf, sizeof buf, "%dx%d", w, h);
    return xstrdup(buf);
}

static char *res_from_cmd(const char *cmd) {
    FILE *f = popen(cmd, "r");
    if (!f) return NULL;
    char line[512];
    char *res = NULL;
    while (fgets(line, sizeof line, f)) {
        res = res_from_line(line);
        if (res) break;
    }
    pclose(f);
    return res;
}

char *get_resolution(void) {
    char *res = NULL;
    if (getenv("WAYLAND_DISPLAY")) {
        res = res_from_cmd("hyprctl monitors 2>/dev/null");
        if (!res) res = res_from_cmd("wlr-randr 2>/dev/null");
        if (res) return res;
    }
    if (getenv("DISPLAY")) {
        FILE *f = popen("xrandr 2>/dev/null", "r");
        if (f) {
            char line[512];
            while (fgets(line, sizeof line, f)) {
                if (!strstr(line, "current ")) continue;
                res = res_from_line(line);
                if (res) break;
            }
            pclose(f);
            if (res) return res;
        }
    }
    return xstrdup("unknown");
}
