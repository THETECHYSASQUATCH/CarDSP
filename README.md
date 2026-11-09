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
| **Linux / macOS desktop** | Qt desktop source and CI build/test jobs | CI passed for tested Phase 1 revision; local GUI, audio and clean-install checks pending |
| **Android / iOS app packages** | Native audio hosts and distributable app artifacts | Not yet implemented |

## Project status

### What works in automated testing (verified October 31, 2026)

- **Qt desktop builds/tests:** Windows, Ubuntu and macOS jobs all passed in [Phase 1 desktop CI run 41243662610](https://github.com/THETECHYSASQUATCH/CarDSP/actions/runs/41243662610) on the Xcode feature branch; its changes were subsequently merged through PR #17.
- **SwiftUI macOS executable:** the Xcode Phase 1 workflow passed on `development/phase_one` at `18b39e9` ([run 41243847211](https://github.com/THETECHYSASQUATCH/CarDSP/actions/runs/41243847211)). The existing `Package.swift` opens in Xcode and defines `CarDSPApp` as a Swift Package executable, not a signed `.app`.
- **Shared C++ DSP and Swift core:** automated jobs passed in the above runs. The Qt desktop CMake target includes decoder, controller, silent playback and QML numeric-editor tests; their successful CI execution does not replace real-device testing.
- **Implemented in source:** 32-band Qt EQ and six filter types, response/spectrum view, presets, PCM playback controls, device enumeration, decoder/controller code, and a separate Swift DSP/SwiftUI app with a 31-band EQ. Treat audible behavior and feature parity as unverified.

### Still being implemented or validated

- Local Xcode and Linux build/run, Qt deployment from a clean directory, codec fixture coverage, physical playback, device reconnection, latency and audible EQ/bypass acceptance.
- Conventional signed macOS `.app` and iOS/iPadOS application targets; Android APK/AAB host and packaging.
- Phase 2 responsive navigation and numeric-editor UI: source is present on `development/phase_two`, but its latest checked desktop CI ([run 40952452981](https://github.com/THETECHYSASQUATCH/CarDSP/actions/runs/40952452981)) failed two QML navigation visibility assertions across desktop OSes. This does not change the Phase 1 green CI result.
- Later-phase multichannel routing, advanced DSP integration and platform-specific release packaging.

See [development status](DEVELOPMENT_STATUS.md) for dated evidence and [local acceptance checklist](docs/PHASE1_LOCAL_VALIDATION.md) for work that remains unchecked.

**Phase 1 is not yet accepted or released as complete.** A successful compilation or CI run is not proof of audible playback, decoder support, clean-machine deployment, or mobile packaging.

- **Source version:** `0.1.0-phase1.alpha.1` on the Phase 1 release-preparation branch. This does **not** imply a published downloadable release.
- **Active Phase 1 acceptance:** [Issue #12](https://github.com/THETECHYSASQUATCH/CarDSP/issues/12)
- **Phase 2 dashboard and numeric controls:** [Issue #14](https://github.com/THETECHYSASQUATCH/CarDSP/issues/14)
- **Detailed evidence and outstanding work:** [DEVELOPMENT_STATUS.md](DEVELOPMENT_STATUS.md)
- **Phase checklist:** [docs/PROJECT_CHECKLIST.md](docs/PROJECT_CHECKLIST.md)

### Current limitations

- The older next-Play EQ limitation is historical; live-EQ transition code now exists, but real-time audible acceptance remains pending.
- WAV, MP3 and FLAC decoding code exists; format/fixture coverage, playback lifecycle edge cases, output reconnection, and hardware acceptance remain pending.
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

### Linux: Qt desktop and shared DSP

On the [Phase 1 local-build PR branch](https://github.com/THETECHYSASQUATCH/CarDSP/pull/18), run `bash scripts/build-phase1-linux.sh`; optionally set `CARDSP_STAGE_INSTALL=1` to stage installation. See [Linux build guide](docs/LINUX_PHASE1_BUILD.md). This new script has not yet been locally executed or verified.

### macOS: Xcode / SwiftUI

Open `Package.swift` in Xcode and select the `CarDSPApp` scheme for My Mac, or run `bash scripts/build-phase1-xcode.sh`. See [Xcode build guide](docs/XCODE_PHASE1_BUILD.md). CI passed, but local Mac launch and `.app` packaging are not verified.

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
