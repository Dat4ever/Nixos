#include "datfetch.h"

#include <stdarg.h>

char *xstrdup(const char *s) {
    if (!s) return NULL;
    char *r = strdup(s);
    if (!r) { perror("strdup"); exit(1); }
    return r;
}

char *strf(const char *fmt, ...) {
    va_list ap;
    va_start(ap, fmt);
    char *s = NULL;
    if (vasprintf(&s, fmt, ap) < 0) s = NULL;
    va_end(ap);
    return s;
}

char *read_file_line(const char *path) {
    FILE *f = fopen(path, "r");
    if (!f) return NULL;
    char buf[1024];
    if (!fgets(buf, sizeof buf, f)) { fclose(f); return NULL; }
    fclose(f);
    buf[strcspn(buf, "\n")] = 0;
    return xstrdup(buf);
}

char *read_file_stripped(const char *path) {
    char *s = read_file_line(path);
    if (s) {
        size_t len = strlen(s);
        while (len > 0 && (s[len-1] == ' ' || s[len-1] == '\t' || s[len-1] == '\r'))
            s[--len] = 0;
    }
    return s;
}

const char *get_user(void) {
    struct passwd *pw = getpwuid(getuid());
    return pw ? pw->pw_name : "unknown";
}

char *get_host(void) {
    char buf[256];
    if (gethostname(buf, sizeof buf) != 0) return xstrdup("unknown");
    buf[strcspn(buf, ".")] = 0;
    return xstrdup(buf);
}

static int utf8_len(unsigned char c) {
    if (c < 0x80) return 1;
    if ((c & 0xE0) == 0xC0) return 2;
    if ((c & 0xF0) == 0xE0) return 3;
    if ((c & 0xF8) == 0xF0) return 4;
    return 1;
}

int vis_width(const char *s) {
    int w = 0;
    for (const char *p = s; *p;) {
        if (*p == '\x1b' && p[1] == '[') {
            p += 2;
            while (*p && *p != 'm') p++;
            if (*p == 'm') p++;
            continue;
        }
        w++;
        p += utf8_len((unsigned char)*p);
    }
    return w;
}

void truncate_ellipsis(char *dst, size_t cap, const char *src, int max_cols) {
    if (cap == 0) return;
    dst[0] = 0;
    if (max_cols <= 0) return;

    if (vis_width(src) <= max_cols) {
        size_t len = strlen(src);
        if (len + 1 > cap) len = cap - 1;
        memcpy(dst, src, len);
        dst[len] = 0;
        return;
    }

    if (max_cols <= 3) {
        if (cap >= 4) strcpy(dst, "...");
        return;
    }
    int budget = max_cols - 3;
    int w = 0;
    size_t o = 0;
    const char *p = src;
    while (*p && w < budget) {
        if (*p == '\x1b' && p[1] == '[') {
            const char *s = p;
            p += 2;
            while (*p && *p != 'm') p++;
            if (*p == 'm') p++;
            size_t len = (size_t)(p - s);
            if (o + len + 1 < cap) { memcpy(dst + o, s, len); o += len; }
            continue;
        }
        int len = utf8_len((unsigned char)*p);
        if (o + len + 1 >= cap) break;
        memcpy(dst + o, p, (size_t)len);
        o += len;
        w++;
        p += len;
    }
    if (o + 3 + 1 < cap) { memcpy(dst + o, "...", 3); o += 3; }
    dst[o] = 0;
}

int term_width(void) {
    struct winsize ws;
    if (ioctl(STDOUT_FILENO, TIOCGWINSZ, &ws) == 0 && ws.ws_col > 0)
        return ws.ws_col;
    const char *c = getenv("COLUMNS");
    if (c && *c) { int v = atoi(c); if (v > 0) return v; }
    return 80;
}
