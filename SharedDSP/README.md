# CarDSP Portable DSP Core

This directory is the migration boundary for the cross-platform CarDSP engine.

## Goal

Move platform-neutral real-time DSP out of Swift-only implementation into a portable C++20 library while preserving the tested behavior of `Sources/CarDSPCore`.

The portable core will be consumed by:

- iOS/macOS through a thin Swift/C++ bridge
- Windows through a WASAPI host
- Android through JNI + Oboe

## Migration order

1. Biquad coefficient generation and stateful sample processing
2. DSP configuration model and 31-band EQ
3. HPF, subsonic and LPF filters
4. Master gain, limiter and compressor
5. Time alignment and polarity
6. RTA analysis and target curves
7. Auto-EQ recommendations
8. Signal generator
9. Portable profile serialization

During migration, Swift `CarDSPCore` remains authoritative and its tests act as compatibility references. A component moves to the portable core only after numerical regression tests are added.

## Platform boundary

The shared core must not depend on AVFoundation, SwiftUI, UIKit, AppKit, WASAPI, Android SDK, Oboe, MusicKit, networking, analytics, or account services. Audio device I/O and UI remain native platform responsibilities.

## Privacy

The core performs local signal processing only. It has no network or telemetry layer.

## Stereo buffers and Windows stream tool

`cardsp/stereo_processor.hpp` provides separate left/right filter histories and
in-place interleaved or planar Float32 processing. Configure it while stopped;
it is not safe to change coefficients concurrently with processing. Call `reset`
when starting a new stream. Planar channel regions must not overlap. Invalid
buffer layouts return false without modifying the buffer or state. Coefficient
factories return identity for non-finite parameters or unsupported sample rates
(supported: 8–384 kHz). There is no limiter in this portable chain yet.

Build and test on Windows, macOS or Linux:

```sh
cmake -S SharedDSP -B SharedDSP/build -DCMAKE_BUILD_TYPE=Release
cmake --build SharedDSP/build --config Release
ctest --test-dir SharedDSP/build -C Release --output-on-failure
```

The `cardsp_process_pcm` executable reads native-endian interleaved stereo Float32
PCM from standard input and writes processed PCM to standard output. It applies
a 20 Hz high-pass and the requested preamp. On Windows, run binary redirection
from Command Prompt (older PowerShell versions may transform binary streams):

```bat
SharedDSP\build\Release\cardsp_process_pcm.exe 48000 -6 < input.f32 > output.f32
```

These are raw PCM files, not WAV/MP3 containers. Input and output must be distinct
files. Failed processing may leave partial output, which should be discarded.
The tool rejects malformed frames and non-finite samples. This is a tested host
boundary, not a Windows system-wide equalizer: WASAPI capture/render, endpoint
selection, clock recovery and a native Windows UI remain to be implemented.
Python enables the additional stream-adapter regression test in CTest.
