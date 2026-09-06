#include "modules.h"

char **get_cpus(void) {
    FILE *f = fopen("/proc/cpuinfo", "r");
    if (!f) return NULL;
    char *list[64];
    int n = 0;
    char line[512];
    while (fgets(line, sizeof line, f) && n < 64) {
        const char *name = NULL;
        if (strncmp(line, "model name", 10) == 0 || strncmp(line, "Hardware", 8) == 0) {
            const char *colon = strchr(line, ':');
            if (colon) {
                name = colon + 1;
                while (*name == ' ' || *name == '\t') name++;
            }
        }
        if (!name) continue;
        char tmp[512];
        snprintf(tmp, sizeof tmp, "%s", name);
        tmp[strcspn(tmp, "\n")] = 0;

        int dup = 0;
        for (int i = 0; i < n; i++)
            if (strcmp(list[i], tmp) == 0) { dup = 1; break; }
        if (dup) continue;

        list[n++] = xstrdup(tmp);
    }
    fclose(f);
    if (n == 0) return NULL;
    char **out = malloc((n + 1) * sizeof(char *));
    if (!out) return NULL;
    for (int i = 0; i < n; i++) out[i] = list[i];
    out[n] = NULL;
    return out;
}

int get_cpu_count(void) {
    FILE *f = fopen("/proc/cpuinfo", "r");
    if (!f) return 0;
    char line[512];
    int n = 0;
    while (fgets(line, sizeof line, f))
        if (strncmp(line, "processor", 9) == 0) n++;
    fclose(f);
    return n;
}
