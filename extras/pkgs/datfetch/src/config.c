#include "datfetch.h"

#include <dirent.h>

static const char *const module_keys[N_MODULES] = {
    "user", "host", "user_host", "model", "os", "kernel", "shell", "desktop", "terminal",
    "cpu", "gpu", "memory", "disk", "font", "resolution", "uptime", "ip",
    "installed", "packages",
};

static const char *const default_palette[] = {
    "red", "yellow", "green", "cyan", "blue", "magenta",
};

char *config_dir(void) {
    const char *xdg = getenv("XDG_CONFIG_HOME");
    const char *home = getenv("HOME");
    if (xdg && *xdg) return strf("%s/datfetch", xdg);
    if (home && *home) return strf("%s/.config/datfetch", home);
    return NULL;
}

char *config_path(void) {
    char *dir = config_dir();
    if (!dir) return NULL;
    char *p = strf("%s/config", dir);
    free(dir);
    return p;
}

char *builtin_dir(void) {
    const char *override = getenv("DATFETCH_DATA_DIR");
    if (override && *override) return xstrdup(override);
    const char *home = getenv("HOME");
    if (home && *home) return strf("%s/Documents/projects/Datfetch/config", home);
    return NULL;
}

static void mkdir_p(char *path) {
    for (char *p = path + 1; *p; p++)
        if (*p == '/') { *p = 0; mkdir(path, 0755); *p = '/'; }
    mkdir(path, 0755);
}

void copy_dir(const char *src, const char *dst, const char *suffix) {
    char *d = xstrdup(dst);
    mkdir_p(d);
    free(d);

    DIR *dir = opendir(src);
    if (!dir) return;
    struct dirent *e;
    size_t sl = strlen(suffix);
    while ((e = readdir(dir)) != NULL) {
        const char *n = e->d_name;
        if (n[0] == '.') continue;
        size_t nl = strlen(n);
        if (nl <= sl || strcmp(n + nl - sl, suffix) != 0) continue;
        char *sp = strf("%s/%s", src, n);
        char *dp = strf("%s/%s", dst, n);
        FILE *in = fopen(sp, "r");
        if (in) {
            fseek(in, 0, SEEK_END);
            long sz = ftell(in);
            fseek(in, 0, SEEK_SET);
            char *buf = malloc(sz > 0 ? (size_t)sz : 1);
            size_t r = fread(buf, 1, (size_t)sz, in);
            fclose(in);
            FILE *out = fopen(dp, "w");
            if (out) { fwrite(buf, 1, r, out); fclose(out); }
            free(buf);
        }
        free(sp); free(dp);
    }
    closedir(dir);
}

static char *trim(char *s) {
    while (*s == ' ' || *s == '\t') s++;
    char *e = s + strlen(s);
    while (e > s && (e[-1] == ' ' || e[-1] == '\t' || e[-1] == '\r' || e[-1] == '\n'))
        *--e = 0;
    return s;
}

static char *unquote(char *s) {
    char *t = trim(s);
    size_t l = strlen(t);
    if (l >= 2 && ((t[0] == '"' && t[l - 1] == '"') || (t[0] == '\'' && t[l - 1] == '\''))) {
        t[l - 1] = 0;
        return t + 1;
    }
    return t;
}

void config_defaults(Config *c) {
    memset(c, 0, sizeof *c);
    c->logo_position = POS_LEFT;
    c->modules_position = POS_LEFT;
    c->padding = 2;
    c->separator = xstrdup(":");
    for (int i = 0; i < N_MODULES; i++) {
        c->mod[i].enabled = 1;
        c->order[i] = i;
    }
    c->mod[M_USER].enabled = 0;
    c->mod[M_HOST].enabled = 0;
    c->mod[M_MODEL].enabled = 0;
    c->mod[M_TERMINAL].enabled = 0;
    c->mod[M_CPU].enabled = 0;
    c->mod[M_GPU].enabled = 0;
    c->mod[M_MEMORY].enabled = 0;
    c->mod[M_DISK].enabled = 0;
    c->mod[M_FONT].enabled = 0;
    c->mod[M_RESOLUTION].enabled = 0;
    c->mod[M_IP].enabled = 0;
    c->mod[M_INSTALLED].enabled = 0;
    c->mod[M_USERHOST].color = xstrdup("cyan");
    c->n_order = N_MODULES;
    c->palette = calloc(7, sizeof(char *));
    for (int i = 0; i < 6; i++) c->palette[i] = xstrdup(default_palette[i]);
    c->palette_n = 6;
}

void config_free(Config *c) {
    free(c->logo);
    free(c->logo_color);
    free(c->label_color);
    free(c->value_color);
    free(c->separator);
    for (int i = 0; c->palette && c->palette[i]; i++) free(c->palette[i]);
    free(c->palette);
    for (int i = 0; c->section_breaks && c->section_breaks[i]; i++) free(c->section_breaks[i]);
    free(c->section_breaks);
    for (int i = 0; i < N_MODULES; i++) free(c->mod[i].color);
    memset(c, 0, sizeof *c);
}

static int module_index(const char *key) {
    for (int i = 0; i < N_MODULES; i++)
        if (strcmp(key, module_keys[i]) == 0) return i;
    return -1;
}

static void set_palette(Config *c, const char *list) {
    for (int i = 0; c->palette && c->palette[i]; i++) free(c->palette[i]);
    free(c->palette);
    c->palette = NULL;
    c->palette_n = 0;

    char *copy = xstrdup(list);
    char *save = NULL;
    for (char *tok = strtok_r(copy, ",", &save); tok; tok = strtok_r(NULL, ",", &save)) {
        char *t = trim(tok);
        if (!*t) continue;
        c->palette = realloc(c->palette, (c->palette_n + 2) * sizeof(char *));
        c->palette[c->palette_n++] = xstrdup(t);
        c->palette[c->palette_n] = NULL;
    }
    free(copy);
}

static void set_string_list(char ***list, int *n, const char *val) {
    for (int i = 0; *list && (*list)[i]; i++) free((*list)[i]);
    free(*list);
    *list = NULL;
    *n = 0;

    char *copy = xstrdup(val);
    char *s = copy;
    while (*s == '[' || *s == ' ' || *s == '\t') s++;
    char *e = s + strlen(s);
    while (e > s && (e[-1] == ']' || e[-1] == ' ' || e[-1] == '\t')) *--e = 0;

    char *save = NULL;
    for (char *tok = strtok_r(s, ",", &save); tok; tok = strtok_r(NULL, ",", &save)) {
        char *t = unquote(trim(tok));
        if (!*t) continue;
        *list = realloc(*list, (*n + 2) * sizeof(char *));
        (*list)[(*n)++] = xstrdup(t);
        (*list)[*n] = NULL;
    }
    free(copy);
}

int config_load(Config *c, const char *path) {
    FILE *f = fopen(path, "r");
    if (!f) return -1;
    char line[512];
    int section = 0;
    int modules_seen = 0;
    while (fgets(line, sizeof line, f)) {
        char *t = trim(line);
        for (char *p = t; *p; p++) {
            if (*p == '#' && (p == t || p[-1] == ' ' || p[-1] == '\t')) {
                *p = 0;
                break;
            }
        }
        t = trim(t);
        if (!*t) continue;
        if (*t == '[') {
            char *end = strchr(t, ']');
            if (end) {
                *end = 0;
                char *sec = trim(t + 1);
                if (strcmp(sec, "modules") == 0) {
                    section = 1;
                    if (!modules_seen) { modules_seen = 1; c->n_order = 0; }
                } else if (strcmp(sec, "colors") == 0) {
                    section = 2;
                } else {
                    section = 0;
                }
            }
            continue;
        }
        char *eq = strchr(t, '=');
        if (!eq) continue;
        *eq = 0;
        char *key = trim(t);
        char *val = unquote(eq + 1);

        if (section == 1) {
            int idx = module_index(key);
            if (idx >= 0) {
                c->mod[idx].enabled = strcasecmp(val, "true") == 0;
                int found = 0;
                for (int i = 0; i < c->n_order; i++)
                    if (c->order[i] == idx) { found = 1; break; }
                if (!found) c->order[c->n_order++] = idx;
            }
        } else if (section == 2) {
            if (strcmp(key, "label") == 0) {
                set_palette(c, val);
            } else {
                int idx = module_index(key);
                if (idx >= 0) {
                    free(c->mod[idx].color);
                    c->mod[idx].color = xstrdup(val);
                }
            }
        } else if (strcmp(key, "logo_position") == 0) {
            if (strcasecmp(val, "right") == 0) c->logo_position = POS_RIGHT;
            else if (strcasecmp(val, "top") == 0 || strcasecmp(val, "center") == 0) c->logo_position = POS_TOP;
            else c->logo_position = POS_LEFT;
        } else if (strcmp(key, "modules_position") == 0) {
            if (strcasecmp(val, "right") == 0) c->modules_position = POS_RIGHT;
            else if (strcasecmp(val, "top") == 0 || strcasecmp(val, "center") == 0) c->modules_position = POS_TOP;
            else c->modules_position = POS_LEFT;
        } else if (strcmp(key, "icons") == 0) {
            c->icons = strcasecmp(val, "true") == 0;
        } else if (strcmp(key, "padding") == 0) {
            c->padding = atoi(val);
        } else if (strcmp(key, "logo") == 0) {
            free(c->logo);
            c->logo = xstrdup(val);
        } else if (strcmp(key, "logo_color") == 0) {
            free(c->logo_color);
            c->logo_color = xstrdup(val);
        } else if (strcmp(key, "label_color") == 0) {
            free(c->label_color);
            c->label_color = xstrdup(val);
        } else if (strcmp(key, "value_color") == 0) {
            free(c->value_color);
            c->value_color = xstrdup(val);
        } else if (strcmp(key, "separator") == 0 || strcmp(key, "seperator") == 0) {
            free(c->separator);
            c->separator = xstrdup(val);
        } else if (strcmp(key, "section_breaks") == 0) {
            set_string_list(&c->section_breaks, &c->n_section_breaks, val);
        }
    }
    for (int i = 0; i < N_MODULES; i++) {
        int found = 0;
        for (int j = 0; j < c->n_order; j++)
            if (c->order[j] == i) { found = 1; break; }
        if (!found) c->order[c->n_order++] = i;
    }
    fclose(f);
    return 0;
}

void config_write(const Config *c, const char *path) {
    char *dir = xstrdup(path);
    char *slash = strrchr(dir, '/');
    if (slash) { *slash = 0; mkdir_p(dir); }
    free(dir);

    FILE *f = fopen(path, "w");
    if (!f) return;
    const char *pos = c->logo_position == POS_TOP ? "top"
                    : c->logo_position == POS_RIGHT ? "right" : "left";
    fprintf(f, "logo_position = \"%s\"\n", pos);
    const char *mpos = c->modules_position == POS_TOP ? "top"
                     : c->modules_position == POS_RIGHT ? "right" : "left";
    fprintf(f, "modules_position = \"%s\"\n", mpos);
    fprintf(f, "icons = %s\n", c->icons ? "true" : "false");
    fprintf(f, "padding = %d\n", c->padding);
    if (c->logo) fprintf(f, "logo = \"%s\"\n", c->logo);
    if (c->logo_color) fprintf(f, "logo_color = \"%s\"\n", c->logo_color);
    if (c->label_color) fprintf(f, "label_color = \"%s\"\n", c->label_color);
    if (c->value_color) fprintf(f, "value_color = \"%s\"\n", c->value_color);
    fprintf(f, "separator = \"%s\"\n", c->separator ? c->separator : ":");
    if (c->n_section_breaks > 0) {
        fputs("section_breaks = [", f);
        for (int i = 0; i < c->n_section_breaks; i++)
            fprintf(f, "%s\"%s\"", i ? ", " : "", c->section_breaks[i]);
        fputs("]\n", f);
    }
    fprintf(f, "\n[modules]\n");
    for (int i = 0; i < N_MODULES; i++)
        fprintf(f, "%s = %s\n", module_keys[i], c->mod[i].enabled ? "true" : "false");
    fprintf(f, "\n[colors]\n");
    if (c->palette_n > 0) {
        fputs("label = \"", f);
        for (int i = 0; i < c->palette_n; i++)
            fprintf(f, "%s%s", i ? ", " : "", c->palette[i]);
        fputs("\"\n", f);
    }
    for (int i = 0; i < N_MODULES; i++)
        if (c->mod[i].color)
            fprintf(f, "%s = \"%s\"\n", module_keys[i], c->mod[i].color);
    fclose(f);
}
