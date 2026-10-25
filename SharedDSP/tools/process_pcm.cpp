#include "cardsp/stereo_processor.hpp"
#include <array>
#include <cstdio>
#include <cstdlib>
#include <cstring>
#include <cerrno>
#include <limits>
#ifdef _WIN32
#include <fcntl.h>
#include <io.h>
#endif

// Binary stdin/stdout adapter for hosts supplying native-endian Float32 stereo.
// No device capture, resampling or DRM access is performed here.
int main(int argc, char** argv) {
    if (argc != 3) {
        std::fprintf(stderr, "Usage: cardsp_process_pcm SAMPLE_RATE PREAMP_DB < input.f32 > output.f32\n");
        return 2;
    }
    const auto parse = [](const char* text, float& value) {
        char* end = nullptr;
        errno = 0;
        value = std::strtof(text, &end);
        return end != text && *end == '\0' && errno != ERANGE && std::isfinite(value);
    };
    float rate, gain;
    if (!parse(argv[1], rate) || !parse(argv[2], gain) || rate < 8000 || rate > 384000 || gain < -96 || gain > 24) {
        std::fprintf(stderr, "Expected sample rate 8000–384000 Hz and preamp -96–24 dB\n");
        return 2;
    }
#ifdef _WIN32
    if (_setmode(_fileno(stdin), _O_BINARY) == -1 || _setmode(_fileno(stdout), _O_BINARY) == -1) return 1;
#endif
    cardsp::StereoProcessor<> dsp;
    dsp.setPreampDecibels(gain);
    if (!dsp.add(cardsp::makeHighPass(rate, 20))) return 1;
    std::array<float, 2048> samples{};
    while (true) {
        const auto bytes = std::fread(samples.data(), 1, sizeof(samples), stdin);
        if (std::ferror(stdin)) return 1;
        if (bytes % (2 * sizeof(float)) != 0) {
            std::fprintf(stderr, "Input ends with an incomplete stereo Float32 frame\n");
            return 1;
        }
        if (!bytes) break;
        for (std::size_t i = 0; i < bytes / sizeof(float); ++i) {
            if (!std::isfinite(samples[i])) {
                std::fprintf(stderr, "Input contains non-finite PCM\n");
                return 1;
            }
        }
        if (!dsp.processInterleaved(samples.data(), bytes / (2 * sizeof(float)))) return 1;
        if (std::fwrite(samples.data(), 1, bytes, stdout) != bytes) return 1;
    }
    return std::fflush(stdout) == 0 ? 0 : 1;
}
