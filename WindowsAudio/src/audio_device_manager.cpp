#include "cardsp/audio_device_manager.hpp"

#include <functiondiscoverykeys_devpkey.h>

namespace cardsp {

AudioDeviceManager::AudioDeviceManager() = default;

HRESULT AudioDeviceManager::Initialize() {
    HRESULT hr = CoCreateInstance(
        __uuidof(MMDeviceEnumerator),
        nullptr,
        CLSCTX_ALL,
        IID_PPV_ARGS(&enumerator_)
    );

    if (FAILED(hr)) return hr;

    return Refresh();
}

HRESULT AudioDeviceManager::ResolveDefault(
    EDataFlow flow,
    AudioEndpoint& endpoint
) {
    endpoint = {};

    if (!enumerator_) return E_UNEXPECTED;

    Microsoft::WRL::ComPtr<IMMDevice> device;

    HRESULT hr = enumerator_->GetDefaultAudioEndpoint(
        flow,
        eMultimedia,
        &device
    );

    if (FAILED(hr)) return hr;

    LPWSTR id = nullptr;
    hr = device->GetId(&id);

    if (FAILED(hr)) return hr;

    endpoint.id = id;
    CoTaskMemFree(id);

    Microsoft::WRL::ComPtr<IPropertyStore> properties;

    if (SUCCEEDED(device->OpenPropertyStore(
        STGM_READ,
        &properties
    ))) {
        PROPVARIANT name;
        PropVariantInit(&name);

        if (SUCCEEDED(properties->GetValue(
            PKEY_Device_FriendlyName,
            &name
        ))) {
            if (name.vt == VT_LPWSTR && name.pwszVal) {
                endpoint.name = name.pwszVal;
            }
        }

        PropVariantClear(&name);
    }

    endpoint.available = true;
    return S_OK;
}

HRESULT AudioDeviceManager::Refresh() {
    AudioEndpoint playback;
    AudioEndpoint recording;

    HRESULT playbackHr = ResolveDefault(eRender, playback);
    HRESULT recordingHr = ResolveDefault(eCapture, recording);

    {
        std::lock_guard<std::mutex> lock(mutex_);
        playback_ = std::move(playback);
        recording_ = std::move(recording);
    }

    if (FAILED(playbackHr)) return playbackHr;
    if (FAILED(recordingHr)) return recordingHr;

    return S_OK;
}

AudioEndpoint AudioDeviceManager::Playback() const {
    std::lock_guard<std::mutex> lock(mutex_);
    return playback_;
}

AudioEndpoint AudioDeviceManager::Recording() const {
    std::lock_guard<std::mutex> lock(mutex_);
    return recording_;
}

}
