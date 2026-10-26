#pragma once

#include <QObject>
#include <QAudioFormat>
#include <QAudioSource>
#include <QIODevice>
#include <QMediaDevices>
#include <QStringList>
#include <QVariantList>
#include <memory>

class MicrophoneManager : public QObject
{
    Q_OBJECT

    Q_PROPERTY(QVariantList devices READ devices NOTIFY devicesChanged)
    Q_PROPERTY(bool capturing READ capturing NOTIFY capturingChanged)
    Q_PROPERTY(double level READ level NOTIFY levelChanged)
    Q_PROPERTY(QString lastError READ lastError NOTIFY lastErrorChanged)

public:
    explicit MicrophoneManager(QObject *parent = nullptr);

    QVariantList devices() const;
    bool capturing() const;
    double level() const;
    QString lastError() const;

    Q_INVOKABLE void refreshDevices();
    Q_INVOKABLE bool startCapture(int deviceIndex);
    Q_INVOKABLE void stopCapture();

signals:
    void devicesChanged();
    void capturingChanged();
    void levelChanged();
    void lastErrorChanged();

    // Normalized mono PCM, designed for both local and future mobile input.
    void pcmAvailable(const QVector<float> &samples, int sampleRate);

private:
    void processAudio();
    void setError(const QString &error);

    QMediaDevices m_mediaDevices;
    QList<QAudioDevice> m_devices;
    std::unique_ptr<QAudioSource> m_source;
    QIODevice *m_io = nullptr;

    QByteArray m_pending;
    QAudioFormat m_format;
    bool m_capturing = false;
    double m_level = 0.0;
    QString m_lastError;
};
