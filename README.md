# CarDSP

**Cross-platform audio DSP • C++20 • Qt Quick • Swift**

[![Shared DSP CI](https://github.com/THETECHYSASQUATCH/CarDSP/actions/workflows/shared-dsp.yml/badge.svg?branch=development%2Fphase_one)](https://github.com/THETECHYSASQUATCH/CarDSP/actions/workflows/shared-dsp.yml)
[![Phase 1 desktop builds](https://github.com/THETECHYSASQUATCH/CarDSP/actions/workflows/phase-one-alpha.yml/badge.svg?branch=development%2Fphase_one)](https://github.com/THETECHYSASQUATCH/CarDSP/actions/workflows/phase-one-alpha.yml)
[![Development](https://img.shields.io/badge/status-Phase%201%20validation-orange)](DEVELOPMENT_STATUS.md)

> **CarDSP** is an experimental, cross-platform audio processing project building a reusable DSP engine and native audio interfaces. Its long-term goal is flexible equalization, crossover, routing, and playback control across desktop and mobile platforms.

[**Get started**](#build-and-test) · [**Project status**](#project-status) · [**Roadmap**](docs/PROJECT_CHECKLIST.md) · [**Issues**](https://github.com/THETECHYSASQUATCH/CarDSP/issues) · [**Actions**](https://github.com/THETECHYSASQUATCH/CarDSP/actions) · [**Releases**](https://github.com/THETECHYSASQUATCH/CarDSP/releases)

---

## Highlights

| Component | What it provides | Status |
| --- | --- | --- |
| **SharedDSP** | Portable C++20 biquad processing, stereo DSP, crossovers, alignment, polarity, routing and PCM adapter | Implemented; testing ongoing |
| **Windows desktop** | Qt Quick 32-band EQ, raw 48 kHz stereo Float32 PCM playback, output selection, volume and bypass | Experimental |
| **WindowsAudio** | Windows audio-device discovery and integration foundations | In development |
| **Apple sources** | Swift DSP core and Apple application sources; historical Swift EQ has 31 bands | Packaging/validation pending |
| **Linux / macOS desktop** | Shared DSP builds and tests | UI and hardware acceptance pending |
| **Android / iOS app packages** | Native audio hosts and distributable app artifacts | Not yet implemented |

## Project status

**Phase 1 is not yet accepted or released as complete.** A successful compilation or CI run is not proof of audible playback, decoder support, clean-machine deployment, or mobile packaging.

- **Source version:** `0.1.0-phase1.alpha.1` on the Phase 1 release-preparation branch. This does **not** imply a published downloadable release.
- **Active Phase 1 acceptance:** [Issue #12](https://github.com/THETECHYSASQUATCH/CarDSP/issues/12)
- **Phase 2 dashboard and numeric controls:** [Issue #14](https://github.com/THETECHYSASQUATCH/CarDSP/issues/14)
- **Detailed evidence and outstanding work:** [DEVELOPMENT_STATUS.md](DEVELOPMENT_STATUS.md)
- **Phase checklist:** [docs/PROJECT_CHECKLIST.md](docs/PROJECT_CHECKLIST.md)

### Current limitations

- EQ edits are applied on the next Play; volume and bypass can be changed during playback.
- WAV, MP3 and FLAC decoding, full playback lifecycle tests, output reconnection, and hardware acceptance remain to be verified or implemented.
- System-wide audio interception and unrestricted Apple Music sample processing are **not** supported.
- Android APK/AAB and iOS IPA/simulator deliverables must not be claimed until real application hosts and packaging exist.

## Build and test

### Windows: SharedDSP and WindowsAudio

Requirements: **PowerShell 7**, **CMake 3.25+**, **Visual Studio 2026** with C++ and a Windows SDK, and **Python 3** for the PCM adapter test.

From the repository root:

```powershell
$ErrorActionPreference = 'Stop'
try {
    & ./build.ps1 -Platform Windows -Configuration Release
    if ($LASTEXITCODE -ne 0) { throw 'Build or tests failed.' }
} catch {
    Write-Error $_
    exit 1
}
```

> The root build covers SharedDSP and WindowsAudio, **not** the Qt desktop application.

### Windows: Qt Quick desktop

Install **Qt 6.8+** with Quick, QuickControls2, QuickDialogs2 and Multimedia, and use a matching Qt/compiler toolchain. The desktop CMake project is in [UI/Desktop](UI/Desktop/CMakeLists.txt).

For an **already configured** Qt build, adjust the paths to match your installation:

```powershell
$ErrorActionPreference = 'Stop'
try {
    $env:Path = "C:\Qt\Tools\mingw1310_64\bin;C:\Qt\6.12.0\mingw_64\bin;$env:Path"
    cmake --build build/qt-desktop --parallel 4
    if ($LASTEXITCODE -ne 0) { throw 'Qt build failed.' }
    ctest --test-dir build/qt-desktop --output-on-failure --no-tests=error
    if ($LASTEXITCODE -ne 0) { throw 'Qt tests failed.' }
} catch {
    Write-Error $_
    exit 1
}
```

Use [Launch-CarDSP.ps1](Launch-CarDSP.ps1) for desktop launch instructions. For a fresh configuration, use [UI/Desktop/CMakeLists.txt](UI/Desktop/CMakeLists.txt) as the CMake source directory.

## CI and releases

[Shared DSP CI](.github/workflows/shared-dsp.yml) runs cross-platform C++ checks on Windows, Ubuntu and macOS. [Phase 1 desktop builds](.github/workflows/phase-one-alpha.yml) and [manual prerelease publishing](.github/workflows/publish-phase-one-alpha.yml) are separate workflows. Review the artifacts and acceptance evidence before publishing a prerelease.

Historical alpha tags and release notes are retained in [CHANGELOG.md](CHANGELOG.md). Do not relabel source archives as mobile app packages.

## Architecture

```text
CarDSP/
├── SharedDSP/         Portable C++20 audio processing and tests
├── WindowsAudio/      Windows audio integration
├── UI/Desktop/        Qt Quick desktop application
├── docs/              Roadmap, status and troubleshooting
├── .github/workflows/ CI and release workflows
├── build.ps1          Windows build/test entry point
└── DEVELOPMENT_STATUS.md
```

Apple-specific Swift sources are also maintained in the repository; see the source tree and development status for their current locations and readiness.

## Audio, privacy and safety

CarDSP processes audio samples supplied to it. MusicKit does not grant access to protected Apple Music audio samples for arbitrary DSP, and iOS does not permit unrestricted processing of other apps' output. Settings and profiles are intended to remain local; do not commit secrets, signing certificates, or private keys.

**Experimental software:** CarDSP is not a certified hearing-protection or speaker-protection system.

## Contributing and troubleshooting

Use issues to report reproducible failures with OS, audio device, input format, build revision and logs. Keep changes on development branches and use pull requests for review. See [Git troubleshooting](docs/GIT_TROUBLESHOOTING.md) for lock and permission errors. Keep build products and scratch exports out of version control.

---

*Developed by [THETECHYSASQUATCH](https://github.com/THETECHYSASQUATCH).*
