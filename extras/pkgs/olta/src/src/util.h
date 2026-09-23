/* util.h - small helpers: string buffer, fs checks, time, process capture. */
#ifndef YTGRAB_UTIL_H
#define YTGRAB_UTIL_H

#include <stddef.h>

/* Growable NUL-terminated string buffer. */
typedef struct {
    char  *data;
    size_t len; /* bytes used, excluding NUL */
    size_t cap; /* allocated bytes (>= len + 1) */
} strbuf;

void sb_init(strbuf *sb);
void sb_free(strbuf *sb);
void sb_add(strbuf *sb, const char *s);
void sb_addn(strbuf *sb, const char *s, size_t n);
void sb_addch(strbuf *sb, char c);

/* Filesystem helpers, return 1 = yes / 0 = no. */
int file_exists(const char *path);
int dir_exists(const char *path);
/* mkdir -p equivalent; 0 on success. */
int mkdir_p(const char *path);

/* Time helpers. */
long now_sec(void);
long long now_ms(void);

/* Run argv (fork + execvp) capturing stdout/stderr; child gets its own
 * process group. Returns child exit code, -1 on spawn failure, -2 on timeout. */
int run_capture(char *const argv[], strbuf *out, strbuf *err, int timeout_ms);

/* Free a NULL-terminated argv vector built with strdup. */
void argv_free(char **argv);

/* Safe string helpers. */
char *str_trim(char *s);                                   /* in place, returns s */
int   str_copy(char *dst, size_t cap, const char *src);    /* 0 ok, -1 truncated */
int   str_starts(const char *s, const char *prefix);       /* 1 if s starts with prefix */

#endif
