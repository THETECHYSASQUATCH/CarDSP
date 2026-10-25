#pragma once

#include <QObject>
#include <QStringList>
#include <QJsonObject>

class PresetManager : public QObject
{
    Q_OBJECT

    Q_PROPERTY(QStringList presets READ presets NOTIFY presetsChanged)
    Q_PROPERTY(QString lastError READ lastError NOTIFY lastErrorChanged)

public:
    explicit PresetManager(QObject *parent = nullptr);

    QStringList presets() const;
    QString lastError() const;

    Q_INVOKABLE bool savePreset(const QString &name,
                               const QString &settingsPath);

    Q_INVOKABLE bool loadPreset(const QString &name,
                               const QString &settingsPath);

    Q_INVOKABLE bool deletePreset(const QString &name);
    Q_INVOKABLE bool renamePreset(const QString &oldName,
                                  const QString &newName);
    Q_INVOKABLE bool duplicatePreset(const QString &source,
                                     const QString &destination);

    Q_INVOKABLE bool exportPreset(const QString &name,
                                  const QString &destinationPath);

    Q_INVOKABLE bool importPreset(const QString &sourcePath,
                                  const QString &name);

    Q_INVOKABLE void refresh();

signals:
    void presetsChanged();
    void lastErrorChanged();

private:
    QString presetDirectory() const;
    QString presetPath(const QString &name) const;

    bool validName(const QString &name) const;
    bool readJson(const QString &path, QJsonObject &object);
    bool writeJson(const QString &path, const QJsonObject &object);
    bool validateSettings(const QJsonObject &object) const;

    void setError(const QString &error);

    QString m_lastError;
};
