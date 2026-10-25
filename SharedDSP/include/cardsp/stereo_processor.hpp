#pragma once
#include "cardsp/dsp_chain.hpp"

namespace cardsp {

// Configure only while processing is stopped. Each channel owns its filter history.
// Buffer methods allocate no memory and accept exactly two Float32 channels.
template <std::size_t MaxFilters = 40>
class StereoProcessor {
public:
    bool add(const BiquadCoefficients& coefficients) noexcept {
        if (left_.size() >= MaxFilters) return false;
        const bool leftAdded = left_.add(coefficients);
        const bool rightAdded = right_.add(coefficients);
        return leftAdded && rightAdded;
    }
    void setPreampDecibels(float db) noexcept {
        left_.setPreampDecibels(db);
        right_.setPreampDecibels(db);
    }
    void reset() noexcept { left_.reset(); right_.reset(); }
    void clear() noexcept { left_.clear(); right_.clear(); }

    // Returns false without changing samples or filter state for an invalid buffer.
    bool processInterleaved(float* samples, std::size_t frames, std::size_t channels = 2) noexcept {
        if (channels != 2 || (frames && !samples)) return false;
        for (std::size_t i = 0; i < frames; ++i) {
            samples[0] = left_.process(samples[0]);
            samples[1] = right_.process(samples[1]);
            samples += 2;
        }
        return true;
    }
    bool processPlanar(float* left, float* right, std::size_t frames) noexcept {
        if (frames && (!left || !right || left == right)) return false;
        left_.process(left, frames);
        right_.process(right, frames);
        return true;
    }
private:
    FilterChain<MaxFilters> left_, right_;
};
} // namespace cardsp
