#include "cardsp/wasapi_loopback_capture.hpp"

#include <cstring>
#include <ksmedia.h>
#include <limits>

namespace cardsp {

WasapiLoopbackCapture::~WasapiLoopbackCapture() {
    Stop();

    captureClient_.Reset();
    audioClient_.Reset();
    device_.Reset();

    if (mixFormat_) {
        CoTaskMemFree(mixFormat_);
        mixFormat_ = nullptr;
    }
}

HRESULT WasapiLoopbackCapture::Initialize(
    const std::wstring& endpointId
) {
    if (started_) return AUDCLNT_E_NOT_STOPPED;
    if (endpointId.empty()) return E_INVALIDARG;

    captureClient_.Reset();
    audioClient_.Reset();
    device_.Reset();

    if (mixFormat_) {
        CoTaskMemFree(mixFormat_);
        mixFormat_ = nullptr;
    }

    format_ = {};

    Microsoft::WRL::ComPtr<IMMDeviceEnumerator> enumerator;

    HRESULT hr = CoCreateInstance(
        __uuidof(MMDeviceEnumerator),
        nullptr,
        CLSCTX_ALL,
        IID_PPV_ARGS(&enumerator)
    );

    if (FAILED(hr)) return hr;

    hr = enumerator->GetDevice(endpointId.c_str(), &device_);
    if (FAILED(hr)) return hr;

    hr = device_->Activate(
        __uuidof(IAudioClient),
        CLSCTX_ALL,
        nullptr,
        reinterpret_cast<void**>(audioClient_.GetAddressOf())
    );

    if (FAILED(hr)) return hr;

    hr = audioClient_->GetMixFormat(&mixFormat_);
    if (FAILED(hr)) return hr;

    format_.sampleRate = mixFormat_->nSamplesPerSec;
    format_.channels = mixFormat_->nChannels;
    format_.bitsPerSample = mixFormat_->wBitsPerSample;
    format_.blockAlign = mixFormat_->nBlockAlign;

    if (mixFormat_->wFormatTag == WAVE_FORMAT_IEEE_FLOAT) {
        format_.isFloat = true;
    }

    if (mixFormat_->wFormatTag == WAVE_FORMAT_EXTENSIBLE &&
        mixFormat_->cbSize >= sizeof(WAVEFORMATEXTENSIBLE) - sizeof(WAVEFORMATEX)) {
        const auto* extensible =
            reinterpret_cast<const WAVEFORMATEXTENSIBLE*>(mixFormat_);

        format_.isFloat =
            IsEqualGUID(extensible->SubFormat, KSDATAFORMAT_SUBTYPE_IEEE_FLOAT);
    }

    hr = audioClient_->Initialize(
        AUDCLNT_SHAREMODE_SHARED,
        AUDCLNT_STREAMFLAGS_LOOPBACK,
        1000000,
        0,
        mixFormat_,
        nullptr
    );

    if (FAILED(hr)) return hr;

    return audioClient_->GetService(
        IID_PPV_ARGS(&captureClient_)
    );
}

HRESULT WasapiLoopbackCapture::Start() {
    if (!audioClient_ || !captureClient_) return E_UNEXPECTED;
    if (started_) return S_FALSE;

    HRESULT hr = audioClient_->Start();

    if (SUCCEEDED(hr)) started_ = true;
    return hr;
}

HRESULT WasapiLoopbackCapture::Stop() {
    if (!audioClient_ || !started_) return S_FALSE;

    HRESULT hr = audioClient_->Stop();

    if (SUCCEEDED(hr)) started_ = false;
    return hr;
}

HRESULT WasapiLoopbackCapture::Read(
    std::vector<uint8_t>& buffer,
    uint32_t& framesRead,
    DWORD& flags
) {
    buffer.clear();
    framesRead = 0;
    flags = 0;

    if (!started_ || !captureClient_) return E_UNEXPECTED;

    UINT32 packetFrames = 0;
    HRESULT hr = captureClient_->GetNextPacketSize(&packetFrames);

    if (FAILED(hr)) return hr;
    if (packetFrames == 0) return S_FALSE;

    BYTE* data = nullptr;
    UINT32 frames = 0;
    DWORD packetFlags = 0;

    hr = captureClient_->GetBuffer(
        &data, &frames, &packetFlags, nullptr, nullptr
    );

    if (FAILED(hr)) return hr;

    const size_t byteCount =
        static_cast<size_t>(frames) * format_.blockAlign;

    if (packetFlags & AUDCLNT_BUFFERFLAGS_SILENT) {
        buffer.assign(byteCount, 0);
    } else {
        buffer.resize(byteCount);
        std::memcpy(buffer.data(), data, byteCount);
    }

    hr = captureClient_->ReleaseBuffer(frames);

    if (FAILED(hr)) {
        buffer.clear();
        return hr;
    }

    framesRead = frames;
    flags = packetFlags;

    return S_OK;
}

}
