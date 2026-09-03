#include "modules.h"

void memory_info(long long *used_kib, long long *total_kib) {
    *used_kib = 0;
    *total_kib = 0;
    FILE *f = fopen("/proc/meminfo", "r");
    if (!f) return;
    char line[256];
    long total = 0, avail = 0;
    while (fgets(line, sizeof line, f)) {
        if (strncmp(line, "MemTotal:", 9) == 0) total = strtol(line + 9, NULL, 10);
        else if (strncmp(line, "MemAvailable:", 13) == 0) avail = strtol(line + 13, NULL, 10);
    }
    fclose(f);
    *total_kib = total;
    *used_kib = total - avail;
}
