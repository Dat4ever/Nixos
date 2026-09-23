/* util.c - implementation of util.h helpers. */
#include "util.h"

#include <errno.h>
#include <fcntl.h>
#include <poll.h>
#include <signal.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/stat.h>
#include <sys/types.h>
#include <sys/wait.h>
#include <time.h>
#include <unistd.h>

/* ---------- strbuf ---------- */

void sb_init(strbuf *sb) {
    sb->data = NULL;
    sb->len = 0;
    sb->cap = 0;
}

static int sb_reserve(strbuf *sb, size_t extra) {
    if (sb->len + extra + 1 <= sb->cap)
        return 0;
    size_t ncap = sb->cap ? sb->cap : 256;
    while (ncap < sb->len + extra + 1)
        ncap *= 2;
    char *nd = realloc(sb->data, ncap);
    if (!nd)
        return -1;
    sb->data = nd;
    sb->cap = ncap;
    if (sb->len == 0)
        sb->data[0] = '\0'; /* keep NUL-terminated invariant for empty buffer */
    return 0;
}

void sb_addn(strbuf *sb, const char *s, size_t n) {
    if (!s || sb_reserve(sb, n) != 0)
        return;
    memcpy(sb->data + sb->len, s, n);
    sb->len += n;
    sb->data[sb->len] = '\0';
}

void sb_add(strbuf *sb, const char *s) {
    if (s)
        sb_addn(sb, s, strlen(s));
}

void sb_addch(strbuf *sb, char c) {
    sb_addn(sb, &c, 1);
}

void sb_free(strbuf *sb) {
    free(sb->data);
    sb_init(sb);
}

/* ---------- filesystem ---------- */

int file_exists(const char *path) {
    struct stat st;
    return path && stat(path, &st) == 0 && S_ISREG(st.st_mode);
}

int dir_exists(const char *path) {
    struct stat st;
    return path && stat(path, &st) == 0 && S_ISDIR(st.st_mode);
}

int mkdir_p(const char *path) {
    if (!path || !path[0])
        return -1;
    char buf[4096];
    if (str_copy(buf, sizeof buf, path) != 0)
        return -1;
    /* strip trailing slashes (keep a lone root slash) */
    size_t len = strlen(buf);
    while (len > 1 && buf[len - 1] == '/')
        buf[--len] = '\0';
    for (char *p = buf + 1; *p; p++) {
        if (*p == '/') {
            *p = '\0';
            if (mkdir(buf, 0755) != 0 && errno != EEXIST)
                return -1;
            *p = '/';
        }
    }
    if (mkdir(buf, 0755) != 0 && errno != EEXIST)
        return -1;
    return dir_exists(buf) ? 0 : -1;
}

/* ---------- time ---------- */

long now_sec(void) {
    struct timespec ts;
    clock_gettime(CLOCK_REALTIME, &ts);
    return (long)ts.tv_sec;
}

long long now_ms(void) {
    struct timespec ts;
    clock_gettime(CLOCK_REALTIME, &ts);
    return (long long)ts.tv_sec * 1000 + ts.tv_nsec / 1000000;
}

/* ---------- process capture ---------- */

static void wait_child(pid_t pid) {
    int st;
    while (waitpid(pid, &st, 0) < 0 && errno == EINTR)
        ;
}

int run_capture(char *const argv[], strbuf *out, strbuf *err, int timeout_ms) {
    int op[2], ep[2];
    if (pipe(op) != 0 || pipe(ep) != 0) {
        close(op[0]);
        close(op[1]);
        return -1;
    }
    pid_t pid = fork();
    if (pid < 0) {
        close(op[0]); close(op[1]);
        close(ep[0]); close(ep[1]);
        return -1;
    }
    if (pid == 0) {
        /* own process group so the parent can kill the whole tree */
        setpgid(0, 0);
        dup2(op[1], STDOUT_FILENO);
        dup2(ep[1], STDERR_FILENO);
        int devnull = open("/dev/null", O_RDONLY);
        dup2(devnull, STDIN_FILENO);
        for (int fd = 3; fd < 4096; fd++)
            close(fd);
        execvp(argv[0], argv);
        _exit(127);
    }
    close(op[1]);
    close(ep[1]);

    long long deadline = now_ms() + timeout_ms;
    int o_done = 0, e_done = 0, timed_out = 0;
    while (!o_done || !e_done) {
        long long left = deadline - now_ms();
        if (left <= 0) {
            timed_out = 1;
            break;
        }
        struct pollfd pf[2] = {
            { .fd = op[0], .events = POLLIN, .revents = 0 },
            { .fd = ep[0], .events = POLLIN, .revents = 0 },
        };
        int nfd = o_done ? 1 : 2;
        int pr = poll(pf, (nfds_t)nfd, (int)(left > 250 ? 250 : left));
        if (pr < 0) {
            if (errno == EINTR)
                continue;
            break;
        }
        if (!o_done && (pf[0].revents & (POLLIN | POLLHUP | POLLERR))) {
            char chunk[4096];
            ssize_t r = read(op[0], chunk, sizeof chunk);
            if (r > 0)
                sb_addn(out, chunk, (size_t)r);
            else if (r == 0)
                o_done = 1;
            else if (errno != EINTR && errno != EAGAIN)
                o_done = 1;
        }
        if (!e_done && nfd == 2 && (pf[1].revents & (POLLIN | POLLHUP | POLLERR))) {
            char chunk[4096];
            ssize_t r = read(ep[0], chunk, sizeof chunk);
            if (r > 0)
                sb_addn(err, chunk, (size_t)r);
            else if (r == 0)
                e_done = 1;
            else if (errno != EINTR && errno != EAGAIN)
                e_done = 1;
        }
    }
    close(op[0]);
    close(ep[0]);

    if (timed_out) {
        kill(-pid, SIGKILL);
        wait_child(pid);
        return -2;
    }
    int st;
    if (waitpid(pid, &st, 0) < 0)
        return -1;
    return WIFEXITED(st) ? WEXITSTATUS(st) : -1;
}

/* ---------- misc ---------- */

void argv_free(char **argv) {
    if (!argv)
        return;
    for (int i = 0; argv[i]; i++)
        free(argv[i]);
    free(argv);
}

char *str_trim(char *s) {
    if (!s)
        return s;
    size_t len = strlen(s);
    size_t start = 0;
    while (start < len && (s[start] == ' ' || s[start] == '\t' || s[start] == '\r' || s[start] == '\n'))
        start++;
    size_t end = len;
    while (end > start && (s[end - 1] == ' ' || s[end - 1] == '\t' || s[end - 1] == '\r' || s[end - 1] == '\n'))
        end--;
    if (start > 0)
        memmove(s, s + start, end - start);
    s[end - start] = '\0';
    return s;
}

int str_copy(char *dst, size_t cap, const char *src) {
    if (!dst || cap == 0)
        return -1;
    if (!src)
        src = "";
    size_t n = strlen(src);
    if (n >= cap) {
        memcpy(dst, src, cap - 1);
        dst[cap - 1] = '\0';
        return -1;
    }
    memcpy(dst, src, n + 1);
    return 0;
}

int str_starts(const char *s, const char *prefix) {
    return s && prefix && strncmp(s, prefix, strlen(prefix)) == 0;
}
