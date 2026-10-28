# Phase 2 agent notes — 2026-10-27

## Scope and authorization

Phase 1 is DONE by the user's 2026-10-27 checkpoint decision, except macOS/iOS, deferred to Phase 4. Continue on `development/phase_two` with dashboard, navigation, numeric-input UX and mono, stereo, 2.1, 3.1, 4.2 and 4.4 layouts. Do not silently change the default branch or merge to main.

## Project memory and evidence

Use [DEVELOPMENT_STATUS.md](../DEVELOPMENT_STATUS.md) as the canonical checkpoint and [PROJECT_CHECKLIST.md](PROJECT_CHECKLIST.md) for planned features. The status records independently verified seven-job CI success and the published release-signed Android APK. Hardware/decoder/deployment follow-ups stay unverified until tested. macOS CI may continue as regression coverage despite deferred platform completion. New Phase 2 layouts are not implemented by this documentation checkpoint.

## Work order
1. Inspect `UI/Desktop/Main.qml`, `EditableValue.qml`, `EqController.*`, and `Audio/SpectrumView.qml` and preserve current playback bindings.
2. Introduce a responsive application shell with dashboard and navigation. Move 32-band EQ to its own page without changing audio processing semantics.
3. Split EQ response/spectrum, channel routing, crossovers, time alignment, presets and settings into navigable views. Mark unsupported backend functions as previews rather than pretending they work.
4. Standardize sliders with typed numeric editing: volume 0–100%, dB, Hz and Q. Validate/clamp values; support keyboard Enter and Escape; preserve existing ranges and bindings.
5. Ensure playback and microphone controls remain accessible across pages.
6. Define the mono, stereo, 2.1, 3.1, 4.2 and 4.4 speaker/subwoofer mappings; implement layout selection, persistence and required channel routing/processing with device-capacity checks. Preserve 4.4 as requested until its mapping is confirmed.
7. Add channel isolation, conversion, subwoofer routing, preset and layout-switching tests. Add QML/UI regression tests for navigation, editable values, all 32 EQ bands, and small window layouts.
8. Run desktop CI on Windows, Linux and macOS, plus SharedDSP and Swift tests; record workflow URLs and exact results. Do not mark Phase 2 complete without tests and review.

## Agent rules
- Read `AGENTS.md`, `DEVELOPMENT_STATUS.md`, and `docs/PROJECT_CHECKLIST.md` before editing.
- Keep UI changes focused and reviewable; do not change DSP behavior merely to restructure the interface.
- Protect user files, local changes and credentials; no forced resets or force pushes.
- Use complete PowerShell scripts with explicit error checking, `[OK]`/`[ERROR]` feedback, and quoted paths.
- Create a PR before merging Phase 2 into `main`; do not publish alpha releases based only on a successful compile.
- Update `DEVELOPMENT_STATUS.md` with actual test evidence after each milestone; avoid duplicate progress documents.
