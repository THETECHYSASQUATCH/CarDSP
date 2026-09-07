# CarDSP

Real-time DSP foundation and iPhone car-audio EQ application.

## Current release

**CarDSP v0.1.0-alpha.2** — current install/test alpha.

This is an early testing release. GitHub Actions builds the ARM64 iPhone application, assembles a versioned IPA, embeds the CarDSP app icon, and publishes an alpha prerelease. The workflow always produces an unsigned IPA and can additionally produce a signed/device-provisioned IPA when valid Apple signing secrets are configured.

### Alpha.2 changes

- Added the CarDSP application icon to IPA builds.
- Generates the required 180×180 and 120×120 iPhone icon files during bundle assembly.
- Adds `CFBundleIcons`/`CFBundleIconFiles` metadata to the packaged `Info.plist`.
- Added optional GitHub Actions Apple certificate/provisioning support for producing a signed IPA.
- Corrected macOS runner Base64 decoding for the app icon and signing assets.
- Versioned this build as `0.1.0-alpha.2` without replacing alpha.1.
- Detailed release notes: [`CHANGELOG_ALPHA2.md`](CHANGELOG_ALPHA2.md).

### Alpha testing goals

- Verify the app installs and launches on a physical iPhone.
- Verify the new application icon appears correctly on iOS.
- Verify microphone permission and RTA/analyzer operation.
- Verify Bluetooth audio route detection/configuration.
- Verify EQ, filters, presets, limiter, compressor, time alignment, and polarity controls.
- Test Apple Music/MusicKit authorization and determine which capabilities are available with the selected Apple Developer team.
- Identify device-only crashes, signing issues, entitlement issues, and audio-routing limitations.

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
- Microphone-driven RTA/analyzer
- Physical iPhone ARM64 CI build
- Versioned unsigned IPA packaging
- CarDSP iOS app icon packaging
- Optional certificate/provisioning based signing in GitHub Actions
- Automated alpha prerelease publishing

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

- **DSP Core Tests** — builds and tests the reusable DSP core on macOS.
- **iOS Simulator Build** — verifies the iOS application compiles for the simulator.
- **iOS IPA** — builds the physical-device ARM64 executable, manually assembles `CarDSP.app`, embeds the app icon, packages the versioned unsigned IPA, optionally signs the app when Apple signing assets are configured, uploads artifacts, and publishes the alpha release.

The IPA workflow lives at [`.github/workflows/ipa.yml`](.github/workflows/ipa.yml). The icon source is stored at [`Assets/AppIcon180.png.b64`](Assets/AppIcon180.png.b64), and release versioning is stored in [`VERSION`](VERSION).

Alpha releases use semantic prerelease numbering such as `0.1.0-alpha.1`, `0.1.0-alpha.2`, and so on.

## IPA outputs

For the current version the pipeline produces:

- `CarDSP-0.1.0-alpha.2-unsigned.ipa`
- `CarDSP-0.1.0-alpha.2-signed.ipa` when all required Apple signing secrets are available.

The signed path expects a valid Apple code-signing `.p12` certificate/private key and a matching provisioning profile. Signing credentials belong in GitHub Actions secrets, never in source control.

## Installing an alpha IPA

An unsigned IPA cannot be installed directly as a normally provisioned iOS application. It must first be signed/re-signed with an Apple development identity and a provisioning profile appropriate for the iPhone and bundle identifier.

When the GitHub Actions signing secrets are configured correctly, the workflow can perform that signing on its macOS runner and publish the signed IPA alongside the unsigned build. Free Personal Team provisioning is temporary and may require periodic re-signing/reinstallation.

Never commit Apple passwords, certificate private keys, `.p12` passwords, keychain passwords, provisioning credentials, or signing secrets to this repository.

## Bundle and signing references

- Bundle identifier: `com.thetechysasquatch.CarDSP`
- App metadata: [`Sources/CarDSPApp/Info.plist`](Sources/CarDSPApp/Info.plist)
- App icon source: [`Assets/AppIcon180.png.b64`](Assets/AppIcon180.png.b64)
- IPA/signing workflow: [`.github/workflows/ipa.yml`](.github/workflows/ipa.yml)
- Version: [`VERSION`](VERSION)
- Full development history: [`CHANGELOG.md`](CHANGELOG.md)
- Alpha.2 release changelog: [`CHANGELOG_ALPHA2.md`](CHANGELOG_ALPHA2.md)

## Xcode build checklist

1. Open the project/package in Xcode on macOS.
2. Select the app target and an iPhone simulator or connected iPhone.
3. Select a valid Apple Developer team for signing.
4. Add required capabilities/entitlements, including MusicKit where available to the selected team.
5. Confirm privacy descriptions in [`Sources/CarDSPApp/Info.plist`](Sources/CarDSPApp/Info.plist): `NSAppleMusicUsageDescription`, `NSMicrophoneUsageDescription`, and `NSBluetoothAlwaysUsageDescription`.
6. Add Background Modes / Audio if background playback is required.
7. Build and launch the app.
8. Verify Player, EQ, and Analyzer tabs.
9. Test Apple Music authorization, audio routing, presets, DSP controls, and analyzer access.

## Windows testing

The Swift/iOS source requires Apple/Xcode tooling to compile and Apple tooling to perform native iOS code signing. GitHub Actions supplies the macOS/Xcode environment, allowing development from Windows while the cloud runner builds and, when valid signing assets are supplied, signs the IPA. The resulting signed/device-provisioned IPA can then be transferred to Windows for installation/testing on the Developer Mode iPhone.
