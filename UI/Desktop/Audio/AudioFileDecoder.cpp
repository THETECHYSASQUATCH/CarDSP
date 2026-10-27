#include "AudioFileDecoder.hpp"
#include <QAudioBuffer>
#include <QDir>
#include <QUrl>
#include <cmath>

AudioFileDecoder::AudioFileDecoder(QObject* parent) : QObject(parent) {
    m_timeout.setSingleShot(true);
    m_timeout.setInterval(30000);
    connect(&m_timeout, &QTimer::timeout, this, [this] { fail("Audio decoding stalled. Try another file."); });
}
void AudioFileDecoder::cancel() {
    m_timeout.stop();
    if (m_decoder) {
        disconnect(m_decoder.get(), nullptr, this, nullptr);
        m_decoder->stop();
        // Signals can call cancel(): defer destruction until signal delivery returns.
        m_decoder.release()->deleteLater();
    }
    m_file.reset();
}
void AudioFileDecoder::fail(const QString& message) {
    cancel();
    emit failed(message);
}
bool AudioFileDecoder::decode(const QString& path) {
    cancel();
    m_file = std::make_unique<QTemporaryFile>(QDir::tempPath() + "/cardsp-audio-XXXXXX.pcm");
    if (!m_file->open()) { fail("Cannot create a temporary decoded-audio file."); return false; }
    m_decoder = std::make_unique<QAudioDecoder>();
    if (!m_decoder->isSupported()) { fail("Audio decoding backend is unavailable."); return false; }
    QAudioFormat format;
    format.setSampleRate(48000);
    format.setChannelCount(2);
    format.setSampleFormat(QAudioFormat::Float);
    m_decoder->setAudioFormat(format);
    m_decoder->setSource(QUrl::fromLocalFile(path));
    connect(m_decoder.get(), &QAudioDecoder::bufferReady, this, [this, format] {
        const auto buffer = m_decoder->read();
        if (!buffer.isValid() || buffer.format() != format || buffer.byteCount() % 8) {
            fail("Decoder did not produce 48 kHz stereo Float32 audio."); return;
        }
        const auto* samples = buffer.constData<float>();
        for (int i = 0; i < buffer.sampleCount(); ++i) {
            if (!std::isfinite(samples[i])) { fail("Decoded audio contains non-finite samples."); return; }
        }
        // Explicit disk bound: about three hours of stereo 48 kHz Float32.
        constexpr qint64 maxBytes = 4LL * 1024 * 1024 * 1024;
        if (m_file->size() + buffer.byteCount() > maxBytes) {
            fail("Decoded audio exceeds the 4 GiB temporary-file limit."); return;
        }
        if (m_file->write(buffer.constData<char>(), buffer.byteCount()) != buffer.byteCount()) {
            fail("Cannot write decoded audio; check free disk space."); return;
        }
        m_timeout.start();
    });
    connect(m_decoder.get(), qOverload<QAudioDecoder::Error>(&QAudioDecoder::error), this,
            [this](QAudioDecoder::Error) { fail("Audio decoding failed: " + m_decoder->errorString()); });
    connect(m_decoder.get(), &QAudioDecoder::finished, this, [this] {
        m_timeout.stop();
        if (!m_file || m_file->size() == 0) { fail("The file contains no decodable audio."); return; }
        if (!m_file->flush()) { fail("Cannot flush decoded audio to disk."); return; }
        const auto path = m_file->fileName();
        m_file->close();
        emit ready(path);
    });
    m_timeout.start();
    m_decoder->start();
    return true;
}
