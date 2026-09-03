#include "modules.h"

long get_packages_total(void) {
    static const struct { const char *name; const char *cmd; } pm[] = {
        { "nix",     "nix-store -qR /run/current-system/sw 2>/dev/null" },
        { "pacman",  "pacman -Q 2>/dev/null" },
        { "yay",     "yay -Qm 2>/dev/null" },
        { "paru",    "paru -Qm 2>/dev/null" },
        { "xbps",    "xbps-query -l 2>/dev/null" },
        { "dpkg",    "dpkg-query -W 2>/dev/null" },
        { "rpm",     "rpm -qa 2>/dev/null" },
        { "apk",     "apk info --installed 2>/dev/null" },
        { "emerge",  "qlist -I 2>/dev/null" },
        { "flatpak", "flatpak list 2>/dev/null" },
        { "snap",    "snap list 2>/dev/null" },
        { "pip",     "pip list --format=freeze 2>/dev/null" },
        { "cargo",   "cargo install --list 2>/dev/null" },
        { "npm",     "npm ls -g --depth=0 --parseable 2>/dev/null | tail -n +2" },
        { "gem",     "gem list --local 2>/dev/null" },
        { "brew",    "brew list -1 2>/dev/null" },
        { "guix",    "guix package -I 2>/dev/null" },
        { NULL, NULL }
    };

    long total = 0;
    for (int i = 0; pm[i].name; i++) {
        FILE *f = popen(pm[i].cmd, "r");
        if (!f) continue;
        char line[256];
        long n = 0;
        while (fgets(line, sizeof line, f)) n++;
        pclose(f);
        if (n > 0) total += n;
    }
    return total;
}
