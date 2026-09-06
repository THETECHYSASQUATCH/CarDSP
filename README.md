# CarDSP

Real-time DSP foundation and iPhone car-audio EQ application.

## Current release

**CarDSP v0.1.0-alpha.1** — first installable alpha build.

This is an early testing release. The iPhone ARM64 application and unsigned IPA are built by GitHub Actions. The IPA must be signed for your Apple Developer team before installation on a physical iPhone.

### Alpha testing goals

- Verify the app installs and launches on a physical iPhone
- Verify microphone permission and RTA/analyzer operation
- Verify Bluetooth audio route detection/configuration
- Verify EQ, filters, presets, limiter, compressor, time alignment, and polarity controls
- Test Apple Music/MusicKit authorization and determine which capabilities are available with the selected Apple Developer team
- Identify device-only crashes, signing issues, entitlement issues, and audio-routing limitations

> **Alpha warning:** CarDSP is under active development. Do not rely on this build for hearing protection, speaker protection, or guaranteed output-level limiting.

## Implemented

- 31-band parametric/graphic-style EQ using cascaded biquads
- Stereo Float32 in-place processing
- High-pass filter and subsonic filtering
- Independent subwoofer processing bus with subsonic + LPF
- Master gain
- Soft limiter
- Compressor stage with threshold and ratio control
- Time alignment and phase/polarity support
- DSP configuration and preset persistence
- Pink noise and sine sweep generation helpers
- AVAudioSession Bluetooth route configuration
- MusicKit `ApplicationMusicPlayer` authorization/playback coordinator
- Physical iPhone ARM64 CI build
- Unsigned IPA packaging for sideload testing

## Important architecture note

MusicKit playback and an AVAudioEngine render graph are separate concerns on iOS. The MusicKit application player is included for Apple Music catalog/account playback, while the DSP engine is exposed as a real-time processing component. CarDSP should only claim Apple Music DSP processing where the chosen iOS audio architecture actually provides access to the audio samples.

## Current app tabs

- Player
- EQ
- Analyzer

## Standard EQ presets

- Flat
- Bass Boost
- Treble Boost
- Vocal
- Rock

## Feature coverage

- 31-band EQ with real-time gain adjustment
- High-pass filter control
- Subsonic filter control
- Low-pass filter control
- Master gain control
- Limiter threshold and enable/disable toggle
- Compressor threshold and ratio controls
- Time alignment control
- Polarity invert control
- Built-in EQ presets
- Microphone-based RTA analysis
- MusicKit playback authorization
- Bluetooth route configuration guidance

## CI / build status

The repository uses separate GitHub Actions workflows for:

- **DSP Core Tests** — builds and tests the reusable DSP core on macOS
- **iOS Simulator Build** — verifies the iOS application compiles for the simulator
- **Unsigned iOS IPA** — builds the physical-device ARM64 executable, assembles `CarDSP.app`, and packages `CarDSP-unsigned.ipa`

Release versioning is stored in [`VERSION`](VERSION). Alpha releases use semantic prerelease numbering such as `0.1.0-alpha.1`, `0.1.0-alpha.2`, and so on.

## Installing an alpha IPA

The GitHub release IPA is **unsigned**. Before installing it on an iPhone, it must be signed/re-signed with an Apple development identity and provisioning profile appropriate for that device and bundle identifier.

For free Personal Team testing, provisioning is temporary and the app may need periodic re-signing. Never commit Apple passwords, certificate private keys, `.p12` passwords, or provisioning credentials to this repository.

## Xcode build checklist

1. Open the project/package in Xcode on macOS.
2. Select the app target and an iPhone simulator or connected iPhone.
3. Select a valid Apple Developer team for signing.
4. Add required capabilities/entitlements, including MusicKit where available to the selected team.
5. Confirm privacy descriptions in [`Sources/CarDSPApp/Info.plist`](Sources/CarDSPApp/Info.plist):
   - `NSAppleMusicUsageDescription`
   - `NSMicrophoneUsageDescription`
   - `NSBluetoothAlwaysUsageDescription`
6. Add Background Modes / Audio if background playback is required.
7. Build and launch the app.
8. Verify Player, EQ, and Analyzer tabs.
9. Test Apple Music authorization, audio routing, presets, DSP controls, and analyzer access.

## Windows testing

The Swift/iOS source itself requires Apple/Xcode tooling to compile for iOS. GitHub Actions provides the macOS/Xcode build environment so Windows users can obtain an unsigned IPA without owning a Mac. The resulting IPA still requires valid Apple signing/provisioning before installation on an iPhone.
