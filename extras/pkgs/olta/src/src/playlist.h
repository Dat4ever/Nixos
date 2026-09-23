/* playlist.h - file-backed saved-playlists store. */
#ifndef YTGRAB_PLAYLIST_H
#define YTGRAB_PLAYLIST_H

#include <cJSON.h>

typedef enum {
    PLAYLIST_OK = 0,     /* entry appended */
    PLAYLIST_DUPLICATE,  /* url already present, store unchanged */
    PLAYLIST_BAD_URL,    /* url missing or not http(s):// */
    PLAYLIST_ERROR       /* out of memory or persistence failure */
} playlist_status_t;

/* Store files live under g_download_dir (main.h), which config_load() fills
 * before the server starts:
 *   .olta-playlists.txt        one URL per line; '#' comments and blank
 *                              lines allowed; unknown lines preserved in
 *                              place; new entries appended at the end.
 *   .olta-playlists.meta.json  {"<url>":{"title":..,"added_at":N,
 *                                       "last_downloaded_at":N}}
 * The .txt file is the source of truth for the URL set; the sidecar is
 * rebuilt from the loaded entries on every save (orphan meta entries are
 * dropped). Everything is lazy-loaded on first use and thread-safe (one
 * static mutex); every mutation is persisted before returning. */

/* {"playlists":[{"url","title","added_at","last_downloaded_at"}, ...]} in
 * file order. Timestamps are epoch seconds, null when unknown/never.
 * Fresh cJSON tree, caller cJSON_Delete; NULL on OOM. */
cJSON *playlist_to_json(void);

/* Append url (trimmed) at the end and persist both files. Returns a fresh
 * cJSON {"url","title","added_at","last_downloaded_at"} for the entry (the
 * existing one when *st is PLAYLIST_DUPLICATE), caller deletes; NULL on bad
 * url, OOM or persist failure (*st says which). Title may be NULL -> "". */
cJSON *playlist_add(const char *url, const char *title, playlist_status_t *st);

/* Drop url (trimmed) from the store and persist. 0 ok, -1 unknown url. */
int playlist_remove(const char *url);

/* Set last_downloaded_at = now_sec() for url and persist. 0 ok, -1 unknown. */
int playlist_mark_downloaded(const char *url);

#endif
