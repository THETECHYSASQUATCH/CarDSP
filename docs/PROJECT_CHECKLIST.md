# CarDSP development roadmap

Updated: 2026-10-27. Phase 2 branch: `development/phase_two`.

## Phase 1 — Windows desktop audio engine

**Automated desktop CI passed per user and PR #13 merged; full hardware and decoder acceptance remains outstanding.** The authoritative acceptance checklist, baseline evidence and unfinished implementation are in [DEVELOPMENT_STATUS.md](../DEVELOPMENT_STATUS.md). Do not equate the earlier PCM/EQ foundation checkpoint with full Phase 1 completion.

The later-phase lists below are planning items inherited from the original roadmap. Some component work already exists (including editable numeric controls and shared DSP primitives), but phase-level acceptance has not been completed. Reconcile each item against current code when that phase is authorized. Do not automatically create later-phase branches.

## Phase 2 — Dashboard, Navigation and UI

**Status: STARTED — branch and agent handoff prepared; feature checklist remains open.**

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
