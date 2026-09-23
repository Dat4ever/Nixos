/* api.h - /api/ endpoints + static frontend serving. */
#ifndef YTGRAB_API_H
#define YTGRAB_API_H

#include "http.h"

/* Entry point passed to http_serve(); dispatches every request. */
void api_route(const http_request *req, int fd, void *ud);

#endif
