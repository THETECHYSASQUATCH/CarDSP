#!/usr/bin/env bash
set -euo pipefail

# Build and test both the native Qt desktop app and portable C++ DSP engine.
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

for tool in cmake ctest; do
    command -v "$tool" >/dev/null 2>&1 || { echo "Missing executable: $tool" >&2; exit 1; }
done

DESKTOP_BUILD="${CARDSP_DESKTOP_BUILD:-$ROOT/build/phase1-linux-desktop}"
CORE_BUILD="${CARDSP_CORE_BUILD:-$ROOT/build/phase1-linux-core}"
INSTALL_DIR="${CARDSP_INSTALL_DIR:-$ROOT/build/phase1-linux-install}"
BUILD_TYPE="${CARDSP_BUILD_TYPE:-Release}"
BUILD_JOBS="${CARDSP_BUILD_JOBS:-2}"

echo "Configuring Qt desktop application ($BUILD_TYPE)"
cmake -S "$ROOT/UI/Desktop" -B "$DESKTOP_BUILD" -DCMAKE_BUILD_TYPE="$BUILD_TYPE" -DBUILD_TESTING=ON
cmake --build "$DESKTOP_BUILD" --parallel "$BUILD_JOBS"
ctest --test-dir "$DESKTOP_BUILD" --output-on-failure --no-tests=error

echo "Configuring portable DSP engine ($BUILD_TYPE)"
cmake -S "$ROOT" -B "$CORE_BUILD" -DCMAKE_BUILD_TYPE="$BUILD_TYPE" -DBUILD_TESTING=ON
cmake --build "$CORE_BUILD" --parallel "$BUILD_JOBS"
ctest --test-dir "$CORE_BUILD" --output-on-failure --no-tests=error

if [[ "${CARDSP_STAGE_INSTALL:-0}" == "1" ]]; then
    echo "Staging Qt application to $INSTALL_DIR"
    cmake --install "$DESKTOP_BUILD" --prefix "$INSTALL_DIR"
    echo "Inspect and launch the staged application from: $INSTALL_DIR"
fi

echo "Phase 1 Linux builds and automated tests completed successfully."
echo "The desktop binary is under: $DESKTOP_BUILD"
echo "A successful build does not establish audible playback or clean-machine deployment."
