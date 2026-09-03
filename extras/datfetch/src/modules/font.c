#include "modules.h"

static char *fc_family(const char *generic) {
    char cmd[128];
    snprintf(cmd, sizeof cmd, "fc-match -f '%%{family}' %s 2>/dev/null", generic);
    FILE *f = popen(cmd, "r");
    if (!f) return NULL;
    char line[512];
    char *res = NULL;
    if (fgets(line, sizeof line, f)) {
        line[strcspn(line, "\n")] = 0;
        res = xstrdup(line);
    }
    pclose(f);
    return res;
}

char *get_font_mono(void) {
    char *r = fc_family("monospace");
    return r ? r : xstrdup("unknown");
}

char *get_font_sans(void) {
    char *r = fc_family("sans-serif");
    return r ? r : xstrdup("unknown");
}

char *get_font_serif(void) {
    char *r = fc_family("serif");
    return r ? r : xstrdup("unknown");
}
