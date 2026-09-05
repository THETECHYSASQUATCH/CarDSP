
# CarDSP — Phase 2

Real-time DSP foundation for an iPhone car-audio EQ.

## Implemented

- 31-band parametric/graphic-style EQ using cascaded biquads
- Stereo Float32 in-place processing
- High-pass filter
- Independent subwoofer processing bus with subsonic + LPF
- Master gain
- Soft limiter
- DSP configuration/presets
- AVAudioSession Bluetooth route configuration
- MusicKit `ApplicationMusicPlayer` authorization/playback coordinator

## Important architecture note

MusicKit playback and an AVAudioEngine render graph are separate concerns on iOS. The MusicKit application player is included for Apple Music catalog/account playback, while the DSP engine is exposed as a real-time processing component. The final app should only claim Apple Music DSP processing where the chosen iOS audio architecture actually provides access to the audio samples.

## Next phase

- AVAudioEngine/Audio Unit render integration for audio the app owns
- RTA microphone analyzer
- pink noise and sine sweep generator
- time alignment
- phase/polarity
- compressor
- preset persistence
- vehicle profile for 2017 Kia Sportage LX
