# TNDOS-SDK

**写 TNDDOS 程序不需要内核源码。** 这个仓库就是为此存在的。

它提供头文件、运行时、链接脚本和样例 —— 第三方（或者半年后的你自己）
clone 这个仓库就能产出能在 TNDDOS 上跑的东西，不用碰 TNDOS-SysCore 一行代码。

---

## 目录

| 目录 | 内容 |
|---|---|
| `include/` | `tnx.h`（格式）、`tnd_api.h`（内核 API 契约）、`drv.h`（驱动 SDK）、`efi.h`、`tnd_utf8.h` |
| `lib/` | `tndrt.c`（TNX 程序运行时）、`drvlib.c`（驱动运行时） |
| `linker/` | `tnx.ld` —— 把程序链接到固定基址，这样加载器不需要重定位 |
| `examples/` | `hello/`（一个 TNX 程序）、`driver/`（一个驱动） |
| `tools/` | `env.ps1`（工具链定位）、`build-tnx.ps1`、`build-drv.ps1` |

---

## 环境变量

和其他 TNDDOS 仓库一个规矩：**脚本里不写死任何机器相关的路径**。

| 变量 | 指向 | 必填 |
|---|---|---|
| `TNDDOS_LLVM_BIN` | 含 `clang.exe` **和** `ld.lld.exe` 的目录 | 是（clang 在 PATH 上时可省） |
| `TNDDOS_TOOLKIT` | `TNDOS-ToolsKit` 仓库根目录（里面有 `tnxpack.ps1`） | 是（`tnxpack.ps1` 在 PATH 上时可省） |

`​`​`powershell
setx TNDDOS_LLVM_BIN "D:\LLVM\bin"
setx TNDDOS_TOOLKIT  "D:\TNDOS-ToolsKit"
# 设完重开终端
`​`​`

---

## 写一个 TNX 程序

`​`​`
/* myapp.c */
#include "tndrt.h"

int tnx_main(void) {
    tnd_puts("hello from myapp\r\n");
    void *p = tnd_alloc(64);
    if (p) { tnd_puts("kernel heap works\r\n"); tnd_free(p); }
    return 0;
}
`​`​`

`​`​`powershell
.\tools\build-tnx.ps1 -Source myapp.c -Out build\MYAPP.TNX
`​`​`

产出的 MYAPP.TNX 丢进 EFI System Partition，在 TNDDOS 里**直接敲名字就行**（DOS 的规矩）：

`​`​`
C:\>MYAPP.TNX
C:\>MYAPP            扩展名可选
C:\>tnx MYAPP.TNX    只看信息，不执行

查找顺序：当前目录优先，然后依次查 PATH 的每一项。
找不到就是 Bad command or file name。
`​`​`

### 你只需要写 tnx_main

`lib/tndrt.c` 里已经有入口桩 `tnx_entry`：它把加载器传进来的 API 表存好，
再调你的 `tnx_main`。所以用户代码永远只写 `tnd_puts(...)`，
**不需要知道 API 表从哪来**。

将来 API 从「函数表」换成真正的 SYSCALL，这一层不用改，你的代码更不用改。

---

## 写一个驱动

`​`​`
/* mydrv.c */
#include "drv.h"

EFI_STATUS efi_main(EFI_HANDLE ImageHandle, EFI_SYSTEM_TABLE *st) {
    dputs(st, "[MYDRV] hello\r\n");
    return 0;
}
`​`​`

`​`​`powershell
.\tools\build-drv.ps1 -Source mydrv.c -Out build\MYDRV.EFI
`​`​`

把 MYDRV.EFI 放进 `\EFI\TNDOS\DRIVERS\`，然后在 `efidos.sys` 或 `config.sys` 里：

`​`​`
DEVICE=MYDRV.EFI
`​`​`

`DEVICE=` 的语义等价于 UEFI Shell 的 `load fs0:\<文件>`。

---

## 两条硬规矩

**1. 调用约定是 System V，不是 MS ABI。**

TNX 程序编译目标 `x86_64-unknown-none` 用 System V ABI（第一个参数在 RDI），
而 TNDDOS 内核编译目标 `x86_64-pc-windows-msvc` 用 MS ABI（第一个参数在 RCX）。

`tnd_api.h` 里的 `TND_ABI` 宏负责把内核那侧适配过去。**别删它。**
删了的症状是 #UD 无效指令，而且崩溃地址落在内核里，
看起来跟参数传递毫无关系 —— 这个坑已经踩过一次了。

**2. TNX 的加载地址是固定的。**

`linker/tnx.ld` 里的 `0x1000000` 必须和内核的 `TNX_IMAGE_BASE` 一致。
所以链接脚本不要改成 PIE，也不要改基址。

---

## 关于头文件副本

`include/` 里的 `tnx.h` / `tnd_api.h` / `efi.h` / `tnd_utf8.h` 在
TNDOS-SysCore 里也有一份。**这是有意的**：SDK 必须自包含，
否则「不需要内核源码」这句话就是假的。

代价是格式改动要同步两处。缓解办法是 **TNX 格式已冻结在 v1**，
任何改动都必须先升 `TNX_VERSION` —— 那时同步是必然动作，不会漏。
