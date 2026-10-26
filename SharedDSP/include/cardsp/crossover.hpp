#pragma once

#include "cardsp/dsp_chain.hpp"

#include <array>
#include <cmath>
#include <cstddef>
#include <numbers>

namespace cardsp {

enum class CrossoverType {
    Butterworth,
    LinkwitzRiley
};

enum class CrossoverMode {
    HighPass,
    LowPass
};

struct CrossoverSettings {
    bool enabled = false;
    float frequency = 80.0f;
    int slope = 24;
    CrossoverType type = CrossoverType::LinkwitzRiley;
};

class Crossover {
public:
    static constexpr std::size_t MaxStages = 8;

    bool configure(float sampleRate,
                   CrossoverMode mode,
                   const CrossoverSettings& settings) noexcept
    {
        if (!std::isfinite(sampleRate) ||
            sampleRate < 8000.0f ||
            sampleRate > 384000.0f ||
            !std::isfinite(settings.frequency) ||
            settings.frequency < 1.0f ||
            settings.frequency >= sampleRate * 0.499f) {
            return false;
        }

        if (!settings.enabled) {
            stages_ = {};
            count_ = 0;
            return true;
        }

        if (settings.type == CrossoverType::LinkwitzRiley) {
            if (settings.slope != 24 && settings.slope != 48)
                return false;
        } else {
            if (settings.slope != 12 &&
                settings.slope != 24 &&
                settings.slope != 36 &&
                settings.slope != 48)
                return false;
        }

        const int order = settings.slope / 6;
        const int stageCount = order / 2;

        if (stageCount > static_cast<int>(MaxStages))
            return false;

        std::array<BiquadCoefficients, MaxStages> coefficients {};

        for (int stage = 0; stage < stageCount; ++stage) {
            float q = 0.70710678f;

            if (settings.type == CrossoverType::Butterworth) {
                const float angle =
                    std::numbers::pi_v<float> *
                    (2.0f * stage + 1.0f) /
                    (2.0f * order);

                q = 1.0f / (2.0f * std::cos(angle));
            } else {
                const int baseOrder = order / 2;
                const int baseStage = stage % (baseOrder / 2);

                const float angle =
                    std::numbers::pi_v<float> *
                    (2.0f * baseStage + 1.0f) /
                    (2.0f * baseOrder);

                q = 1.0f / (2.0f * std::cos(angle));
            }

            coefficients[stage] =
                mode == CrossoverMode::HighPass
                    ? makeHighPass(sampleRate, settings.frequency, q)
                    : makeLowPass(sampleRate, settings.frequency, q);
        }

        for (int stage = 0; stage < stageCount; ++stage)
            stages_[stage].setCoefficients(coefficients[stage]);

        count_ = static_cast<std::size_t>(stageCount);
        return true;
    }

    float process(float sample) noexcept {
        for (std::size_t i = 0; i < count_; ++i)
            sample = stages_[i].process(sample);
        return sample;
    }

    void reset() noexcept {
        for (std::size_t i = 0; i < count_; ++i)
            stages_[i].reset();
    }

    std::size_t stageCount() const noexcept {
        return count_;
    }

private:
    std::array<Biquad, MaxStages> stages_ {};
    std::size_t count_ = 0;
};

class ChannelCrossover {
public:
    bool configure(float sampleRate,
                   const CrossoverSettings& highPass,
                   const CrossoverSettings& lowPass) noexcept
    {
        Crossover newHighPass;
        Crossover newLowPass;

        if (!newHighPass.configure(sampleRate, CrossoverMode::HighPass, highPass))
            return false;

        if (!newLowPass.configure(sampleRate, CrossoverMode::LowPass, lowPass))
            return false;

        highPass_ = newHighPass;
        lowPass_ = newLowPass;
        return true;
    }

    float process(float sample) noexcept {
        return lowPass_.process(highPass_.process(sample));
    }

    void reset() noexcept {
        highPass_.reset();
        lowPass_.reset();
    }

private:
    Crossover highPass_;
    Crossover lowPass_;
};

} // namespace cardsp
