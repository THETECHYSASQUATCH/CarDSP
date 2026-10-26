#pragma once

#include <algorithm>
#include <cmath>
#include <cstddef>
#include <vector>

namespace cardsp {

// Configure only while audio processing is stopped.
// process() performs no allocations.
class DelayLine {
public:
    bool configure(float sampleRate, float maxDelayMs = 100.0f) {
        if (!std::isfinite(sampleRate) ||
            sampleRate < 8000.0f || sampleRate > 384000.0f ||
            !std::isfinite(maxDelayMs) ||
            maxDelayMs < 0.0f || maxDelayMs > 1000.0f)
            return false;

        sampleRate_ = sampleRate;
        maxDelaySamples_ = static_cast<std::size_t>(
            std::ceil(sampleRate * maxDelayMs / 1000.0f));

        buffer_.assign(maxDelaySamples_ + 2, 0.0f);
        writeIndex_ = 0;
        delaySamples_ = 0.0f;
        return true;
    }

    bool setDelayMilliseconds(float milliseconds) noexcept {
        if (buffer_.empty() ||
            !std::isfinite(milliseconds) ||
            milliseconds < 0.0f ||
            milliseconds * sampleRate_ / 1000.0f >
                static_cast<float>(maxDelaySamples_))
            return false;

        delaySamples_ = milliseconds * sampleRate_ / 1000.0f;
        return true;
    }

    // Delay in milliseconds for an acoustic path difference.
    static float distanceToMilliseconds(
        float distanceMeters,
        float speedOfSound = 343.0f) noexcept
    {
        if (!std::isfinite(distanceMeters) ||
            !std::isfinite(speedOfSound) ||
            distanceMeters < 0.0f ||
            speedOfSound <= 0.0f)
            return 0.0f;

        return 1000.0f * distanceMeters / speedOfSound;
    }

    float process(float input) noexcept {
        if (buffer_.empty())
            return input;

        buffer_[writeIndex_] = input;

        const auto integerDelay =
            static_cast<std::size_t>(delaySamples_);
        const float fraction =
            delaySamples_ - static_cast<float>(integerDelay);

        const std::size_t size = buffer_.size();

        const std::size_t index0 =
            (writeIndex_ + size - integerDelay) % size;

        const std::size_t index1 =
            (index0 + size - 1) % size;

        const float output =
            buffer_[index0] * (1.0f - fraction) +
            buffer_[index1] * fraction;

        writeIndex_ = (writeIndex_ + 1) % size;
        return output;
    }

    void reset() noexcept {
        std::fill(buffer_.begin(), buffer_.end(), 0.0f);
        writeIndex_ = 0;
    }

private:
    std::vector<float> buffer_;
    std::size_t writeIndex_ = 0;
    std::size_t maxDelaySamples_ = 0;
    float delaySamples_ = 0.0f;
    float sampleRate_ = 48000.0f;
};

} // namespace cardsp
