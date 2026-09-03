#include "datfetch.h"
#include "modules/modules.h"

void sysinfo_gather(SysInfo *si, const Distro *distro) {
    memset(si, 0, sizeof *si);

    si->user = xstrdup(get_user());
    si->hostname = get_host();
    si->model = get_model();

    si->os_pretty = xstrdup(os_pretty ? os_pretty : (distro ? distro->name : "Linux"));
    si->kernel_release = get_kernel_release();

    si->shell = get_shell();
    si->desktop = get_desktop();
    si->terminal = get_terminal();

    si->cpus = get_cpus();
    if (si->cpus)
        for (char **c = si->cpus; *c; c++) si->cpu_count++;
    si->cpu_cores = get_cpu_count();

    si->gpus = get_gpus();
    if (si->gpus)
        for (char **g = si->gpus; *g; g++) si->gpu_count++;

    memory_info(&si->mem_used_kib, &si->mem_total_kib);
    disk_info(&si->disk_used_bytes, &si->disk_total_bytes);

    si->font_mono = get_font_mono();
    si->font_sans = get_font_sans();
    si->font_serif = get_font_serif();
    si->resolution = get_resolution();
    si->uptime = get_uptime();
    si->local_ip = get_local_ip();
    si->installed = get_install_date();
    si->packages_total = get_packages_total();
}

void sysinfo_free(SysInfo *si) {
    free(si->user);
    free(si->hostname);
    free(si->model);
    free(si->os_pretty);
    free(si->kernel_release);
    free(si->shell);
    free(si->desktop);
    free(si->terminal);
    for (char **c = si->cpus; c && *c; c++) free(*c);
    free(si->cpus);
    for (char **g = si->gpus; g && *g; g++) free(*g);
    free(si->gpus);
    free(si->font_mono);
    free(si->font_sans);
    free(si->font_serif);
    free(si->resolution);
    free(si->uptime);
    free(si->local_ip);
    free(si->installed);
}
