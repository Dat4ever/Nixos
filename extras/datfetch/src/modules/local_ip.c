#include "modules.h"

char *get_local_ip(void) {
    FILE *f = popen("hostname -I 2>/dev/null", "r");
    if (!f) return xstrdup("unknown");
    char line[256];
    char *res = NULL;
    if (fgets(line, sizeof line, f)) {
        line[strcspn(line, "\n")] = 0;
        char *sp = strchr(line, ' ');
        if (sp) *sp = 0;
        if (*line) {
            char buf[300];
            snprintf(buf, sizeof buf, "%s(local)", line);
            res = xstrdup(buf);
        }
    }
    pclose(f);
    return res ? res : xstrdup("unknown");
}
