#!/usr/bin/env bash
set -euo pipefail

# Phase 1: compile the native SwiftUI macOS executable and exercise Swift/C++ DSP.
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"
export DEVELOPER_DIR="${DEVELOPER_DIR:-$(xcode-select -p)}"
CONFIG="${CONFIGURATION:-release}"
echo "Xcode: $(xcodebuild -version)"
echo "Swift: $(swift --version)"
echo "Building Phase 1 macOS application ($CONFIG)"
swift build --product CarDSPApp --configuration "$CONFIG"
echo "Running Swift core tests"
swift test --configuration debug
echo "Building portable C++ DSP engine and tests"
cmake -S . -B build/phase1-macos -DCMAKE_BUILD_TYPE=Release -DCARDSP_BUILD_TESTS=ON -DCARDSP_BUILD_TOOLS=ON
cmake --build build/phase1-macos --parallel 3
ctest --test-dir build/phase1-macos --output-on-failure
echo "Phase 1 macOS build and tests passed."
echo "Run: swift run --configuration $CONFIG CarDSPApp"
