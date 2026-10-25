#pragma once

#include <array>
#include <cmath>
#include <cstddef>

namespace cardsp {

// Configure routing gains while audio processing is stopped.
// No dynamic allocation occurs during processing.
template <std::size_t Inputs = 2, std::size_t Outputs = 9>
class RoutingMatrix {
public:
    using InputFrame = std::array<float, Inputs>;
    using OutputFrame = std::array<float, Outputs>;

    bool setGain(std::size_t output,
                 std::size_t input,
                 float gain) noexcept {
        if (output >= Outputs || input >= Inputs ||
            !std::isfinite(gain) ||
            gain < -4.0f || gain > 4.0f)
            return false;

        gains_[output][input] = gain;
        return true;
    }

    float gain(std::size_t output,
               std::size_t input) const noexcept {
        if (output >= Outputs || input >= Inputs)
            return 0.0f;

        return gains_[output][input];
    }

    void clear() noexcept {
        for (auto& row : gains_)
            row.fill(0.0f);
    }

    OutputFrame process(const InputFrame& input) const noexcept {
        OutputFrame output {};

        for (std::size_t out = 0; out < Outputs; ++out) {
            float sum = 0.0f;

            for (std::size_t in = 0; in < Inputs; ++in)
                sum += input[in] * gains_[out][in];

            output[out] = sum;
        }

        return output;
    }

private:
    std::array<std::array<float, Inputs>, Outputs> gains_ {};
};

} // namespace cardsp
