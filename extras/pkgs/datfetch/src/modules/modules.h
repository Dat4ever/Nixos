#ifndef DATFETCH_MODULES_H
#define DATFETCH_MODULES_H

#include "../datfetch.h"

char *get_model(void);
char *get_kernel_release(void);
char *get_uptime(void);
char *get_install_date(void);
char *get_shell(void);
char *get_desktop(void);
char *get_terminal(void);
char *get_font_mono(void);
char *get_font_sans(void);
char *get_font_serif(void);
char *get_resolution(void);
char **get_cpus(void);
int get_cpu_count(void);
char **get_gpus(void);
void memory_info(long long *used_kib, long long *total_kib);
void disk_info(long long *used_bytes, long long *total_bytes);
char *get_local_ip(void);
long get_packages_total(void);

#endif
