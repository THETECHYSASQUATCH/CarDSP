#include <cardsp/biquad.hpp>
#include <cmath>
#include <cstdlib>

int main() {
    cardsp::Biquad filter;
    cardsp::BiquadCoefficients passthrough;
    filter.setCoefficients(passthrough);

    float samples[] {0.0f, 0.25f, -0.5f, 1.0f, -1.0f};
    filter.process(samples, 5);

    const float expected[] {0.0f, 0.25f, -0.5f, 1.0f, -1.0f};
    for (int i = 0; i < 5; ++i) {
        if (std::fabs(samples[i] - expected[i]) > 0.000001f) return EXIT_FAILURE;
    }
    return EXIT_SUCCESS;
}
