/* ============================================================================
 * ls -- 列目录
 *
 * 它存在的意义是当 SDK 的活体测试：argc/argv、findfirst/findnext/findclose、
 * printf、TND_FIND 全都过一遍。能跑通，说明 SDK 的基础面是通的。
 * ==========================================================================*/
#include "tndrt.h"

int tnx_main(void) {
    TND_FIND f;
    const char *pat = "*";
    int fh, dirs = 0, files = 0;
    tnd_u64 total = 0;

    if (tnd_argc() > 1) pat = tnd_argv(1);

    tnd_printf("\n Listing: %s\n\n", pat);

    fh = tnd_findfirst(pat, &f);
    if (fh < 0) {
        tnd_printf("  nothing matches\n");
        return 1;
    }

    do {
        if (f.Attr & TND_ATTR_DIR) {
            tnd_printf("  <DIR>          %s\n", f.Name);
            dirs++;
        } else {
            tnd_printf("  %u            %s\n", f.Size, f.Name);
            files++;
            total += f.Size;
        }
    } while (tnd_findnext(fh, &f) == 0);

    tnd_findclose(fh);

    tnd_printf("\n  %d file(s), %u bytes", files, total);
    if (dirs) tnd_printf(", %d dir(s)", dirs);
    tnd_printf("\n");
    return 0;
}
