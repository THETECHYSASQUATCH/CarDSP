# CarDSP Phase 1 — local Linux build

This guide builds the **Qt desktop application** and the separate portable **C++ DSP engine**. The root CMake project alone does not build the desktop UI.

## Requirements

- A Linux development environment with CMake 3.25+, C++20 compiler and a working Qt 6.8+ toolchain.
- Qt modules: Quick, QuickControls2, QuickDialogs2, Multimedia. Install Qt development tools and the QML test runner for desktop tests.
- On Ubuntu, use a Qt installation with the corresponding development packages (such as `qt6-base-dev`, `qt6-declarative-dev`, `qt6-multimedia-dev`, `qt6-tools-dev-tools`, `qt6-qmltooling-plugins`, and the needed QML module packages); package names and availability vary by Ubuntu release. Confirm `qmltestrunner` is available. Use `CMAKE_PREFIX_PATH` or `Qt6_DIR` if CMake cannot find Qt.
- Display/audio support for a real local application launch; offscreen QML tests may not demonstrate full behavior.

## Build and test locally

```bash
git clone https://github.com/THETECHYSASQUATCH/CarDSP.git
cd CarDSP
git checkout development/phase_one
bash scripts/build-phase1-linux.sh
```

For a staging installation after passing tests:

```bash
CARDSP_STAGE_INSTALL=1 bash scripts/build-phase1-linux.sh
```

The script isolates the desktop and core build directories. Override `CARDSP_BUILD_TYPE`, `CARDSP_BUILD_JOBS`, `CARDSP_DESKTOP_BUILD`, `CARDSP_CORE_BUILD`, or `CARDSP_INSTALL_DIR` if needed.

## Run and verify

The desktop executable is `CarDSPDesktop` under `build/phase1-linux-desktop` (the location can vary by generator). Launch it from a graphical Linux session. Check the native file picker, playback and EQ controls, output selection, DSP bypass, preset persistence, microphone permissions, plug-in discovery, and close/reopen behavior.

For deployment, test the staged installation **in a clean environment** with Qt multimedia and QML runtime dependencies present. A staged directory or successful CTest run alone is not proof of portability.

This guide does not claim an APK, iOS app, signed macOS bundle, audible hardware acceptance or a complete Phase 1 release.
