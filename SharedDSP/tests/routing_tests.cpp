#include "cardsp/routing_matrix.hpp"

#include <cassert>
#include <cmath>

int main() {
    cardsp::RoutingMatrix<2, 9> routing;

    // Front left receives left input.
    assert(routing.setGain(0, 0, 1.0f));

    // Front right receives right input.
    assert(routing.setGain(1, 1, 1.0f));

    // Mono subwoofer sums left and right at -6 dB each.
    assert(routing.setGain(8, 0, 0.5f));
    assert(routing.setGain(8, 1, 0.5f));

    const auto output = routing.process({0.8f, 0.4f});

    assert(std::fabs(output[0] - 0.8f) < 0.0001f);
    assert(std::fabs(output[1] - 0.4f) < 0.0001f);
    assert(std::fabs(output[8] - 0.6f) < 0.0001f);

    assert(!routing.setGain(9, 0, 1.0f));
    assert(!routing.setGain(0, 2, 1.0f));
    assert(!routing.setGain(0, 0, NAN));

    routing.clear();

    const auto muted = routing.process({1.0f, 1.0f});

    for (float sample : muted)
        assert(sample == 0.0f);

    return 0;
}
