/* ============================================================================
 * SDK 示例驱动
 *
 * 存在的意义只有一个：证明**第三方不需要内核源码**就能写出一个 TNDDOS 驱动。
 * 它只依赖 TNDOS-SDK 的 include/ 和 lib/。
 *
 * 装法：把编出来的 .EFI 放进 \EFI\TNDOS\DRIVERS\DEMO.EFI，
 * 然后在 efidos.sys 或 config.sys 里加一行  DEVICE=DEMO.EFI
 * ==========================================================================*/
#include "drv.h"

EFI_STATUS efi_main(EFI_HANDLE ImageHandle, EFI_SYSTEM_TABLE *st) {
    (void)ImageHandle;

    dputs(st, "[DEMO.EFI] built outside the kernel tree, with TNDOS-SDK\r\n");
    dputs(st, "           this proves the SDK is self-contained\r\n");
    dputs(st, "           firmware revision: ");
    dnum(st, (UINT64)st->FirmwareRevision);
    dputs(st, "\r\n");
    dputs(st, "[DEMO.EFI] init done -> EFI_SUCCESS\r\n");
    return 0;
}
