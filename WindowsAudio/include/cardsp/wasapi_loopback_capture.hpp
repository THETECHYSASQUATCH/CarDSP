#pragma once

#include <windows.h>
#include <audioclient.h>
#include <mmdeviceapi.h>
#include <wrl/client.h>

#include <cstdint>
#include <string>
#include <vector>

namespace cardsp {

struct CapturedAudioFormat {
    uint32_t sampleRate = 0;
    uint16_t channels = 0;
    uint16_t bitsPerSample = 0;
    uint16_t blockAlign = 0;
    bool isFloat = false;
};

class WasapiLoopbackCapture final {
public:
    WasapiLoopbackCapture() = default;
    ~WasapiLoopbackCapture();

    WasapiLoopbackCapture(const WasapiLoopbackCapture&) = delete;
    WasapiLoopbackCapture& operator=(const WasapiLoopbackCapture&) = delete;

    HRESULT Initialize(const std::wstring& endpointId);
    HRESULT Start();
    HRESULT Stop();

    // Reads available audio into the supplied buffer.
    // Buffer contains interleaved audio bytes in the endpoint mix format.
    HRESULT Read(
        std::vector<uint8_t>& buffer,
        uint32_t& framesRead,
        DWORD& flags
    );

    const CapturedAudioFormat& Format() const noexcept {
        return format_;
    }

private:
    Microsoft::WRL::ComPtr<IMMDevice> device_;
    Microsoft::WRL::ComPtr<IAudioClient> audioClient_;
    Microsoft::WRL::ComPtr<IAudioCaptureClient> captureClient_;

    WAVEFORMATEX* mixFormat_ = nullptr;
    CapturedAudioFormat format_{};
    bool started_ = false;
};

}
