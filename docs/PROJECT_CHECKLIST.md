# CarDSP — Master Development Checklist

**Branch:** `feature/realtime-audio-engine`  
**Updated:** October 26, 2026

## Phase 1 — Windows Desktop Audio Engine

**Status: IN PROGRESS**

### Foundation
- [x] Create Qt desktop application
- [x] Implement audio output-device enumeration
- [x] Implement 32-band EQ controller
- [x] Implement six DSP filter types
- [x] Implement frequency-response visualization
- [x] Implement preset controls
- [x] Implement PCM file selection
- [x] Confirm direct PCM playback through Bluetooth headphones

### DSP Playback
- [x] Implement custom PcmStreamDevice
- [x] Connect StereoProcessor to PCM readData()
- [x] Add file-backed stream positioning and available-byte handling
- [ ] Verify continuous playback through custom DSP stream
- [ ] Test playback through MSI WS75 laptop speakers
- [ ] Confirm audible EQ processing
- [ ] Verify EQ bypass operation
- [ ] Resolve audio buffering and underrun issues
- [ ] Support safe real-time EQ updates

### Playback Controls
- [ ] Verify Play
- [ ] Implement and verify Pause
- [ ] Implement and verify Resume
- [ ] Verify Stop
- [ ] Implement Seek
- [ ] Add playback position and duration
- [ ] Handle end-of-file correctly
- [ ] Handle output-device changes safely

### Audio Formats
- [ ] Implement WAV decoding
- [ ] Implement MP3 decoding
- [ ] Implement FLAC decoding
- [ ] Evaluate additional supported audio formats

### Phase 1 Verification
- [ ] Complete continuous playback tests
- [ ] Complete DSP bypass and active-EQ tests
- [ ] Complete playback control tests
- [ ] Complete audio device tests
- [ ] Complete Windows regression testing
- [ ] Fix QtQuick.Dialogs runtime deployment configuration
- [ ] Mark Phase 1 complete

---

## Phase 2 — Dashboard, Navigation and UI

**Status: PLANNED**

### Navigation
- [ ] Create dedicated Dashboard page
- [ ] Move 32-band EQ controls to their own submenu
- [ ] Create EQ Response & Spectrum page
- [ ] Create Channel Routing page
- [ ] Create Crossovers page
- [ ] Create Time Alignment page
- [ ] Create Presets page
- [ ] Create Settings page
- [ ] Keep playback toolbar accessible
- [ ] Keep microphone toolbar accessible

### Sliders and Numeric Inputs
- [ ] Display volume as 0–100%
- [ ] Allow clicking volume value to type exact percentage
- [ ] Add editable numeric input to every slider
- [ ] Display EQ gain in dB
- [ ] Display frequency in Hz
- [ ] Display bandwidth as Q
- [ ] Preserve existing slider ranges and bindings
- [ ] Validate and clamp typed values
- [ ] Support Enter to apply changes
- [ ] Support Escape to cancel changes
- [ ] Verify keyboard and mouse interactions

### Appearance
- [ ] Improve responsive layouts
- [ ] Improve scrolling and control grouping
- [ ] Add appearance and theme options
- [ ] Improve graph and spectrum presentation
- [ ] Complete UI regression testing

---

## Phase 3 — Advanced DSP and Car Audio

**Status: PLANNED**

- [ ] Implement flexible channel routing
- [ ] Implement multi-channel DSP
- [ ] Implement high-pass crossovers
- [ ] Implement low-pass crossovers
- [ ] Implement speaker time alignment
- [ ] Implement speaker delay controls
- [ ] Expand advanced filter configuration
- [ ] Implement car audio system configuration
- [ ] Expand measurement and visualization tools
- [ ] Complete advanced DSP testing

---

## Phase 4 — Cross-Platform Development

**Status: PLANNED**

### Windows
- [ ] Finalize Windows audio backend
- [ ] Package Windows application
- [ ] Create installer
- [ ] Test clean installation

### macOS
- [ ] Port shared DSP engine
- [ ] Implement compatible macOS audio backend
- [ ] Develop macOS interface
- [ ] Test macOS playback and DSP

### iOS
- [ ] Port shared DSP processing
- [ ] Develop mobile interface
- [ ] Implement supported iOS audio integration
- [ ] Investigate supported Apple Music integration
- [ ] Document Apple Music DRM and platform restrictions
- [ ] Complete iOS testing

---

## Current Development Notes

- Active branch: `feature/realtime-audio-engine`
- Qt: 6.12.0 MinGW 64-bit
- Build directory: `build/qt-desktop`
- DSP stream patched but audible playback not yet verified
- MSI WS75 laptop speaker test pending
- QtQuick.Dialogs launches with explicit QML import paths
- Preserve existing modified and untracked source files

## Next Development Priority

1. Verify custom PCM DSP playback through laptop speakers.
2. Confirm active EQ processing and bypass behavior.
3. Implement reliable playback controls.
4. Add native audio decoding.
5. Complete Phase 1 regression testing.

**Rule:** Check a task only after implementation and verification.
