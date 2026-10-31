# CarDSP Phase 1 — Xcode macOS build

The existing `Package.swift` defines the `CarDSPApp` SwiftUI executable, the `CarDSPCore` library and Swift tests. The repository also contains a separate C++ DSP engine in `SharedDSP`.

## Build on a Mac

Install Xcode and its command-line tools, select the active Xcode installation, and run:

```bash
git clone https://github.com/THETECHYSASQUATCH/CarDSP.git
cd CarDSP
git checkout development/phase_one
sudo xcode-select -s /Applications/Xcode.app/Contents/Developer
bash scripts/build-phase1-xcode.sh
swift run -c release CarDSPApp
```

To use the Xcode interface, open `Package.swift` in Xcode, select the `CarDSPApp` scheme and **My Mac**, then Build/Run. This builds a Swift Package executable, not a signed distributable `.app` bundle. The automated workflow builds the macOS target and runs Swift and C++ tests; it does not certify playback behavior or iOS support.

The Swift package specifies macOS 14+ and iOS 18+. iOS requires a separate app bundle target/project, provisioning and device/simulator validation. For a local macOS release bundle, add an Xcode application target with signing and asset configuration in a later phase.

If compilation fails, inspect the Xcode Phase 1 macOS Actions job and fix source/API errors before calling the build verified.
