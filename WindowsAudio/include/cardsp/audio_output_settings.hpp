#pragma once

#include <string>

namespace cardsp {

enum class OutputSelectionMode {
    SystemDefault,
    SpecificDevice
};

enum class SpeakerLayoutMode {
    Automatic,
    Stereo,
    Surround51,
    Surround71
};

struct AudioOutputSettings {
    OutputSelectionMode mode =
        OutputSelectionMode::SystemDefault;

    SpeakerLayoutMode layout =
        SpeakerLayoutMode::Automatic;

    std::wstring preferredDeviceId;
};

}
