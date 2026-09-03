#include "modules.h"

char *get_desktop(void) {
    const char *de = getenv("XDG_CURRENT_DESKTOP");
    if (de && *de) return xstrdup(de);
    de = getenv("DESKTOP_SESSION");
    if (de && *de) return xstrdup(de);
    de = getenv("XDG_SESSION_DESKTOP");
    if (de && *de) return xstrdup(de);
    return xstrdup("unknown");
}
