# CarDSP

[GitHub repository](https://github.com/THETECHYSASQUATCH/CarDSP) · [Development branch](https://github.com/THETECHYSASQUATCH/CarDSP/tree/development/phase_one) · [Actions](https://github.com/THETECHYSASQUATCH/CarDSP/actions) · [Releases](https://github.com/THETECHYSASQUATCH/CarDSP/releases)

CarDSP is an audio DSP project with a portable C++20 processing library, a Windows Qt Quick desktop application, and Swift sources for Apple platforms.

The version recorded in [VERSION](VERSION) is **0.1.0-alpha.7**. This identifies the source version; it does not establish that a corresponding downloadable release has been published. Earlier alpha release notes remain in [CHANGELOG.md](CHANGELOG.md).

## Current development

Work continues on `development/phase_one`. See the [PCM/EQ checkpoint](PHASE_ONE_CHECKPOINT.md), [development status](DEVELOPMENT_STATUS.md), and [project checklist](docs/PROJECT_CHECKLIST.md).

- Windows desktop: 32-band EQ interface, raw 48 kHz stereo Float32 PCM playback, output selection, volume, and EQ bypass.
- Shared DSP: biquad filters, stereo processing, crossovers, alignment, polarity, routing, and a command-line PCM adapter.
- Swift: reusable DSP core and Apple application sources. The historical Swift EQ has 31 bands; the Windows desktop interface has 32.
- EQ edits apply on the next Play; volume and bypass can change during playback.
- Audible EQ, device reconnection, latency, and playback completion still need hardware qualification. WAV/MP3/FLAC decoding and system-wide routing remain future work.

## Build and test on Windows

Use PowerShell 7 from the repository root. Install CMake 3.25 or newer, Visual Studio 2026 with C++ and a Windows SDK, and Python 3 for the PCM adapter test. The checked-in Windows preset selects Visual Studio 2026.

```powershell
$ErrorActionPreference = 'Stop'
try {
    & ./build.ps1 -Platform Windows -Configuration Release
    if (-not $?) { throw 'CarDSP build or tests failed.' }
} catch {
    Write-Error $_
    exit 1
}
```

The root build compiles SharedDSP and WindowsAudio. It does not build the Qt desktop application.

For an already configured Qt desktop build, put the matching Qt and MinGW tools on PATH and run:

```powershell
$ErrorActionPreference = 'Stop'
try {
    $env:Path = "C:\Qt\Tools\mingw1310_64\bin;C:\Qt\6.12.0\mingw_64\bin;$env:Path"
    cmake --build build/qt-desktop --parallel 4
    if ($LASTEXITCODE -ne 0) { throw 'Desktop build failed.' }
    ctest --test-dir build/qt-desktop --output-on-failure --no-tests=error
    if ($LASTEXITCODE -ne 0) { throw 'Desktop tests failed.' }
} catch {
    Write-Error $_
    exit 1
}
```

A fresh Qt build uses [UI/Desktop/CMakeLists.txt](UI/Desktop/CMakeLists.txt) as its source directory and requires Qt 6.8 or newer with Quick, QuickControls2, QuickDialogs2, and Multimedia. Match Qt's compiler/toolchain when configuring it. Launch with [Launch-CarDSP.ps1](Launch-CarDSP.ps1).

## Continuous integration

[Shared DSP CI](.github/workflows/shared-dsp.yml) builds and tests on Windows, Ubuntu, and macOS. It runs for SharedDSP, WindowsAudio, root CMake, and workflow changes, and can be started manually. Release assertions remain enabled for the C++ smoke tests.

This branch does not currently contain the historical IPA, iOS simulator, or documentation-sync workflows. Do not assume it packages iPhone releases or synchronizes version documentation automatically. Qt desktop and Apple application validation are separate from Shared DSP CI.

## Audio and privacy boundaries

DSP applies to audio samples supplied to CarDSP. MusicKit playback does not itself provide access to Apple Music samples for DSP, and output-route support does not bypass iOS restrictions on other applications' audio.

Settings and DSP profiles are intended to remain local. No advertising or analytics systems are intentionally included. Apple Music and microphone permissions support playback and user-requested analysis features. Never commit signing credentials or private keys.

CarDSP is experimental and is not a guaranteed hearing or speaker protection system.

## Repository maintenance

See [Git troubleshooting](docs/GIT_TROUBLESHOOTING.md) for index-lock permission errors. Local backups, build outputs, and scratch exports should remain outside version control. Preserve local work before changing branches; never remove a lock belonging to a running Git operation.
