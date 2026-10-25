[CmdletBinding()]
param(
    [ValidateSet("Windows", "Linux")]
    [string]$Platform = "Windows",

    [ValidateSet("Debug", "Release")]
    [string]$Configuration = "Debug",

    [switch]$Clean,

    [switch]$SkipTests
)

$ErrorActionPreference = "Stop"

$root = $PSScriptRoot
Set-Location $root

function Invoke-Native {
    param(
        [string]$Program,
        [string[]]$Arguments
    )

    Write-Host ">> $Program $($Arguments -join ' ')" -ForegroundColor Cyan

    & $Program @Arguments

    if ($LASTEXITCODE -ne 0) {
        throw "$Program failed with exit code $LASTEXITCODE"
    }
}

if ($Platform -eq "Windows") {

    $buildDirectory = Join-Path $root "build\visual-studio"

    if ($Clean -and (Test-Path $buildDirectory)) {
        Write-Host "Removing Windows build directory..." -ForegroundColor Yellow
        Remove-Item $buildDirectory -Recurse -Force
    }

    Invoke-Native "cmake" @("--preset", "windows")

    $buildPreset = if ($Configuration -eq "Release") {
        "windows-release"
    } else {
        "windows-debug"
    }

    Invoke-Native "cmake" @("--build", "--preset", $buildPreset, "--parallel")

    if (-not $SkipTests) {
        Invoke-Native "ctest" @("--preset", $buildPreset)
    }

} elseif ($Platform -eq "Linux") {

    if (-not (Get-Command wsl.exe -ErrorAction SilentlyContinue)) {
        throw "WSL is not available."
    }

    $linuxRoot = (& wsl.exe wslpath -a ($root -replace '\\','/')).Trim()

    if ($LASTEXITCODE -ne 0 -or -not $linuxRoot) {
        throw "Could not resolve the repository path in WSL."
    }

    $commands = @(
        "cd '$linuxRoot'",
        "cmake --preset linux",
        "cmake --build --preset linux --parallel"
    )

    if (-not $SkipTests) {
        $commands += "ctest --preset linux"
    }

    $script = $commands -join " && "

    Invoke-Native "wsl.exe" @("bash", "-lc", $script)
}

Write-Host "`nCarDSP $Platform $Configuration build completed successfully." -ForegroundColor Green
