#include "modules.h"

char *get_shell(void) {
    const char *s = getenv("SHELL");
    if (!s) return xstrdup("unknown");
    const char *slash = strrchr(s, '/');
    return xstrdup(slash ? slash + 1 : s);
}
