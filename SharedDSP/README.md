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
