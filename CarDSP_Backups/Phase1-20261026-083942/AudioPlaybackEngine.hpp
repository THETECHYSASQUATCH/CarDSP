#pragma once

#include <QObject>
#include <QUrl>
#include <QAudioSink>
#include <QAudioDevice>
#include <QAudioFormat>
#include <QFile>
#include <QMediaDevices>
#include <QVariantList>

#include <memory>

#include "cardsp/stereo_processor.hpp"

class PcmStreamDevice;

class AudioPlaybackEngine : public QObject
{
    Q_OBJECT

    Q_PROPERTY(bool playing READ playing NOTIFY playingChanged)
    Q_PROPERTY(bool bypass READ bypass WRITE setBypass NOTIFY bypassChanged)
    Q_PROPERTY(double volume READ volume WRITE setVolume NOTIFY volumeChanged)
    Q_PROPERTY(QString lastError READ lastError NOTIFY lastErrorChanged)
    Q_PROPERTY(QVariantList outputDevices READ outputDevices NOTIFY outputDevicesChanged)

public:
    explicit AudioPlaybackEngine(QObject *parent = nullptr);
    ~AudioPlaybackEngine() override;

    bool playing() const { return m_playing; }
    bool bypass() const { return m_bypass; }
    double volume() const { return m_volume; }
    QString lastError() const { return m_lastError; }

    QVariantList outputDevices() const;
    Q_INVOKABLE QString localFilePath(const QUrl &url) const { return url.toLocalFile(); }

    Q_INVOKABLE bool playPcm(const QString &path, int deviceIndex = 0);
    Q_INVOKABLE bool configureEq(const QVariantList &bands);
    Q_INVOKABLE void stop();
    Q_INVOKABLE void refreshOutputDevices();

    void setBypass(bool bypass);
    void setVolume(double volume);

signals:
    void playingChanged();
    void bypassChanged();
    void volumeChanged();
    void lastErrorChanged();
    void outputDevicesChanged();

private:
    void setError(const QString &message);

    QMediaDevices m_mediaDevices;
    QList<QAudioDevice> m_devices;

    std::unique_ptr<QAudioSink> m_sink;
    std::unique_ptr<PcmStreamDevice> m_stream;
    std::unique_ptr<QFile> m_file;

    cardsp::StereoProcessor<> m_processor;
    QVariantList m_eqBands;

    bool m_playing = false;
    bool m_bypass = false;
    double m_volume = 0.25;
    QString m_lastError;
};


