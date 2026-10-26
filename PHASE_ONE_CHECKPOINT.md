# Windows PCM/EQ foundation checkpoint — 2026-10-26

## Scope

The available project history does not define a milestone named “Phase One”.
For this checkpoint, that name is interpreted as the first usable Windows
48 kHz stereo Float32 PCM/EQ software foundation, continuing Phase 4C/4D.
This is a software validation checkpoint, not a claim of completed hardware
qualification or completion of the full cross-platform roadmap.

## Delivered

- PCM file selection, output selection, Play/Stop, volume and EQ bypass.
- Master volume has an editable percentage; gain uses dB, frequency Hz and Q
  uses Q. Enter applies, Escape cancels, focus loss applies, invalid text reverts,
  and out-of-range values clamp. Gain preserves its 0.5 dB step.
- Both EQ Enabled and Bypass EQ control the same playback bypass state.
- All six filter types share the tested playback configuration path.
- Bypass is atomic; queued sink events are guarded against obsolete sessions.
- Buffered EOF now accounts for unread bytes, including odd-size reads.
- Empty/incomplete PCM, non-finite samples, invalid EQ and non-finite volume are
  rejected. Local backups and scratch exports stay out of source control.

## Local verification

- Qt desktop build passed with the installed Qt 6.12.0/MinGW toolchain.
- Desktop CTest: 2/2 passed (silent playback regression and QML editing tests).
- Shared DSP CTest: 7/7 passed.
- Hidden offscreen startup loaded Main.qml and all controllers. The offscreen
  environment reported font-directory and device-property warnings; no QML
  component-load failure occurred. Explicit installed Qt plugin paths were used.
- Git whitespace validation passed before commit.

The supplied song was processed locally, without constructing QAudioSink or
opening an audio output, in bypass, flat and all six filter modes. Each run
returned all 10,897,920 stereo frames (227.04 seconds assuming 48 kHz), with finite
output. Flat/bypass matched input samples exactly. Raw PCM carries no metadata;
the sample rate/channel interpretation comes from the supplied format.

| Mode | Peak before volume | Samples above full scale |
|---|---:|---:|
| Bypass / flat | 1.07730 | 380 |
| Peaking | 1.16734 | 381 |
| Low shelf | 1.16627 | 850 |
| High shelf | 0.96704 | 0 |
| Low pass | 0.96873 | 0 |
| High pass | 1.48037 | 5,739 |
| Notch | 1.45902 | 4,543 |

Filter tests use 1 kHz, Q 0.71 and -6 dB where applicable. These are test settings,
not saved user presets. The source already exceeds full scale. No limiter was
introduced; these peaks are before the output-volume stage. The song and derived
audio are not included in Git.

## Repeatable silent tests

With Qt and MinGW bin directories on PATH, from the repository root:

```powershell
cmake --build build/qt-desktop --parallel 4
ctest --test-dir build/qt-desktop --output-on-failure
ctest --test-dir build/shared-dsp-advanced --output-on-failure
& ./build/qt-desktop/cardsp_playback_tests.exe 'C:/path/to/song.pcm'
```

The optional filename runs the full-song checks; without it, the executable runs
synthetic regressions. It links Qt Core only and cannot play sound.

## Remaining work

- Real-device playback completion, unplug/reconnect, audible EQ, and latency
  still need hardware verification. No sound was played during this checkpoint.
- EQ edits apply on the next Play; live coefficient updates/crossfades remain
  future work. Volume and bypass can change while playing.
- The selected channel's EQ is applied to both stereo playback channels. The
  layout selector is not a multichannel hardware router.
- WAV/MP3/FLAC decoding, system-wide routing and platform app parity remain later
  milestones. No new macOS/iOS/Android app builds were validated here.
- Hosted GitHub CI is separate from the local results reported above.
