# CarDSP development status

Updated: 2026-10-27 (Phase 2 handoff).

## Latest Phase 1 CI and Phase 2 handoff

The user reported **all seven Phase 1 alpha workflow jobs passed** after fixes and **PR #13 merged** into `development/phase_one` (merge commit `c7c0a2cb9c2e4937e77048aeffba92c813f5ddd1`). The original failed run [40573155716](https://github.com/THETECHYSASQUATCH/CarDSP/actions/runs/40573155716) exposed Linux float-equality regression, Windows relative deployment prefix, and macOS missing AGL framework. Follow-up changes addressed the test comparison, absolute install prefix, and newer Qt CI version. The successful follow-up run ID and actual artifact verification have **not** been independently recorded here.

The user authorized `development/phase_two` for dashboard, navigation, UI and numeric input work. **CI success establishes cross-platform compilation and automated test success, not full Phase 1 acceptance.** Decoder fixtures, physical audio output tests, and deployment launch checks remain unverified in this record. See [Phase 2 agent notes](docs/PHASE_TWO_AGENT_NOTES.md).



## Current decision and repository

**Phase 1 CI: user-reported green and merged. Phase 1 full acceptance: outstanding checks remain. Phase 2: authorized and branch created.**

Authoritative checkout: `C:\Users\thetechysasquatch\Documents\GitHub\CarDSP`, Phase 2 branch `development/phase_two` based on `development/phase_one`. GitHub default branch should be checked before any change. The separate `Documents\ChatGPT\CarDSP` checkout is older and dirty; leave it untouched.

Published baseline: `c3bcdbc5fe7901d7208952b7d09a0a00d2cf90e5` (documentation/CI cleanup). The subsequent Phase 1 source changes and this documentation consolidation are included in the work-in-progress snapshot requested for publication on 2026-10-26. This snapshot does not establish Phase 1 completion. No full Phase 1 completion by Ollama is established: the inspected OpenCode log only showed a VERSION read, and commit authors do not identify a model.

## Status at the stop point

| Area | Published baseline | Local unfinished implementation | Acceptance still needed |
| --- | --- | --- | --- |
| PCM playback | Play/Stop, volume, bypass, six filters | Transport abstraction and controller restructuring | Continuous playback, EOF, failures and stop/restart regression tests |
| Pause/resume | Missing | Added methods and QML button | State, position, repeated operations, errors and EOF |
| Seek / time | Missing | Seek slider, position and duration, output recreation | Boundary seeks, paused seeks, buffered position accuracy, stale events |
| WAV/MP3/FLAC | Raw PCM only | QAudioDecoder to temporary 48 kHz stereo Float32 PCM | Real fixtures in all three formats, conversion, failure and cancellation cases |
| Live EQ | Applied on next Play | Detached processor mailbox and 256-frame crossfade | Concurrent edits, rapid changes, bypass, finite output and channel isolation |
| Output changes | Enumeration, basic output errors | Stop on selected-device disappearance | Disconnect/reconnect, list reorder and explicit device selection |
| Underruns | Stop with error | Up to three recovery attempts from consumed position | Recovery without duplicated/skipped audio; persistent failure handling |
| Qt deployment | Local configured build | CMake Qt/QML deployment script | Install to clean folder and launch without development Qt paths |
| Hardware | Incomplete qualification | Not tested | MSI WS75 speakers, headphones/Bluetooth, audible EQ/bypass, latency |

These local features are implementation attempts, not verified completion claims. Review the code before building on it.

### Files already changed before coding stopped

Modified: `UI/Desktop/Audio/AudioPlaybackEngine.cpp`, `.hpp`, `PcmStreamDevice.hpp`, `PlaybackEq.hpp`; `UI/Desktop/CMakeLists.txt`, `Main.qml`, and `main.cpp`.

New: `UI/Desktop/Audio/AudioFileDecoder.cpp`, `.hpp`, `PlaybackOutput.cpp`, and `.hpp`.

The decoder requests 48 kHz stereo Float32, stores decoded data in an auto-removed temporary file, has a 4 GiB output limit and a 30-second no-buffer timeout, and decodes the full file before playback. Verify lifecycle, disk failure, unsupported formats, cancellation, and signal reentrancy. Do not promise immediate streamed startup.

The output abstraction was added so controller failures can be tested without speakers. **Those new controller/decoder tests were not written before coding stopped.** Existing CTest registration still contains only playback_silent and editable_values for the desktop project.

Live EQ uses per-stream processor state, a try-lock mailbox, and a 256-frame transition. This is not proof of hard real-time safety or glitch-free audio. File I/O and QIODevice buffering still need review. The selected EQ channel remains applied to both stereo channels; the UI layout selector is not a multichannel router.

## Evidence, with scope

### Published baseline (before the new implementation)

- Windows root Release build passed; SharedDSP CTest: 7/7 passed.
- Qt desktop build passed; desktop CTest: 2/2 passed (silent PCM and editable-value QML tests).
- Hosted Shared DSP CI succeeded on Windows, Ubuntu, and macOS for c3bcdbc: [run 40440636511](https://github.com/THETECHYSASQUATCH/CarDSP/actions/runs/40440636511).
- This workflow does not validate the Qt desktop application, decoding, or physical audio outputs.
- Local Git index refresh worked with approved access; no stale lock existed. Default remote points to the intended repository. Local shared-dsp-ci has a separate roadmap commit that must be preserved.

### Local Phase 1 changes at stop

- The desktop build already running when the user stopped coding finished with exit code 0 and linked CarDSPDesktop.exe and cardsp_playback_tests.exe.
- **No tests were run against these new changes.** No current hardware, UI runtime, decoder fixture, deployment, or CI verification was performed.
- Previous 9/9 passing tests and green hosted CI apply to the baseline, not this modified working tree.

### Earlier PCM/EQ checkpoint

Historical silent full-song processing tested 10,897,920 stereo frames (227.04 seconds at assumed 48 kHz) in bypass, flat, and all six filter modes. Outputs were finite; flat/bypass matched input exactly. The source already exceeded full scale: bypass peak 1.07730, with 380 samples above full scale. Tested filtering also produced overshoots (largest recorded peak 1.48037 in high-pass mode). These figures precede the current implementation, are not an audible test, and establish no limiter or speaker protection.

The earlier checkpoint also recorded offscreen startup with no QML component-load failure, using explicit Qt plugin paths; font/device warnings occurred. That did not prove clean deployment. An earlier checklist marked direct Bluetooth PCM playback as done, but continuous DSP playback and audible qualification remained open.

## Phase 1 acceptance checklist

Check an item only after implementation and verification of the current code, not from a successful build or historical result.

- [x] Baseline Qt desktop application, 32-band EQ, six filters, response graph, preset controls, PCM selection and output enumeration existed.
- [ ] Review and test the local playback-controller changes against the baseline.
- [ ] Verify Play, Pause, Resume, Stop, repeated commands, failed start and stop during loading.
- [ ] Verify position/duration and seek at start, middle, end, negative/out-of-range positions, and while paused; reject stale sink callbacks.
- [ ] Verify stream EOF, odd-size reads, empty/truncated/non-finite input, and read/output errors.
- [ ] Test WAV, MP3 and FLAC fixtures, including mono/stereo and differing sample rates; document which additional formats were evaluated and which are supported.
- [ ] Verify decoder cancellation, unsupported/malformed files, temporary-file cleanup, disk/size limits and timeout behavior.
- [ ] Verify live EQ, rapid parameter changes, transition behavior, bypass and independent channel histories without non-finite output.
- [ ] Verify device removal during loading, playback and pause; reconnect, device-list reorder, unsupported output format and explicit output selection.
- [ ] Verify bounded underrun recovery and persistent-failure behavior without replaying or dropping unexpected samples.
- [ ] Run existing SharedDSP and desktop tests plus new controller/decoder regressions; check QML interactions and all 32 bands.
- [ ] Verify QtQuick.Dialogs and multimedia codec deployment from a clean install directory.
- [ ] Complete authorized continuous playback tests on MSI WS75 speakers and headphones/Bluetooth; confirm audible EQ, bypass, EOF, latency and unplug/reconnect.
- [ ] Update documentation with actual evidence, review the final diff, and mark Phase 1 complete only when every required gate passes.

## Commands for a future authorized coding session

These are reference instructions, not work executed during this documentation-only handoff. Run in PowerShell 7; preserve the existing desktop cache and compiler pairing.

```powershell
$ErrorActionPreference = 'Stop'
$repoPath = 'C:\Users\thetechysasquatch\Documents\GitHub\CarDSP'
try {
    Set-Location -LiteralPath $repoPath
    git status --short --branch
    if ($LASTEXITCODE -ne 0) { throw 'Git status failed.' }
    $env:Path = "C:\Qt\Tools\mingw1310_64\bin;C:\Qt\6.12.0\mingw_64\bin;$env:Path"
    cmake --build build/qt-desktop --parallel 4
    if ($LASTEXITCODE -ne 0) { throw 'Desktop build failed.' }
    ctest --test-dir build/qt-desktop --output-on-failure --no-tests=error
    if ($LASTEXITCODE -ne 0) { throw 'Desktop tests failed.' }
    cmake --build build/codex-validation --config Release --parallel 4
    if ($LASTEXITCODE -ne 0) { throw 'Shared DSP/WindowsAudio build failed.' }
    ctest --test-dir build/codex-validation -C Release --output-on-failure --no-tests=error
    if ($LASTEXITCODE -ne 0) { throw 'Shared DSP tests failed.' }
    git diff --check
    if ($LASTEXITCODE -ne 0) { throw 'Diff whitespace validation failed.' }
} catch {
    Write-Error $_
    exit 1
}
```

## Earlier cross-platform work and remaining limits

The October 25 notes described the portable stereo processor, binary PCM tool, retained Release assertions, Swift core portability, source-rate handling, Apple local-file DSP, and experimental macOS virtual-device routing. Historical validation recorded four C++ tests and eight Windows Swift tests; Apple parser checks were syntax-only. These counts are historical, not current regression results.

Apple local-file decoding processes bounded 4096-frame chunks and queues up to three buffers, but main-actor scheduling and a lock still prevent a hard real-time claim. EQ state resets may click; queued latency can be about 256 ms at 48 kHz. Swift and C++ remain separate implementations. Swift subwoofer/main-bus state separation and platform parity remain future work.

Experimental macOS routing requires a separately installed virtual stereo device, physical output selection, and microphone permission. It uses native EQ/HPF/subsonic/preamp, not the complete Swift dynamics/delay/polarity/subwoofer chain. Restore the system output manually afterward; device clocks, feedback, reconnects and latency need Mac validation. No driver installation or DRM bypass is provided. iOS MusicKit is separate from DSP; only accessible local audio samples can be processed. Apple signing, notarization and device builds were not verified on this Windows host.

Older notes reported CI failures due to account spending limits and removal of failed/cancelled runs; they do not establish a current CI failure. This branch currently has Shared DSP CI, not historical IPA or documentation-sync workflows. VERSION is 0.1.0-alpha.7; publication of an alpha.7 release is not established here.

## Document ownership

This document replaces overlapping DEVELOPMENT_STATUS, PROGRESS and PHASE_ONE_CHECKPOINT content. The original Markdown files were copied and hash-verified in `CarDSP_Backups/docs-consolidation-*` before consolidation; published originals remain in Git history. Keep later-phase work in [the roadmap](docs/PROJECT_CHECKLIST.md), agent rules in [AGENTS.md](AGENTS.md), and resumption instructions in [the continuation prompt](docs/PHASE_ONE_CONTINUATION_PROMPT.md).
