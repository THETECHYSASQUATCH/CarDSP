# Phase 1 local acceptance checklist (Xcode and Linux)

Use this alongside [issue #12](https://github.com/THETECHYSASQUATCH/CarDSP/issues/12) and [DEVELOPMENT_STATUS.md](../DEVELOPMENT_STATUS.md). This checklist is a plan, **not** test evidence. Record the tested SHA, OS, Qt/Xcode versions, test commands, artifacts and outcomes before marking a gate complete.

## Automated builds

- [ ] macOS: open `Package.swift` in Xcode, select `CarDSPApp` > My Mac and build/run the existing Swift Package executable.
- [ ] macOS: `bash scripts/build-phase1-xcode.sh` completes the Swift and portable C++ tests.
- [ ] Linux: `bash scripts/build-phase1-linux.sh` completes Qt desktop and portable C++ tests.
- [ ] Linux: `CARDSP_STAGE_INSTALL=1 bash scripts/build-phase1-linux.sh` installs into the staging prefix.
- [ ] Validate test counts; missing QML test runner must not be mistaken for passing UI tests.
- [ ] Check clean environment launch and runtime plugin resolution for both desktop systems.

## Audio and interface acceptance (manual, only with approval and low output volume)

- [ ] WAV / MP3 / FLAC; mono/stereo and sample-rate conversion; malformed input and cancellation.
- [ ] Play, pause, resume, seek, stop, EOF, rapid actions and repeated start/stop.
- [ ] Live EQ, flat, bypass and 32-band Qt UI; parameter changes, output level and finite samples.
- [ ] Device selection, unplug/replug, Bluetooth/headphones and underrun recovery.
- [ ] Presets, file dialogs, microphone inputs and clean folder runtime assets.
- [ ] Document latency/glitches and verify no unsafe output during tests.

## Apple application scope

The current `Package.swift` provides a macOS SwiftUI executable. Opening it in Xcode is supported, but it **is not yet a signed/distributable macOS .app bundle or an iOS/iPadOS app target**. Create native application targets with verified SDK settings, bundle IDs, platform entitlements, resources and signing before asserting those deliverables are complete.

## Exit criterion

Update [DEVELOPMENT_STATUS.md](../DEVELOPMENT_STATUS.md) with observed results, pass/fail logs and unresolved risks. Phase 1 remains open until acceptance gates are demonstrated on the actual target hardware.
