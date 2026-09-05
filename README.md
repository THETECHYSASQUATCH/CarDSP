
# CarDSP — Phase 2+

Real-time DSP foundation for an iPhone car-audio EQ.

## Implemented

- 31-band parametric/graphic-style EQ using cascaded biquads
- Stereo Float32 in-place processing
- High-pass filter and subsonic filtering
- Independent subwoofer processing bus with subsonic + LPF
- Master gain
- Soft limiter
- Compressor stage with threshold and ratio control
- Time alignment and phase/polarity support
- DSP configuration, preset persistence, and vehicle profile support
- Pink noise and sine sweep generation helpers
- AVAudioSession Bluetooth route configuration
- MusicKit `ApplicationMusicPlayer` authorization/playback coordinator
- Vehicle profile support for custom tuning profiles

## Important architecture note

MusicKit playback and an AVAudioEngine render graph are separate concerns on iOS. The MusicKit application player is included for Apple Music catalog/account playback, while the DSP engine is exposed as a real-time processing component. The final app should only claim Apple Music DSP processing where the chosen iOS audio architecture actually provides access to the audio samples.

## Completed recommendation set

- AVAudioEngine render integration hooks for app-owned audio paths
- RTA-style analyzer utilities for band energy estimation
- Pink noise and sine sweep generation
- Time alignment support in the engine
- Phase/polarity support in the engine
- Compressor stage with adjustable threshold and ratio
- Preset persistence via `UserDefaults`
- Vehicle profile configuration support

## Current app tabs

The current app exposes the following tabs:

- Player
- EQ
- Analyzer

## Standard EQ presets

The app includes these built-in presets:

- Flat
- Bass Boost
- Treble Boost
- Vocal
- Rock

## Feature coverage in the current app

- 31-band EQ with real-time gain adjustment
- high-pass filter control
- subsonic filter control
- low-pass filter control
- master gain control
- limiter threshold and enable/disable toggle
- compressor threshold and ratio controls
- time alignment control
- polarity invert control
- built-in preset actions for Flat, Bass Boost, Treble Boost, Vocal, and Rock
- microphone-based RTA analysis
- MusicKit playback authorization
- Bluetooth route configuration guidance

## Xcode build checklist

1. Open this project in Xcode on a Mac.
2. Open [Package.swift](Package.swift) and select the app target.
3. Choose an iPhone simulator or a connected iPhone as the run destination.
4. In the app target settings, select a valid Apple Developer team for signing.
5. Add the MusicKit capability in Signing & Capabilities.
6. Ensure the app has the required privacy descriptions in [Sources/CarDSPApp/Info.plist](Sources/CarDSPApp/Info.plist):
   - NSAppleMusicUsageDescription
   - NSMicrophoneUsageDescription
   - NSBluetoothAlwaysUsageDescription
7. If music playback should continue in the background, add Background Modes and enable Audio.
8. Build the app and confirm the package loads without errors.
9. Launch the app and verify the Player, EQ, and Analyzer tabs open correctly.
10. Test Apple Music authorization flow, audio routing, preset changes, and analyzer access.
11. Verify microphone permission is handled properly when the Analyzer tab starts.

> This project is a Swift/iOS app and cannot be built in Visual Studio on Windows. Xcode on macOS is required for building and running it on an iPhone or iOS simulator.
