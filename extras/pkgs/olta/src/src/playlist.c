/* playlist.c - file-backed saved-playlists store (see playlist.h). */
#include "playlist.h"

#include "main.h"
#include "util.h"

#include <pthread.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

/* One entry per URL line in .olta-playlists.txt, in file order. */
typedef struct {
    char *url;               /* trimmed, owned */
    char *title;             /* owned, "" when unknown */
    long added_at;           /* 0 = unknown -> null in JSON */
    long last_downloaded_at; /* 0 = never -> null in JSON */
} pl_entry;

static pthread_mutex_t g_mu = PTHREAD_MUTEX_INITIALIZER;

static int g_loaded;
static char g_loaded_dir[768]; /* dir the in-memory store was loaded from */

static char **g_lines; /* verbatim file lines, without trailing newline */
static size_t g_nlines;
static size_t g_lines_cap;

static pl_entry *g_entries;
static size_t g_nentries;
static size_t g_entries_cap;

/* ---------- internal helpers (all take g_mu) ---------- */

/* Trimmed [a,b) view of s without modifying it (like util str_trim). */
static void trim_view(const char *s, size_t len, size_t *a, size_t *b) {
    size_t i = 0, j = len;
    while (i < j && (s[i] == ' ' || s[i] == '\t' || s[i] == '\r' || s[i] == '\n'))
        i++;
    while (j > i && (s[j - 1] == ' ' || s[j - 1] == '\t' || s[j - 1] == '\r' || s[j - 1] == '\n'))
        j--;
    *a = i;
    *b = j;
}

static void reset_locked(void) {
    for (size_t i = 0; i < g_nlines; i++)
        free(g_lines[i]);
    free(g_lines);
    g_lines = NULL;
    g_nlines = 0;
    g_lines_cap = 0;

    for (size_t i = 0; i < g_nentries; i++) {
        free(g_entries[i].url);
        free(g_entries[i].title);
    }
    free(g_entries);
    g_entries = NULL;
    g_nentries = 0;
    g_entries_cap = 0;
}

static pl_entry *find_entry_locked(const char *url) {
    for (size_t i = 0; i < g_nentries; i++)
        if (strcmp(g_entries[i].url, url) == 0)
            return &g_entries[i];
    return NULL;
}

static void remove_entry_at_locked(size_t idx) {
    free(g_entries[idx].url);
    free(g_entries[idx].title);
    memmove(&g_entries[idx], &g_entries[idx + 1],
            (g_nentries - idx - 1) * sizeof *g_entries);
    g_nentries--;
}

/* Remove the first raw line whose trimmed content equals url. */
static void remove_line_of_locked(const char *url) {
    for (size_t i = 0; i < g_nlines; i++) {
        size_t a, b;
        trim_view(g_lines[i], strlen(g_lines[i]), &a, &b);
        if (strcmp(g_lines[i] + a, url) == 0) {
            free(g_lines[i]);
            memmove(&g_lines[i], &g_lines[i + 1],
                    (g_nlines - i - 1) * sizeof *g_lines);
            g_nlines--;
            return;
        }
    }
}

/* Take ownership of an already-allocated, NUL-terminated line. */
static int line_push_owned_locked(char *owned) {
    if (!owned)
        return -1;
    if (g_nlines == g_lines_cap) {
        size_t ncap = g_lines_cap ? g_lines_cap * 2 : 16;
        char **nl = realloc(g_lines, ncap * sizeof *g_lines);
        if (!nl) {
            free(owned);
            return -1;
        }
        g_lines = nl;
        g_lines_cap = ncap;
    }
    g_lines[g_nlines++] = owned;
    return 0;
}

static int entry_push_locked(const char *url) {
    if (g_nentries == g_entries_cap) {
        size_t ncap = g_entries_cap ? g_entries_cap * 2 : 16;
        pl_entry *ne = realloc(g_entries, ncap * sizeof *g_entries);
        if (!ne)
            return -1;
        g_entries = ne;
        g_entries_cap = ncap;
    }
    pl_entry *e = &g_entries[g_nentries];
    e->url = strdup(url);
    e->title = strdup("");
    if (!e->url || !e->title) {
        free(e->url);
        free(e->title);
        return -1;
    }
    e->added_at = 0;
    e->last_downloaded_at = 0;
    g_nentries++;
    return 0;
}

/* {"url","title","added_at","last_downloaded_at"}; timestamps null when 0.
 * with_url=0 renders the meta sidecar shape (url is the object key there). */
static cJSON *entry_json_locked(const pl_entry *e, int with_url) {
    cJSON *o = cJSON_CreateObject();
    if (!o)
        return NULL;
    if (with_url && !cJSON_AddStringToObject(o, "url", e->url)) {
        cJSON_Delete(o);
        return NULL;
    }
    if (!cJSON_AddStringToObject(o, "title", e->title)) {
        cJSON_Delete(o);
        return NULL;
    }
    if (e->added_at > 0) {
        if (!cJSON_AddNumberToObject(o, "added_at", (double)e->added_at)) {
            cJSON_Delete(o);
            return NULL;
        }
    } else if (!cJSON_AddNullToObject(o, "added_at")) {
        cJSON_Delete(o);
        return NULL;
    }
    if (e->last_downloaded_at > 0) {
        if (!cJSON_AddNumberToObject(o, "last_downloaded_at",
                                     (double)e->last_downloaded_at)) {
            cJSON_Delete(o);
            return NULL;
        }
    } else if (!cJSON_AddNullToObject(o, "last_downloaded_at")) {
        cJSON_Delete(o);
        return NULL;
    }
    return o;
}

/* ---------- persistence ---------- */

static char *read_all(const char *path, size_t max) {
    FILE *fp = fopen(path, "rb");
    if (!fp)
        return NULL;
    fseek(fp, 0, SEEK_END);
    long size = ftell(fp);
    fseek(fp, 0, SEEK_SET);
    if (size < 0 || (unsigned long)size > max) {
        fclose(fp);
        return NULL;
    }
    char *buf = malloc((size_t)size + 1);
    if (!buf) {
        fclose(fp);
        return NULL;
    }
    size_t got = fread(buf, 1, (size_t)size, fp);
    fclose(fp);
    buf[got] = '\0';
    return buf;
}

static long meta_num(const cJSON *o, const char *key) {
    const cJSON *v = cJSON_GetObjectItemCaseSensitive(o, key);
    return (v && cJSON_IsNumber(v) && v->valuedouble > 0)
               ? (long)v->valuedouble
               : 0;
}

static void load_meta_locked(void) {
    char path[1024];
    snprintf(path, sizeof path, "%s/.olta-playlists.meta.json",
             g_download_dir);
    char *text = read_all(path, 4 * 1024 * 1024);
    if (!text)
        return; /* absent or unreadable: entries keep defaults */
    cJSON *root = cJSON_Parse(text);
    free(text);
    if (!root)
        return;
    cJSON *it;
    cJSON_ArrayForEach(it, root) {
        if (!it->string || !cJSON_IsObject(it))
            continue;
        pl_entry *e = find_entry_locked(it->string);
        if (!e)
            continue; /* orphan: dropped on next save */
        const cJSON *t = cJSON_GetObjectItemCaseSensitive(it, "title");
        if (t && cJSON_IsString(t)) {
            char *nt = strdup(t->valuestring);
            if (nt) {
                free(e->title);
                e->title = nt;
            }
        }
        e->added_at = meta_num(it, "added_at");
        e->last_downloaded_at = meta_num(it, "last_downloaded_at");
    }
    cJSON_Delete(root);
}

static void load_locked(void) {
    char path[1024];
    snprintf(path, sizeof path, "%s/.olta-playlists.txt", g_download_dir);

    /* unknown lines/comment lines/blank lines are kept verbatim; URL lines
     * additionally create entries (first occurrence wins, later duplicate
     * lines are dropped so url set and entries always agree). */
    FILE *fp = fopen(path, "rb");
    if (!fp)
        return; /* no file yet: empty store until first persist */
    char *buf = NULL;
    size_t bufcap = 0;
    ssize_t got;
    while ((got = getline(&buf, &bufcap, fp)) != -1) {
        size_t len = (size_t)got;
        while (len > 0 && (buf[len - 1] == '\n' || buf[len - 1] == '\r'))
            len--;
        buf[len] = '\0';

        size_t a, b;
        trim_view(buf, len, &a, &b);
        const char *t = buf + a;
        if (t[0] == '#' || a == b)
            goto keep; /* comment or blank line */
        if (str_starts(t, "http://") || str_starts(t, "https://")) {
            if (find_entry_locked(t))
                continue; /* duplicate URL line: drop from file */
            if (entry_push_locked(t) != 0)
                goto keep; /* OOM: keep as plain line, entry missing */
        }
    keep:
        line_push_owned_locked(strdup(buf));
    }
    free(buf);
    fclose(fp);

    load_meta_locked();
}

static void ensure_loaded_locked(void) {
    if (g_loaded && strcmp(g_loaded_dir, g_download_dir) == 0)
        return;
    reset_locked();
    load_locked();
    g_loaded = 1;
    str_copy(g_loaded_dir, sizeof g_loaded_dir, g_download_dir);
}

/* temp file + rename so a crash cannot truncate the real store. */
static int write_text_locked(void) {
    char path[1024], tmp[1024];
    snprintf(path, sizeof path, "%s/.olta-playlists.txt", g_download_dir);
    snprintf(tmp, sizeof tmp, "%s/.olta-playlists.txt.tmp", g_download_dir);
    FILE *fp = fopen(tmp, "wb");
    if (!fp)
        return -1;
    for (size_t i = 0; i < g_nlines; i++)
        fprintf(fp, "%s\n", g_lines[i]);
    int bad = ferror(fp) != 0;
    if (fflush(fp) != 0)
        bad = 1;
    if (fclose(fp) != 0)
        bad = 1;
    if (bad || rename(tmp, path) != 0) {
        remove(tmp);
        return -1;
    }
    return 0;
}

static int write_meta_locked(void) {
    char path[1024], tmp[1024];
    snprintf(path, sizeof path, "%s/.olta-playlists.meta.json",
             g_download_dir);

    /* rebuilt from the loaded entries: orphan meta entries disappear */
    cJSON *meta = cJSON_CreateObject();
    if (!meta)
        return -1;
    for (size_t i = 0; i < g_nentries; i++) {
        cJSON *o = entry_json_locked(&g_entries[i], 0);
        if (!o || !cJSON_AddItemToObject(meta, g_entries[i].url, o)) {
            cJSON_Delete(o);
            cJSON_Delete(meta);
            return -1;
        }
    }
    char *s = cJSON_Print(meta);
    cJSON_Delete(meta);
    if (!s)
        return -1;

    snprintf(tmp, sizeof tmp, "%s/.olta-playlists.meta.json.tmp",
             g_download_dir);
    FILE *fp = fopen(tmp, "wb");
    if (!fp) {
        free(s);
        return -1;
    }
    int bad = fputs(s, fp) < 0;
    if (fputc('\n', fp) == EOF)
        bad = 1;
    if (fflush(fp) != 0)
        bad = 1;
    if (fclose(fp) != 0)
        bad = 1;
    free(s);
    if (bad || rename(tmp, path) != 0) {
        remove(tmp);
        return -1;
    }
    return 0;
}

static int persist_locked(void) {
    if (write_text_locked() != 0)
        return -1;
    if (write_meta_locked() != 0)
        return -1;
    return 0;
}

/* ---------- public API (all take g_mu) ---------- */

cJSON *playlist_to_json(void) {
    pthread_mutex_lock(&g_mu);
    ensure_loaded_locked();
    cJSON *arr = cJSON_CreateArray();
    if (!arr) {
        pthread_mutex_unlock(&g_mu);
        return NULL;
    }
    for (size_t i = 0; i < g_nentries; i++) {
        cJSON *item = entry_json_locked(&g_entries[i], 1);
        if (!item || !cJSON_AddItemToArray(arr, item)) {
            cJSON_Delete(item);
            cJSON_Delete(arr);
            pthread_mutex_unlock(&g_mu);
            return NULL;
        }
    }
    pthread_mutex_unlock(&g_mu);

    cJSON *root = cJSON_CreateObject();
    if (!root || !cJSON_AddItemToObject(root, "playlists", arr)) {
        cJSON_Delete(arr);
        cJSON_Delete(root);
        return NULL;
    }
    return root;
}

cJSON *playlist_add(const char *url, const char *title, playlist_status_t *st) {
    playlist_status_t dummy;
    if (!st)
        st = &dummy;
    *st = PLAYLIST_ERROR;
    if (!url || !url[0]) {
        *st = PLAYLIST_BAD_URL;
        return NULL;
    }
    char *turl = strdup(url);
    char *ttitle = strdup(title ? title : "");
    if (!turl || !ttitle) {
        free(turl);
        free(ttitle);
        return NULL;
    }
    str_trim(turl);
    if (!str_starts(turl, "http://") && !str_starts(turl, "https://")) {
        free(turl);
        free(ttitle);
        *st = PLAYLIST_BAD_URL;
        return NULL;
    }

    pthread_mutex_lock(&g_mu);
    ensure_loaded_locked();
    pl_entry *e = find_entry_locked(turl);
    if (e) {
        cJSON *out = entry_json_locked(e, 1);
        pthread_mutex_unlock(&g_mu);
        free(turl);
        free(ttitle);
        *st = out ? PLAYLIST_DUPLICATE : PLAYLIST_ERROR;
        return out;
    }
    if (entry_push_locked(turl) != 0) {
        pthread_mutex_unlock(&g_mu);
        free(turl);
        free(ttitle);
        return NULL; /* *st stays PLAYLIST_ERROR */
    }
    pl_entry *ne = &g_entries[g_nentries - 1];
    free(ne->title);
    ne->title = ttitle; /* takes ownership */
    ttitle = NULL;
    ne->added_at = now_sec();

    /* append the URL line after the existing raw content */
    if (line_push_owned_locked(strdup(turl)) != 0 || persist_locked() != 0) {
        /* keep the in-memory append but report the failure; the next
         * mutation re-persists everything. */
        pthread_mutex_unlock(&g_mu);
        free(turl);
        free(ttitle);
        return NULL;
    }

    cJSON *out = entry_json_locked(ne, 1);
    pthread_mutex_unlock(&g_mu);
    free(turl);
    *st = out ? PLAYLIST_OK : PLAYLIST_ERROR;
    return out;
}

int playlist_remove(const char *url) {
    if (!url || !url[0])
        return -1;
    char *turl = strdup(url);
    if (!turl)
        return -1;
    str_trim(turl);

    int rc = -1;
    pthread_mutex_lock(&g_mu);
    ensure_loaded_locked();
    pl_entry *e = find_entry_locked(turl);
    if (e) {
        remove_line_of_locked(e->url);
        remove_entry_at_locked((size_t)(e - g_entries));
        rc = persist_locked() == 0 ? 0 : -1;
    }
    pthread_mutex_unlock(&g_mu);
    free(turl);
    return rc;
}

int playlist_mark_downloaded(const char *url) {
    if (!url || !url[0])
        return -1;
    char *turl = strdup(url);
    if (!turl)
        return -1;
    str_trim(turl);

    int rc = -1;
    pthread_mutex_lock(&g_mu);
    ensure_loaded_locked();
    pl_entry *e = find_entry_locked(turl);
    if (e) {
        e->last_downloaded_at = now_sec();
        rc = persist_locked() == 0 ? 0 : -1;
    }
    pthread_mutex_unlock(&g_mu);
    free(turl);
    return rc;
}
