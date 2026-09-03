#ifndef DATFETCH_H
#define DATFETCH_H

#define _GNU_SOURCE
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <strings.h>
#include <unistd.h>
#include <pwd.h>
#include <ctype.h>
#include <sys/utsname.h>
#include <sys/ioctl.h>
#include <sys/stat.h>
#include <sys/statvfs.h>
#include <sys/types.h>

#define RGB(r,g,b) "\x1b[38;2;" #r ";" #g ";" #b "m"
#define RESET "\x1b[0m"

typedef struct {
    const char *id;
    const char *name;
    const char *const *colors;
} Distro;

extern const Distro distros[];
extern char *os_id, *os_pretty;

const Distro *detect_distro(void);
const Distro *distro_by_id(const char *id);
char *logo_line_ansi(const char *line, const char *const *colors);

typedef struct {
    char *user;
    char *hostname;
    char *model;
    char *os_pretty;
    char *kernel_release;
    char *shell;
    char *desktop;
    char *terminal;
    char **cpus;
    int cpu_count;
    int cpu_cores;
    char **gpus;
    int gpu_count;
    long long mem_used_kib;
    long long mem_total_kib;
    long long disk_used_bytes;
    long long disk_total_bytes;
    char *font_mono;
    char *font_sans;
    char *font_serif;
    char *resolution;
    char *uptime;
    char *local_ip;
    char *installed;
    long packages_total;
} SysInfo;

void sysinfo_gather(SysInfo *si, const Distro *distro);
void sysinfo_free(SysInfo *si);

enum {
    M_USER, M_HOST, M_USERHOST, M_MODEL, M_OS, M_KERNEL, M_SHELL, M_DESKTOP, M_TERMINAL,
    M_CPU, M_GPU, M_MEMORY, M_DISK, M_FONT, M_RESOLUTION, M_UPTIME, M_IP,
    M_INSTALLED, M_PACKAGES, N_MODULES
};

enum {
    POS_LEFT = 0, POS_RIGHT = 1, POS_TOP = 2
};

typedef struct {
    int enabled;
    char *color;
} Module;

typedef struct {
    int logo_position;
    int modules_position;
    int icons;
    int padding;
    char *logo;
    char *logo_color;
    char *label_color;
    char *value_color;
    char *separator;
    char **palette;
    int palette_n;
    char **section_breaks;
    int n_section_breaks;
    int order[N_MODULES];
    int n_order;
    Module mod[N_MODULES];
} Config;

char *config_dir(void);
char *config_path(void);
char *builtin_dir(void);
void copy_dir(const char *src, const char *dst, const char *suffix);
void config_defaults(Config *c);
void config_free(Config *c);
int config_load(Config *c, const char *path);
void config_write(const Config *c, const char *path);

char *xstrdup(const char *s);
char *strf(const char *fmt, ...);
char *read_file_line(const char *path);
char *read_file_stripped(const char *path);
const char *get_user(void);
char *get_host(void);
int vis_width(const char *s);
int term_width(void);
void truncate_ellipsis(char *dst, size_t cap, const char *src, int max_cols);

int df_run(const Config *cfg);

#endif
