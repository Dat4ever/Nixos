#include "datfetch.h"

static const char *const nixos_colors[8] = {
    "",
    RGB(126, 186, 228),
    RGB(82, 119, 195),
};

static const char *const arch_colors[8] = {
    "",
    RGB(23, 147, 209),
};

static const char *const debian_colors[8] = {
    "",
    RGB(206, 0, 86),
};

static const char *const fedora_colors[8] = {
    "",
    RGB(81, 162, 218),
    RGB(255, 255, 255),
};

static const char *const guix_colors[8] = {
    "",
    RGB(255, 204, 0),
};

static const char *const tux_colors[8] = {
    "",
    RGB(255, 255, 255),
};

const Distro distros[] = {
    { "nixos",  "NixOS",  nixos_colors },
    { "arch",   "Arch Linux", arch_colors },
    { "debian", "Debian", debian_colors },
    { "fedora", "Fedora", fedora_colors },
    { "guix",   "Guix", guix_colors },
    { "tux",    "Linux", tux_colors },
    { NULL, NULL, NULL }
};

char *os_id, *os_pretty;

static void strip_quotes(char *s) {
    size_t len = strlen(s);
    if (len >= 2 && ((s[0] == '"' && s[len-1] == '"') || (s[0] == '\'' && s[len-1] == '\''))) {
        s[len-1] = 0;
        memmove(s, s + 1, len - 1);
    }
}

static void read_os_release(void) {
    FILE *f = fopen("/etc/os-release", "r");
    if (!f) return;
    char line[512];
    while (fgets(line, sizeof line, f)) {
        line[strcspn(line, "\n")] = 0;
        char *eq = strchr(line, '=');
        if (!eq) continue;
        *eq = 0;
        char *key = line, *val = eq + 1;
        strip_quotes(val);
        if (strcmp(key, "ID") == 0) os_id = xstrdup(val);
        else if (strcmp(key, "PRETTY_NAME") == 0) os_pretty = xstrdup(val);
    }
    fclose(f);
}

const Distro *distro_by_id(const char *id) {
    for (const Distro *d = distros; d->id; d++)
        if (strcasecmp(d->id, id) == 0) return d;
    return NULL;
}

const Distro *detect_distro(void) {
    read_os_release();
    const Distro *d = os_id ? distro_by_id(os_id) : NULL;
    if (d) return d;
    d = distro_by_id("tux");
    return d ? d : &distros[0];
}

char *logo_line_ansi(const char *line, const char *const *colors) {
    size_t cap = strlen(line) + 128;
    char *out = malloc(cap);
    if (!out) return NULL;
    size_t o = 0;
    for (const char *p = line; *p; p++) {
        if (*p == '$' && p[1] >= '1' && p[1] <= '6') {
            const char *c = colors[p[1] - '0'];
            if (c) {
                size_t cl = strlen(c);
                if (o + cl + 1 >= cap) { cap = (o + cl) * 2; out = realloc(out, cap); }
                memcpy(out + o, c, cl);
                o += cl;
            }
            p++;
        } else {
            if (o + 2 >= cap) { cap *= 2; out = realloc(out, cap); }
            out[o++] = *p;
        }
    }
    size_t rl = strlen(RESET);
    if (o + rl + 1 >= cap) { cap = o + rl + 1; out = realloc(out, cap); }
    memcpy(out + o, RESET, rl + 1);
    return out;
}
