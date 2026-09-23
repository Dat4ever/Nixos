/* http.c - hand-written minimal HTTP/1.1 server: 127.0.0.1 only,
 * one detached thread per connection, Content-Length bodies (cap 1 MB),
 * JSON and static file responses. */
#include "http.h"

#include "util.h"

#include <arpa/inet.h>
#include <ctype.h>
#include <errno.h>
#include <netinet/in.h>
#include <netinet/tcp.h>
#include <pthread.h>
#include <signal.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <strings.h>
#include <sys/socket.h>
#include <sys/types.h>
#include <unistd.h>

#define MAX_HEADER_BYTES (32 * 1024)
#define MAX_BODY_BYTES   (1024 * 1024)

/* ---------- low-level write ---------- */

static int write_all(int fd, const void *buf, size_t len) {
    const char *p = buf;
    while (len > 0) {
        ssize_t w = write(fd, p, len);
        if (w < 0) {
            if (errno == EINTR)
                continue;
            return -1;
        }
        p += w;
        len -= (size_t)w;
    }
    return 0;
}

static const char *status_reason(int status) {
    switch (status) {    case 200: return "OK";
    case 202: return "Accepted";
    case 204: return "No Content";
    case 400: return "Bad Request";
    case 403: return "Forbidden";
    case 404: return "Not Found";
    case 405: return "Method Not Allowed";
    case 409: return "Conflict";
    case 413: return "Payload Too Large";
    case 500: return "Internal Server Error";
    case 503: return "Service Unavailable";
    default:  return "Unknown";
    }
}

static void respond_raw(int fd, int status, const char *content_type,
                        const void *body, size_t body_len) {
    char head[512];
    int n = snprintf(head, sizeof head,
                     "HTTP/1.1 %d %s\r\n"
                     "Content-Type: %s\r\n"
                     "Content-Length: %zu\r\n"
                     "Cache-Control: no-cache\r\n"
                     "Connection: close\r\n"
                     "\r\n",
                     status, status_reason(status), content_type, body_len);
    if (n < 0 || (size_t)n >= sizeof head)
        return;
    if (write_all(fd, head, (size_t)n) == 0 && body_len > 0)
        write_all(fd, body, body_len);
}

void http_respond_json(int fd, int status, const char *json_body) {
    if (!json_body)
        json_body = "{}";
    respond_raw(fd, status, "application/json; charset=utf-8",
                json_body, strlen(json_body));
}

/* ---------- static files ---------- */

static const char *mime_for_path(const char *path) {
    const char *dot = strrchr(path, '.');
    if (!dot)
        return "application/octet-stream";
    if (strcmp(dot, ".html") == 0 || strcmp(dot, ".htm") == 0)
        return "text/html; charset=utf-8";
    if (strcmp(dot, ".js") == 0)
        return "text/javascript; charset=utf-8";
    if (strcmp(dot, ".css") == 0)
        return "text/css; charset=utf-8";
    if (strcmp(dot, ".svg") == 0)
        return "image/svg+xml";
    if (strcmp(dot, ".png") == 0)
        return "image/png";
    if (strcmp(dot, ".ico") == 0)
        return "image/x-icon";
    if (strcmp(dot, ".json") == 0)
        return "application/json; charset=utf-8";
    return "application/octet-stream";
}

int http_send_file(int fd, const char *path) {
    FILE *fp = fopen(path, "rb");
    if (!fp)
        return -1;
    fseek(fp, 0, SEEK_END);
    long size = ftell(fp);
    fseek(fp, 0, SEEK_SET);
    if (size < 0 || size > 16 * 1024 * 1024) {
        fclose(fp);
        return -1;
    }
    char *buf = malloc((size_t)size + 1);
    if (!buf) {
        fclose(fp);
        return -1;
    }
    size_t got = fread(buf, 1, (size_t)size, fp);
    fclose(fp);
    respond_raw(fd, 200, mime_for_path(path), buf, got);
    free(buf);
    return 0;
}

/* ---------- request parsing ---------- */

static const char *find_header_end(const char *s, size_t len) {
    for (size_t i = 0; i + 3 < len; i++)
        if (s[i] == '\r' && s[i + 1] == '\n' && s[i + 2] == '\r' && s[i + 3] == '\n')
            return s + i + 4;
    return NULL;
}

/* Case-insensitive header line lookup within the header block. */
static int header_value(const char *hdrs, size_t len, const char *name,
                        char *out, size_t cap) {
    size_t nlen = strlen(name);
    size_t pos = 0;
    while (pos < len) {
        const char *eol = memchr(hdrs + pos, '\n', len - pos);
        size_t line_len = eol ? (size_t)(eol - (hdrs + pos)) : len - pos;
        if (line_len > 0 && hdrs[pos + line_len - 1] == '\r')
            line_len--;
        if (line_len > nlen && strncasecmp(hdrs + pos, name, nlen) == 0 &&
            hdrs[pos + nlen] == ':') {
            size_t v = pos + nlen + 1;
            while (v < pos + line_len && (hdrs[v] == ' ' || hdrs[v] == '\t'))
                v++;
            size_t vlen = pos + line_len - v;
            if (vlen >= cap)
                vlen = cap - 1;
            memcpy(out, hdrs + v, vlen);
            out[vlen] = '\0';
            return 1;
        }
        pos += eol ? (size_t)(eol - (hdrs + pos)) + 1 : len - pos;
    }
    return 0;
}

/* Read one request from fd. Returns 0 and fills req on success. On malformed
 * input an error response is sent and -1 returned. */
static int read_request(int fd, http_request *req) {
    strbuf buf;
    sb_init(&buf);
    memset(req, 0, sizeof *req);

    const char *hdr_end = NULL;
    size_t header_len = 0;
    char chunk[4096];
    for (;;) {
        hdr_end = find_header_end(buf.data ? buf.data : "", buf.len);
        if (hdr_end)
            break;
        if (buf.len > MAX_HEADER_BYTES) {
            http_respond_json(fd, 400, "{\"error\":\"header too large\"}");
            goto fail;
        }
        ssize_t r = read(fd, chunk, sizeof chunk);
        if (r < 0) {
            if (errno == EINTR)
                continue;
            goto fail; /* client vanished: no response possible */
        }
        if (r == 0) {
            if (buf.len == 0) {
                goto fail; /* idle close */
            }
            http_respond_json(fd, 400, "{\"error\":\"malformed request\"}");
            goto fail;
        }
        sb_addn(&buf, chunk, (size_t)r);
    }
    header_len = (size_t)(hdr_end - (buf.data ? buf.data : ""));

    /* request line: METHOD SP target SP version */
    const char *line_end = memchr(buf.data, '\n', header_len);
    size_t req_line_len = line_end ? (size_t)(line_end - buf.data) : header_len;
    if (req_line_len > 0 && buf.data[req_line_len - 1] == '\r')
        req_line_len--;
    char reqline[4096];
    if (req_line_len == 0 || req_line_len >= sizeof reqline) {
        http_respond_json(fd, 400, "{\"error\":\"malformed request\"}");
        goto fail;
    }
    memcpy(reqline, buf.data, req_line_len);
    reqline[req_line_len] = '\0';

    char target[2048];
    char method[16] = "";
    {
        char version[16] = "";
        if (sscanf(reqline, "%15s %2047s %15s", method, target, version) < 2) {
            http_respond_json(fd, 400, "{\"error\":\"malformed request\"}");
            goto fail;
        }
    }
    str_copy(req->method, sizeof req->method, method);

    /* split target into path + query */
    char *qm = strchr(target, '?');
    if (qm) {
        req->query = strdup(qm + 1);
        *qm = '\0';
    } else {
        req->query = strdup("");
    }
    req->path = strdup(target);
    if (!req->path || !req->query)
        goto fail;

    /* body: Content-Length only */
    char cl[32] = "";
    if (header_value(buf.data, header_len, "Content-Length", cl, sizeof cl)) {
        char *endp = NULL;
        long long v = strtoll(cl, &endp, 10);
        if (!endp || *endp != '\0' || v < 0 || v > MAX_BODY_BYTES) {
            http_respond_json(fd, v > MAX_BODY_BYTES ? 413 : 400,
                              v > MAX_BODY_BYTES ? "{\"error\":\"body too large\"}"
                                                 : "{\"error\":\"malformed request\"}");
            goto fail;
        }
        size_t have = buf.len - header_len; /* already-read body bytes */
        if (have > (size_t)v)
            have = (size_t)v;
        req->body = malloc((size_t)v + 1);
        if (!req->body)
            goto fail;
        memcpy(req->body, buf.data + header_len, have);
        req->body_len = (size_t)v;
        while (have < req->body_len) {
            ssize_t r = read(fd, req->body + have, req->body_len - have);
            if (r < 0) {
                if (errno == EINTR)
                    continue;
                goto fail;
            }
            if (r == 0) {
                http_respond_json(fd, 400, "{\"error\":\"incomplete body\"}");
                goto fail;
            }
            have += (size_t)r;
        }
        req->body[req->body_len] = '\0';
    }

    sb_free(&buf);
    return 0;

fail:
    sb_free(&buf);
    free(req->path);
    free(req->query);
    free(req->body);
    memset(req, 0, sizeof *req);
    return -1;
}

static void request_free(http_request *req) {
    free(req->path);
    free(req->query);
    free(req->body);
    memset(req, 0, sizeof *req);
}

/* ---------- connection handling ---------- */

typedef struct {
    int fd;
    http_handler_fn fn;
    void *ud;
} conn_task;

static void *conn_main(void *arg) {
    conn_task task = *(conn_task *)arg;
    free(arg);

    /* 30 s receive timeout so stuck clients cannot pin a thread forever */
    struct timeval tv = { .tv_sec = 30, .tv_usec = 0 };
    setsockopt(task.fd, SOL_SOCKET, SO_RCVTIMEO, &tv, sizeof tv);

    http_request req;
    if (read_request(task.fd, &req) == 0) {
        task.fn(&req, task.fd, task.ud);
        request_free(&req);
    }
    shutdown(task.fd, SHUT_RDWR);
    close(task.fd);
    return NULL;
}

int http_serve(int port, http_handler_fn fn, void *ud) {
    signal(SIGPIPE, SIG_IGN); /* ignore globally, per contract */

    int sfd = socket(AF_INET, SOCK_STREAM, 0);
    if (sfd < 0) {
        perror("socket");
        return -1;
    }
    int one = 1;
    setsockopt(sfd, SOL_SOCKET, SO_REUSEADDR, &one, sizeof one);

    struct sockaddr_in addr;
    memset(&addr, 0, sizeof addr);
    addr.sin_family = AF_INET;
    addr.sin_addr.s_addr = htonl(INADDR_LOOPBACK); /* 127.0.0.1 only */
    addr.sin_port = htons((uint16_t)port);
    if (bind(sfd, (struct sockaddr *)&addr, sizeof addr) != 0) {
        perror("bind");
        close(sfd);
        return -1;
    }
    if (listen(sfd, 64) != 0) {
        perror("listen");
        close(sfd);
        return -1;
    }

    pthread_attr_t attr;
    pthread_attr_init(&attr);
    pthread_attr_setdetachstate(&attr, PTHREAD_CREATE_DETACHED);

    fprintf(stderr, "[olta] listening on http://127.0.0.1:%d\n", port);

    for (;;) {
        struct sockaddr_in peer;
        socklen_t plen = sizeof peer;
        int cfd = accept(sfd, (struct sockaddr *)&peer, &plen);
        if (cfd < 0) {
            if (errno == EINTR)
                continue;
            perror("accept");
            continue;
        }
        conn_task *task = malloc(sizeof *task);
        if (!task) {
            close(cfd);
            continue;
        }
        task->fd = cfd;
        task->fn = fn;
        task->ud = ud;
        pthread_t tid;
        if (pthread_create(&tid, &attr, conn_main, task) != 0) {
            close(cfd);
            free(task);
        }
    }
}
