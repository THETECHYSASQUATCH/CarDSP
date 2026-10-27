#pragma once
#include <QObject>
#include <QAudioDecoder>
#include <QTemporaryFile>
#include <QTimer>
#include <memory>

// Decode to a temporary PCM file, keeping RAM bounded and disk I/O off playback.
// The result remains owned by this object until cancel() or the next decode().
class AudioFileDecoder final : public QObject {
    Q_OBJECT
public:
    explicit AudioFileDecoder(QObject* parent = nullptr);
    bool decode(const QString& path);
    void cancel();
signals:
    void ready(const QString& pcmPath);
    void failed(const QString& message);
private:
    void fail(const QString& message);
    std::unique_ptr<QAudioDecoder> m_decoder;
    std::unique_ptr<QTemporaryFile> m_file;
    QTimer m_timeout;
};
