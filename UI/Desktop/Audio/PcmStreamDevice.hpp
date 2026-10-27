#pragma once
#include <QFile>
#include <QIODevice>
#include <algorithm>
#include <array>
#include <atomic>
#include <cmath>
#include <cstring>
#include <mutex>
#include "cardsp/stereo_processor.hpp"

class PcmStreamDevice final : public QIODevice {
public:
    PcmStreamDevice(QFile* file, cardsp::StereoProcessor<>* processor, QObject* parent = nullptr)
        : QIODevice(parent), m_file(file), m_processor(processor ? *processor : cardsp::StereoProcessor<>{}) {}
    void setBypass(bool bypass) noexcept {
        m_bypass.store(bypass, std::memory_order_relaxed);
        if (!isOpen()) m_wet = bypass ? 0.0f : 1.0f;
    }
    // Only the producer locks. The audio consumer tries once and defers a busy update.
    // Each stream owns active filter history; the UI never mutates it.
    void queueProcessor(const cardsp::StereoProcessor<>& processor) {
        std::lock_guard<std::mutex> lock(m_mailboxMutex);
        m_pending = processor;
        m_hasPending = true;
    }
    bool failed() const { return m_failed.load(std::memory_order_acquire); }
    bool atEnd() const override { return bytesAvailable() == 0; }
    bool isSequential() const override { return true; }
    qint64 bytesAvailable() const override {
        return QIODevice::bytesAvailable() + (m_file ? m_file->bytesAvailable() : 0);
    }
protected:
    qint64 readData(char* data, qint64 maxSize) override {
        if (!m_file || !data || maxSize <= 0) return 0;
        if (failed()) return -1;
        const auto requested = std::min((maxSize / 8) * 8, qint64(8192));
        if (requested <= 0) return 0;
        const auto bytes = m_file->read(data, requested);
        if (bytes < 0) return fail("Audio file read failed: " + m_file->errorString());
        if (!bytes) return 0;
        if (bytes % 8) return fail("Incomplete stereo Float32 frame.");
        std::memcpy(m_samples.data(), data, size_t(bytes));
        for (qint64 i = 0; i < bytes / 4; ++i)
            if (!std::isfinite(m_samples[i])) return fail("Audio contains non-finite samples.");
        if (m_transition == 0) {
            std::unique_lock<std::mutex> lock(m_mailboxMutex, std::try_to_lock);
            if (lock.owns_lock() && m_hasPending) {
                m_previous = m_processor;
                m_processor = m_pending;
                m_hasPending = false;
                m_transition = fadeFrames;
            }
        }
        const float targetWet = m_bypass.load(std::memory_order_relaxed) ? 0.0f : 1.0f;
        for (qint64 i = 0; i < bytes / 4; i += 2) {
            float dry[2]{m_samples[i], m_samples[i+1]};
            float wet[2]{dry[0], dry[1]};
            m_processor.processInterleaved(wet, 1);
            if (m_transition) {
                float old[2]{dry[0], dry[1]};
                m_previous.processInterleaved(old, 1);
                const float blend = float(fadeFrames - m_transition + 1) / fadeFrames;
                for (int ch = 0; ch < 2; ++ch) wet[ch] = old[ch] + blend * (wet[ch] - old[ch]);
                --m_transition;
            }
            m_wet += std::clamp(targetWet - m_wet, -1.0f/fadeFrames, 1.0f/fadeFrames);
            for (int ch = 0; ch < 2; ++ch) {
                const float sample = m_wet == 0 ? dry[ch] : (m_wet == 1 ? wet[ch] : dry[ch] + m_wet*(wet[ch]-dry[ch]));
                if (!std::isfinite(sample)) return fail("DSP produced a non-finite sample.");
                m_samples[i+ch] = sample;
            }
        }
        std::memcpy(data, m_samples.data(), size_t(bytes));
        return bytes;
    }
    qint64 writeData(const char*, qint64) override { return -1; }
private:
    qint64 fail(const QString& message) {
        setErrorString(message); m_failed.store(true, std::memory_order_release); return -1;
    }
    static constexpr int fadeFrames = 256;
    QFile* m_file;
    cardsp::StereoProcessor<> m_processor, m_previous, m_pending;
    std::mutex m_mailboxMutex;
    bool m_hasPending = false;
    int m_transition = 0;
    float m_wet = 1.0f;
    std::atomic_bool m_bypass{false}, m_failed{false};
    std::array<float, 2048> m_samples{};
};
