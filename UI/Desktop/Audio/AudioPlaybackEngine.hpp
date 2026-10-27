#pragma once
#include <QObject>
#include <QUrl>
#include <QFile>
#include <QVariantList>
#include <QTimer>
#include "PlaybackOutput.hpp"
#include "AudioFileDecoder.hpp"
#include "cardsp/stereo_processor.hpp"

class PcmStreamDevice;
class AudioPlaybackEngine : public QObject {
    Q_OBJECT
    Q_PROPERTY(bool playing READ playing NOTIFY playingChanged)
    Q_PROPERTY(bool paused READ paused NOTIFY pausedChanged)
    Q_PROPERTY(bool loading READ loading NOTIFY loadingChanged)
    Q_PROPERTY(qint64 position READ position NOTIFY positionChanged)
    Q_PROPERTY(qint64 duration READ duration NOTIFY durationChanged)
    Q_PROPERTY(bool bypass READ bypass WRITE setBypass NOTIFY bypassChanged)
    Q_PROPERTY(double volume READ volume WRITE setVolume NOTIFY volumeChanged)
    Q_PROPERTY(QString lastError READ lastError NOTIFY lastErrorChanged)
    Q_PROPERTY(QVariantList outputDevices READ outputDevices NOTIFY outputDevicesChanged)
public:
    explicit AudioPlaybackEngine(QObject* parent = nullptr);
    AudioPlaybackEngine(std::shared_ptr<PlaybackBackend> backend, QObject* parent = nullptr);
    ~AudioPlaybackEngine() override;
    bool playing() const { return m_playing; } // A session exists, including while paused.
    bool paused() const { return m_paused; }
    bool loading() const { return m_loading; }
    qint64 position() const;
    qint64 duration() const { return m_duration; }
    bool bypass() const { return m_bypass; }
    double volume() const { return m_volume; }
    QString lastError() const { return m_lastError; }
    QVariantList outputDevices() const;
    Q_INVOKABLE QString localFilePath(const QUrl& url) const { return url.toLocalFile(); }
    Q_INVOKABLE bool playFile(const QString& path, int deviceIndex = 0);
    Q_INVOKABLE bool playPcm(const QString& path, int deviceIndex = 0);
    Q_INVOKABLE bool configureEq(const QVariantList& bands);
    Q_INVOKABLE void pause();
    Q_INVOKABLE void resume();
    Q_INVOKABLE bool seek(qint64 milliseconds);
    Q_INVOKABLE void stop();
    Q_INVOKABLE void refreshOutputDevices();
    void setBypass(bool bypass);
    void setVolume(double volume);
signals:
    void playingChanged();
    void pausedChanged();
    void loadingChanged();
    void positionChanged();
    void durationChanged();
    void bypassChanged();
    void volumeChanged();
    void lastErrorChanged();
    void outputDevicesChanged();
private:
    void setError(const QString& message);
    void setLoading(bool loading);
    void releaseOutput();
    bool selectOutput(int index);
    bool openPcm(const QString& path);
    bool startAt(qint64 milliseconds, bool paused);
    void finish();
    void handleState(QAudio::State state);
    static QAudioFormat pcmFormat();
    std::shared_ptr<PlaybackBackend> m_backend;
    QMediaDevices m_mediaDevices;
    QList<QAudioDevice> m_devices;
    QAudioDevice m_selectedDevice;
    std::unique_ptr<PlaybackOutput> m_sink;
    std::unique_ptr<PcmStreamDevice> m_stream;
    std::unique_ptr<QFile> m_file;
    AudioFileDecoder m_decoder;
    QTimer m_clock;
    cardsp::StereoProcessor<> m_processor;
    QVariantList m_eqBands;
    bool m_playing = false, m_paused = false, m_loading = false, m_bypass = false;
    double m_volume = 0.25;
    qint64 m_basePosition = 0, m_duration = 0;
    int m_recoveries = 0;
    QString m_lastError;
};
