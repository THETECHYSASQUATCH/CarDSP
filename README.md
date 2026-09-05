
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
- Vehicle profile preset for a 2017 Kia Sportage LX

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
- Vehicle profile configuration for 2017 Kia Sportage LX
