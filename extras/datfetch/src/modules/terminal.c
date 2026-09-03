#include "modules.h"

char *get_terminal(void) {
    const char *t = getenv("TERM_PROGRAM");
    if (!t || !*t) t = getenv("TERM");
    return xstrdup(t && *t ? t : "unknown");
}
