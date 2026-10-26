#pragma once
#include <QFile>
#include <QIODevice>
#include <array>
#include <atomic>
#include <cmath>
#include <cstring>
#include "cardsp/stereo_processor.hpp"

class PcmStreamDevice final : public QIODevice
{
public:
    PcmStreamDevice(
        QFile *file,
        cardsp::StereoProcessor<> *processor,
        QObject *parent = nullptr)
        : QIODevice(parent),
          m_file(file),
          m_processor(processor)
    {
    }

    void setBypass(bool bypass) noexcept
    {
        m_bypass.store(bypass, std::memory_order_relaxed);
    }

    bool atEnd() const override { return bytesAvailable() == 0; }

    // Forward-only DSP stream: QIODevice owns any partially consumed bytes.
    // File position can be ahead of the consumer because of this read-ahead.
    bool isSequential() const override { return true; }

    qint64 bytesAvailable() const override
    {
        return QIODevice::bytesAvailable() +
               (m_file ? m_file->bytesAvailable() : 0);
    }

protected:
    qint64 readData(char *data, qint64 maxSize) override
    {
        if (!m_file || !data || maxSize <= 0)
            return 0;

        constexpr qint64 frameBytes = 8;
        constexpr qint64 bufferBytes = 8192;

        const qint64 requested =
            std::min((maxSize / frameBytes) * frameBytes,
                     bufferBytes);

        if (requested <= 0)
            return 0;

        const qint64 bytesRead =
            m_file->read(data, requested);

        if (bytesRead <= 0)
            return bytesRead;

        if (bytesRead % frameBytes != 0) {
            setErrorString("Incomplete stereo Float32 frame.");
            return -1;
        }
        std::memcpy(m_samples.data(), data, static_cast<std::size_t>(bytesRead));
        for (qint64 i = 0; i < bytesRead / sizeof(float); ++i) {
            if (!std::isfinite(m_samples[i])) {
                setErrorString("PCM contains non-finite samples.");
                return -1;
            }
        }
        if (!m_bypass.load(std::memory_order_relaxed) && m_processor)
            m_processor->processInterleaved(m_samples.data(), bytesRead / frameBytes, 2);
        std::memcpy(data, m_samples.data(), static_cast<std::size_t>(bytesRead));

        return bytesRead;
    }

    qint64 writeData(const char *, qint64) override
    {
        return -1;
    }

private:
    QFile *m_file = nullptr;
    cardsp::StereoProcessor<> *m_processor = nullptr;

    std::atomic_bool m_bypass{false};

    // 8192 bytes / 4 bytes per Float32 sample.
    std::array<float, 2048> m_samples{};
};
