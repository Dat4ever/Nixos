#include "modules.h"

char *get_kernel_release(void) {
    struct utsname u;
    if (uname(&u) != 0) return xstrdup("unknown");
    return xstrdup(u.release);
}
