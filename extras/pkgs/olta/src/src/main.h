/* main.h - process-wide configuration globals (defined in main.c). */
#ifndef YTGRAB_MAIN_H
#define YTGRAB_MAIN_H

/* Current download directory (config.download_dir). */
extern char g_download_dir[768];

/* Load ~/.config/olta/config.json into globals, applying defaults
 * (~/Downloads/olta, max_concurrent 2) and creating missing dirs. */
void config_load(void);

/* Persist the current config to disk. */
void config_save(void);

#endif
