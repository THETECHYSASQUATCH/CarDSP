param(
    [ValidateSet("Auto", "Vulkan", "D3D11", "OpenGL")]
    [string]$Graphics = "Auto"
)

$ErrorActionPreference = "Stop"

$root = Split-Path -Parent $MyInvocation.MyCommand.Path

$qtBin = "C:\Qt\6.12.0\mingw_64\bin"
$mingwBin = "C:\Qt\Tools\mingw1310_64\bin"

$exe = Join-Path $root "build\qt-desktop\CarDSPDesktop.exe"

if (-not (Test-Path $exe)) {
    throw "CarDSP executable not found."
}

$env:Path = "$qtBin;$mingwBin;$env:Path"

Remove-Item Env:QSG_RHI_BACKEND -ErrorAction SilentlyContinue

switch ($Graphics) {
    "Vulkan" { $env:QSG_RHI_BACKEND = "vulkan" }
    "D3D11"  { $env:QSG_RHI_BACKEND = "d3d11" }
    "OpenGL" { $env:QSG_RHI_BACKEND = "opengl" }
}

Write-Host "Launching CarDSP..." -ForegroundColor Cyan
Write-Host "Graphics: $Graphics"

& $exe
