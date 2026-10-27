# Phase 2 agent notes — 2026-10-27

## Scope and authorization
The user explicitly requested Phase 2 branch creation and updated agents/progress notes. Phase 2 is the **dashboard, navigation, and numeric-input UX** phase. Begin on `development/phase_two`, branched from the merged Phase 1 head. Do not silently change the default branch or merge to main.

## Verified versus reported
- User reports all seven jobs passed in the updated Phase 1 alpha desktop workflow and PR #13 was merged.
- PR #13 merge commit: `c7c0a2cb9c2e4937e77048aeffba92c813f5ddd1`.
- Previous run 40573155716 had three desktop failures: Linux float comparison in `playback_silent`; Windows Qt `stage/bin/qt.conf` relative path; macOS AGL linker failure.
- Phase 1 automated CI success is not equivalent to audible playback, clean install, decoder format, and device reconnection acceptance. Preserve the open gates in `DEVELOPMENT_STATUS.md`.
- No Phase 2 UI implementation has been completed in this branch as of this handoff.

## Work order
1. Inspect `UI/Desktop/Main.qml`, `EditableValue.qml`, `EqController.*`, and `Audio/SpectrumView.qml` and preserve current playback bindings.
2. Introduce a responsive application shell with dashboard and navigation. Move 32-band EQ to its own page without changing audio processing semantics.
3. Split EQ response/spectrum, channel routing, crossovers, time alignment, presets and settings into navigable views. Mark unsupported backend functions as previews rather than pretending they work.
4. Standardize sliders with typed numeric editing: volume 0–100%, dB, Hz and Q. Validate/clamp values; support keyboard Enter and Escape; preserve existing ranges and bindings.
5. Ensure playback and microphone controls remain accessible across pages.
6. Add QML/UI regression tests for navigation, editable values, all 32 EQ bands, and small window layouts.
7. Run desktop CI on Windows, Linux and macOS, plus SharedDSP and Swift tests; record workflow URLs and exact results. Do not mark Phase 2 complete without tests and review.

## Agent rules
- Read `AGENTS.md`, `DEVELOPMENT_STATUS.md`, and `docs/PROJECT_CHECKLIST.md` before editing.
- Keep UI changes focused and reviewable; do not change DSP behavior merely to restructure the interface.
- Protect user files, local changes and credentials; no forced resets or force pushes.
- Use complete PowerShell scripts with explicit error checking, `[OK]`/`[ERROR]` feedback, and quoted paths.
- Create a PR before merging Phase 2 into `main`; do not publish alpha releases based only on a successful compile.
- Update `DEVELOPMENT_STATUS.md` with actual test evidence after each milestone; avoid duplicate progress documents.
