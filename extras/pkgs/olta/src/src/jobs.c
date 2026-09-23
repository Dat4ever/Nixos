/* jobs.c - job list + workers. One detached worker thread per job; workers
 * wait on a condvar while all max_concurrent slots are busy. The yt-dlp
 * child runs in its own process group; cancel sends SIGTERM to -pid and
 * escalates to SIGKILL after 3 s. */
#include "jobs.h"

#include "util.h"
#include "ytdlp.h"

#include <errno.h>
#include <poll.h>
#include <pthread.h>
#include <signal.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/wait.h>
#include <unistd.h>

#define CANCEL_ESCALATION_MS 3000

static pthread_mutex_t g_mtx = PTHREAD_MUTEX_INITIALIZER;
static pthread_cond_t  g_cv  = PTHREAD_COND_INITIALIZER;
static job_t **g_jobs;
static size_t g_count, g_cap;
static int g_running = 0;
static int g_max_concurrent = 2;
static unsigned g_counter = 0;
static pthread_attr_t g_detached;
static int g_attr_ready = 0;

const char *job_state_name(job_state_t s) {
    switch (s) {
    case JOB_QUEUED:   return "queued";
    case JOB_RUNNING:  return "running";
    case JOB_DONE:     return "done";
    case JOB_ERROR:    return "error";
    case JOB_CANCELED: return "canceled";
    }
    return "queued";
}

void jobs_init(void) {
    pthread_attr_init(&g_detached);
    pthread_attr_setdetachstate(&g_detached, PTHREAD_CREATE_DETACHED);
    g_attr_ready = 1;
}

void jobs_set_max_concurrent(int n) {
    pthread_mutex_lock(&g_mtx);
    if (n >= 1 && n <= 8)
        g_max_concurrent = n;
    pthread_cond_broadcast(&g_cv);
    pthread_mutex_unlock(&g_mtx);
}

int jobs_get_max_concurrent(void) {
    pthread_mutex_lock(&g_mtx);
    int n = g_max_concurrent;
    pthread_mutex_unlock(&g_mtx);
    return n;
}

void jobs_lock(void) {
    pthread_mutex_lock(&g_mtx);
}

void jobs_unlock(void) {
    pthread_mutex_unlock(&g_mtx);
}

/* ---------- id + list helpers (callers hold g_mtx) ---------- */

static void make_job_id(char *out, size_t cap) {
    /* short hex from time + counter */
    snprintf(out, cap, "%08lx%04x", (unsigned long)(now_sec() & 0xffffffff),
             (unsigned)(++g_counter & 0xffff));
}

static void list_remove_locked(size_t idx) {
    free(g_jobs[idx]);
    memmove(&g_jobs[idx], &g_jobs[idx + 1], (g_count - idx - 1) * sizeof *g_jobs);
    g_count--;
}

static size_t find_locked(const char *id) {
    for (size_t i = 0; i < g_count; i++)
        if (strcmp(g_jobs[i]->id, id) == 0)
            return i;
    return (size_t)-1;
}

/* ---------- worker ---------- */

/* finalize under mutex: set terminal state, free the slot, apply pending remove */
static void finalize_locked(job_t *j, int exit_code, const char *dest,
                            const char *errmsg) {
    g_running--;
    if (j->cancel_flag) {
        j->state = JOB_CANCELED;
    } else if (exit_code == 0) {
        j->state = JOB_DONE;
        j->progress = 100.0;
        if (dest && dest[0])
            str_copy(j->filepath, sizeof j->filepath, dest);
    } else {
        j->state = JOB_ERROR;
        str_copy(j->error, sizeof j->error, errmsg ? errmsg : "");
        if (j->error[0] == '\0')
            snprintf(j->error, sizeof j->error, "yt-dlp exited with code %d", exit_code);
    }
    j->pid = 0;
    size_t idx = find_locked(j->id);
    if (j->remove_pending && idx != (size_t)-1)
        list_remove_locked(idx);
    pthread_cond_broadcast(&g_cv);
}

static void run_job(job_t *j) {
    char **argv = ytdlp_build_argv(j);
    if (!argv) {
        pthread_mutex_lock(&g_mtx);
        finalize_locked(j, 1, "", "failed to build yt-dlp command");
        pthread_mutex_unlock(&g_mtx);
        return;
    }

    pid_t pid;
    int out_fd, err_fd;
    int rc = ytdlp_spawn((char *const *)argv, &pid, &out_fd, &err_fd);
    argv_free(argv);
    if (rc != 0) {
        pthread_mutex_lock(&g_mtx);
        finalize_locked(j, 1, "", "failed to start yt-dlp (not installed?)");
        pthread_mutex_unlock(&g_mtx);
        return;
    }

    pthread_mutex_lock(&g_mtx);
    j->pid = pid;
    pthread_mutex_unlock(&g_mtx);

    strbuf err;
    sb_init(&err);
    char line[8192];
    size_t llen = 0;
    char dest[1024] = "";
    int sigterm_sent = 0, escalated = 0, out_done = 0, err_done = 0;

    while (!out_done || !err_done) {
        struct pollfd pf[2] = {
            { .fd = out_fd, .events = POLLIN, .revents = 0 },
            { .fd = err_fd, .events = POLLIN, .revents = 0 },
        };
        int nfd = out_done ? 1 : 2;
        int pr = poll(pf, (nfds_t)nfd, 200);
        if (pr < 0 && errno != EINTR)
            break;

        if (!out_done && (pf[0].revents & (POLLIN | POLLHUP | POLLERR))) {
            char chunk[4096];
            ssize_t r = read(out_fd, chunk, sizeof chunk);
            if (r > 0) {
                for (ssize_t k = 0; k < r; k++) {
                    if (chunk[k] == '\n' || llen >= sizeof line - 1) {
                        line[llen] = '\0';
                        ytdlp_parse_progress(line, j);
                        ytdlp_scan_dest(line, dest, sizeof dest);
                        llen = 0;
                    } else {
                        line[llen++] = chunk[k];
                    }
                }
            } else if (r == 0 || (r < 0 && errno != EINTR && errno != EAGAIN)) {
                out_done = 1;
            }
        }
        if (!err_done && nfd == 2 && (pf[1].revents & (POLLIN | POLLHUP | POLLERR))) {
            char chunk[4096];
            ssize_t r = read(err_fd, chunk, sizeof chunk);
            if (r > 0) {
                sb_addn(&err, chunk, (size_t)r);
                /* bound stderr buffer; keep the tail (error messages live there) */
                if (err.len > 131072) {
                    size_t keep = 65536;
                    memmove(err.data, err.data + err.len - keep, keep);
                    err.len = keep;
                    err.data[err.len] = '\0';
                }
            } else if (r == 0 || (r < 0 && errno != EINTR && errno != EAGAIN)) {
                err_done = 1;
            }
        }

        /* cancel handling: SIGTERM once, SIGKILL 3 s after the request */
        pthread_mutex_lock(&g_mtx);
        int cf = j->cancel_flag;
        long t0 = j->cancel_at_ms;
        pthread_mutex_unlock(&g_mtx);
        if (cf && !sigterm_sent) {
            kill(-pid, SIGTERM);
            sigterm_sent = 1;
        }
        if (cf && !escalated && t0 > 0 && now_ms() - t0 >= CANCEL_ESCALATION_MS) {
            kill(-pid, SIGKILL);
            escalated = 1;
        }
    }

    /* flush trailing partial line */
    if (llen > 0) {
        line[llen] = '\0';
        ytdlp_parse_progress(line, j);
        ytdlp_scan_dest(line, dest, sizeof dest);
    }

    close(out_fd);
    close(err_fd);

    int st, exit_code = -1;
    while (waitpid(pid, &st, 0) < 0 && errno == EINTR)
        ;
    if (WIFEXITED(st))
        exit_code = WEXITSTATUS(st);

    /* Playlist runs: if every yt-dlp error is a per-entry "video not
     * downloadable" class (private, unavailable, members-only...), the
     * successful items still count — treat the job as done. */
    if (j->playlist && exit_code > 0 &&
        ytdlp_errors_all_skippable(err.data ? err.data : ""))
        exit_code = 0;

    char msg[192];
    ytdlp_error_message(err.data ? err.data : "", exit_code, msg, sizeof msg);
    pthread_mutex_lock(&g_mtx);
    finalize_locked(j, exit_code, dest, msg);
    pthread_mutex_unlock(&g_mtx);

    sb_free(&err);
}

static void *worker_main(void *arg) {
    job_t *j = arg;
    pthread_mutex_lock(&g_mtx);
    while (!j->cancel_flag && g_running >= g_max_concurrent)
        pthread_cond_wait(&g_cv, &g_mtx);
    if (j->cancel_flag) {
        j->state = JOB_CANCELED;
        size_t idx = find_locked(j->id);
        if (j->remove_pending && idx != (size_t)-1)
            list_remove_locked(idx);
        pthread_cond_broadcast(&g_cv);
        pthread_mutex_unlock(&g_mtx);
        return NULL;
    }
    j->state = JOB_RUNNING;
    g_running++;
    pthread_mutex_unlock(&g_mtx);

    run_job(j);
    return NULL;
}

/* ---------- public API ---------- */

const char *jobs_enqueue(const char *url, const char *title, const char *kind,
                         const char *quality, const char *audio_format,
                         const char *subtitles, const char *folder,
                         int playlist, int archive) {
    job_t *j = calloc(1, sizeof *j);
    if (!j)
        return NULL;
    make_job_id(j->id, sizeof j->id);
    str_copy(j->url, sizeof j->url, url);
    str_copy(j->title, sizeof j->title, title ? title : "");
    str_copy(j->kind, sizeof j->kind, kind);
    str_copy(j->quality, sizeof j->quality, quality);
    str_copy(j->audio_format, sizeof j->audio_format, audio_format);
    str_copy(j->subtitles, sizeof j->subtitles, subtitles);
    str_copy(j->folder, sizeof j->folder, folder);
    j->playlist = playlist ? 1 : 0;
    j->archive = archive ? 1 : 0;
    j->state = JOB_QUEUED;
    j->eta = -1;
    j->created_at = now_sec();

    pthread_mutex_lock(&g_mtx);
    if (g_count == g_cap) {
        size_t ncap = g_cap ? g_cap * 2 : 16;
        job_t **nj = realloc(g_jobs, ncap * sizeof *g_jobs);
        if (!nj) {
            pthread_mutex_unlock(&g_mtx);
            free(j);
            return NULL;
        }
        g_jobs = nj;
        g_cap = ncap;
    }
    g_jobs[g_count++] = j;
    pthread_mutex_unlock(&g_mtx);

    if (!g_attr_ready)
        jobs_init();
    pthread_t tid;
    if (pthread_create(&tid, &g_detached, worker_main, j) != 0) {
        /* no worker possible: drop the job entirely */
        pthread_mutex_lock(&g_mtx);
        size_t idx = find_locked(j->id);
        if (idx != (size_t)-1)
            list_remove_locked(idx); /* frees j */
        pthread_mutex_unlock(&g_mtx);
        return NULL;
    }
    /* copy the id out under the lock: another request could remove the job
     * before the caller finishes reading the response */
    static char idbuf[24];
    pthread_mutex_lock(&g_mtx);
    str_copy(idbuf, sizeof idbuf, j->id);
    pthread_mutex_unlock(&g_mtx);
    return idbuf;
}

int jobs_cancel(const char *id) {
    pthread_mutex_lock(&g_mtx);
    size_t idx = find_locked(id);
    if (idx == (size_t)-1) {
        pthread_mutex_unlock(&g_mtx);
        return -1;
    }
    job_t *j = g_jobs[idx];
    if (j->state == JOB_QUEUED || j->state == JOB_RUNNING) {
        j->cancel_flag = 1;
        if (j->cancel_at_ms == 0)
            j->cancel_at_ms = now_ms();
        if (j->state == JOB_QUEUED)
            j->state = JOB_CANCELED; /* worker will skip execution */
        pthread_cond_broadcast(&g_cv);
    }
    pthread_mutex_unlock(&g_mtx);
    return 0;
}

int jobs_remove(const char *id) {
    pthread_mutex_lock(&g_mtx);
    size_t idx = find_locked(id);
    if (idx == (size_t)-1) {
        pthread_mutex_unlock(&g_mtx);
        return -1;
    }
    job_t *j = g_jobs[idx];
    if (j->state == JOB_QUEUED || j->state == JOB_RUNNING) {
        /* can't free while a worker references it: cancel now, drop at exit */
        j->cancel_flag = 1;
        if (j->cancel_at_ms == 0)
            j->cancel_at_ms = now_ms();
        j->remove_pending = 1;
        pthread_cond_broadcast(&g_cv);
    } else {
        list_remove_locked(idx);
    }
    pthread_mutex_unlock(&g_mtx);
    return 0;
}

/* Newest-first JSON snapshot; caller prints + cJSON_Delete. */
cJSON *jobs_to_json(void) {
    cJSON *root = cJSON_CreateObject();
    cJSON *arr = root ? cJSON_AddArrayToObject(root, "jobs") : NULL;
    if (!root || !arr) {
        cJSON_Delete(root);
        return NULL;
    }
    jobs_lock();
    for (size_t i = g_count; i-- > 0; ) {
        job_t *j = g_jobs[i];
        cJSON *o = cJSON_CreateObject();
        if (!o)
            break;
        cJSON_AddStringToObject(o, "id", j->id);
        cJSON_AddStringToObject(o, "url", j->url);
        cJSON_AddStringToObject(o, "title", j->title);
        cJSON_AddStringToObject(o, "kind", j->kind);
        cJSON_AddBoolToObject(o, "playlist", j->playlist);
        cJSON_AddBoolToObject(o, "archive", j->archive);
        cJSON_AddStringToObject(o, "state", job_state_name(j->state));
        cJSON_AddNumberToObject(o, "progress", j->progress);
        cJSON_AddNumberToObject(o, "pl_index", j->pl_index);
        cJSON_AddNumberToObject(o, "pl_total", j->pl_total);
        if (j->speed[0])
            cJSON_AddStringToObject(o, "speed", j->speed);
        else
            cJSON_AddNullToObject(o, "speed");
        if (j->eta >= 0)
            cJSON_AddNumberToObject(o, "eta", j->eta);
        else
            cJSON_AddNullToObject(o, "eta");
        if (j->filepath[0])
            cJSON_AddStringToObject(o, "filepath", j->filepath);
        else
            cJSON_AddNullToObject(o, "filepath");
        if (j->error[0])
            cJSON_AddStringToObject(o, "error", j->error);
        else
            cJSON_AddNullToObject(o, "error");
        cJSON_AddNumberToObject(o, "created_at", (double)j->created_at);
        cJSON_AddItemToArray(arr, o);
    }
    jobs_unlock();
    return root;
}
