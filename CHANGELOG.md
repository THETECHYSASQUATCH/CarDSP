# CarDSP Changelog

All release notes are maintained in this file. `VERSION` is the source version. This branch has no documentation-sync workflow; update version references explicitly.

## Unreleased — documentation handoff (2026-10-26)

- Consolidate overlapping progress and checkpoint notes into DEVELOPMENT_STATUS.md; keep the roadmap and release history separate.
- Replace duplicated AGENTS.md instructions and add a Phase 1 continuation prompt.
- Record uncommitted playback changes as build-only verified; coding stopped before new tests or hardware qualification. Phase 1 is not complete.

## Unreleased — repository maintenance (2026-10-26)

- Refresh README links, platform boundaries, Windows build instructions, and actual CI coverage.
- Correct README source version to 0.1.0-alpha.7 without claiming a new published release.
- Trigger Shared DSP CI for WindowsAudio changes, configure Release consistently, and fail if no tests are discovered.
- Stop tracking local UI backups and an accidental Git diff-stat export, preserving the files locally.
- Consolidate duplicate ignore rules and document Git index-lock permission troubleshooting.

## 0.1.0-alpha.7 — source checkpoint

`VERSION` records alpha.7. See DEVELOPMENT_STATUS.md for the Windows PCM/EQ foundation, software validation, and remaining hardware checks. Publication of an alpha.7 release is not verified by this maintenance entry.

## 0.1.0-alpha.6

### Added

- Local per-output DSP profiles using on-device storage only.
- Save and restore full DSP configuration for the currently connected audio route.
- Automatic profile recall when a known Bluetooth, wired AUX, USB audio, AirPlay, or other route reconnects.
- Route-profile management controls in the Player UI.
- RTA/Auto-EQ target-curve selection.
- Target curves for Flat, Car SQ, Bass Lift, Warm, and Reference listening goals.
- Adjustable Auto-EQ correction strength.

### Changed

- Auto-EQ remains deliberately conservative, with correction limiting and gain/headroom protection.
- Output profile persistence follows the privacy-first design: no cloud sync, analytics, advertising identifiers, or user tracking.

### Key commits

- `1b222b4` — add Auto-EQ target curves.
- `b0c4cb1` — add local audio-output profile storage.
- `39b2cb6` — add output-profile save/recall UI.
- `030e637` — expand RTA and Auto-EQ controls.
- `d8cef60` — bump CarDSP to alpha.6.

## 0.1.0-alpha.5

### Added

- Automatic AVAudioSession route-change monitoring.
- Human-readable route-change status messages.
- Live output channel-count display.
- Real-time peak meter for CarDSP's app-owned audio-engine path.
- dBFS peak display and clipping warning state.

### Changed

- Audio Output UI now refreshes automatically when routes connect, disconnect, or reconfigure.
- The level meter explicitly applies only to audio that actually enters CarDSP's AVAudioEngine graph.

### Build status

- Physical-device ARM64 iPhone build passed.
- App bundle assembly passed.
- Unsigned IPA packaging and artifact upload passed.
- Alpha release publishing passed.
- Apple signing steps remain optional and are skipped when signing secrets are absent.

## 0.1.0-alpha.4

### Added

- Signal Path dashboard showing source, DSP stages, sample path, and current output.
- Digital-headroom estimate based on EQ boost plus master gain.
- Good / Caution / Clipping Risk headroom status.
- Safe Preamp control that offsets the largest positive EQ boost.

### Changed

- The Player dashboard provides clearer visibility into EQ, HPF, subsonic filter, LPF, time alignment, limiter state, and physical output.

### Key commits

- `3bc453d` — add Signal Path and headroom dashboard.
- `45827d3` — bump CarDSP to alpha.4.

## 0.1.0-alpha.3

Alpha.3 focused on audio-output visibility, wired-route compatibility, and privacy clarity.

### Added

- Dedicated Audio Output panel on the Player tab.
- Active output type, detailed AVAudioSession route, sample rate, and DSP-engine status.
- Readable labels for Lightning-to-AUX, USB-C-to-AUX, USB audio, wired line-out/AUX, Bluetooth A2DP/HFP, AirPlay, speaker, and receiver routes.
- Wired Lightning/USB-C/USB route support without forcing Bluetooth.

### Privacy

- Expanded Apple Music, microphone, and Bluetooth usage descriptions.
- No advertising SDKs or analytics/telemetry are intentionally included.
- No App Tracking Transparency permission is requested because CarDSP is not designed to track users.
- DSP configuration and presets are stored locally for app functionality.

### Key commits

- `d04698d` — clarify privacy permissions and no-tracking intent.
- `0e2c2ba` — support wired Lightning/USB-C/USB audio routes.
- `2c2be5c` — add Audio Output status panel.
- `7ea9912` — add sample-rate reporting.
- `3f19452` — bump to alpha.3.

## 0.1.0-alpha.2

Alpha.2 focused on making the physical-iPhone IPA pipeline more complete.

### Added

- CarDSP app-icon source at `Assets/AppIcon180.png.b64`.
- iPhone `@3x` and `@2x` icon generation during app-bundle assembly.
- Optional Apple signing support in `.github/workflows/ipa.yml`.
- Provisioning-profile validation against `com.thetechysasquatch.CarDSP`.
- Signed IPA generation when valid signing assets are provided through GitHub Actions secrets.
- Signed and unsigned release artifact support.

### CI fixes

- `4764ff8` — fix macOS Base64 decoding behavior.
- `11fcd35` — fix Base64 file input/output syntax on the macOS runner.

### Key commits

- `7498932` — add app icon source.
- `de85ebd` — bundle app icon in IPA builds.
- `bf8047c` — bump to alpha.2.
- `d64942a` — update README for alpha.2.

## 0.1.0-alpha.1

The first packaged alpha established the core application and CI/release foundation.

### Major milestones

- Real-time stereo DSP engine with persistent filter and dynamics state.
- 31-band EQ, high-pass, subsonic and low-pass filters.
- Master gain, soft limiter, compressor, time alignment, and polarity control.
- Non-interleaved Float32 real-time buffer-processing API.
- Microphone-driven RTA analyzer and conservative Auto-EQ assistance.
- Vehicle/audio-system profile foundation.
- Pink-noise, sine, and sweep signal-generation helpers.
- SwiftUI Player, EQ, and Analyzer tabs.
- AVAudioEngine lifecycle management and AVAudioSession playback/measurement modes.
- MusicKit authorization and `ApplicationMusicPlayer` coordination.
- Swift 6 concurrency and platform-availability stabilization.
- Separate DSP Core Tests and iOS Simulator CI workflows.
- Physical-device ARM64 compilation.
- Manual `Payload/CarDSP.app` assembly and unsigned IPA creation.
- Versioned GitHub alpha prerelease publishing.

### Key stabilization commits

- `37d3e6a` — fix Swift 6 MusicKit concurrency import.
- `2373d71` — fix audio-session method call.
- `7e11b4d` — fix Swift 6 audio-session isolation.
- `956b64a` — split iOS Simulator CI.
- `4e210e6` — split DSP Core Tests CI.
- `07d3d1a` / `ea31d5c` — correct macOS deployment targets.
- `75ff958` — guard iOS audio-session APIs from macOS tests.
- `c514ccf` — link UIKit only on iOS.
- `0200f5c` — add unsigned IPA workflow.
- `34a32a3` — fix Info.plist placeholder packaging.
- `709cf75` — establish alpha.1 version.
- `274bd10` — publish versioned alpha releases.

## Current code reference map

| Area | Primary code | Purpose |
| --- | --- | --- |
| DSP engine | `Sources/CarDSPCore/RealTimeDSPEngine.swift` | Real-time stereo DSP chain |
| DSP configuration | `Sources/CarDSPCore/DSPConfiguration.swift` | EQ and DSP state |
| Auto-EQ | `Sources/CarDSPCore/AutoEQ.swift` | Measurement-assisted EQ and target curves |
| RTA | `Sources/CarDSPCore/RTAAnalyzer.swift` | Frequency analysis |
| Audio engine | `Sources/CarDSPApp/AudioEngineController.swift` | AVAudioEngine lifecycle and live metering |
| Audio session | `Sources/CarDSPApp/AudioSessionController.swift` | Route/session management |
| Output profiles | `Sources/CarDSPApp/OutputProfileStore.swift` | Local per-route DSP presets |
| Main UI | `Sources/CarDSPApp/ContentView.swift` | Player dashboard and route/profile controls |
| Analyzer UI | `Sources/CarDSPApp/MicrophoneAnalyzerView.swift` | RTA and Auto-EQ target controls |
| Shared DSP CI | `.github/workflows/shared-dsp.yml` | Cross-platform C++ build and tests |
| Desktop UI | `UI/Desktop/Main.qml` | Windows Qt Quick interface |
| Version | `VERSION` | Canonical release version |

## Security and signing

Never commit Apple account passwords, certificate private keys, `.p12` passwords, provisioning profiles containing device/team data, keychain passwords, or signing secrets. Signing material belongs in protected GitHub Actions secrets.
