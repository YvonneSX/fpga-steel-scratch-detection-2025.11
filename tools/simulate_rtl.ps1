$ErrorActionPreference = 'Stop'

$iverilog = Get-Command iverilog -ErrorAction SilentlyContinue
$vvp = Get-Command vvp -ErrorAction SilentlyContinue
if (-not $iverilog -or -not $vvp) {
    throw 'Icarus Verilog is required. Install it separately, then retry this script.'
}

$repoRoot = Split-Path -Parent $PSScriptRoot
$buildDir = Join-Path $repoRoot 'build\rtl_sim'
New-Item -ItemType Directory -Path $buildDir -Force | Out-Null
$image = Join-Path $buildDir 'tb_scratch_detector.vvp'
$rtl = Join-Path $repoRoot 'rtl\scratch\scratch_detector.v'
$tb = Join-Path $repoRoot 'sim\tb\tb_scratch_detector.v'

& $iverilog.Source -g2012 -s tb_scratch_detector -o $image $rtl $tb
if ($LASTEXITCODE -ne 0) { throw "iverilog exited with code $LASTEXITCODE" }

& $vvp.Source $image
if ($LASTEXITCODE -ne 0) { throw "vvp exited with code $LASTEXITCODE" }
