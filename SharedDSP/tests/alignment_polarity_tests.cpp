#include "cardsp/delay_line.hpp"
#include "cardsp/polarity.hpp"

#include <cassert>
#include <cmath>

int main() {
    cardsp::DelayLine delay;

    assert(delay.configure(48000.0f, 100.0f));
    assert(delay.setDelayMilliseconds(1.0f));

    assert(delay.process(1.0f) == 0.0f);

    for (int i = 1; i < 48; ++i)
        assert(delay.process(0.0f) == 0.0f);

    assert(std::fabs(delay.process(0.0f) - 1.0f) < 0.0001f);

    assert(std::fabs(
        cardsp::DelayLine::distanceToMilliseconds(0.343f) -
        1.0f) < 0.0001f);

    cardsp::Polarity polarity;

    assert(polarity.process(0.5f) == 0.5f);

    polarity.setInverted(true);

    assert(polarity.process(0.5f) == -0.5f);
    assert(polarity.inverted());

    return 0;
}
