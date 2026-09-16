#include "modules.h"

char *get_model(void) {
    char *vendor = read_file_stripped("/sys/devices/virtual/dmi/id/sys_vendor");
    char *product = read_file_stripped("/sys/devices/virtual/dmi/id/product_name");
    char *res;
    if (vendor && product && *product) {
        size_t len = strlen(vendor) + strlen(product) + 4;
        res = malloc(len);
        snprintf(res, len, "%s %s", vendor, product);
    } else if (product && *product) {
        res = xstrdup(product);
    } else {
        res = xstrdup("unknown");
    }
    free(vendor);
    free(product);
    return res;
}
