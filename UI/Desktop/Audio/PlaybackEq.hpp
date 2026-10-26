#pragma once
#include <QVariantList>
#include <QVariantMap>
#include <QString>
#include "cardsp/stereo_processor.hpp"

// Called only while processing is stopped; shared by playback and silent tests.
inline bool configurePlaybackProcessor(cardsp::StereoProcessor<>& processor,
                                       const QVariantList& bands, QString& error) {
    processor.clear();
    if (bands.size() > 40) { error = "Too many EQ filters."; return false; }
    constexpr float sampleRate = 48000.0f;

    for (const QVariant &entry : bands) {
        const QVariantMap band = entry.toMap();

        if (!band.value("enabled", true).toBool())
            continue;

        const float frequency =
            band.value("frequency", 1000.0).toFloat();

        const float gain =
            band.value("gain", 0.0).toFloat();

        const float q =
            band.value("q", 1.41).toFloat();

        const int type =
            band.value("type", 0).toInt();

        if (!std::isfinite(frequency) || frequency < 20 || frequency > 20000 ||
            !std::isfinite(gain) || gain < -18 || gain > 18 ||
            !std::isfinite(q) || q < 0.1f || q > 30) {
            error = "Invalid EQ frequency, gain or Q.";
            return false;
        }

        cardsp::BiquadCoefficients coefficients;

        switch (type) {
        case 0:
            coefficients = cardsp::makePeakingEQ(
                sampleRate, frequency, q, gain);
            break;
        case 1:
            coefficients = cardsp::makeLowShelf(
                sampleRate, frequency, gain);
            break;
        case 2:
            coefficients = cardsp::makeHighShelf(
                sampleRate, frequency, gain);
            break;
        case 3:
            coefficients = cardsp::makeLowPass(
                sampleRate, frequency, q);
            break;
        case 4:
            coefficients = cardsp::makeHighPass(
                sampleRate, frequency, q);
            break;
        case 5:
            coefficients = cardsp::makeNotch(
                sampleRate, frequency, q);
            break;
        default:
            error = "Unsupported EQ filter type.";
            return false;
        }

        if (!processor.add(coefficients)) {
            error = "Unable to add EQ filter.";
            return false;
        }
    }

    processor.reset();
    return true;
}
