/* http.h - minimal HTTP/1.1 server for local use. */
#ifndef YTGRAB_HTTP_H
#define YTGRAB_HTTP_H

#include <stddef.h>

typedef struct {
    char   method[16];
    char  *path;      /* malloc'd, query string removed */
    char  *query;     /* malloc'd, "" when absent */
    char  *body;      /* malloc'd, NUL-terminated; NULL when no body */
    size_t body_len;
} http_request;

/* Handle one parsed request; must send exactly one response via the helpers
 * below. The connection is closed afterwards (Connection: close). */
typedef void (*http_handler_fn)(const http_request *req, int fd, void *ud);

/* Blocks forever accepting connections (thread per connection). */
int http_serve(int port, http_handler_fn fn, void *ud);

/* Response helpers. */
void http_respond_json(int fd, int status, const char *json_body);
/* Serves a whole file; MIME type is derived from the extension. 0 on success. */
int  http_send_file(int fd, const char *path);

#endif
