#include "datfetch.h"

#define RED     "\x1b[31m"
#define GREEN   "\x1b[32m"
#define YELLOW  "\x1b[33m"
#define BLUE    "\x1b[34m"
#define MAGENTA "\x1b[35m"
#define CYAN    "\x1b[36m"
#define WHITE   "\x1b[37m"

static char *wrap(const char *code, const char *s) {
    char *r = malloc(strlen(code) + strlen(s) + strlen(RESET) + 1);
    sprintf(r, "%s%s%s", code, s, RESET);
    return r;
}

static int hexval(char c) {
    if (c >= '0' && c <= '9') return c - '0';
    if (c >= 'a' && c <= 'f') return c - 'a' + 10;
    if (c >= 'A' && c <= 'F') return c - 'A' + 10;
    return 0;
}

static const char *const base16[16] = {
    "black", "red", "green", "yellow", "blue", "magenta", "cyan", "white",
    "bright_black", "bright_red", "bright_green", "bright_yellow",
    "bright_blue", "bright_magenta", "bright_cyan", "bright_white",
};

static char *parse_color(const char *val) {
    if (!val || !*val) return NULL;
    const char *p = val;
    while (*p == '#') p++;
    if (strlen(p) == 6 && strspn(p, "0123456789abcdefABCDEF") == 6) {
        int r = (hexval(p[0]) << 4) | hexval(p[1]);
        int g = (hexval(p[2]) << 4) | hexval(p[3]);
        int b = (hexval(p[4]) << 4) | hexval(p[5]);
        return strf("\x1b[38;2;%d;%d;%dm", r, g, b);
    }
    char *end;
    long n = strtol(val, &end, 10);
    int idx = -1;
    if (*val && *end == 0 && n >= 0 && n <= 15) {
        idx = (int)n;
    } else {
        for (int i = 0; i < 16; i++)
            if (strcasecmp(val, base16[i]) == 0) { idx = i; break; }
    }
    if (idx < 0) return NULL;
    return strf("\x1b[%dm", idx < 8 ? 30 + idx : 90 + (idx - 8));
}

static char **read_logo_file(const char *path) {
    FILE *f = fopen(path, "r");
    if (!f) return NULL;
    char **lines = NULL;
    int n = 0, cap = 0;
    char line[512];
    while (fgets(line, sizeof line, f)) {
        line[strcspn(line, "\n")] = 0;
        if (n + 1 >= cap) { cap = cap ? cap * 2 : 16; lines = realloc(lines, cap * sizeof(char *)); }
        lines[n++] = xstrdup(line);
    }
    fclose(f);
    if (n + 1 >= cap) { cap = cap ? cap * 2 : 16; lines = realloc(lines, cap * sizeof(char *)); }
    lines[n] = NULL;
    return lines;
}

static char **read_logo_file_try(const char *path) {
    char **lines = read_logo_file(path);
    if (lines) return lines;
    char *p = strf("%s.txt", path);
    lines = read_logo_file(p);
    free(p);
    return lines;
}

static char **load_logo(const char *name) {
    const char *override = getenv("DATFETCH_LOGO_DIR");
    if (override && *override) {
        char *p = strf("%s/%s", override, name);
        char **lines = read_logo_file_try(p);
        free(p);
        if (lines) return lines;
    }
    char *cd = config_dir();
    if (cd) {
        char *p = strf("%s/logo/%s", cd, name);
        char **lines = read_logo_file_try(p);
        free(p);
        free(cd);
        if (lines) return lines;
    }
    char *bd = builtin_dir();
    if (bd) {
        char *p = strf("%s/logo/%s", bd, name);
        char **lines = read_logo_file_try(p);
        free(p);
        free(bd);
        if (lines) return lines;
    }
    return NULL;
}

static char *logo_name(const char *logo, const Distro *sys) {
    if (strcasecmp(logo, "none") == 0)
        return NULL;
    if (!logo || strcasecmp(logo, "auto") == 0 || strcasecmp(logo, "braille-auto") == 0)
        return strf("braille-%s", sys->id);
    if (strcasecmp(logo, "mini") == 0 || strcasecmp(logo, "mini-auto") == 0)
        return strf("mini-%s", sys->id);
    return xstrdup(logo);
}

static const Distro *logo_distro(const char *logo, const Distro *sys) {
    if (!logo || strcasecmp(logo, "none") == 0 || strchr(logo, '/'))
        return sys;
    if (strcasecmp(logo, "auto") == 0 || strcasecmp(logo, "braille-auto") == 0 ||
        strcasecmp(logo, "mini") == 0 || strcasecmp(logo, "mini-auto") == 0)
        return sys;
    const char *id = logo;
    if (strncasecmp(logo, "braille-", 8) == 0) id = logo + 8;
    else if (strncasecmp(logo, "mini-", 5) == 0) id = logo + 5;
    const Distro *d = distro_by_id(id);
    return d ? d : sys;
}

typedef struct { char *label; char *value; char *color; int bare; } Item;

typedef struct { Item *items; int n; } ItemList;

static void add_item(ItemList *l, const char *label, const char *value, const char *color) {
    l->items = realloc(l->items, (l->n + 1) * sizeof(Item));
    l->items[l->n].label = xstrdup(label);
    l->items[l->n].value = xstrdup(value);
    l->items[l->n].color = color ? parse_color(color) : NULL;
    l->items[l->n].bare = 0;
    l->n++;
}

static void add_bare_item(ItemList *l, const char *value, const char *color) {
    l->items = realloc(l->items, (l->n + 1) * sizeof(Item));
    l->items[l->n].label = xstrdup("");
    l->items[l->n].value = xstrdup(value);
    l->items[l->n].color = color ? parse_color(color) : NULL;
    l->items[l->n].bare = 1;
    l->n++;
}

static int in_breaks(const Config *cfg, const char *name) {
    for (int i = 0; i < cfg->n_section_breaks; i++)
        if (strcmp(cfg->section_breaks[i], name) == 0) return 1;
    return 0;
}

static void addi(ItemList *l, const Config *cfg, const char *name, const char *label, const char *value, const char *color) {
    add_item(l, label, value, color);
    if (in_breaks(cfg, name)) add_item(l, "", "", NULL);
}

static void free_items(ItemList *l) {
    for (int i = 0; i < l->n; i++) {
        free(l->items[i].label);
        free(l->items[i].value);
        free(l->items[i].color);
    }
    free(l->items);
}

static ItemList build_items(const SysInfo *si, const Config *cfg) {
    ItemList l = {0};
    int ic = cfg->icons;

    for (int oi = 0; oi < cfg->n_order; oi++) {
        int m = cfg->order[oi];
        if (!cfg->mod[m].enabled) continue;
        const char *col = cfg->mod[m].color;

        switch (m) {
        case M_USER:
            addi(&l, cfg, "User", ic ? "\uF007  User" : "User", si->user, col);
            break;
        case M_HOST:
            addi(&l, cfg, "Host", ic ? "\uF109  Host" : "Host", si->hostname, col);
            break;
        case M_USERHOST: {
            char *v = strf("%s@%s", si->user, si->hostname);
            add_bare_item(&l, v, col);
            if (in_breaks(cfg, "User")) add_item(&l, "", "", NULL);
            free(v);
            break;
        }
        case M_MODEL:
            addi(&l, cfg, "Model", ic ? "\uF02C  Model" : "Model", si->model, col);
            break;
        case M_OS:
            addi(&l, cfg, "OS", ic ? "\uF17C  OS" : "OS", si->os_pretty, col);
            break;
        case M_KERNEL:
            addi(&l, cfg, "Kernel", ic ? "\uF013  Kernel" : "Kernel", si->kernel_release, col);
            break;
        case M_SHELL:
            addi(&l, cfg, "Shell", ic ? "\uF120  Shell" : "Shell", si->shell, col);
            break;
        case M_DESKTOP:
            addi(&l, cfg, "Desktop", ic ? "\uF488  Desktop" : "Desktop", si->desktop, col);
            break;
        case M_TERMINAL:
            addi(&l, cfg, "Terminal", ic ? "\uF489  Terminal" : "Terminal", si->terminal, col);
            break;
        case M_CPU:
            for (int i = 0; i < si->cpu_count; i++) {
                char *label = (i == 0)
                    ? strf("%s", ic ? "\uF2DB  CPU" : "CPU")
                    : strf("%s %d", ic ? "\uF2DB  CPU" : "CPU", i + 1);
                char *value = (i == 0)
                    ? strf("%s (%d)", si->cpus[i], si->cpu_cores)
                    : xstrdup(si->cpus[i]);
                addi(&l, cfg, "CPU", label, value, col);
                free(label); free(value);
            }
            break;
        case M_GPU:
            for (int i = 0; i < si->gpu_count; i++) {
                char *label = strf("%s %d", ic ? "\U000F091B  GPU" : "GPU", i + 1);
                addi(&l, cfg, "GPU", label, si->gpus[i], col);
                free(label);
            }
            break;
        case M_MEMORY: {
            char *v = strf("%.1f GiB / %.1f GiB (%.0f%%)",
                si->mem_used_kib / (1024.0 * 1024.0), si->mem_total_kib / (1024.0 * 1024.0),
                si->mem_total_kib ? si->mem_used_kib * 100.0 / si->mem_total_kib : 0.0);
            addi(&l, cfg, "Memory", ic ? "\uEFC5  Memory" : "Memory", v, col);
            free(v);
            break;
        }
        case M_DISK: {
            char *v = strf("%.0f GiB / %.0f GiB (%.0f%%)",
                si->disk_used_bytes / (1024.0 * 1024.0 * 1024.0), si->disk_total_bytes / (1024.0 * 1024.0 * 1024.0),
                si->disk_total_bytes ? si->disk_used_bytes * 100.0 / si->disk_total_bytes : 0.0);
            addi(&l, cfg, "Disk", ic ? "\uF0C7  Disk" : "Disk", v, col);
            free(v);
            break;
        }
        case M_FONT:
            addi(&l, cfg, "Font Sans", ic ? "\uF031  Font Sans" : "Font Sans", si->font_sans, col);
            addi(&l, cfg, "Font Serif", ic ? "\uF031  Font Serif" : "Font Serif", si->font_serif, col);
            addi(&l, cfg, "Font Mono", ic ? "\uF031  Font Mono" : "Font Mono", si->font_mono, col);
            break;
        case M_RESOLUTION:
            addi(&l, cfg, "Resolution", ic ? "\uF26C  Resolution" : "Resolution", si->resolution, col);
            break;
        case M_UPTIME:
            addi(&l, cfg, "Uptime", ic ? "\uF017  Uptime" : "Uptime", si->uptime, col);
            break;
        case M_IP:
            addi(&l, cfg, "IP", ic ? "\uF0AC  IP" : "IP", si->local_ip, col);
            break;
        case M_INSTALLED:
            addi(&l, cfg, "Installed", ic ? "\uF133  Installed" : "Installed", si->installed, col);
            break;
        case M_PACKAGES: {
            char *v = strf("%ld", si->packages_total);
            addi(&l, cfg, "Packages", ic ? "\uEB29  Packages" : "Packages", v, col);
            free(v);
            break;
        }
        }
    }

    return l;
}

typedef struct { char **lines; int n; int maxw; } Column;

enum { ALIGN_LEFT = 0, ALIGN_CENTER = 1, ALIGN_RIGHT = 2 };

static void column_measure(Column *c) {
    int mw = 0;
    for (int i = 0; i < c->n; i++) {
        int w = vis_width(c->lines[i]);
        if (w > mw) mw = w;
    }
    c->maxw = mw;
}

static void render_layout(Column *cols, int ncols, int padding, const int *starts, int tw) {
    int total = 0;
    for (int c = 0; c < ncols; c++) if (cols[c].n > total) total = cols[c].n;
    for (int r = 0; r < total; r++) {
        int cur = 0;
        for (int c = 0; c < ncols; c++) {
            const char *line = (r < cols[c].n) ? cols[c].lines[r] : "";
            int start = starts[c] > 0 ? starts[c] : 0;
            if (start > cur) {
                for (int s = 0; s < start - cur; s++) putchar(' ');
                cur = start;
            }
            int w = vis_width(line);
            if (c == ncols - 1) {
                int avail = tw - cur;
                if (avail > 0 && w > avail) {
                    char tbuf[1024];
                    truncate_ellipsis(tbuf, sizeof tbuf, line, avail);
                    fputs(tbuf, stdout);
                    fputs(RESET, stdout);
                } else {
                    fputs(line, stdout);
                }
            } else {
                fputs(line, stdout);
                int pad = cols[c].maxw - w + padding;
                if (pad > 0) for (int s = 0; s < pad; s++) putchar(' ');
                cur = start + cols[c].maxw + padding;
            }
        }
        putchar('\n');
    }
}

static void render_aligned(char **lines, int n, int align, int tw) {
    for (int i = 0; i < n; i++) {
        int w = vis_width(lines[i]);
        if (w > tw) {
            char tbuf[1024];
            truncate_ellipsis(tbuf, sizeof tbuf, lines[i], tw);
            fputs(tbuf, stdout);
            fputs(RESET, stdout);
        } else {
            int pad = align == ALIGN_CENTER ? (tw - w) / 2 : align == ALIGN_RIGHT ? (tw - w) : 0;
            if (pad < 0) pad = 0;
            for (int s = 0; s < pad; s++) putchar(' ');
            fputs(lines[i], stdout);
        }
        putchar('\n');
    }
}

static void render_block(char **lines, int n, int align, int tw) {
    int maxw = 0;
    for (int i = 0; i < n; i++) {
        int w = vis_width(lines[i]);
        if (w > maxw) maxw = w;
    }
    int offset = align == ALIGN_CENTER ? (tw - maxw) / 2 : align == ALIGN_RIGHT ? tw - maxw : 0;
    if (offset < 0) offset = 0;
    for (int i = 0; i < n; i++) {
        int w = vis_width(lines[i]);
        if (w > tw) {
            char tbuf[1024];
            truncate_ellipsis(tbuf, sizeof tbuf, lines[i], tw);
            fputs(tbuf, stdout);
            fputs(RESET, stdout);
        } else {
            for (int s = 0; s < offset; s++) putchar(' ');
            fputs(lines[i], stdout);
        }
        putchar('\n');
    }
}

static char **build_item_lines(const SysInfo *si, const Config *cfg, char **palette, int palette_n,
                               char *label_ansi, char *value_ansi, int *out_n) {
    ItemList items = build_items(si, cfg);
    char **lines = calloc(items.n ? items.n : 1, sizeof(char *));
    int k = 0, pi = 0;
    for (int i = 0; i < items.n; i++) {
        if (items.items[i].bare) {
            const char *code = items.items[i].color ? items.items[i].color : value_ansi;
            lines[k++] = code ? wrap(code, items.items[i].value) : xstrdup(items.items[i].value);
            continue;
        }
        if (!*items.items[i].label) {
            lines[k++] = xstrdup("");
            continue;
        }
        const char *code = items.items[i].color ? items.items[i].color
                         : (label_ansi ? label_ansi : palette[pi++ % palette_n]);
        char *lab = wrap(code, items.items[i].label);
        char *val = value_ansi ? wrap(value_ansi, items.items[i].value) : xstrdup(items.items[i].value);
        lines[k++] = strf("%s%s %s", lab, cfg->separator ? cfg->separator : ":", val);
        free(lab);
        free(val);
    }
    free_items(&items);
    *out_n = k;
    return lines;
}

static void free_lines(char **lines, int n) {
    for (int i = 0; i < n; i++) free(lines[i]);
    free(lines);
}

static void render_side(const SysInfo *si, char **art, int art_n, const Config *cfg,
                        char **palette, int palette_n, char *label_ansi, char *value_ansi,
                        int logo_right) {
    ItemList items = build_items(si, cfg);
    char **labels = calloc(items.n, sizeof(char *));
    char **values = calloc(items.n, sizeof(char *));
    int pi = 0;
    for (int i = 0; i < items.n; i++) {
        if (items.items[i].bare) {
            const char *code = items.items[i].color ? items.items[i].color : value_ansi;
            labels[i] = code ? wrap(code, items.items[i].value) : xstrdup(items.items[i].value);
            values[i] = xstrdup("");
            continue;
        }
        if (!*items.items[i].label) {
            labels[i] = xstrdup("");
            values[i] = xstrdup("");
            continue;
        }
        const char *code = items.items[i].color ? items.items[i].color
                         : (label_ansi ? label_ansi : palette[pi++ % palette_n]);
        labels[i] = wrap(code, items.items[i].label);
        values[i] = value_ansi ? wrap(value_ansi, items.items[i].value) : xstrdup(items.items[i].value);
    }

    int padding = cfg->padding > 0 ? cfg->padding : 0;
    int tw = term_width();

    Column artc = { art, art_n, 0 };
    Column labc = { labels, items.n, 0 };
    Column valc = { values, items.n, 0 };
    column_measure(&artc);
    column_measure(&labc);
    column_measure(&valc);

    Column cols[3];
    int starts[3];

    if (!logo_right) {
        cols[0] = artc; cols[1] = labc; cols[2] = valc;
        if (cfg->modules_position == POS_RIGHT) {
            int mw = labc.maxw + padding + valc.maxw;
            starts[0] = 0;
            starts[1] = tw - mw;
            if (starts[1] < artc.maxw + padding) starts[1] = artc.maxw + padding;
            starts[2] = starts[1] + labc.maxw + padding;
        } else {
            starts[0] = 0;
            starts[1] = artc.maxw + padding;
            starts[2] = starts[1] + labc.maxw + padding;
        }
    } else {
        cols[0] = labc; cols[1] = valc; cols[2] = artc;
        starts[0] = 0;
        starts[1] = labc.maxw + padding;
        starts[2] = tw - artc.maxw;
        int min2 = starts[1] + valc.maxw + padding;
        if (starts[2] < min2) starts[2] = min2;
    }

    render_layout(cols, 3, padding, starts, tw);

    for (int i = 0; i < items.n; i++) { free(labels[i]); free(values[i]); }
    free(labels);
    free(values);
    free_items(&items);
}

static void render_stacked(const SysInfo *si, char **art, int art_n, const Config *cfg,
                           char **palette, int palette_n, char *label_ansi, char *value_ansi,
                           int logo_top) {
    int tw = term_width();
    int item_n = 0;
    char **item_lines = build_item_lines(si, cfg, palette, palette_n, label_ansi, value_ansi, &item_n);

    if (logo_top) {
        render_block(art, art_n, ALIGN_CENTER, tw);
        putchar('\n');
        int malign = cfg->modules_position == POS_RIGHT ? ALIGN_RIGHT
                   : cfg->modules_position == POS_TOP ? ALIGN_CENTER : ALIGN_LEFT;
        render_aligned(item_lines, item_n, malign, tw);
    } else {
        render_aligned(item_lines, item_n, ALIGN_CENTER, tw);
        putchar('\n');
        int lalign = cfg->logo_position == POS_RIGHT ? ALIGN_RIGHT
                   : cfg->logo_position == POS_TOP ? ALIGN_CENTER : ALIGN_LEFT;
        render_block(art, art_n, lalign, tw);
    }

    free_lines(item_lines, item_n);
}

int df_run(const Config *cfg) {
    const Distro *sys = detect_distro();

    SysInfo si;
    sysinfo_gather(&si, sys);

    const char *logo = cfg->logo ? cfg->logo : "mini-auto";

    const Distro *ld = logo_distro(logo, sys);
    const char *logo_colors[8] = { NULL };
    char *logo_color_ansi = cfg->logo_color ? parse_color(cfg->logo_color) : NULL;
    if (logo_color_ansi) {
        for (int i = 1; i <= 6; i++) logo_colors[i] = logo_color_ansi;
    } else {
        for (int i = 1; i <= 6; i++) logo_colors[i] = ld->colors[i];
    }

    char *name = logo_name(logo, sys);
    char **file_lines = name ? load_logo(name) : NULL;
    free(name);

    char **art = NULL;
    int art_n = 0;
    if (file_lines) {
        for (char **l = file_lines; *l; l++) art_n++;
        art = calloc(art_n ? art_n : 1, sizeof(char *));
        int k = 0;
        for (char **l = file_lines; *l; l++)
            art[k++] = logo_line_ansi(*l, logo_colors);
    }

    char **palette;
    int palette_n;
    int palette_malloc = 0;
    if (cfg->palette_n > 0) {
        palette_n = cfg->palette_n;
        palette = calloc(palette_n, sizeof(char *));
        for (int i = 0; i < palette_n; i++) palette[i] = parse_color(cfg->palette[i]);
        palette_malloc = 1;
    } else {
        static char *def[] = { RED, YELLOW, GREEN, CYAN, BLUE, MAGENTA };
        palette = def;
        palette_n = 6;
    }

    char *label_ansi = cfg->label_color ? parse_color(cfg->label_color) : NULL;
    char *value_ansi = cfg->value_color ? parse_color(cfg->value_color) : NULL;

    if (cfg->logo_position == POS_TOP || cfg->modules_position == POS_TOP)
        render_stacked(&si, art, art_n, cfg, palette, palette_n, label_ansi, value_ansi,
                       cfg->logo_position == POS_TOP);
    else
        render_side(&si, art, art_n, cfg, palette, palette_n, label_ansi, value_ansi,
                    cfg->logo_position == POS_RIGHT);

    if (palette_malloc) {
        for (int i = 0; i < palette_n; i++) free(palette[i]);
        free(palette);
    }
    for (int i = 0; i < art_n; i++) free(art[i]);
    free(art);
    if (file_lines) {
        for (char **l = file_lines; *l; l++) free(*l);
        free(file_lines);
    }
    free(logo_color_ansi);
    free(label_ansi);
    free(value_ansi);
    sysinfo_free(&si);
    free(os_id); free(os_pretty);
    return 0;
}
