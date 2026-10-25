#include "cardsp/stereo_processor.hpp"
#include <array>
#include <cstdlib>
#include <iostream>
#include <limits>

static void require(bool condition) {
    if (!condition) { std::cerr << "Stereo processor regression failed\n"; std::exit(1); }
}

int main() {
    const auto invalid = cardsp::makeLowPass(0, 1000);
    require(invalid.b0 == 1 && invalid.a1 == 0);
    const auto invalidEQ = cardsp::makePeakingEQ(48000, 1000, 1, std::numeric_limits<float>::infinity());
    require(invalidEQ.b0 == 1 && invalidEQ.a1 == 0);
    cardsp::StereoProcessor<> whole, split, planar;
    for (auto* p : {&whole, &split, &planar}) {
        require(p->add(cardsp::makeLowPass(48000, 2000)));
        p->setPreampDecibels(-6);
    }
    std::array<float, 512> a{}, b{};
    std::array<float, 256> left{}, right{};
    a[0] = b[0] = left[0] = 1;
    require(whole.processInterleaved(a.data(), 256));
    require(split.processInterleaved(b.data(), 37));
    require(split.processInterleaved(b.data() + 74, 219));
    require(planar.processPlanar(left.data(), right.data(), 256));
    for (std::size_t i = 0; i < 256; ++i) {
        require(std::abs(a[i*2] - b[i*2]) < 1e-7f);
        require(std::abs(a[i*2] - left[i]) < 1e-7f);
        require(a[i*2+1] == 0 && right[i] == 0);
    }
    require(!whole.processInterleaved(a.data(), 256, 1));
    require(!whole.processInterleaved(nullptr, 1));
    require(!whole.processPlanar(left.data(), left.data(), 1));
    require(whole.processInterleaved(nullptr, 0));
    whole.reset();
    std::array<float, 2> silence{};
    require(whole.processInterleaved(silence.data(), 1));
    require(silence[0] == 0 && silence[1] == 0);
    cardsp::StereoProcessor<1> bounded;
    require(bounded.add(cardsp::makeLowPass(48000, 1000)));
    require(!bounded.add(cardsp::makeHighPass(48000, 20)));
    std::cout << "Stereo layout, isolation, continuity, reset and validation passed\n";
}
