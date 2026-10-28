# CarDSP — Phase 2 roadmap

**Branch:** development/phase_two
**Status:** Active. Check off items only with code and test evidence.

This branch's roadmap intentionally contains **Phase 2 only**. Phase 1 acceptance is tracked in DEVELOPMENT_STATUS.md and issue #12; future phases are tracked outside this branch.

## Dashboard and navigation
- [ ] Responsive dashboard
- [ ] Dedicated 32-band EQ page with existing bindings preserved
- [ ] EQ response and spectrum page
- [ ] Routing, crossovers, time alignment, presets and settings pages
- [ ] Honest placeholders for DSP features not yet implemented
- [ ] Playback and microphone controls accessible on every page

## Numeric inputs and accessibility
- [ ] Volume displays 0–100% and accepts exact typed percentages
- [ ] Editable numeric fields for every slider: dB, Hz and Q as applicable
- [ ] Preserve slider ranges and DSP bindings
- [ ] Validate and clamp values; Enter applies and Escape cancels
- [ ] Keyboard, mouse, focus and accessibility regression tests

## Channel layouts
- [ ] Mono
- [ ] Stereo
- [ ] 2.1
- [ ] 3.1
- [ ] 4.2
- [ ] 4.4
- [ ] Define speaker/output/subwoofer mappings; confirm 4.2 and 4.4 semantics
- [ ] Persistent layout selection and preset round trips
- [ ] Real routing and independent channel processing, not just a selector
- [ ] Check output capacity and handle unsupported layouts
- [ ] Test channel isolation, conversion, subwoofer routing and live switching

## Appearance and acceptance
- [ ] Responsive layout, scrolling, grouping and themes
- [ ] Improve graph and spectrum presentation
- [ ] Windows, Linux and macOS desktop CI/QML regression evidence
- [ ] Update development status and open review PR before main merge

See [issue #14](https://github.com/THETECHYSASQUATCH/CarDSP/issues/14).
