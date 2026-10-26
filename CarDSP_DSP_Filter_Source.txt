#pragma once

#include "cardsp/biquad.hpp"

#include <algorithm>
#include <array>
#include <cmath>
#include <cstddef>
#include <numbers>

namespace cardsp {

inline float decibelsToLinear(float decibels) noexcept {
    return std::pow(10.0f, decibels / 20.0f);
}

class Gain {
public:
    void setDecibels(float decibels) noexcept {
        decibels_ = decibels;
        linear_ = decibelsToLinear(decibels);
    }

    [[nodiscard]] float decibels() const noexcept { return decibels_; }
    [[nodiscard]] float linear() const noexcept { return linear_; }

    [[nodiscard]] float process(float input) const noexcept {
        return input * linear_;
    }

    void process(float* samples, std::size_t frameCount) const noexcept {
        for (std::size_t frame = 0; frame < frameCount; ++frame) {
            samples[frame] *= linear_;
        }
    }

private:
    float decibels_ {0.0f};
    float linear_ {1.0f};
};

inline BiquadCoefficients makeLowPass(float sampleRate, float frequency, float q = 0.70710678f) noexcept {
    if (!std::isfinite(sampleRate) || sampleRate < 8000 || sampleRate > 384000 ||
        !std::isfinite(frequency) || !std::isfinite(q) || q <= 0) return {};
    frequency = std::clamp(frequency, 1.0f, sampleRate * 0.499f);
    q = std::max(q, 0.001f);

    const float omega = 2.0f * std::numbers::pi_v<float> * frequency / sampleRate;
    const float cosine = std::cos(omega);
    const float sine = std::sin(omega);
    const float alpha = sine / (2.0f * q);
    const float a0 = 1.0f + alpha;

    return {
        (1.0f - cosine) * 0.5f / a0,
        (1.0f - cosine) / a0,
        (1.0f - cosine) * 0.5f / a0,
        (-2.0f * cosine) / a0,
        (1.0f - alpha) / a0
    };
}

inline BiquadCoefficients makeHighPass(float sampleRate, float frequency, float q = 0.70710678f) noexcept {
    if (!std::isfinite(sampleRate) || sampleRate < 8000 || sampleRate > 384000 ||
        !std::isfinite(frequency) || !std::isfinite(q) || q <= 0) return {};
    frequency = std::clamp(frequency, 1.0f, sampleRate * 0.499f);
    q = std::max(q, 0.001f);

    const float omega = 2.0f * std::numbers::pi_v<float> * frequency / sampleRate;
    const float cosine = std::cos(omega);
    const float sine = std::sin(omega);
    const float alpha = sine / (2.0f * q);
    const float a0 = 1.0f + alpha;

    return {
        (1.0f + cosine) * 0.5f / a0,
        -(1.0f + cosine) / a0,
        (1.0f + cosine) * 0.5f / a0,
        (-2.0f * cosine) / a0,
        (1.0f - alpha) / a0
    };
}

inline BiquadCoefficients makePeakingEQ(float sampleRate, float frequency, float q, float gainDB) noexcept {
    if (!std::isfinite(sampleRate) || sampleRate < 8000 || sampleRate > 384000 ||
        !std::isfinite(frequency) || !std::isfinite(q) || q <= 0 ||
        !std::isfinite(gainDB) || gainDB < -96 || gainDB > 96) return {};
    frequency = std::clamp(frequency, 1.0f, sampleRate * 0.499f);
    q = std::max(q, 0.001f);

    const float amplitude = std::pow(10.0f, gainDB / 40.0f);
    const float omega = 2.0f * std::numbers::pi_v<float> * frequency / sampleRate;
    const float cosine = std::cos(omega);
    const float sine = std::sin(omega);
    const float alpha = sine / (2.0f * q);
    const float a0 = 1.0f + alpha / amplitude;

    return {
        (1.0f + alpha * amplitude) / a0,
        (-2.0f * cosine) / a0,
        (1.0f - alpha * amplitude) / a0,
        (-2.0f * cosine) / a0,
        (1.0f - alpha / amplitude) / a0
    };
}

template <std::size_t MaxFilters = 40>
class FilterChain {
public:
    void clear() noexcept {
        reset();
        count_ = 0;
    }

    [[nodiscard]] bool add(const BiquadCoefficients& coefficients) noexcept {
        if (count_ >= MaxFilters) {
            return false;
        }
        filters_[count_].setCoefficients(coefficients);
        ++count_;
        return true;
    }

    [[nodiscard]] std::size_t size() const noexcept { return count_; }

    [[nodiscard]] float process(float input) noexcept {
        float output = gain_.process(input);
        for (std::size_t index = 0; index < count_; ++index) {
            output = filters_[index].process(output);
        }
        return output;
    }

    void process(float* samples, std::size_t frameCount) noexcept {
        gain_.process(samples, frameCount);
        for (std::size_t index = 0; index < count_; ++index) {
            filters_[index].process(samples, frameCount);
        }
    }

    void setPreampDecibels(float decibels) noexcept { gain_.setDecibels(decibels); }
    [[nodiscard]] float preampDecibels() const noexcept { return gain_.decibels(); }

    void reset() noexcept {
        for (std::size_t index = 0; index < count_; ++index) {
            filters_[index].reset();
        }
    }

private:
    Gain gain_ {};
    std::array<Biquad, MaxFilters> filters_ {};
    std::size_t count_ {0};
};

} // namespace cardsp
