#include "SpectrumAnalyzer.hpp"
#include "cardsp/SpectrumFFT.hpp"

#include <algorithm>
#include <span>

SpectrumAnalyzer::SpectrumAnalyzer(QObject* parent)
    : QObject(parent) {}

QVariantList SpectrumAnalyzer::bands() const {
    return bands_;
}

void SpectrumAnalyzer::processSamples(
    const QVector<float>& samples,
    int sampleRate
) {
    if (sampleRate <= 0 || samples.isEmpty()) {
        return;
    }

    buffer_.insert(
        buffer_.end(),
        samples.begin(),
        samples.end()
    );

    constexpr auto size = cardsp::SpectrumFFT::fftSize;

    // Limit retained audio to the latest FFT window.
    if (buffer_.size() > size) {
        buffer_.erase(
            buffer_.begin(),
            buffer_.end() - size
        );
    }

    if (buffer_.size() < size) {
        return;
    }

    const auto spectrum = cardsp::SpectrumFFT::analyze(
        std::span<const float>(buffer_.data(), buffer_.size()),
        static_cast<double>(sampleRate)
    );

    QVariantList updated;

    for (const auto& band : spectrum) {
        updated.append(band.decibels);
    }

    bands_ = updated;
    emit bandsChanged();
}
