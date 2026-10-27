# Phase 1 continuation prompt

This is a prepared prompt for a future coding session. Do not execute it merely because it is present in the repository. The latest instruction stopped coding; the user must explicitly submit this prompt or otherwise request resumption.

---

Resume Phase 1 in `C:\Users\thetechysasquatch\Documents\GitHub\CarDSP` on `development/phase_one`.

Read AGENTS.md and DEVELOPMENT_STATUS.md first. Inspect Git status, current source and the complete local diff. Do not overwrite unfinished work or switch to the separate older checkout at `C:\Users\thetechysasquatch\Documents\ChatGPT\CarDSP`.

The published baseline is c3bcdbc. Work-in-progress playback code was added afterward, built successfully, and included in the requested snapshot, but was not tested. It includes pause/resume, seek and time display, QAudioDecoder temporary-file decoding, live EQ transitions, an injectable output backend, device-removal handling, underrun retries, QML controls and CMake deployment. Treat all of these as unverified implementation attempts; do not blindly reapply generator scripts or assume they are correct.

Complete the Phase 1 acceptance checklist in DEVELOPMENT_STATUS.md. First review resource ownership, state transitions, stale signals, buffering and threading. Then add behavioral tests using the PlaybackOutput/PlaybackBackend boundary for pause/resume, seeking, stop/restart, output failures and device changes. Add real WAV/MP3/FLAC fixture tests for decoding, conversion, cancellation, malformed inputs and temporary-file cleanup. Test live EQ/bypass transitions, rapid updates, channel isolation and finite samples. Review bounded underrun recovery for duplicated/dropped audio and positions based on consumed rather than read-ahead samples.

Build with the existing Qt 6.12.0/MinGW desktop configuration; run existing and new desktop tests and SharedDSP regressions. Validate the QML controls, all 32 EQ bands, native file dialog and deployed multimedia plugins. A green Shared DSP CI run does not validate the Qt desktop application. Use complete PowerShell 7 scripts with error handling and native exit-code checks.

For audible tests, obtain the user's selected output and low-volume approval before playing sound. Verify continuous playback, audible EQ/bypass, pause/resume/seek, EOF and device disconnect/reconnect on MSI WS75 speakers and headphones/Bluetooth. If hardware access or user feedback is unavailable, finish the independently testable software work and report the exact pending hardware gates; do not mark Phase 1 complete.

Preserve existing DSP functionality, preset bindings, microphone features and numeric editing. Avoid unrelated redesigns and later-phase work. No force pushes, destructive resets, branch deletion, merges to main, or automatic phase-two branch creation. Do not commit or push unless explicitly requested for this resumed work.

Update DEVELOPMENT_STATUS.md with current, reproducible evidence and remaining failures. Keep README and CHANGELOG accurate without creating another overlapping progress document. Finish with changed files, actual build/test results, hardware evidence, unresolved work, and publication status.
