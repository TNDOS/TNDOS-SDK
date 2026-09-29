# ============================================================================
# TNDOS-SDK 工具链定位（用 . (dot-source) 引入）
#
#   . "$PSScriptRoot\env.ps1"
#
# 引入后可用：$SDK_ROOT $INCLUDE_DIR $LIB_DIR $LINKER_DIR
#             $CLANG $LLD $TNXPACK $TOOLKIT
#
# 规矩和 SysCore 的 build-run.ps1 一致：**脚本里不写死任何机器相关的路径**。
# 环境变量优先，其次自动探测，再找不到就报错并把 setx 命令打给你。
#
#   TNDDOS_LLVM_BIN    含 clang.exe 的目录（也要有 ld.lld.exe）
#   TNDDOS_TOOLKIT     TNDOS-ToolsKit 仓库的根目录（里面有 tnxpack.ps1）
# ============================================================================

$script:NL = [char]10
$script:Q  = [char]34

function __HowTo([string]$Name, [string]$Example) {
    return ("请设置环境变量 " + $Name + "，然后重开一个终端：" + $script:NL +
            "    setx " + $Name + " " + $script:Q + $Example + $script:Q)
}

function __EnvDir([string]$Name) {
    $v = [Environment]::GetEnvironmentVariable($Name)
    if (-not $v) { return $null }
    if (-not (Test-Path -LiteralPath $v)) {
        throw ("环境变量 " + $Name + " 指向的路径不存在：" + $script:NL + "    " + $v)
    }
    return (Get-Item -LiteralPath $v).FullName
}

$SDK_ROOT    = Split-Path -Parent $PSScriptRoot
$INCLUDE_DIR = Join-Path $SDK_ROOT 'include'
$LIB_DIR     = Join-Path $SDK_ROOT 'lib'
$LINKER_DIR  = Join-Path $SDK_ROOT 'linker'

# --- clang / lld ---
$llvm = __EnvDir 'TNDDOS_LLVM_BIN'
if ($llvm) {
    $CLANG = Join-Path $llvm 'clang.exe'
    $LLD   = Join-Path $llvm 'ld.lld.exe'
} else {
    $c = Get-Command clang.exe -ErrorAction SilentlyContinue
    if (-not $c) { throw ("找不到 clang.exe。" + $script:NL + (__HowTo 'TNDDOS_LLVM_BIN' 'D:\LLVM\bin')) }
    $CLANG = $c.Source
    $LLD   = Join-Path (Split-Path -Parent $CLANG) 'ld.lld.exe'
}
if (-not (Test-Path -LiteralPath $CLANG)) { throw ("找不到 clang：" + $CLANG) }
if (-not (Test-Path -LiteralPath $LLD))   { throw ("找不到 ld.lld：" + $LLD + $script:NL + "（clang 和 ld.lld 应该在同一个目录里）") }

# --- tnxpack（来自 TNDOS-ToolsKit）---
$TOOLKIT = __EnvDir 'TNDDOS_TOOLKIT'
if ($TOOLKIT) {
    $TNXPACK = Join-Path $TOOLKIT 'tnxpack.ps1'
    if (-not (Test-Path -LiteralPath $TNXPACK)) {
        throw ("TNDDOS_TOOLKIT 里没有 tnxpack.ps1：" + $TOOLKIT)
    }
} else {
    $t = Get-Command tnxpack.ps1 -ErrorAction SilentlyContinue
    if ($t) { $TNXPACK = $t.Source }
    else {
        throw ("找不到 tnxpack.ps1（TNDDOS_TOOLKIT 未设置，PATH 上也没有）。" + $script:NL +
               (__HowTo 'TNDDOS_TOOLKIT' 'D:\TNDOS-ToolsKit') + $script:NL +
               "TNDOS-ToolsKit 就是放 tnxpack / tnxdump / mkfat 的那个仓库。")
    }
}
