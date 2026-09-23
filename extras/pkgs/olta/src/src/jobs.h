/* jobs.h - download job manager: mutex+condvar guarded list, worker threads. */
#ifndef YTGRAB_JOBS_H
#define YTGRAB_JOBS_H

#include <sys/types.h>

#include <cJSON.h>

typedef enum {
    JOB_QUEUED = 0,
    JOB_RUNNING,
    JOB_DONE,
    JOB_ERROR,
    JOB_CANCELED
} job_state_t;

typedef struct job job_t;

struct job {
    char id[24];
    char url[2048];
    char title[256];
    char kind[8];           /* "video" | "audio" */
    char quality[16];       /* video: best|2160|...|360 */
    char audio_format[16];  /* audio: mp3|m4a|flac|opus */
    char subtitles[16];     /* video: none|embed|file */
    char folder[768];
    int playlist;           /* true: omit --no-playlist, per-playlist output */
    int archive;            /* playlist only: pass --download-archive */
    int pl_index;           /* 1-based current playlist item */
    int pl_total;           /* total playlist items, 0 = unknown */
    job_state_t state;
    double progress;        /* 0..100 */
    char speed[32];         /* "" -> null */
    int eta;                /* seconds, -1 -> null */
    char filepath[1024];    /* filled when done */
    char error[256];        /* filled when error */
    long created_at;
    pid_t pid;              /* yt-dlp pid while running */
    volatile int cancel_flag;
    volatile int remove_pending;
    long cancel_at_ms;      /* wall ms when cancel was requested (3 s escalation) */
};

void jobs_init(void);

/* Enqueue a job and start its worker thread; returns the new job id (static
 * storage, valid until the next call) or NULL on OOM. */
const char *jobs_enqueue(const char *url, const char *title, const char *kind,
                         const char *quality, const char *audio_format,
                         const char *subtitles, const char *folder,
                         int playlist, int archive);

/* 0 ok, -1 unknown id. */
int jobs_cancel(const char *id);
/* 0 ok, -1 unknown id. Running jobs are canceled and dropped when the
 * process exits; terminal jobs are removed immediately. */
int jobs_remove(const char *id);

/* Worker-slot budget (config.max_concurrent). */
void jobs_set_max_concurrent(int n);
int  jobs_get_max_concurrent(void);

/* Raw lock/unlock; used by the yt-dlp progress parser to update one job. */
void jobs_lock(void);
void jobs_unlock(void);

/* Newest-first {"jobs":[...]} snapshot; caller prints + cJSON_Delete. */
cJSON *jobs_to_json(void);

const char *job_state_name(job_state_t s);

#endif
