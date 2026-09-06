# CarDSP Development Log

This document records the development history of CarDSP from the initial repository commit through **v0.1.0-alpha.1**. It is intended to explain not only *what* changed, but *why* it changed and where the implementation lives in the codebase.

> Commit links below open the exact Git diff. Code links point to the current implementation on `main`. Early commits with generic messages such as `updated` or `test` are preserved as-is; for those entries, the linked commit diff is the authoritative record.

## Current code reference map

| Area | Primary code | Purpose |
| --- | --- | --- |
| DSP engine | [`RealTimeDSPEngine.swift`](Sources/CarDSPCore/RealTimeDSPEngine.swift) | Real-time stereo DSP chain, EQ, filters, gain, limiter/compressor, timing/polarity state |
| Biquad filters | [`Biquad.swift`](Sources/CarDSPCore/Biquad.swift) | Peaking EQ, HPF, LPF and band-pass biquad processing |
| Audio buffer bridge | [`AudioBufferProcessor.swift`](Sources/CarDSPCore/AudioBufferProcessor.swift) | Non-interleaved Float32 buffer processing for render callbacks |
| DSP configuration | [`DSPConfiguration.swift`](Sources/CarDSPCore/DSPConfiguration.swift) | EQ bands and DSP control/state model |
| Preset persistence | [`DSPConfiguration+Storage.swift`](Sources/CarDSPCore/DSPConfiguration+Storage.swift) | Save/load DSP configuration |
| RTA | [`RTAAnalyzer.swift`](Sources/CarDSPCore/RTAAnalyzer.swift) | Frequency-band analysis |
| Auto-EQ | [`AutoEQ.swift`](Sources/CarDSPCore/AutoEQ.swift) | Conservative measurement-assisted EQ recommendations |
| Vehicle profile | [`CarAudioProfile.swift`](Sources/CarDSPCore/CarAudioProfile.swift) | Vehicle/audio-system tuning profile data |
| Test signals | [`SignalGenerator.swift`](Sources/CarDSPCore/SignalGenerator.swift) | Pink-noise and sine/sweep generation helpers |
| Audio engine | [`AudioEngineController.swift`](Sources/CarDSPApp/AudioEngineController.swift) | AVAudioEngine lifecycle and app-owned audio routing |
| Audio session | [`AudioSessionController.swift`](Sources/CarDSPApp/AudioSessionController.swift) | Playback/measurement sessions and Bluetooth routing |
| Apple Music | [`MusicPlaybackCoordinator.swift`](Sources/CarDSPApp/MusicPlaybackCoordinator.swift) | MusicKit authorization and `ApplicationMusicPlayer` control |
| Microphone analysis | [`MicrophoneAnalyzer.swift`](Sources/CarDSPApp/MicrophoneAnalyzer.swift) | Microphone capture feeding RTA analysis |
| Main UI | [`ContentView.swift`](Sources/CarDSPApp/ContentView.swift) | Player/EQ/Analyzer navigation and app-level controls |
| EQ UI | [`EQScreen.swift`](Sources/CarDSPApp/EQScreen.swift) | 31-band EQ and DSP controls |
| Analyzer UI | [`MicrophoneAnalyzerView.swift`](Sources/CarDSPApp/MicrophoneAnalyzerView.swift) | RTA/measurement user interface |
| App entry | [`CarDSPApp.swift`](Sources/CarDSPApp/CarDSPApp.swift) | SwiftUI application entry point |
| Bundle metadata | [`Info.plist`](Sources/CarDSPApp/Info.plist) | iOS bundle/privacy metadata |
| Core tests | [`BiquadTests.swift`](Tests/CarDSPCoreTests/BiquadTests.swift) | DSP regression/unit tests |
| Package definition | [`Package.swift`](Package.swift) | Swift targets, platforms and framework linkage |
| DSP CI | [`.github/workflows/swift.yml`](.github/workflows/swift.yml) | Portable DSP Core build/tests |
| iOS CI | [`.github/workflows/ios.yml`](.github/workflows/ios.yml) | iOS Simulator compilation |
| IPA/release CI | [`.github/workflows/ipa.yml`](.github/workflows/ipa.yml) | Physical-device ARM64 IPA packaging and alpha release publishing |
| Version | [`VERSION`](VERSION) | Canonical alpha version used by release automation |

## Development milestones

### Alpha packaging and releases

CarDSP progressed from simulator/core CI to a physical-device ARM64 build and unsigned IPA artifact. The packaging workflow manually assembles `Payload/CarDSP.app`, resolves SwiftPM `Info.plist` placeholders, validates the bundle, creates a versioned IPA, uploads the Actions artifact, and publishes a GitHub prerelease. See [`.github/workflows/ipa.yml`](.github/workflows/ipa.yml), [`Info.plist`](Sources/CarDSPApp/Info.plist), and [`VERSION`](VERSION).

Key commits: [`0200f5c`](https://github.com/THETECHYSASQUATCH/CarDSP/commit/0200f5c9f4bf5fc9c615149c8d741132910b41aa), [`34a32a3`](https://github.com/THETECHYSASQUATCH/CarDSP/commit/34a32a3d25e51c46697adff166a19808baf47352), [`709cf75`](https://github.com/THETECHYSASQUATCH/CarDSP/commit/709cf75b7f30e16e978087b013835bdb1b17c0ce), [`b959b38`](https://github.com/THETECHYSASQUATCH/CarDSP/commit/b959b385c28f9f32020d26d7b366edf107b1d6f1), and [`274bd10`](https://github.com/THETECHYSASQUATCH/CarDSP/commit/274bd108b04bcad0b73899883453cf9a067fe829).

### CI and Swift 6 stabilization

CI was separated so portable DSP tests run independently of the iOS app build. Swift 6 actor/concurrency issues around AVAudioSession and MusicKit were corrected, macOS availability was raised where required for test-host compilation, iOS-only APIs/framework linkage were guarded, and a dedicated iOS Simulator workflow was added. See [`Package.swift`](Package.swift), [`AudioSessionController.swift`](Sources/CarDSPApp/AudioSessionController.swift), [`MusicPlaybackCoordinator.swift`](Sources/CarDSPApp/MusicPlaybackCoordinator.swift), [`swift.yml`](.github/workflows/swift.yml), and [`ios.yml`](.github/workflows/ios.yml).

### Real-time DSP correctness

The DSP path was changed from prototype-style processing into stateful real-time processing. Work included an allocation-free/non-interleaved buffer interface, maintaining filter state between render blocks, correcting reset behavior, fixing a reset naming collision, making coefficient changes reset stale history, and strengthening DSP regression tests. See [`RealTimeDSPEngine.swift`](Sources/CarDSPCore/RealTimeDSPEngine.swift), [`AudioBufferProcessor.swift`](Sources/CarDSPCore/AudioBufferProcessor.swift), [`Biquad.swift`](Sources/CarDSPCore/Biquad.swift), and [`BiquadTests.swift`](Tests/CarDSPCoreTests/BiquadTests.swift).

### RTA, Auto-EQ and vehicle tuning

The analyzer moved from basic frequency measurement to band-pass-assisted RTA analysis, gained a microphone-driven UI, and added conservative Auto-EQ assistance. A dedicated Kia Sportage audio profile was also introduced. See [`RTAAnalyzer.swift`](Sources/CarDSPCore/RTAAnalyzer.swift), [`AutoEQ.swift`](Sources/CarDSPCore/AutoEQ.swift), [`CarAudioProfile.swift`](Sources/CarDSPCore/CarAudioProfile.swift), [`MicrophoneAnalyzer.swift`](Sources/CarDSPApp/MicrophoneAnalyzer.swift), and [`MicrophoneAnalyzerView.swift`](Sources/CarDSPApp/MicrophoneAnalyzerView.swift).

### App/UI and audio routing

The project evolved from a DSP library into an executable SwiftUI iOS application. The app gained a working EQ screen, Player/EQ/Analyzer UI, AVAudioEngine lifecycle management, separate playback and measurement AVAudioSession modes, Bluetooth routing support, microphone analysis, and MusicKit authorization/playback coordination. See [`CarDSPApp.swift`](Sources/CarDSPApp/CarDSPApp.swift), [`ContentView.swift`](Sources/CarDSPApp/ContentView.swift), [`EQScreen.swift`](Sources/CarDSPApp/EQScreen.swift), [`AudioEngineController.swift`](Sources/CarDSPApp/AudioEngineController.swift), and [`AudioSessionController.swift`](Sources/CarDSPApp/AudioSessionController.swift).

## Complete commit ledger

Newest first. Each commit hash links to the exact code diff.

| # | Commit | Change and purpose | Code / area |
| ---: | --- | --- | --- |
| 64 | [`274bd10`](https://github.com/THETECHYSASQUATCH/CarDSP/commit/274bd108b04bcad0b73899883453cf9a067fe829) | **Publish versioned alpha IPA releases.** Reads `VERSION`, names the IPA by version, gives the workflow release permission, updates the bundle version, and creates/updates a GitHub prerelease with the IPA attached. | `VERSION`, `ipa.yml`, `Info.plist` |
| 63 | [`b959b38`](https://github.com/THETECHYSASQUATCH/CarDSP/commit/b959b385c28f9f32020d26d7b366edf107b1d6f1) | **Update README for first alpha IPA release.** Documents alpha status, build/sign/install expectations and current feature coverage. | `README.md` |
| 62 | [`709cf75`](https://github.com/THETECHYSASQUATCH/CarDSP/commit/709cf75b7f30e16e978087b013835bdb1b17c0ce) | **Set initial CarDSP alpha version.** Establishes `0.1.0-alpha.1` as the canonical release version. | `VERSION` |
| 61 | [`34a32a3`](https://github.com/THETECHYSASQUATCH/CarDSP/commit/34a32a3d25e51c46697adff166a19808baf47352) | **Fix IPA Info.plist placeholder packaging.** Replaces the unresolved development-language placeholder before validating the manually assembled app bundle. | `ipa.yml`, `Info.plist` |
| 60 | [`0200f5c`](https://github.com/THETECHYSASQUATCH/CarDSP/commit/0200f5c9f4bf5fc9c615149c8d741132910b41aa) | **Add unsigned iOS IPA build workflow.** Builds `arm64-apple-ios`, assembles `Payload/CarDSP.app`, creates an unsigned IPA and uploads it as an Actions artifact. | `ipa.yml`, `Package.swift`, `Info.plist` |
| 59 | [`c514ccf`](https://github.com/THETECHYSASQUATCH/CarDSP/commit/c514ccf6501c356a7c9aa50e01f97ab538248607) | **Condition UIKit linking to iOS.** Prevents the macOS DSP test host from attempting to link UIKit while retaining UIKit for the iOS app. | `Package.swift` |
| 58 | [`75ff958`](https://github.com/THETECHYSASQUATCH/CarDSP/commit/75ff9584ee0801717a14bb1ceb8635861f67326e) | **Guard iOS audio-session APIs from macOS tests.** Wraps AVAudioSession-specific behavior by platform so portable core/test builds work on macOS. | `AudioSessionController.swift` |
| 57 | [`ea31d5c`](https://github.com/THETECHYSASQUATCH/CarDSP/commit/ea31d5cfa54329de43fae8ed86f34488bb3d2e9a) | **Raise macOS target for MusicKit Song playback.** Resolves API availability errors when the package is compiled by the macOS CI host. | `Package.swift`, `MusicPlaybackCoordinator.swift` |
| 56 | [`07d3d1a`](https://github.com/THETECHYSASQUATCH/CarDSP/commit/07d3d1a21eaf24fa216778df9562e79f00c7e1e7) | **Fix DSP Core macOS deployment target.** Adds/adjusts macOS platform compatibility needed for Swift Package CI. | `Package.swift` |
| 55 | [`37d3e6a`](https://github.com/THETECHYSASQUATCH/CarDSP/commit/37d3e6a197dae4ed1b7fcbfc454ece6e001acf1b) | **Fix Swift 6 MusicKit concurrency import.** Uses the compatibility import strategy needed for MusicKit under Swift 6 concurrency checking. | `MusicPlaybackCoordinator.swift` |
| 54 | [`2373d71`](https://github.com/THETECHYSASQUATCH/CarDSP/commit/2373d712b3ee5262e7e4a03d96bc82f06a8167e2) | **Fix audio-session method call.** Corrects the app call site to match the session-controller API. | `AudioEngineController.swift`, `AudioSessionController.swift` |
| 53 | [`7e11b4d`](https://github.com/THETECHYSASQUATCH/CarDSP/commit/7e11b4deaceabd36302d626f67b30a087b2b4b5e) | **Fix Swift 6 audio-session isolation.** Makes the audio-session controller main-actor isolated to satisfy Swift 6 concurrency rules. | `AudioSessionController.swift` |
| 52 | [`956b64a`](https://github.com/THETECHYSASQUATCH/CarDSP/commit/956b64ade6ccebe424629670cc8227eae20477b0) | **Split CI: add iOS Simulator build.** Adds an independent iOS app compilation check. | `ios.yml` |
| 51 | [`4e210e6`](https://github.com/THETECHYSASQUATCH/CarDSP/commit/4e210e62c6ec83a4e27d025e47653a18b96985fa) | **Split CI: isolate DSP core tests.** Separates platform-neutral DSP validation from the iOS application build. | `swift.yml` |
| 50 | [`6fca679`](https://github.com/THETECHYSASQUATCH/CarDSP/commit/6fca679ccbf3e7daa4bc27ce0e24df37a6c957cb) | **Fix RealTimeDSPEngine reset-state naming collision.** Removes a compile/API collision in DSP reset handling. | `RealTimeDSPEngine.swift` |
| 49 | [`a848aba`](https://github.com/THETECHYSASQUATCH/CarDSP/commit/a848aba8ce796d8876a593aa065b0e76f517b999) | **Fix Swift 6 core-test workflow command.** Corrects the CI invocation used for the portable DSP test target. | `swift.yml` |
| 48 | [`20b0ecf`](https://github.com/THETECHYSASQUATCH/CarDSP/commit/20b0ecf1d75efcbc7e9e598f0e9402cf60f62127) | **Fix Biquad Float type error and reset state on coefficient changes.** Makes coefficient math explicitly Float-safe, changes state handling, and clears stale filter history when a filter is reconfigured. | `Biquad.swift` |
| 47 | [`e72d727`](https://github.com/THETECHYSASQUATCH/CarDSP/commit/e72d7270257ac1ba1655329273cbedb083126d01) | **Add non-interleaved realtime DSP render API.** Provides a render-friendly channel-buffer entry point for real-time audio. | `AudioBufferProcessor.swift`, `RealTimeDSPEngine.swift` |
| 46 | [`dcb85dc`](https://github.com/THETECHYSASQUATCH/CarDSP/commit/dcb85dc7e2564361921443477df80ba3f8cbea5a) | **Fix audio-session API mismatch in app.** Aligns app audio-engine calls with the session-controller interface. | `AudioEngineController.swift`, `AudioSessionController.swift` |
| 45 | [`03e176a`](https://github.com/THETECHYSASQUATCH/CarDSP/commit/03e176af575cff17122d9bb89ee7cd749217068e) | **Fix EQ screen API references.** Updates UI references to the current DSP configuration/engine API. | `EQScreen.swift`, `DSPConfiguration.swift` |
| 44 | [`4d9cf44`](https://github.com/THETECHYSASQUATCH/CarDSP/commit/4d9cf44727ea3dcb6e04a8e3439f744c8ef7ebda) | **Correct DSP reset buffer clearing.** Fixes clearing of internal DSP delay/state buffers. | `RealTimeDSPEngine.swift` |
| 43 | [`fe48067`](https://github.com/THETECHYSASQUATCH/CarDSP/commit/fe48067ae030bfc2a09e7e6c6e650ad76f5188bc) | **Finalize DSP state reset and realtime processing correctness.** Tightens persistent state/reset behavior used by streaming audio. | `RealTimeDSPEngine.swift`, `Biquad.swift` |
| 42 | [`b1baed9`](https://github.com/THETECHYSASQUATCH/CarDSP/commit/b1baed9404bff853e6971f6e38b85238600be7da) | **Run only portable CarDSPCore tests in CI.** Stops app/platform-specific code from blocking DSP regression testing. | `swift.yml`, `BiquadTests.swift` |
| 41 | [`713b066`](https://github.com/THETECHYSASQUATCH/CarDSP/commit/713b0668ed16ae05b360c1d4e7ac0525194a105f) | **Fix audio engine lifecycle and DSP app integration.** Reworks AVAudioEngine ownership/start/stop behavior and connects it to the core DSP type. | `AudioEngineController.swift`, `RealTimeDSPEngine.swift` |
| 40 | [`c79111e`](https://github.com/THETECHYSASQUATCH/CarDSP/commit/c79111e2f7230b99aea796c835e249c43c07fab1) | **Fix app DSP view-model and audio-engine integration.** Aligns UI state with DSP/audio controller ownership and APIs. | `ContentView.swift`, `AudioEngineController.swift`, `DSPConfiguration.swift` |
| 39 | [`b6c5c9c`](https://github.com/THETECHYSASQUATCH/CarDSP/commit/b6c5c9c08ff2ed45ff29d3707d384cdd6c12ae92) | **Expand DSP regression tests.** Adds coverage around filters/processing behavior to catch DSP regressions. | `BiquadTests.swift`, `Biquad.swift` |
| 38 | [`0c64122`](https://github.com/THETECHYSASQUATCH/CarDSP/commit/0c641222d9fe74ce7e1d2d8cb760aa38e5900e09) | **Fix CI to test portable DSP core.** Refocuses CI on code that can be validated reliably on the runner. | `swift.yml` |
| 37 | [`a979bf1`](https://github.com/THETECHYSASQUATCH/CarDSP/commit/a979bf104c5a16e10ad2af285fc5a6bea0e3c372) | **Fix audio-engine imports and session lifecycle.** Corrects framework imports and audio startup/shutdown behavior. | `AudioEngineController.swift`, `AudioSessionController.swift` |
| 36 | [`00239a0`](https://github.com/THETECHYSASQUATCH/CarDSP/commit/00239a0aaec132a731ddfe0d49003789276d093f) | **Fix microphone analyzer concurrency and session setup.** Makes microphone measurement conform to actor/session requirements. | `MicrophoneAnalyzer.swift`, `AudioSessionController.swift` |
| 35 | [`c38cc00`](https://github.com/THETECHYSASQUATCH/CarDSP/commit/c38cc00c5d0dba89f28ae3c4e2d4b15f4d53ab60) | **Separate playback and measurement audio-session modes.** Gives normal playback and microphone measurement distinct AVAudioSession configurations. | `AudioSessionController.swift` |
| 34 | [`6cd50ce`](https://github.com/THETECHYSASQUATCH/CarDSP/commit/6cd50ce1425becb469b75565b1165a2282153b77) | **Fix app imports and playback-session usage.** Cleans app-side framework dependencies and session invocation. | `ContentView.swift`, `AudioEngineController.swift`, `AudioSessionController.swift` |
| 33 | [`7063c91`](https://github.com/THETECHYSASQUATCH/CarDSP/commit/7063c91d7b9fe6296b93d9277a7fd96e413c479d) | **Fix RTA view dependencies.** Corrects module/type dependencies needed by the analyzer UI. | `MicrophoneAnalyzerView.swift`, `RTAAnalyzer.swift` |
| 32 | [`cdb51c9`](https://github.com/THETECHYSASQUATCH/CarDSP/commit/cdb51c9220bee740c36319d283d4810d035bb408) | **Add RTA analyzer UI.** Adds an interactive view for microphone/frequency analysis. | `MicrophoneAnalyzerView.swift`, `MicrophoneAnalyzer.swift`, `RTAAnalyzer.swift` |
| 31 | [`a444f85`](https://github.com/THETECHYSASQUATCH/CarDSP/commit/a444f85fb2e5947a3130aaaf01cabf11df76694f) | **Add conservative Auto-EQ measurement assist.** Converts analyzer measurements into bounded EQ recommendations rather than aggressive automatic correction. | `AutoEQ.swift`, `DSPConfiguration.swift` |
| 30 | [`598090d`](https://github.com/THETECHYSASQUATCH/CarDSP/commit/598090d54c268003419b806b493102f1f9d7ed86) | **Add Kia Sportage audio profile.** Introduces vehicle/system-specific tuning/profile data. | `CarAudioProfile.swift` |
| 29 | [`fbc60fa`](https://github.com/THETECHYSASQUATCH/CarDSP/commit/fbc60fa480e5184f18072937fa5a63abbb209285) | **Fix EQ screen bindings.** Repairs SwiftUI bindings between sliders/toggles and DSP configuration. | `EQScreen.swift`, `DSPConfiguration.swift` |
| 28 | [`7301420`](https://github.com/THETECHYSASQUATCH/CarDSP/commit/7301420c30ab295cd7ac8c06c214418f37cf6d42) | **Add working EQ screen.** Adds interactive EQ/filter/processing controls to the app. | `EQScreen.swift`, `ContentView.swift` |
| 27 | [`a6fad83`](https://github.com/THETECHYSASQUATCH/CarDSP/commit/a6fad83fd1adb927bf22f4a2f0ef2a06349252f6) | **Fix RTA frequency measurement.** Corrects analyzer calculations used to estimate band energy. | `RTAAnalyzer.swift` |
| 26 | [`c59c68e`](https://github.com/THETECHYSASQUATCH/CarDSP/commit/c59c68ef04606a2b5a5f9952324fd813ec9f6f9c) | **Add band-pass filter for accurate RTA analysis.** Adds a biquad band-pass mode used to isolate analysis bands. | `Biquad.swift`, `RTAAnalyzer.swift` |
| 25 | [`8a41993`](https://github.com/THETECHYSASQUATCH/CarDSP/commit/8a419930af797f11ca70e7b454cf67957a0f1d67) | **Correct DSP state reset implementation.** Repairs state-clearing behavior inside the real-time engine. | `RealTimeDSPEngine.swift` |
| 24 | [`1b6d2ba`](https://github.com/THETECHYSASQUATCH/CarDSP/commit/1b6d2ba40f61d36c65f4ec845d34300d234f6468) | **Fix DSP state continuity and real-time processing.** Preserves filter/delay history across audio blocks instead of treating each block as independent audio. | `RealTimeDSPEngine.swift`, `Biquad.swift` |
| 23 | [`277120d`](https://github.com/THETECHYSASQUATCH/CarDSP/commit/277120d6e45f5feaf67320f56ab1d5d5038860cc) | **Add executable iOS app target dependencies for Phase 2 DSP.** Expands the package from a library-only structure to include the application target/framework dependencies. | `Package.swift`, `CarDSPApp.swift` |
| 22 | [`3a4eb80`](https://github.com/THETECHYSASQUATCH/CarDSP/commit/3a4eb80c39023a899d22428bee8db6d77aecc328) | **Add allocation-free real-time DSP buffer adapter.** Introduces a processing bridge designed to avoid per-buffer allocation in the render path. | `AudioBufferProcessor.swift`, `RealTimeDSPEngine.swift` |
| 21 | [`f811c6f`](https://github.com/THETECHYSASQUATCH/CarDSP/commit/f811c6f1150def4d31b280f137dce6a00ed9532c) | **Fix audio-engine architecture and prepare real-time DSP routing.** Restructures app audio plumbing for future render integration. | `AudioEngineController.swift`, `RealTimeDSPEngine.swift` |
| 20 | [`5689a51`](https://github.com/THETECHYSASQUATCH/CarDSP/commit/5689a51e1ce6d037f1c5b594f239f634fd1fd154) | **Package.swift syntax repair (`Added )`).** Fixes a manifest syntax error during deployment-target work. | `Package.swift` |
| 19 | [`dd66d13`](https://github.com/THETECHYSASQUATCH/CarDSP/commit/dd66d13fd1e7fea88f7a05e6d3bdbf2ec3d5ed7e) | **Change iOS version in package manifest.** Iterates the deployment target while resolving build compatibility. | `Package.swift` |
| 18 | [`e6981c7`](https://github.com/THETECHYSASQUATCH/CarDSP/commit/e6981c7df07028405c6c936c4b27c9d485ac1af7) | **Update Package.swift.** Package/deployment-target iteration; exact change is preserved in the linked diff. | `Package.swift` |
| 17 | [`809c9d4`](https://github.com/THETECHYSASQUATCH/CarDSP/commit/809c9d408909141f9a170b38f87e648c12519fbe) | **Update iOS deployment target to 26.0.** Build-compatibility iteration in the package manifest. | `Package.swift` |
| 16 | [`8d60545`](https://github.com/THETECHYSASQUATCH/CarDSP/commit/8d605454d75a46c892d96e68a7f351f48bf82d6f) | **Update iOS deployment target to 26.0.** Earlier deployment-target correction. | `Package.swift` |
| 15 | [`df6f6ff`](https://github.com/THETECHYSASQUATCH/CarDSP/commit/df6f6ff077395ffbed0717a1ea39194f39fd4f30) | **Add availability annotation to MicrophoneAnalyzer.** Resolves ObservableObject/API availability compilation issues. | `MicrophoneAnalyzer.swift` |
| 14 | [`1fed348`](https://github.com/THETECHYSASQUATCH/CarDSP/commit/1fed3487fcf14783c5a225fe8db43443fa80785a) | **Add iOS 16 availability to MusicPlaybackCoordinator.** Matches the coordinator to the MusicKit APIs it uses. | `MusicPlaybackCoordinator.swift` |
| 13 | [`9e4a5f0`](https://github.com/THETECHYSASQUATCH/CarDSP/commit/9e4a5f0a285e820140895f22ccd3fc5e1ef8b86d) | **Add GitHub Actions workflow for Swift build and tests.** Establishes the project's first automated Swift CI. | `swift.yml` |
| 12 | [`0ece4a1`](https://github.com/THETECHYSASQUATCH/CarDSP/commit/0ece4a1c5eab229c8a517f5e76b4b671f87458b7) | **Target iOS 16 minimum.** Adjusts the package platform around MusicKit/app API availability. | `Package.swift` |
| 11 | [`b9c0b6d`](https://github.com/THETECHYSASQUATCH/CarDSP/commit/b9c0b6de1764bff3b4a5906e66ff2175561e075f) | **Fix MicrophoneAnalyzer for iOS 16+ compatibility.** Updates microphone-analysis implementation to match the chosen platform/API level. | `MicrophoneAnalyzer.swift` |
| 10 | [`02420da`](https://github.com/THETECHYSASQUATCH/CarDSP/commit/02420dae86b2b2c5e79d78497b72e038bcf601e2) | **Fix MusicPlaybackCoordinator for iOS 16+ compatibility.** Updates MusicKit usage for the package's supported iOS API level. | `MusicPlaybackCoordinator.swift` |
| 9 | [`90eac38`](https://github.com/THETECHYSASQUATCH/CarDSP/commit/90eac38f8ab7041069f5c44483f38d6a8d614030) | **Add DSPConfiguration load/save helpers.** Adds preset/configuration persistence. | `DSPConfiguration+Storage.swift`, `DSPConfiguration.swift` |
| 8 | [`f6afe8f`](https://github.com/THETECHYSASQUATCH/CarDSP/commit/f6afe8fcbf87f6e13ebb1bbb4c7a019aa1d88366) | **Move SwiftUI view out of DSPViewModel, add ContentView and expose engine.** Separates UI and model responsibilities and establishes the app's main view structure. | `ContentView.swift`, `DSPConfiguration.swift` |
| 7 | [`bef5444`](https://github.com/THETECHYSASQUATCH/CarDSP/commit/bef5444c01c3e458c5ecfd68c8e04fe490b463f0) | **`test` checkpoint.** Early repository test/checkpoint commit; use the linked diff for its exact snapshot. | Early project files |
| 6 | [`8dcd283`](https://github.com/THETECHYSASQUATCH/CarDSP/commit/8dcd283ce605542c5a02ee73ba520c27ae76e597) | **`updated` checkpoint.** Early iterative project update; exact files are preserved in the linked diff. | Early project files |
| 5 | [`f8f9613`](https://github.com/THETECHYSASQUATCH/CarDSP/commit/f8f96131088b841347d93424b90930bc8e017afa) | **`Fixed_bad_files`.** Repairs early source/package files during repository bring-up. | Early project files / package structure |
| 4 | [`94709b5`](https://github.com/THETECHYSASQUATCH/CarDSP/commit/94709b5ccf1b19ae9518062c8a4014be4f5b1fb6) | **`updated_files`.** Early source update; linked diff is the authoritative record. | Early project files |
| 3 | [`2cdefcf`](https://github.com/THETECHYSASQUATCH/CarDSP/commit/2cdefcf8b9cf48a4ebf2056d7e58232c27adbfdf) | **Added new code.** Expands the initial project implementation. | Early DSP/app sources |
| 2 | [`577b8c1`](https://github.com/THETECHYSASQUATCH/CarDSP/commit/577b8c111da804d8af0629492b7c1dc787d1938c) | **Fixed Layout.** Early project/source layout correction. | Repository/source layout |
| 1 | [`90659c2`](https://github.com/THETECHYSASQUATCH/CarDSP/commit/90659c213f1f6a5bce699d80143ec2d0955159e7) | **Initial repository commit (`New files`).** Creates the Swift 6 package, initial README and Phase 2 DSP project foundation. | `Package.swift`, `README.md`, initial Phase 2 archive |

## Current alpha state

At `v0.1.0-alpha.1`, the repository contains a Swift 6 DSP core, SwiftUI iOS application shell, MusicKit coordinator, microphone/RTA path, EQ/vehicle tuning components, separated CI, physical-device ARM64 compilation and automated unsigned IPA prerelease packaging.

The unsigned IPA intentionally does **not** contain an Apple development/distribution signature. Signing and provisioning are a separate installation step and depend on the Apple team/account used for testing.

## How to use this log

- For the **exact historical code change**, open the commit hash in the ledger.
- For the **current implementation**, open the linked source file in the code-reference map.
- For build failures, start with [`swift.yml`](.github/workflows/swift.yml), [`ios.yml`](.github/workflows/ios.yml), or [`ipa.yml`](.github/workflows/ipa.yml), depending on which CI job failed.
- For audio/DSP bugs, start with [`RealTimeDSPEngine.swift`](Sources/CarDSPCore/RealTimeDSPEngine.swift), [`Biquad.swift`](Sources/CarDSPCore/Biquad.swift), and [`AudioEngineController.swift`](Sources/CarDSPApp/AudioEngineController.swift).

This file should be updated with each future release or meaningful implementation commit so the alpha/beta history remains auditable.
