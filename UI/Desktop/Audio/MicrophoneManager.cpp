#include "MicrophoneManager.hpp"

#include <QAudioDevice>
#include <QtEndian>
#include <QtMath>
#include <algorithm>
#include <cmath>
#include <cstring>

MicrophoneManager::MicrophoneManager(QObject *parent)
    : QObject(parent)
{
    connect(&m_mediaDevices, &QMediaDevices::audioInputsChanged,
            this, &MicrophoneManager::refreshDevices);

    refreshDevices();
}

QVariantList MicrophoneManager::devices() const
{
    QVariantList result;

    for (const auto &device : m_devices) {
        QVariantMap entry;
        entry["name"] = device.description();
        entry["id"] = QString::fromUtf8(device.id().toHex());
        result.append(entry);
    }

    return result;
}

bool MicrophoneManager::capturing() const
{
    return m_capturing;
}

double MicrophoneManager::level() const
{
    return m_level;
}

QString MicrophoneManager::lastError() const
{
    return m_lastError;
}

void MicrophoneManager::setError(const QString &error)
{
    if (m_lastError == error)
        return;

    m_lastError = error;
    emit lastErrorChanged();
}

void MicrophoneManager::refreshDevices()
{
    m_devices = QMediaDevices::audioInputs();
    emit devicesChanged();
}

bool MicrophoneManager::startCapture(int deviceIndex)
{
    stopCapture();
    refreshDevices();
    setError({});

    if (deviceIndex < 0 || deviceIndex >= m_devices.size()) {
        setError("Invalid microphone selection.");
        return false;
    }

    const auto &device = m_devices.at(deviceIndex);

    QAudioFormat format;
    format.setSampleRate(48000);
    format.setChannelCount(1);
    format.setSampleFormat(QAudioFormat::Float);

    if (!device.isFormatSupported(format))
        format = device.preferredFormat();

    if (!format.isValid()) {
        setError("No supported audio format for this microphone.");
        return false;
    }

    m_format = format;
    m_pending.clear();

    m_source = std::make_unique<QAudioSource>(device, m_format);
    m_io = m_source->start();

    if (!m_io) {
        setError("Could not start microphone capture.");
        m_source.reset();
        return false;
    }

    connect(m_io, &QIODevice::readyRead,
            this, &MicrophoneManager::processAudio);

    m_capturing = true;
    emit capturingChanged();

    return true;
}

void MicrophoneManager::stopCapture()
{
    if (m_io)
        disconnect(m_io, nullptr, this, nullptr);

    m_io = nullptr;

    if (m_source) {
        m_source->stop();
        m_source.reset();
    }

    m_pending.clear();

    if (m_capturing) {
        m_capturing = false;
        emit capturingChanged();
    }

    if (m_level != 0.0) {
        m_level = 0.0;
        emit levelChanged();
    }
}

void MicrophoneManager::processAudio()
{
    if (!m_io || !m_capturing)
        return;

    m_pending.append(m_io->readAll());

    const int channels = m_format.channelCount();
    const int bytesPerSample = m_format.bytesPerSample();
    const int bytesPerFrame = m_format.bytesPerFrame();

    if (channels <= 0 || bytesPerSample <= 0 || bytesPerFrame <= 0)
        return;

    const qsizetype frameCount = m_pending.size() / bytesPerFrame;

    if (frameCount <= 0)
        return;

    const qsizetype consumed = frameCount * bytesPerFrame;

    QVector<float> mono;
    mono.reserve(static_cast<qsizetype>(frameCount));

    const char *data = m_pending.constData();

    double sumSquares = 0.0;

    for (qsizetype frame = 0; frame < frameCount; ++frame) {
        double value = 0.0;

        for (int channel = 0; channel < channels; ++channel) {
            const char *sample =
                data + frame * bytesPerFrame + channel * bytesPerSample;

            double decoded = 0.0;

            switch (m_format.sampleFormat()) {
            case QAudioFormat::UInt8:
                decoded =
                    (static_cast<unsigned char>(*sample) - 128.0) / 128.0;
                break;

            case QAudioFormat::Int16: {
                const qint16 pcm = qFromLittleEndian<qint16>(sample);
                decoded = static_cast<double>(pcm) / 32768.0;
                break;
            }

            case QAudioFormat::Int32: {
                const qint32 pcm = qFromLittleEndian<qint32>(sample);
                decoded = static_cast<double>(pcm) / 2147483648.0;
                break;
            }

            case QAudioFormat::Float: {
                float pcm;
                std::memcpy(&pcm, sample, sizeof(float));
                decoded = std::isfinite(pcm) ? pcm : 0.0;
                break;
            }

            default:
                break;
            }

            value += decoded;
        }

        value /= channels;
        value = std::clamp(value, -1.0, 1.0);

        mono.append(static_cast<float>(value));
        sumSquares += value * value;
    }

    m_pending.remove(0, consumed);

    const double rms =
        std::sqrt(sumSquares / static_cast<double>(frameCount));

    const double newLevel = std::clamp(rms, 0.0, 1.0);

    if (std::abs(newLevel - m_level) > 0.001) {
        m_level = newLevel;
        emit levelChanged();
    }

    emit pcmAvailable(mono, m_format.sampleRate());
}
