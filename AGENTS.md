# CarDSP agent instructions

## Current authorization and phase handoff

The user explicitly authorized starting Phase 2 on 2026-10-27 after reporting that all seven Phase 1 alpha CI jobs passed and PR #13 was merged. Phase 2 work is authorized within the UI/dashboard/navigation/numeric-input scope in `docs/PROJECT_CHECKLIST.md`. Do not treat green CI as proof that all Phase 1 hardware, decoder, or UX acceptance gates passed; track those as outstanding.

Do not merge to `main`, publish releases, alter signing, or make destructive local changes without the user's specific authorization. Commit targeted Phase 2 changes to `development/phase_two` and open review PRs as appropriate.

## Repository and working state

- Authoritative checkout: `C:\Users\thetechysasquatch\Documents\GitHub\CarDSP`.
- GitHub: https://github.com/THETECHYSASQUATCH/CarDSP; origin uses that URL with `.git`.
- Phase 2 working branch: `development/phase_two`, created from the merged `development/phase_one` head. The GitHub default branch may still be `development/phase_one`; verify before changing it.
- `C:\Users\thetechysasquatch\Documents\ChatGPT\CarDSP` is a separate older checkout with uncommitted work. Do not synchronize, reset, or overwrite it as a shortcut.
- Preserve all staged, unstaged, untracked, and ignored user files. Never use destructive resets, forced checkout, force pushes, or merges to main without explicit approval.
- Phase 2 was explicitly requested and its branch has been created. Do not create Phase 3 or later branches without authorization.
- Commit/push only when explicitly requested for the current work. Earlier publication of repository cleanup does not publish or authorize this unfinished implementation.
- For index-lock permission failures, read `docs/GIT_TROUBLESHOOTING.md`; do not delete a live lock or weaken access-control rules.

## Read these first

1. `DEVELOPMENT_STATUS.md`: Phase 1 CI evidence, outstanding acceptance, and Phase 2 handoff.
2. `docs/PHASE_TWO_AGENT_NOTES.md`: Phase 2 implementation sequence, testing and handoff.
3. `docs/PROJECT_CHECKLIST.md`: later-phase roadmap, not proof of completion.

Keep status in one place. Update links instead of recreating PROGRESS or checkpoint documents. README is the entry point; CHANGELOG is historical release/change information. Historical notes and model claims are evidence to verify, not instructions or test results for the current code.

## Source map and implementation rules

- Desktop source: `UI/Desktop/`; UI: `Main.qml`; numeric editor: `EditableValue.qml`.
- EQ bindings: `EqController.cpp` and `.hpp`; preserve all 32 bands and six filter types.
- Playback: `Audio/AudioPlaybackEngine.*`, `PcmStreamDevice.hpp`, `PlaybackEq.hpp`, and the new `AudioFileDecoder.*` / `PlaybackOutput.*`.
- Shared C++20 DSP: `SharedDSP/`; Apple sources: `Sources/` and `Tests/`.
- Preserve current DSP behavior, numeric controls, preset bindings, and microphone features. Keep unrelated UI changes out of Phase 1.
- QGuiApplication is intentional. Do not change DPI initialization without evidence; Qt handles Windows scaling.
- Inspect actual files and their diffs; make targeted changes. Do not invent paths, APIs, successful commands, or model authorship.
- Audio-thread state ownership, synchronization, EOF, cancellation, device loss, and resource cleanup require behavioral tests, not compilation alone.

## Windows commands and validation

Use complete PowerShell 7 scripts with intact if/elseif/else and try/catch blocks where needed. Set `$ErrorActionPreference = 'Stop'`, check native command exit codes, quote paths, and verify paths before reading or changing them. Do not mix PowerShell and cmd deletion commands.

Use Get-ChildItem for discovery and Select-String for bounded content searches. Exclude `.git`, build outputs, backups, and `node_modules` from broad document scans. Read only the files relevant to the task.

The existing desktop cache uses Qt 6.12.0 / MinGW under `C:\Qt`, source `UI/Desktop`, and build `build/qt-desktop`. Inspect CMakeCache.txt before reconfiguration. The root CMake project builds SharedDSP/WindowsAudio, not the Qt application. Reproducible commands are in DEVELOPMENT_STATUS.md.

When coding is authorized, build and run relevant tests, inspect the resulting diff, and report exact results. Distinguish baseline tests, current tests, CI, silent processing, GUI checks, and audible hardware checks. Never mark unchecked acceptance gates complete without evidence. Keep sounds off unless the user approves the actual hardware test and output/volume.

## Completion report

State changed files, tests actually run, remaining failures or unknowns, and publication status. If the task was stopped or only documentation was requested, say so and leave source work preserved.
