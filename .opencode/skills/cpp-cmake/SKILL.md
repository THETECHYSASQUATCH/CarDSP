---
name: cpp-cmake
description: Build and troubleshoot CarDSP C++ and CMake code.
---
# C++ and CMake
- Source directory: UI/Desktop.
- Build directory: build/qt-desktop.
- Use existing Qt 6 MinGW toolchain.
- Build with: cmake --build build/qt-desktop --parallel 4
- Never reconfigure from the repository root without inspecting CMakeCache.txt.
- Use clangd and compile_commands.json when available.
- Report actual compiler errors without inventing fixes.
