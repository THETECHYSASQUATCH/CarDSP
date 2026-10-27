# CarDSP Development Instructions

- This repository is named CarDSP, without spaces.
- Repository root: C:\Users\thetechysasquatch\Documents\GitHub\CarDSP
- Windows desktop UI: UI/Desktop/
- Main QML interface: UI/Desktop/Main.qml
- Editable numeric component: UI/Desktop/EditableValue.qml
- Use Windows PowerShell-compatible commands.
- Use Get-ChildItem to discover files.
- Use Select-String for searching file contents.
- Never invent file paths. Verify that files exist before accessing them.
- Use the existing CMake configuration for Windows Qt builds.
- Do not push changes to GitHub unless explicitly instructed.
- Preserve existing DSP functionality while implementing new features.

## Local development environment

Operating system: Windows 11
Shell: PowerShell
Project root: C:\Users\thetechysasquatch\Documents\GitHub\CarDSP

This is a native Windows project, not a Linux container.

Path rules:
- Prefer repository-relative paths.
- Never invent /home/user paths.
- Never duplicate the CarDSP directory.
- Check file existence before reporting missing files.
- Read small sections to conserve the local model's context.

Important files:
- UI/Desktop/main.cpp
- UI/Desktop/Main.qml
- UI/Desktop/EqController.cpp
- UI/Desktop/EqController.hpp
- UI/Desktop/EditableValue.qml

Build command:
cmake --build build/qt-desktop --parallel 4

Safety:
- Never commit or push without explicit user authorization.
- Request approval before modifying source files.

## CarDSP Local Agent Rules

- Project: CarDSP, Qt 6 / C++ / QML audio DSP application.
- Primary operating system: Windows.
- Optional Linux environment: WSL2 Ubuntu.
- Use repository-relative file paths.
- Never invent placeholder file paths.
- Use Windows tools for Windows desktop builds.
- Use WSL only when Linux-specific tools are needed.
- QGuiApplication is intentional for the Qt Quick application.
- Qt already detects Windows 150% display scaling.
- Do not modify Qt DPI initialization without evidence.
- Current UI objective: improve responsive QML sizing.
- Preserve all 32 EQ bands and DSP functionality.
- Do not introduce unrelated features.
- Complete clear tasks without unnecessary questions.
- Ask for approval before modifying source files.
- Never commit or push without explicit authorization.


## CarDSP Local Agent Rules

- Project: CarDSP, Qt 6 / C++ / QML audio DSP application.
- Primary operating system: Windows.
- Optional Linux environment: WSL2 Ubuntu.
- Use repository-relative file paths.
- Never invent placeholder file paths.
- Use Windows tools for Windows desktop builds.
- Use WSL only when Linux-specific tools are needed.
- QGuiApplication is intentional for the Qt Quick application.
- Qt already detects Windows 150% display scaling.
- Do not modify Qt DPI initialization without evidence.
- Current UI objective: improve responsive QML sizing.
- Preserve all 32 EQ bands and DSP functionality.
- Do not introduce unrelated features.
- Complete clear tasks without unnecessary questions.
- Ask for approval before modifying source files.
- Never commit or push without explicit authorization.


## Source Code Analysis Rules

When asked to analyze a file:
- Read the actual repository file.
- Answer the exact requested question.
- Provide real source line numbers when requested.
- Quote the relevant existing properties or expressions.
- Do not replace analysis with a general project summary.
- Do not invent paths, code, or line numbers.
- Do not suggest unrelated features.
- If the task is clear, complete it without asking questions.
- If the file is too large, inspect it in smaller sections.
- Never commit or push without explicit authorization.


## Verified CarDSP Paths

Project root:
C:\Users\thetechysasquatch\Documents\GitHub\CarDSP

Main QML:
C:\Users\thetechysasquatch\Documents\GitHub\CarDSP\UI\Desktop\Main.qml

C++ entry point:
C:\Users\thetechysasquatch\Documents\GitHub\CarDSP\UI\Desktop\main.cpp

Use these exact paths when necessary.
Prefer repository-relative paths when tools support them.
Never invent /path/to/ placeholders.
Never claim a file is missing until its actual path has been checked.


## Mandatory File Path Verification

Before using the Read tool:
1. Use Glob to locate the requested file if its path is uncertain.
2. Copy the returned path exactly.
3. Never generate placeholder paths such as /path/to/.
4. Never substitute example paths for actual paths.
5. If Read fails, verify the working directory and retry with the verified path.
6. Do not report a file as missing without verifying its actual location.
7. Do not ask the user to supply a path already verified in this repository.

## Reliable CarDSP File Reading

The repository includes:

tools/Read-CarDSPFile.ps1

When a Read operation fails because of an invalid path,
use this PowerShell command:

pwsh -NoProfile -File tools/Read-CarDSPFile.ps1 -File "UI/Desktop/Main.qml" -StartLine 780 -LineCount 30

Always use repository-relative paths.

Never use /path/to/, C:\path\to\, or other example paths.

Do not modify source files unless the user approves.
Never commit or push without explicit authorization.