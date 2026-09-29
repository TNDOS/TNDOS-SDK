# ============================================================================
# build-drv.ps1 -- 把一个或多个 .c 编译成 TNDDOS 驱动（UEFI 映像）
#
#   .\tools\build-drv.ps1 -Source examples\driver\hello_drv.c -Out build\DEMO.EFI
#
# 驱动目前不是 TNX，是普通 PE32+ UEFI 映像 —— 因为 DEVICE= 现在走的是固件的
# LoadImage。等 TNX 加载器接管驱动加载之后这里会改。
# drvlib.c 由本脚本自动带上，不用写进 -Source。
# ============================================================================
param(
    [Parameter(Mandatory=$true)][string[]]$Source,
    [Parameter(Mandatory=$true)][string]$Out,
    [switch]$Quiet
)

$ErrorActionPreference = 'Stop'
[Console]::OutputEncoding = [Text.Encoding]::UTF8
. (Join-Path $PSScriptRoot 'env.ps1')

$outDir = [System.IO.Path]::GetDirectoryName($Out)
if (-not $outDir) { $outDir = '.' }
New-Item -ItemType Directory -Force -Path $outDir | Out-Null

# drvlib.c 和 utf8.c 是驱动运行时的固定组成，用户不用管
$srcs = @($Source) + @((Join-Path $LIB_DIR 'drvlib.c'), (Join-Path $LIB_DIR 'utf8.c'))
if (-not $Quiet) { Write-Host ("  [ cc ] " + (($srcs | ForEach-Object { Split-Path $_ -Leaf }) -join ', ')) }

$a = @('-target','x86_64-pc-windows-msvc','-ffreestanding','-fno-builtin','-fshort-wchar','-nostdlib',
       '-fno-stack-protector','-mno-red-zone','-Wall',
       '-Wl,/subsystem:efi_application,/entry:efi_main','-Wl,/machine:x64',
       '-I', $INCLUDE_DIR) + $srcs + @('-o', $Out)
& $CLANG @a
if ($LASTEXITCODE -ne 0) { throw 'clang 编译驱动失败' }

if (-not $Quiet) { Write-Host ("  done: " + $Out + "  (" + (Get-Item $Out).Length + " bytes)") }
