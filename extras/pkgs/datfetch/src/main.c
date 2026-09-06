#include "datfetch.h"

static void gen_config(void) {
    Config c;
    config_defaults(&c);
    char *dir = config_dir();
    char *path = config_path();
    if (!dir || !path) { fprintf(stderr, "datfetch: cannot determine config dir\n"); return; }
    config_write(&c, path);

    char *bd = builtin_dir();
    if (bd) {
        char *sl = strf("%s/logo", bd);
        char *dl = strf("%s/logo", dir);
        copy_dir(sl, dl, ".txt");
        char *de = strf("%s/examples", dir);
        copy_dir(bd, de, ".toml");
        free(sl); free(dl); free(de);
        free(bd);
    }

    printf("Wrote config to %s\n", path);
    free(path); free(dir);
    config_free(&c);
}

int main(int argc, char **argv) {
    const char *logo_arg = NULL;
    for (int i = 1; i < argc; i++) {
        if (strcmp(argv[i], "--help") == 0 || strcmp(argv[i], "-h") == 0) {
            printf(
                "Usage: datfetch [options]\n"
                "\n"
                "Options:\n"
                "  --logo <name>   Force a logo: auto, mini, none, braille-<d> or\n"
                "                  mini-<d> (d: nixos, arch, debian, fedora, guix, tux),\n"
                "                  or a path to a logo file\n"
                "  --generate-config  Write a default config file\n"
                "  -h, --help      Show this help\n"
            );
            return 0;
        } else if (strcmp(argv[i], "--generate-config") == 0) {
            gen_config();
            return 0;
        } else if (strcmp(argv[i], "--logo") == 0 && i + 1 < argc) {
            logo_arg = argv[++i];
        }
    }

    Config cfg;
    config_defaults(&cfg);
    char *path = config_path();
    if (path) { config_load(&cfg, path); free(path); }

    if (logo_arg) { free(cfg.logo); cfg.logo = xstrdup(logo_arg); }

    int rc = df_run(&cfg);
    config_free(&cfg);
    return rc;
}
