#pragma once

#include <windows.h>
#include <mmdeviceapi.h>
#include <wrl/client.h>

#include <mutex>
#include <string>

namespace cardsp {

struct AudioEndpoint {
    std::wstring id;
    std::wstring name;
    bool available = false;
};

class AudioDeviceManager {
public:
    AudioDeviceManager();

    HRESULT Initialize();
    HRESULT Refresh();

    AudioEndpoint Playback() const;
    AudioEndpoint Recording() const;

private:
    HRESULT ResolveDefault(
        EDataFlow flow,
        AudioEndpoint& endpoint
    );

    Microsoft::WRL::ComPtr<IMMDeviceEnumerator> enumerator_;

    mutable std::mutex mutex_;
    AudioEndpoint playback_;
    AudioEndpoint recording_;
};

}
