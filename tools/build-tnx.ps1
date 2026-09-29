# ============================================================================
# build-tnx.ps1 -- 把一个或多个 .c 编译成 TNX 可执行文件
#
#   .\tools\build-tnx.ps1 -Source examples\hello\hello.c -Out build\HELLO.TNX
#   .\tools\build-tnx.ps1 -Source a.c,b.c -Out build\APP.TNX -Keep
#
# 流水线：clang -> .o -> ld.lld -> .elf -> tnxpack -> .TNX
# TNX 不需要自己的编译器和链接器，这个脚本只是把三步串起来。
# ============================================================================
param(
    [Parameter(Mandatory=$true)][string[]]$Source,
    [Parameter(Mandatory=$true)][string]$Out,
    [switch]$Keep,
    [switch]$Quiet
)

$ErrorActionPreference = 'Stop'
[Console]::OutputEncoding = [Text.Encoding]::UTF8
. (Join-Path $PSScriptRoot 'env.ps1')

$outDir = [System.IO.Path]::GetDirectoryName($Out)
if (-not $outDir) { $outDir = '.' }
New-Item -ItemType Directory -Force -Path $outDir | Out-Null
$work = Join-Path $outDir 'obj'
New-Item -ItemType Directory -Force -Path $work | Out-Null

# tndrt.c 里是入口桩 tnx_entry —— 它会存下 API 表再调你的 tnx_main。
# 用户代码不该关心它，所以由脚本自动带上。
$allSrc = @($Source) + @((Join-Path $LIB_DIR 'tndrt.c'))
$objs = @()
foreach ($src in $allSrc) {
    if (-not (Test-Path -LiteralPath $src)) { throw ("源文件不存在：" + $src) }
    $base = [System.IO.Path]::GetFileNameWithoutExtension($src)
    $obj = Join-Path $work ($base + '.o')
    if (-not $Quiet) { Write-Host ("  [ cc ] " + (Split-Path $src -Leaf)) }
    $a = @('-target','x86_64-unknown-none','-ffreestanding','-fno-builtin','-fno-stack-protector',
           '-mno-red-zone','-nostdlib','-Wall',
           '-I', $INCLUDE_DIR, '-I', $LIB_DIR,
           '-c', $src, '-o', $obj)
    & $CLANG @a
    if ($LASTEXITCODE -ne 0) { throw ("clang 编译失败：" + $src) }
    $objs += $obj
}

$elf = Join-Path $work ([System.IO.Path]::GetFileNameWithoutExtension($Out) + '.elf')
if (-not $Quiet) { Write-Host "  [ ld ] linking" }
$la = @('-m','elf_x86_64','-T',(Join-Path $LINKER_DIR 'tnx.ld'),'-o',$elf) + $objs
& $LLD @la
if ($LASTEXITCODE -ne 0) { throw 'ld.lld 链接失败' }

if (-not $Quiet) { Write-Host "  [pack] ELF64 -> TNX" }
& $TNXPACK -In $elf -Out $Out
if ($LASTEXITCODE -ne 0) { throw 'tnxpack 失败' }

if (-not $Keep) { Remove-Item $elf -Force -ErrorAction SilentlyContinue }

if (-not $Quiet) { Write-Host ("  done: " + $Out + "  (" + (Get-Item $Out).Length + " bytes)") }
