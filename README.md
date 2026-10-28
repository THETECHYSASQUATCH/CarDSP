# CarDSP

[GitHub repository](https://github.com/THETECHYSASQUATCH/CarDSP) · [Phase 2 development](https://github.com/THETECHYSASQUATCH/CarDSP/tree/development/phase_two) · [Actions](https://github.com/THETECHYSASQUATCH/CarDSP/actions) · [Releases](https://github.com/THETECHYSASQUATCH/CarDSP/releases)

> **Phase 2 checkpoint (2026-10-27):** Phase 1 is DONE by user decision, except macOS/iOS, deferred to Phase 4. Phase 2 adds dashboard/navigation/numeric-input improvements and mono, stereo, 2.1, 3.1, 4.2 and 4.4 channel layouts. See the [roadmap](docs/PROJECT_CHECKLIST.md), [progress and evidence](DEVELOPMENT_STATUS.md), and [agent handoff](docs/PHASE_TWO_AGENT_NOTES.md).

CarDSP is an audio DSP project with a portable C++20 core, Qt Quick application and Swift sources for Apple platforms.

[Phase 1 alpha.1](https://github.com/THETECHYSASQUATCH/CarDSP/releases/tag/phase1-alpha.1) is published with Windows, Linux and macOS desktop previews and an experimental release-signed Android ARM64 APK. Existing macOS downloads remain available despite deferred platform completion. No iOS binary is published. Hardware, decoder and Android device validation follow-ups remain documented; milestone completion does not claim those tests passed.

## Current development

Continue on `development/phase_two`. All seven jobs passed for commit `69a37ce` in [CI run 40611407100](https://github.com/THETECHYSASQUATCH/CarDSP/actions/runs/40611407100). The published alpha.1 packages are based on the earlier release tag, not this Phase 2 commit. New channel layouts remain roadmap work until their mappings, processing and tests are implemented.

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
