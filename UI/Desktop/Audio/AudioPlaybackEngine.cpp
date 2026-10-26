#include "AudioPlaybackEngine.hpp"
#include "PcmStreamDevice.hpp"
#include "PlaybackEq.hpp"
#include <QPointer>

#include <QAudio>
#include <QIODevice>
#include <QDebug>
#include <QVariantMap>

#include <algorithm>
#include <array>
#include <cstring>

AudioPlaybackEngine::AudioPlaybackEngine(QObject *parent)
    : QObject(parent)
{
    refreshOutputDevices();

    connect(
        &m_mediaDevices,
        &QMediaDevices::audioOutputsChanged,
        this,
        &AudioPlaybackEngine::refreshOutputDevices
    );
}

AudioPlaybackEngine::~AudioPlaybackEngine()
{
    stop();
}

QVariantList AudioPlaybackEngine::outputDevices() const
{
    QVariantList result;

    for (int i = 0; i < m_devices.size(); ++i) {
        QVariantMap item;
        item["index"] = i;
        item["name"] = m_devices[i].description();
        result.append(item);
    }

    return result;
}

void AudioPlaybackEngine::refreshOutputDevices()
{
    m_devices = QMediaDevices::audioOutputs();
    emit outputDevicesChanged();
}

void AudioPlaybackEngine::setError(const QString &message)
{
    if (m_lastError == message)
        return;

    m_lastError = message;
    emit lastErrorChanged();
}

void AudioPlaybackEngine::setBypass(bool bypass)
{
    if (m_bypass == bypass)
        return;

    m_bypass = bypass;

    if (m_stream)
        m_stream->setBypass(bypass);

    emit bypassChanged();
}

void AudioPlaybackEngine::setVolume(double volume)
{
    if (!std::isfinite(volume)) return;
    volume = std::clamp(volume, 0.0, 1.0);

    if (m_volume == volume)
        return;

    m_volume = volume;

    if (m_sink)
        m_sink->setVolume(static_cast<float>(volume));

    emit volumeChanged();
}

bool AudioPlaybackEngine::configureEq(const QVariantList &bands)
{
    if (m_playing) {
        setError("Stop playback before configuring EQ.");
        return false;
    }

    if (bands.size() > 40) {
        setError("Too many EQ filters.");
        return false;
    }

    cardsp::StereoProcessor<> candidate;
    QString error;
    if (!configurePlaybackProcessor(candidate, bands, error)) {
        setError(error);
        return false;
    }
    m_eqBands = bands;
    setError(QString());
    return true;
}
bool AudioPlaybackEngine::playPcm(
    const QString &path,
    int deviceIndex)
{
    stop();
    setError(QString());

    if (deviceIndex < 0 || deviceIndex >= m_devices.size()) {
        setError("Invalid output device index.");
        return false;
    }

    auto file = std::make_unique<QFile>(path);

    if (!file->open(QIODevice::ReadOnly)) {
        setError("Unable to open PCM audio file.");
        return false;
    }

    if (file->size() == 0 || file->size() % 8 != 0) {
        setError(
            "PCM file must contain non-empty, complete stereo Float32 frames."
        );
        return false;
    }

    QAudioFormat format;
    format.setSampleRate(48000);
    format.setChannelCount(2);
    format.setSampleFormat(QAudioFormat::Float);

    const QAudioDevice device = m_devices[deviceIndex];

    if (!device.isFormatSupported(format)) {
        setError(
            "Output device does not support 48 kHz stereo Float32."
        );
        return false;
    }

    m_file = std::move(file);
    QString configurationError;
    if (!configurePlaybackProcessor(m_processor, m_eqBands, configurationError)) {
        setError(configurationError);
        stop();
        return false;
    }

    m_sink = std::make_unique<QAudioSink>(
        device,
        format,
        this
    );

    m_sink->setVolume(static_cast<float>(m_volume));

    m_stream = std::make_unique<PcmStreamDevice>(
        m_file.get(),
        &m_processor
    );

    m_stream->setBypass(m_bypass);

    if (!m_stream->open(QIODevice::ReadOnly)) {
        setError("Unable to open PCM stream.");
        stop();
        return false;
    }

    const QPointer<QAudioSink> sessionSink(m_sink.get());
    connect(
        m_sink.get(),
        &QAudioSink::stateChanged,
        this,
        [this, sessionSink](QAudio::State state) {
            if (!sessionSink || sessionSink.data() != m_sink.get()) return;
            qInfo() << "CarDSP sink state:"
                    << static_cast<int>(state)
                    << "error="
                    << (m_sink ? static_cast<int>(m_sink->error()) : -1)
                    << "filePosition="
                    << (m_file ? m_file->pos() : -1)
                    << "fileSize="
                    << (m_file ? m_file->size() : -1);

            if (!m_sink)
                return;

            if (state == QAudio::IdleState) {
                if (m_stream && m_stream->atEnd()) {
                    qInfo() << "CarDSP: End of PCM file reached.";
                    stop();
                } else {
                    setError("PCM playback stopped before the end of the file.");
                    stop();
                }
            } else if (state == QAudio::StoppedState &&
                       m_sink->error() != QAudio::NoError) {
                setError("Audio output stopped with an error.");
                stop();
            }
        },
        Qt::QueuedConnection
    );

    qInfo() << "CarDSP output device:" << device.description();
    qInfo() << "CarDSP output format:"
            << format.sampleRate()
            << format.channelCount()
            << format.sampleFormat();

    qInfo() << "CarDSP: DSP PCM stream enabled";
    m_sink->start(m_stream.get());

    qInfo() << "CarDSP sink after start:"
            << "state=" << static_cast<int>(m_sink->state())
            << "error=" << static_cast<int>(m_sink->error())
            << "processedUSecs=" << m_sink->processedUSecs();

    if (m_sink->error() != QAudio::NoError) {
        setError("Audio output failed to start.");
        stop();
        return false;
    }

    m_playing = true;
    emit playingChanged();

    return true;
}

void AudioPlaybackEngine::stop()
{
    if (m_sink) {
        disconnect(m_sink.get(), nullptr, this, nullptr);
        m_sink->stop();
        m_sink.reset();
    }

    if (m_stream) {
        m_stream->close();
        m_stream.reset();
    }

    m_file.reset();

    if (m_playing) {
        m_playing = false;
        emit playingChanged();
    }
}
