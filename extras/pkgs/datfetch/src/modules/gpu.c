#include "modules.h"

char **get_gpus(void) {
    FILE *f = popen("lspci 2>/dev/null", "r");
    if (!f) return NULL;
    char *list[16];
    int n = 0;
    char line[512];
    while (fgets(line, sizeof line, f) && n < 16) {
        if (!strstr(line, "VGA") && !strstr(line, "3D") && !strstr(line, "Display"))
            continue;
        const char *colon = strchr(line, ':');
        const char *second = colon ? strchr(colon + 1, ':') : NULL;
        const char *start = second ? second + 2 : line;
        char tmp[512];
        snprintf(tmp, sizeof tmp, "%s", start);
        tmp[strcspn(tmp, "\n")] = 0;
        char *rev = strstr(tmp, " (rev ");
        if (rev) *rev = 0;
        list[n++] = xstrdup(tmp);
    }
    pclose(f);
    if (n == 0) return NULL;
    char **out = malloc((n + 1) * sizeof(char *));
    if (!out) return NULL;
    for (int i = 0; i < n; i++) out[i] = list[i];
    out[n] = NULL;
    return out;
}
