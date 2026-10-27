#include "AudioPlaybackEngine.hpp"
#include "PcmStreamDevice.hpp"
#include "PlaybackEq.hpp"
#include <QPointer>
#include <QFileInfo>
#include <algorithm>
#include <cmath>

AudioPlaybackEngine::AudioPlaybackEngine(QObject* parent)
    : AudioPlaybackEngine(std::make_shared<PlaybackBackend>(), parent) {}
AudioPlaybackEngine::AudioPlaybackEngine(std::shared_ptr<PlaybackBackend> backend, QObject* parent)
    : QObject(parent), m_backend(std::move(backend)) {
    refreshOutputDevices();
    connect(&m_mediaDevices, &QMediaDevices::audioOutputsChanged, this, &AudioPlaybackEngine::refreshOutputDevices);
    m_clock.setInterval(100);
    connect(&m_clock, &QTimer::timeout, this, &AudioPlaybackEngine::positionChanged);
    connect(&m_decoder, &AudioFileDecoder::ready, this, [this](const QString& path) {
        setLoading(false);
        if (!openPcm(path)) stop();
    });
    connect(&m_decoder, &AudioFileDecoder::failed, this, [this](const QString& error) {
        stop(); setError(error);
    });
}
AudioPlaybackEngine::~AudioPlaybackEngine() { stop(); }
QAudioFormat AudioPlaybackEngine::pcmFormat() {
    QAudioFormat f; f.setSampleRate(48000); f.setChannelCount(2); f.setSampleFormat(QAudioFormat::Float); return f;
}
QVariantList AudioPlaybackEngine::outputDevices() const {
    QVariantList result;
    for (int i = 0; i < m_devices.size(); ++i)
        result.append(QVariantMap{{"index", i}, {"name", m_devices[i].description()}, {"id", m_devices[i].id()}});
    return result;
}
void AudioPlaybackEngine::refreshOutputDevices() {
    m_devices = m_backend->devices();
    if ((m_playing || m_loading) && !m_devices.contains(m_selectedDevice)) {
        stop(); setError("The selected audio output was disconnected. Choose an output and press Play.");
    }
    emit outputDevicesChanged();
}
void AudioPlaybackEngine::setError(const QString& error) {
    if (m_lastError == error) return;
    m_lastError = error; emit lastErrorChanged();
}
void AudioPlaybackEngine::setLoading(bool loading) {
    if (m_loading == loading) return;
    m_loading = loading; emit loadingChanged();
}
void AudioPlaybackEngine::setBypass(bool bypass) {
    if (m_bypass == bypass) return;
    m_bypass = bypass;
    if (m_stream) m_stream->setBypass(bypass);
    emit bypassChanged();
}
void AudioPlaybackEngine::setVolume(double volume) {
    if (!std::isfinite(volume)) return;
    volume = std::clamp(volume, 0.0, 1.0);
    if (m_volume == volume) return;
    m_volume = volume;
    if (m_sink) m_sink->setVolume(volume);
    emit volumeChanged();
}
bool AudioPlaybackEngine::configureEq(const QVariantList& bands) {
    cardsp::StereoProcessor<> candidate;
    QString error;
    if (!configurePlaybackProcessor(candidate, bands, error)) { setError(error); return false; }
    m_eqBands = bands;
    m_processor = candidate;
    if (m_stream) m_stream->queueProcessor(candidate);
    return true;
}
bool AudioPlaybackEngine::selectOutput(int index) {
    if (index < 0 || index >= m_devices.size()) { setError("Invalid output device selection."); return false; }
    m_selectedDevice = m_devices[index];
    if (!m_backend->supports(m_selectedDevice, pcmFormat())) {
        setError("Output device does not support 48 kHz stereo Float32."); return false;
    }
    return true;
}
bool AudioPlaybackEngine::playFile(const QString& path, int deviceIndex) {
    const auto extension = QFileInfo(path).suffix().toLower();
    if (extension == "pcm" || extension == "raw") return playPcm(path, deviceIndex);
    stop(); setError({});
    if (!selectOutput(deviceIndex)) return false;
    if (extension != "wav" && extension != "mp3" && extension != "flac") {
        setError("Choose WAV, MP3, FLAC, or raw 48 kHz stereo Float32 PCM."); return false;
    }
    setLoading(true);
    return m_decoder.decode(path);
}
bool AudioPlaybackEngine::playPcm(const QString& path, int deviceIndex) {
    stop(); setError({});
    return selectOutput(deviceIndex) && openPcm(path);
}
bool AudioPlaybackEngine::openPcm(const QString& path) {
    auto file = std::make_unique<QFile>(path);
    if (!file->open(QIODevice::ReadOnly)) { setError("Cannot open audio file."); return false; }
    if (file->size() == 0 || file->size() % 8) {
        setError("PCM must contain non-empty, complete stereo Float32 frames."); return false;
    }
    m_duration = (file->size() / 8 * 1000 + 47999) / 48000;
    m_file = std::move(file);
    m_recoveries = 0;
    emit durationChanged();
    return startAt(0, false);
}
qint64 AudioPlaybackEngine::position() const {
    return std::clamp(m_basePosition + (m_sink ? m_sink->processedUSecs() / 1000 : 0), qint64(0), m_duration);
}
void AudioPlaybackEngine::releaseOutput() {
    m_clock.stop();
    if (m_sink) {
        disconnect(m_sink.get(), nullptr, this, nullptr);
        m_sink->reset(); // Discard queued samples before changing file position or DSP state.
        m_sink.reset();
    }
    m_stream.reset();
}
bool AudioPlaybackEngine::startAt(qint64 milliseconds, bool paused) {
    releaseOutput();
    m_basePosition = milliseconds;
    if (!m_file || !m_file->seek(milliseconds * 48 * 8)) {
        stop(); setError("Cannot seek audio file."); return false;
    }
    m_processor.reset();
    m_stream = std::make_unique<PcmStreamDevice>(m_file.get(), &m_processor);
    m_stream->setBypass(m_bypass);
    if (!m_stream->open(QIODevice::ReadOnly)) { stop(); setError("Cannot open DSP stream."); return false; }
    m_sink = m_backend->create(m_selectedDevice, pcmFormat());
    if (!m_sink) { stop(); setError("Cannot create audio output."); return false; }
    m_sink->setVolume(m_volume);
    const QPointer<PlaybackOutput> session(m_sink.get());
    connect(m_sink.get(), &PlaybackOutput::stateChanged, this, [this, session](QAudio::State state) {
        if (session && session.data() == m_sink.get()) handleState(state);
    }, Qt::QueuedConnection);
    m_sink->start(m_stream.get());
    if (m_sink->error() != QAudio::NoError) { stop(); setError("Audio output failed to start."); return false; }
    m_playing = true; m_paused = paused;
    if (paused) m_sink->suspend(); else m_clock.start();
    emit playingChanged(); emit pausedChanged(); emit positionChanged();
    return true;
}
void AudioPlaybackEngine::handleState(QAudio::State state) {
    if (state == QAudio::IdleState && !m_paused) {
        if (m_stream->failed()) { const auto error = m_stream->errorString(); stop(); setError(error); }
        else if (m_stream->atEnd()) finish();
        else if (m_recoveries++ < 3) {
            // Rebuild from the output's consumed position, not the file's read-ahead position.
            const auto at = position();
            startAt(at, false);
        } else { stop(); setError("Audio repeatedly underruns. Try another output or close busy applications."); }
    } else if (state == QAudio::StoppedState && m_sink->error() != QAudio::NoError) {
        const auto error = m_stream->failed() ? m_stream->errorString() : QString("Audio output stopped with an error.");
        stop(); setError(error);
    }
}
void AudioPlaybackEngine::pause() {
    if (!m_sink || m_paused) return;
    m_sink->suspend(); m_paused = true; m_clock.stop();
    emit pausedChanged(); emit positionChanged();
}
void AudioPlaybackEngine::resume() {
    if (!m_sink || !m_paused) return;
    m_sink->resume(); m_paused = false; m_clock.start();
    emit pausedChanged();
}
bool AudioPlaybackEngine::seek(qint64 milliseconds) {
    if (!m_file || !m_playing) return false;
    milliseconds = std::clamp(milliseconds, qint64(0), m_duration);
    if (milliseconds == m_duration) { finish(); return true; }
    return startAt(milliseconds, m_paused);
}
void AudioPlaybackEngine::finish() {
    releaseOutput(); m_file.reset(); m_decoder.cancel();
    m_basePosition = m_duration;
    m_playing = false; m_paused = false;
    emit playingChanged(); emit pausedChanged(); emit positionChanged();
}
void AudioPlaybackEngine::stop() {
    releaseOutput(); m_file.reset(); m_decoder.cancel();
    m_basePosition = 0; m_duration = 0;
    m_playing = false; m_paused = false; setLoading(false);
    emit playingChanged(); emit pausedChanged(); emit positionChanged(); emit durationChanged();
}
