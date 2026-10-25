# Development status — 2026-10-25

Base: `9967cdab09655d3123f68323e0cdc7cde91cc007` from `main`.
Changes in this workspace are not a published release.

## Findings

The repository already had a Swift DSP engine, Apple UI and MusicKit coordinator,
plus a small independent C++20 filter library. The Apple playback controller
started an empty graph and never used its DSP argument. Windows had no audio host.
The portable Release smoke tests used assertions, which could be compiled out.

Recent CI did not execute build steps. The six latest failed runs all contained
GitHub's account-payment/spending-limit annotation. This requires action in the
repository owner's GitHub billing settings, not a source-code fix. Older logs
were unavailable. At the user's request, 85 failed/cancelled runs were removed;
119 other runs were retained. Recent diagnostics and deleted run IDs are saved
locally in `.build/ci-diagnostics.json` and `.build/deleted-runs.json`.

## Implemented in this workspace

- Portable C++ stereo processor: independent channel state, planar/interleaved
  buffers, reset and format validation, guarded coefficient factories.
- Windows-compatible binary PCM stream executable and regression tests.
- Release smoke tests retain their checks.
- Swift core can build/test independently on non-Apple hosts.
- Swift stream preparation binds the source sample rate across preset changes.
- Apple local-file playback decodes mono/stereo Float32 in bounded 4096-frame
  chunks, duplicates mono to stereo, processes through the Swift DSP, and queues
  at most three buffers. The displayed level describes queued processed PCM.
- Experimental macOS virtual-device routing uses Core Audio device selection
  and native AVAudioUnitEQ. It applies EQ, HPF/subsonic and preamp only; it does
  not implement the Swift engine's dynamics, delay, polarity or subwoofer bus.
- macOS CI now packages an ad-hoc-signed `.app` with permission descriptions.

## macOS routing setup and limitations

Install/configure a trusted virtual stereo audio device separately. Set the
system output to that virtual device, select it as CarDSP's virtual input, and
select a separate physical output in CarDSP. Allow audio input permission. Start
EQ Routing. CarDSP does not install a driver or change system defaults. Restart
routing after tuning changes. Restore the system output manually when finished.

Routing remains experimental until tested on a Mac. Hardware sample rates,
separate-device clocks, unplug/reconnect behavior, permission prompts and latency
need real-device validation. Aggregate output devices are excluded to reduce
feedback-path risk. Protected sources may not supply capturable audio; there is
no DRM bypass or promise that every Apple Music source can be routed.

Apple references: [audio engine graphs](https://developer.apple.com/documentation/avfaudio/avaudioengine),
[Core Audio device selection](https://developer.apple.com/documentation/audiotoolbox/kaudiooutputunitproperty_currentdevice),
[native EQ bandwidth](https://developer.apple.com/documentation/avfaudio/avaudiouniteqfilterparameters/bandwidth).

## Remaining constraints

- iOS MusicKit playback stays separate; only app-readable, unprotected local
  files enter DSP. No system-wide iOS interception is implemented.
- File decoding/DSP currently run in bounded work on the main actor. Move this
  to a dedicated producer queue before claiming low-latency or glitch-free use;
  UI stalls can underrun the three-buffer queue. EQ edits reset filter state and
  may click. The engine still uses a lock and should not run in a hard real-time
  render callback. At 48 kHz, queued tuning latency can reach about 256 ms.
- Swift and C++ are still separate implementations; full feature parity and a
  Swift/C++ bridge remain work. The C++ tool is not a WASAPI system-audio host.
- Existing Swift subwoofer processing shares state with the main bus and needs
  separation before both buses are used concurrently. Local playback uses only
  the main stereo path.
- Xcode builds, device audio tests, macOS signing/notarization and iOS signing
  are not available on this Windows host. Ad-hoc signing is not notarization.
- Local changes have not been pushed and hosted CI has not been rerun.

## Validation completed

- Windows MSVC Release build succeeded; all four CTest cases passed, including
  stereo state/isolation and binary stream input/error handling.
- Windows Swift 6.4.1 build succeeded; all eight XCTest cases passed, including
  planar/interleaved equivalence across split buffers and source-rate retention.
  The installed Swift SDK emitted module-version warnings on the first build.
- Swift parser checks passed for macOS and iOS branches of the edited app
  sources. These are syntax checks only, not Apple SDK type-checks or builds.
- `git diff --check` passed.
- GitHub queries confirmed zero failed and zero cancelled runs after cleanup.
