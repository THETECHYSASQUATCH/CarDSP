#include "cardsp/wasapi_loopback_capture.hpp"
#include "cardsp/stereo_processor.hpp"

#include <windows.h>
#include <mmdeviceapi.h>
#include <wrl/client.h>

#include <algorithm>
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
            __uuidof(MMDeviceEnumerator), nullptr,
            CLSCTX_ALL, IID_PPV_ARGS(&enumerator)
        );

        if (FAILED(hr)) {
            std::wcerr << L"Enumerator failed.\n";
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
                LPWSTR id = nullptr;
                hr = device->GetId(&id);

                if (FAILED(hr)) {
                    result = 1;
                } else {
                    cardsp::WasapiLoopbackCapture capture;
                    hr = capture.Initialize(id);
                    CoTaskMemFree(id);

                    if (FAILED(hr)) {
                        std::wcerr << L"Capture initialization failed: 0x"
                                   << std::hex << static_cast<unsigned long>(hr)
                                   << std::dec << L"\n";
                        result = 1;
                    } else {
                        const auto format = capture.Format();

                        if (!format.isFloat ||
                            format.bitsPerSample != 32 ||
                            format.channels != 2 ||
                            format.blockAlign != 8) {
                            std::wcerr << L"This diagnostic requires stereo Float32 audio.\n";
                            result = 1;
                        } else {
                            cardsp::StereoProcessor<> dsp;
                            dsp.setPreampDecibels(-6.0f);

                            hr = capture.Start();

                            if (FAILED(hr)) {
                                std::wcerr << L"Capture start failed.\n";
                                result = 1;
                            } else {
                                double inputPeak = 0.0;
                                double outputPeak = 0.0;
                                uint64_t framesProcessed = 0;
                                uint64_t packetsProcessed = 0;

                                std::wcout << L"CarDSP WASAPI + SharedDSP Test\n";
                                std::wcout << L"Sample rate: " << format.sampleRate << L" Hz\n";
                                std::wcout << L"Channels: " << format.channels << L"\n";
                                std::wcout << L"Preamp: -6.0 dB\n";
                                std::wcout << L"Capturing and processing for 10 seconds...\n";
                                std::wcout << L"Play audio through the default output.\n";

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
                                                   << std::dec << L"\n";
                                        result = 1;
                                        break;
                                    }

                                    if (hr == S_OK && frames > 0) {
                                        const size_t sampleCount =
                                            static_cast<size_t>(frames) * 2;

                                        std::vector<float> samples(sampleCount);

                                        for (size_t i = 0; i < sampleCount; ++i) {
                                            std::memcpy(
                                                &samples[i],
                                                bytes.data() + i * sizeof(float),
                                                sizeof(float)
                                            );

                                            if (std::isfinite(samples[i])) {
                                                inputPeak = std::max(
                                                    inputPeak,
                                                    static_cast<double>(
                                                        std::fabs(samples[i])
                                                    )
                                                );
                                            }
                                        }

                                        if (!dsp.processInterleaved(
                                                samples.data(), frames, 2)) {
                                            std::wcerr << L"DSP processing failed.\n";
                                            result = 1;
                                            break;
                                        }

                                        for (float sample : samples) {
                                            if (std::isfinite(sample)) {
                                                outputPeak = std::max(
                                                    outputPeak,
                                                    static_cast<double>(
                                                        std::fabs(sample)
                                                    )
                                                );
                                            }
                                        }

                                        framesProcessed += frames;
                                        ++packetsProcessed;
                                    }

                                    std::this_thread::sleep_for(
                                        std::chrono::milliseconds(5)
                                    );
                                }

                                capture.Stop();

                                std::wcout << L"\nDSP processing results\n";
                                std::wcout << L"Packets: " << packetsProcessed << L"\n";
                                std::wcout << L"Frames: " << framesProcessed << L"\n";
                                std::wcout << L"Input peak: " << inputPeak << L"\n";
                                std::wcout << L"Output peak: " << outputPeak << L"\n";

                                if (inputPeak > 0.0 && outputPeak > 0.0) {
                                    const double gainDb =
                                        20.0 * std::log10(outputPeak / inputPeak);

                                    std::wcout << L"Measured gain: "
                                               << gainDb << L" dB\n";
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    CoUninitialize();
    return result;
}
