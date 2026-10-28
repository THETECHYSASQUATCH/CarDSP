# CarDSP development roadmap

Updated: 2026-10-27. Phase 2 branch: `development/phase_two`.

## Phase 1 — Windows desktop audio engine

**Status: DONE by user checkpoint on 2026-10-27, except macOS/iOS, deferred to Phase 4.** Alpha.1 desktop and Android packages are published. Outstanding validation is carried forward in [DEVELOPMENT_STATUS.md](../DEVELOPMENT_STATUS.md); milestone closure does not mark unperformed tests as passed.

The later-phase lists below are planning items inherited from the original roadmap. Some component work already exists (including editable numeric controls and shared DSP primitives), but phase-level acceptance has not been completed. Reconcile each item against current code when that phase is authorized. Do not automatically create later-phase branches.

## Phase 2 — Dashboard, Navigation, UI and Channel Layouts

**Status: ACTIVE — checkpoint 2026-10-27; UI and channel-layout features below remain planned until implemented and tested.**

### Channel layouts (new Phase 2 features)

- [ ] Mono
- [ ] Stereo
- [ ] 2.1
- [ ] 3.1
- [ ] 4.2
- [ ] 4.4
- [ ] Define and document each layout's speaker, output and subwoofer mapping; confirm the requested 4.2/4.4 semantics before coding
- [ ] Add layout selection, labels and persistent preset configuration
- [ ] Implement the routing and independent channel processing required for these layouts; a selector alone is not feature completion
- [ ] Check output-device channel capacity and clearly handle unsupported layouts
- [ ] Test channel identity/isolation, mono/stereo conversion, subwoofer routing, preset round trips and switching layouts during playback

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

- [ ] Extend routing beyond the Phase 2 layout requirements
- [ ] Extend multichannel DSP beyond the Phase 2 layouts
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

### macOS — deferred from Phase 1

Existing CI/artifacts do not establish platform acceptance. Resume platform completion in Phase 4.
- [ ] Port shared DSP engine
- [ ] Implement compatible macOS audio backend
- [ ] Develop macOS interface
- [ ] Test macOS playback and DSP

### iOS — deferred from Phase 1

No iOS binary is published. Resume app/device work in Phase 4.
- [ ] Port shared DSP processing
- [ ] Develop mobile interface
- [ ] Implement supported iOS audio integration
- [ ] Investigate supported Apple Music integration
- [ ] Document Apple Music DRM and platform restrictions
- [ ] Complete iOS testing

---
