#include "AudioPlaybackEngine.hpp"

#include <QAudio>
#include <QIODevice>
#include <QDebug>
#include <QVariantMap>

#include <algorithm>
#include <array>
#include <cstring>

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
        m_bypass = bypass;
    }

    bool atEnd() const override
    {
        return !m_file || m_file->atEnd();
    }

    bool isSequential() const override
    {
        return false;
    }

    qint64 size() const override
    {
        return m_file ? m_file->size() : 0;
    }

    qint64 pos() const override
    {
        return m_file ? m_file->pos() : 0;
    }

    bool seek(qint64 position) override
    {
        if (!m_file || !QIODevice::seek(position))
            return false;

        return m_file->seek(position);
    }

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

        static int readLogCount = 0;
        if (readLogCount < 20) {
            qInfo() << "CarDSP PCM read:"
                    << "requested=" << requested
                    << "bytesRead=" << bytesRead
                    << "position=" << m_file->pos()
                    << "size=" << m_file->size();
            ++readLogCount;
        }

        if (bytesRead <= 0)
            return bytesRead;

        if (!m_bypass && m_processor) {
            const std::size_t sampleCount =
                static_cast<std::size_t>(
                    bytesRead / sizeof(float)
                );

            const std::size_t frameCount =
                sampleCount / 2;

            std::memcpy(
                m_samples.data(),
                data,
                static_cast<std::size_t>(bytesRead)
            );

            m_processor->processInterleaved(
                m_samples.data(),
                frameCount,
                2
            );

            std::memcpy(
                data,
                m_samples.data(),
                static_cast<std::size_t>(bytesRead)
            );
        }

        return bytesRead;
    }

    qint64 writeData(const char *, qint64) override
    {
        return -1;
    }

private:
    QFile *m_file = nullptr;
    cardsp::StereoProcessor<> *m_processor = nullptr;

    bool m_bypass = false;

    // 8192 bytes / 4 bytes per Float32 sample.
    std::array<float, 2048> m_samples{};
};

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

    if (file->size() % 8 != 0) {
        setError(
            "PCM file must contain complete stereo Float32 frames."
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
    m_processor.clear();

    constexpr float sampleRate = 48000.0f;

    for (const QVariant &entry : m_eqBands) {
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
            setError("Unsupported EQ filter type.");
            stop();
            return false;
        }

        if (!m_processor.add(coefficients)) {
            setError("Unable to add EQ filter.");
            stop();
            return false;
        }
    }

    m_processor.reset();

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

    connect(
        m_sink.get(),
        &QAudioSink::stateChanged,
        this,
        [this](QAudio::State state) {
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
                if (m_file && m_file->atEnd()) {
                    qInfo() << "CarDSP: End of PCM file reached.";
                    stop();
                } else {
                    qWarning() << "CarDSP: Sink idle before EOF.";
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





