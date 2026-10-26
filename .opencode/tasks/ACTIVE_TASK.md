# CarDSP Active Task: 32-Band EQ

## Objective
Fix the existing 32-band equalizer layout.

## Target
UI/Desktop/Main.qml

## Requirements
- Make all 32 EQ bands accessible through horizontal scrolling.
- Replace the EQ GridLayout with a RowLayout.
- Preserve the existing Repeater delegate and all its controls.
- Preserve draggable gain sliders and editable numeric dB fields.
- Preserve existing EqController bindings.
- Preserve audio playback, volume, and DSP processing.
- Do not modify unrelated files.

## Workflow
1. Inspect the existing EQ layout.
2. Make a minimal targeted edit.
3. Review the Git diff.
4. Build with CMake.
5. Report results.

## Safety
- Do not overwrite the entire Main.qml file.
- Do not commit or push to GitHub.
- Request approval for edits and shell commands.
- Do not claim a change was made without verifying the file.
