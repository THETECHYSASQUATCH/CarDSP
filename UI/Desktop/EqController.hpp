#include <QStringList>
#pragma once

#include <QObject>
#include <QTimer>
#include <QString>
#include <QVariantList>
#include <QVector>

class EqController : public QObject
{
    Q_OBJECT

    Q_PROPERTY(int channel READ channel WRITE setChannel NOTIFY channelChanged)
    Q_PROPERTY(QVariantList bands READ bands NOTIFY bandsChanged)
    Q_PROPERTY(QVariantList response READ response NOTIFY responseChanged)

public:
    explicit EqController(QObject *parent = nullptr);

    Q_INVOKABLE bool saveSettings();
    Q_INVOKABLE bool loadSettings();
    Q_INVOKABLE QString settingsFilePath() const;
    Q_INVOKABLE bool activatePreset(const QString &name, QObject *manager);

    int channel() const;
    void setChannel(int channel);

    QVariantList bands() const;
    QVariantList response() const;

    Q_INVOKABLE void setBandType(int index, int type);
    Q_INVOKABLE void setBandName(int index, const QString &name);
    Q_INVOKABLE void resetBandName(int index);
    Q_INVOKABLE void setBand(int index, double frequency,
                             double gain, double q, bool enabled);

signals:
    void channelChanged();
    void bandsChanged();
    void responseChanged();

private:
    struct Band {
        double frequency = 1000.0;
        double gain = 0.0;
        double q = 1.41;
        bool enabled = true;
        int type = 0;
    };

    QVector<QVector<Band>> m_channels;
    QVector<QStringList> m_bandNames;
    int m_channel = 0;
    double m_sampleRate = 48000.0;
    QTimer m_saveTimer;
    void scheduleSave();
};

