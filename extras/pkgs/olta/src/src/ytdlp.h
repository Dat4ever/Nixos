/* ytdlp.h - yt-dlp/ffmpeg tool wrappers: detection, /api/info extraction,
 * download argv construction, progress line parsing. */
#ifndef YTGRAB_YTDLP_H
#define YTGRAB_YTDLP_H

#include <stddef.h>

#include <cJSON.h>
#include "jobs.h"

/* Run once at startup; caches tool presence + versions. */
void ytdlp_detect(void);

int         ytdlp_available(void);
const char *ytdlp_version(void);
int         ffmpeg_available(void);

/* POST /api/info implementation. Returns a fresh cJSON tree the caller must
 * print + cJSON_Delete, or NULL and fills err. */
cJSON *ytdlp_info(const char *url, char *err, size_t errcap);

/* NULL-terminated, strdup'd argv per the contract download templates.
 * Caller frees with argv_free(). NULL on OOM. */
char **ytdlp_build_argv(const job_t *j);

/* Fork + execvp with setpgid(0,0); stdout/stderr arrive via pipes.
 * 0 on success. */
int ytdlp_spawn(char *const argv[], pid_t *pid, int *out_fd, int *err_fd);

/* Parse one stdout line like
 * "[download]  42.1% of ~12.34MiB at 2.50MiB/s ETA 00:12" into the job
 * (percent "unknown" -> no update). Locks the jobs mutex internally. */
void ytdlp_parse_progress(const char *line, job_t *j);

/* If the line names a final output file (Destination: / already-downloaded /
 * merger quote), update dest. */
void ytdlp_scan_dest(const char *line, char *dest, size_t cap);

/* Short error message from yt-dlp stderr for the job error field. */
void ytdlp_error_message(const char *stderr_text, int exit_code,
                         char *out, size_t cap);

/* 1 when stderr has at least one "ERROR:" line and every one of them is a
 * per-entry "video not downloadable" class (private, unavailable, ...). */
int ytdlp_errors_all_skippable(const char *err);

#endif
