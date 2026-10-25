#include "cardsp/wasapi_loopback_capture.hpp"

#include <windows.h>
#include <mmdeviceapi.h>
#include <wrl/client.h>

#include <chrono>
#include <cmath>
#include <cstdint>
#include <cstring>
#include <iostream>
#include <thread>
#include <vector>

using Microsoft::WRL::ComPtr;

int wmain() {
    HRESULT hr = CoInitializeEx(nullptr, COINIT_MULTITHREADED);

    if (FAILED(hr)) {
        std::wcerr << L"COM initialization failed.\n";
        return 1;
    }

    int result = 0;

    {
        ComPtr<IMMDeviceEnumerator> enumerator;

        hr = CoCreateInstance(
            __uuidof(MMDeviceEnumerator),
            nullptr,
            CLSCTX_ALL,
            IID_PPV_ARGS(&enumerator)
        );

        if (FAILED(hr)) {
            std::wcerr << L"Device enumerator failed.\n";
            result = 1;
        } else {
            ComPtr<IMMDevice> device;

            hr = enumerator->GetDefaultAudioEndpoint(
                eRender, eMultimedia, &device
            );

            if (FAILED(hr)) {
                std::wcerr << L"No default playback device.\n";
                result = 1;
            } else {
                LPWSTR deviceId = nullptr;
                hr = device->GetId(&deviceId);

                if (FAILED(hr)) {
                    result = 1;
                } else {
                    cardsp::WasapiLoopbackCapture capture;

                    hr = capture.Initialize(deviceId);
                    CoTaskMemFree(deviceId);

                    if (FAILED(hr)) {
                        std::wcerr << L"Capture initialization failed: 0x"
                                   << std::hex << static_cast<unsigned long>(hr)
                                   << L"\n";
                        result = 1;
                    } else {
                        const auto format = capture.Format();

                        std::wcout << L"CarDSP WASAPI Loopback Capture\n";
                        std::wcout << L"Sample rate: " << format.sampleRate << L" Hz\n";
                        std::wcout << L"Channels: " << format.channels << L"\n";
                        std::wcout << L"Bits per sample: " << format.bitsPerSample << L"\n";
                        std::wcout << L"Floating point: "
                                   << (format.isFloat ? L"Yes" : L"No") << L"\n";

                        hr = capture.Start();

                        if (FAILED(hr)) {
                            std::wcerr << L"Capture start failed.\n";
                            result = 1;
                        } else {
                            uint64_t totalFrames = 0;
                            uint64_t totalPackets = 0;
                            double peak = 0.0;

                            std::wcout << L"\nCapturing for 10 seconds...\n";
                            std::wcout << L"Play some audio through the default output.\n";

                            const auto deadline =
                                std::chrono::steady_clock::now() +
                                std::chrono::seconds(10);

                            while (std::chrono::steady_clock::now() < deadline) {
                                std::vector<uint8_t> bytes;
                                uint32_t frames = 0;
                                DWORD flags = 0;

                                hr = capture.Read(bytes, frames, flags);

                                if (FAILED(hr)) {
                                    std::wcerr << L"Capture read failed: 0x"
                                               << std::hex
                                               << static_cast<unsigned long>(hr)
                                               << L"\n";
                                    result = 1;
                                    break;
                                }

                                if (hr == S_OK && frames > 0) {
                                    totalFrames += frames;
                                    ++totalPackets;

                                    if (format.isFloat &&
                                        format.bitsPerSample == 32) {
                                        const size_t samples = bytes.size() / sizeof(float);

                                        for (size_t i = 0; i < samples; ++i) {
                                            float sample = 0.0f;
                                            std::memcpy(
                                                &sample,
                                                bytes.data() + i * sizeof(float),
                                                sizeof(float)
                                            );

                                            if (std::isfinite(sample)) {
                                                peak = std::max(
                                                    peak,
                                                    static_cast<double>(std::fabs(sample))
                                                );
                                            }
                                        }
                                    }
                                }

                                std::this_thread::sleep_for(
                                    std::chrono::milliseconds(5)
                                );
                            }

                            capture.Stop();

                            std::wcout << L"\nCapture results\n";
                            std::wcout << L"Packets: " << totalPackets << L"\n";
                            std::wcout << L"Frames: " << totalFrames << L"\n";
                            std::wcout << L"Peak: " << peak << L"\n";
                        }
                    }
                }
            }
        }
    }

    CoUninitialize();
    return result;
}
