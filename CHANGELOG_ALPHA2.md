# CarDSP v0.1.0-alpha.2 Changelog

Release line: `0.1.0-alpha.2`

This update focuses on making the physical-iPhone IPA pipeline more complete: branded app-icon packaging, optional Apple code signing/provisioning on the GitHub macOS runner, and fixes discovered while validating that pipeline.

## Added

- Added the CarDSP application icon source at [`Assets/AppIcon180.png.b64`](Assets/AppIcon180.png.b64).
- The IPA workflow now generates the 180×180 (`@3x`) and 120×120 (`@2x`) iPhone icon files during `CarDSP.app` assembly.
- The packaged [`Info.plist`](Sources/CarDSPApp/Info.plist) receives `CFBundleIcons` and `CFBundleIconFiles` metadata so iOS can use the CarDSP icon.
- Added optional Apple signing support to [`.github/workflows/ipa.yml`](.github/workflows/ipa.yml). When a valid `.p12` certificate/private key, matching provisioning profile, and passwords are supplied through GitHub Actions secrets, the macOS runner can import the signing identity, validate the provisioning profile against `com.thetechysasquatch.CarDSP`, embed the profile, run `codesign`, verify the result, and package a signed IPA.
- The release workflow can publish both unsigned and signed IPA artifacts when signing assets are available.

## Changed

- Bumped the release version from `0.1.0-alpha.1` to `0.1.0-alpha.2` in [`VERSION`](VERSION).
- IPA names are versioned as `CarDSP-0.1.0-alpha.2-unsigned.ipa` and, when signing succeeds, `CarDSP-0.1.0-alpha.2-signed.ipa`.
- The IPA workflow watches `Assets/**` so app-icon changes trigger a new device build.
- Updated [`README.md`](README.md) to describe alpha.2, the icon pipeline, signed/unsigned outputs, signing-secret handling, and the Windows → GitHub Actions macOS → iPhone testing workflow.

## CI fixes during alpha.2

The ARM64 Swift/iPhone compilation itself continued to complete successfully. The alpha.2 failures occurred later during manual `.app` assembly while decoding the new icon.

1. `4764ff8` — **Fix macOS base64 decoding in IPA workflow.** Replaced the original decode form with the macOS runner's decode option.
2. `11fcd35` — **Fix base64 file input syntax on macOS runner.** The runner reported that a filename cannot be passed positionally with its `base64` implementation, so decoding now uses explicit `-i` and `-o` file arguments. The same portable syntax is used for signing assets.

The relevant icon command is maintained in [`.github/workflows/ipa.yml`](.github/workflows/ipa.yml); the workflow should remain the authoritative source for the exact current CI syntax.

## Key alpha.2 commits

- `7498932` — add the CarDSP app icon source.
- `de85ebd` — bundle the CarDSP app icon in IPA builds.
- `bf8047c` — bump CarDSP to `0.1.0-alpha.2`.
- `4764ff8` — correct macOS Base64 decoding behavior.
- `11fcd35` — correct macOS Base64 file-input/output syntax after inspecting the failed Actions log.
- `d64942a` — update the README for the alpha.2 icon/signing pipeline.

For the complete earlier development history and code-reference ledger, see [`CHANGELOG.md`](CHANGELOG.md). That log covers the DSP engine, RTA/Auto-EQ, UI, MusicKit, Swift 6 stabilization, CI separation, physical-device compilation, and the original alpha.1 packaging work.

## Code references

- [`Assets/AppIcon180.png.b64`](Assets/AppIcon180.png.b64) — source app icon used by CI.
- [`.github/workflows/ipa.yml`](.github/workflows/ipa.yml) — ARM64 device build, app assembly, icon generation, optional signing, IPA creation, artifact upload, and prerelease publishing.
- [`Sources/CarDSPApp/Info.plist`](Sources/CarDSPApp/Info.plist) — source bundle/privacy metadata modified during packaging.
- [`Package.swift`](Package.swift) — Swift package/app target and platform definitions.
- [`Sources/CarDSPCore/RealTimeDSPEngine.swift`](Sources/CarDSPCore/RealTimeDSPEngine.swift) — main real-time DSP processing engine.
- [`Sources/CarDSPApp/AudioEngineController.swift`](Sources/CarDSPApp/AudioEngineController.swift) — application audio-engine lifecycle.
- [`Sources/CarDSPApp/MusicPlaybackCoordinator.swift`](Sources/CarDSPApp/MusicPlaybackCoordinator.swift) — MusicKit authorization/playback coordinator.
- [`VERSION`](VERSION) — canonical release version.

## Security / signing note

Do not commit Apple account passwords, `.p12` private-key material, certificate passwords, keychain passwords, provisioning profiles containing device/team data, or GitHub signing secrets. Signing assets should be supplied only through the repository's protected Actions-secret mechanism.
