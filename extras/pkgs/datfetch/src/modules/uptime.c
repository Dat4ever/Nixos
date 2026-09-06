#include "modules.h"

char *get_uptime(void) {
    char *s = read_file_line("/proc/uptime");
    if (!s) return xstrdup("unknown");
    long up = (long)strtod(s, NULL);
    free(s);
    int d = up / 86400, h = (up % 86400) / 3600, m = (up % 3600) / 60;
    char buf[128];
    if (d) snprintf(buf, sizeof buf, "%d days, %d hours, %d mins", d, h, m);
    else if (h) snprintf(buf, sizeof buf, "%d hours, %d mins", h, m);
    else snprintf(buf, sizeof buf, "%d mins", m);
    return xstrdup(buf);
}
