#include "cardsp/crossover.hpp"

#include <cassert>
#include <cmath>

int main() {
    constexpr float sampleRate = 48000.0f;

    cardsp::CrossoverSettings hp;
    hp.enabled = true;
    hp.frequency = 80.0f;
    hp.slope = 24;
    hp.type = cardsp::CrossoverType::LinkwitzRiley;

    cardsp::CrossoverSettings lp;
    lp.enabled = true;
    lp.frequency = 3000.0f;
    lp.slope = 24;
    lp.type = cardsp::CrossoverType::LinkwitzRiley;

    cardsp::ChannelCrossover crossover;
    assert(crossover.configure(sampleRate, hp, lp));

    for (int i = 0; i < 48000; ++i) {
        const float input =
            std::sin(2.0f * 3.14159265358979323846f *
                     1000.0f * i / sampleRate);

        const float output = crossover.process(input);
        assert(std::isfinite(output));
    }

    hp.slope = 18;
    assert(!crossover.configure(sampleRate, hp, lp));

    return 0;
}
