---
name: audio-dsp
description: Work on CarDSP equalizers, audio playback, and signal processing.
---
# Audio DSP
- Preserve existing audio processing and controller interfaces.
- Inspect EqController.cpp and EqController.hpp before modifying bindings.
- Validate frequency, gain, Q, enabled state, and band index.
- Avoid introducing clipping or sudden volume increases.
- Distinguish UI-only changes from actual DSP processing changes.
- Test using low playback volume.
