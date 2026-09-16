#include "modules.h"

void disk_info(long long *used_bytes, long long *total_bytes) {
    *used_bytes = 0;
    *total_bytes = 0;
    struct statvfs st;
    if (statvfs("/", &st) != 0) return;
    unsigned long long total = (unsigned long long)st.f_blocks * st.f_frsize;
    unsigned long long avail = (unsigned long long)st.f_bavail * st.f_frsize;
    *total_bytes = (long long)total;
    *used_bytes = (long long)(total - avail);
}
