#pragma once
#include <QObject>
#include <QAudioSink>
#include <QMediaDevices>
#include <memory>

// The transport boundary lets controller tests exercise failures without hardware.
class PlaybackOutput : public QObject {
    Q_OBJECT
public:
    using QObject::QObject;
    virtual void start(QIODevice*) = 0;
    virtual void reset() = 0;
    virtual void suspend() = 0;
    virtual void resume() = 0;
    virtual void setVolume(double) = 0;
    virtual qint64 processedUSecs() const = 0;
    virtual QAudio::Error error() const = 0;
signals:
    void stateChanged(QAudio::State state);
};

class PlaybackBackend {
public:
    virtual ~PlaybackBackend() = default;
    virtual QList<QAudioDevice> devices() const { return QMediaDevices::audioOutputs(); }
    virtual bool supports(const QAudioDevice& d, const QAudioFormat& f) const {
        return d.isFormatSupported(f);
    }
    virtual std::unique_ptr<PlaybackOutput> create(const QAudioDevice&, const QAudioFormat&);
};
