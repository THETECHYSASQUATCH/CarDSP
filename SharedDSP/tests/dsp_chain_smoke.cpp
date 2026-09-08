#include "cardsp/dsp_chain.hpp"

#include <array>
#include <cassert>
#include <cmath>

namespace {

bool nearlyEqual(float lhs, float rhs, float tolerance = 1.0e-4f) {
    return std::fabs(lhs - rhs) <= tolerance;
}

} // namespace

int main() {
    cardsp::Gain gain;
    gain.setDecibels(-6.0205999f);
    assert(nearlyEqual(gain.linear(), 0.5f, 1.0e-3f));
    assert(nearlyEqual(gain.process(1.0f), 0.5f, 1.0e-3f));

    cardsp::FilterChain<4> chain;
    chain.setPreampDecibels(-6.0205999f);
    assert(chain.add(cardsp::makeHighPass(48000.0f, 25.0f)));
    assert(chain.add(cardsp::makePeakingEQ(48000.0f, 1000.0f, 1.0f, 3.0f)));
    assert(chain.add(cardsp::makeLowPass(48000.0f, 18000.0f)));
    assert(chain.size() == 3);

    std::array<float, 256> impulse {};
    impulse[0] = 1.0f;
    chain.process(impulse.data(), impulse.size());

    for (float sample : impulse) {
        assert(std::isfinite(sample));
    }

    chain.reset();
    const float sample = chain.process(0.25f);
    assert(std::isfinite(sample));

    cardsp::FilterChain<1> bounded;
    assert(bounded.add(cardsp::makeLowPass(48000.0f, 100.0f)));
    assert(!bounded.add(cardsp::makeHighPass(48000.0f, 20.0f)));

    return 0;
}
