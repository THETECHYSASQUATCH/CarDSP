#pragma once

#include <algorithm>
#include <cmath>
#include <complex>
#include <cstddef>
#include <numbers>
#include <span>
#include <vector>

namespace cardsp {

class SpectrumFFT {
public:
    static constexpr std::size_t fftSize = 2048;

    struct Band {
        double frequencyHz = 0.0;
        double decibels = -90.0;
    };

    static std::vector<Band> analyze(
        std::span<const float> samples,
        double sampleRate,
        std::size_t bandCount = 64
    ) {
        if (samples.size() < fftSize ||
            sampleRate <= 0.0 ||
            bandCount == 0) {
            return {};
        }

        std::vector<std::complex<double>> data(fftSize);

        constexpr double pi = std::numbers::pi_v<double>;

        for (std::size_t i = 0; i < fftSize; ++i) {
            const double window =
                0.5 - 0.5 * std::cos(
                    2.0 * pi * static_cast<double>(i) /
                    static_cast<double>(fftSize - 1)
                );

            data[i] = {
                static_cast<double>(samples[i]) * window,
                0.0
            };
        }

        for (std::size_t i = 1, j = 0; i < fftSize; ++i) {
            std::size_t bit = fftSize >> 1;

            for (; j & bit; bit >>= 1) {
                j ^= bit;
            }

            j ^= bit;

            if (i < j) {
                std::swap(data[i], data[j]);
            }
        }

        for (std::size_t len = 2; len <= fftSize; len <<= 1) {
            const double angle =
                -2.0 * pi / static_cast<double>(len);

            const std::complex<double> wlen(
                std::cos(angle),
                std::sin(angle)
            );

            for (std::size_t i = 0; i < fftSize; i += len) {
                std::complex<double> w(1.0, 0.0);

                for (std::size_t j = 0; j < len / 2; ++j) {
                    const auto u = data[i + j];
                    const auto v = data[i + j + len / 2] * w;

                    data[i + j] = u + v;
                    data[i + j + len / 2] = u - v;

                    w *= wlen;
                }
            }
        }

        std::vector<Band> result;
        result.reserve(bandCount);

        const double maximumFrequency =
            std::min(20000.0, sampleRate / 2.0);

        if (maximumFrequency <= 20.0) {
            return {};
        }

        for (std::size_t band = 0; band < bandCount; ++band) {
            const double low =
                20.0 * std::pow(
                    maximumFrequency / 20.0,
                    static_cast<double>(band) / bandCount
                );

            const double high =
                20.0 * std::pow(
                    maximumFrequency / 20.0,
                    static_cast<double>(band + 1) / bandCount
                );

            const auto firstBin = static_cast<std::size_t>(
                std::ceil(low * fftSize / sampleRate)
            );

            const auto lastBin = static_cast<std::size_t>(
                std::floor(high * fftSize / sampleRate)
            );

            double magnitude = 0.0;

            for (std::size_t bin = firstBin;
                 bin <= lastBin && bin <= fftSize / 2;
                 ++bin) {
                magnitude = std::max(
                    magnitude,
                    std::abs(data[bin]) / (fftSize * 0.25)
                );
            }

            const double db = 20.0 * std::log10(
                std::max(magnitude, 1e-9)
            );

            result.push_back({
                std::sqrt(low * high),
                std::clamp(db, -90.0, 0.0)
            });
        }

        return result;
    }
};

}
