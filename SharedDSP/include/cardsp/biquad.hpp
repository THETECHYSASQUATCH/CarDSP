#pragma once

#include <cmath>
#include <cstddef>

namespace cardsp {

struct BiquadCoefficients {
    float b0 {1.0f};
    float b1 {0.0f};
    float b2 {0.0f};
    float a1 {0.0f};
    float a2 {0.0f};
};

class Biquad {
public:
    void setCoefficients(const BiquadCoefficients& coefficients) noexcept {
        coefficients_ = coefficients;
        reset();
    }

    [[nodiscard]] float process(float input) noexcept {
        const float output = coefficients_.b0 * input + z1_;
        z1_ = coefficients_.b1 * input - coefficients_.a1 * output + z2_;
        z2_ = coefficients_.b2 * input - coefficients_.a2 * output;
        return output;
    }

    void process(float* samples, std::size_t frameCount) noexcept {
        for (std::size_t frame = 0; frame < frameCount; ++frame) {
            samples[frame] = process(samples[frame]);
        }
    }

    void reset() noexcept { z1_ = z2_ = 0.0f; }

private:
    BiquadCoefficients coefficients_ {};
    float z1_ {0.0f};
    float z2_ {0.0f};
};

} // namespace cardsp
