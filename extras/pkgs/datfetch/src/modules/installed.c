#include "modules.h"

char *get_install_date(void) {
    char line[256];
    char *res = NULL;

    FILE *f = popen("stat -c %w / 2>/dev/null", "r");
    if (f) {
        if (fgets(line, sizeof line, f)) {
            line[strcspn(line, "\n")] = 0;
            if (*line && strcmp(line, "-") != 0 && strncmp(line, "1970", 4) != 0 && strncmp(line, "1969", 4) != 0) {
                if (strlen(line) > 16) line[16] = 0;
                res = xstrdup(line);
            }
        }
        pclose(f);
    }
    if (res) return res;

    f = popen("stat -c %y /etc/os-release 2>/dev/null", "r");
    if (f) {
        if (fgets(line, sizeof line, f)) {
            line[strcspn(line, "\n")] = 0;
            if (*line) {
                if (strlen(line) > 16) line[16] = 0;
                res = xstrdup(line);
            }
        }
        pclose(f);
    }
    return res ? res : xstrdup("unknown");
}
