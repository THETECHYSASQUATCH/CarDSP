#include "PresetManager.hpp"

#include <QDir>
#include <QFile>
#include <QFileInfo>
#include <QJsonArray>
#include <QJsonDocument>
#include <QJsonParseError>
#include <QRegularExpression>
#include <QSaveFile>
#include <QStandardPaths>

#include <cmath>

PresetManager::PresetManager(QObject *parent)
    : QObject(parent)
{
}

QString PresetManager::presetDirectory() const
{
    const QString base = QStandardPaths::writableLocation(
        QStandardPaths::AppDataLocation);

    return QDir(base).filePath("presets");
}

QString PresetManager::presetPath(const QString &name) const
{
    return QDir(presetDirectory()).filePath(name + ".json");
}

bool PresetManager::validName(const QString &name) const
{
    static const QRegularExpression expression(
        QStringLiteral("^[A-Za-z0-9 _-]{1,64}$"));

    return expression.match(name).hasMatch() &&
           name.trimmed() == name &&
           !name.trimmed().isEmpty();
}

QStringList PresetManager::presets() const
{
    QDir directory(presetDirectory());

    QStringList names;

    const QStringList files = directory.entryList(
        {"*.json"}, QDir::Files, QDir::Name);

    for (const QString &file : files)
        names.append(QFileInfo(file).completeBaseName());

    return names;
}

QString PresetManager::lastError() const
{
    return m_lastError;
}

void PresetManager::setError(const QString &error)
{
    if (m_lastError == error)
        return;

    m_lastError = error;
    emit lastErrorChanged();
}

bool PresetManager::readJson(const QString &path,
                             QJsonObject &object)
{
    QFile file(path);

    if (!file.open(QIODevice::ReadOnly)) {
        setError("Cannot open: " + path);
        return false;
    }

    QJsonParseError error;

    const QJsonDocument document =
        QJsonDocument::fromJson(file.readAll(), &error);

    if (error.error != QJsonParseError::NoError ||
        !document.isObject()) {
        setError("Invalid JSON document.");
        return false;
    }

    object = document.object();
    return true;
}

bool PresetManager::writeJson(const QString &path,
                              const QJsonObject &object)
{
    if (!QDir().mkpath(QFileInfo(path).absolutePath())) {
        setError("Cannot create destination directory.");
        return false;
    }

    QSaveFile file(path);

    if (!file.open(QIODevice::WriteOnly)) {
        setError("Cannot write: " + path);
        return false;
    }

    const QByteArray bytes =
        QJsonDocument(object).toJson(QJsonDocument::Indented);

    if (file.write(bytes) != bytes.size()) {
        file.cancelWriting();
        setError("Failed to write complete preset.");
        return false;
    }

    if (!file.commit()) {
        setError("Failed to commit preset.");
        return false;
    }

    setError({});
    return true;
}

bool PresetManager::validateSettings(const QJsonObject &root) const
{
    if (root.value("formatVersion").toInt(-1) != 1)
        return false;

    const QJsonArray channels = root.value("channels").toArray();

    if (channels.size() != 9)
        return false;

    for (const QJsonValue &channelValue : channels) {
        if (!channelValue.isObject())
            return false;

        const QJsonArray bands =
            channelValue.toObject().value("bands").toArray();

        if (bands.size() != 32)
            return false;

        for (const QJsonValue &bandValue : bands) {
            if (!bandValue.isObject())
                return false;

            const QJsonObject band = bandValue.toObject();

            for (const char *key : {
                     "frequency", "gain", "q", "enabled",
                     "type", "name"}) {
                if (!band.contains(key))
                    return false;
            }

            if (!band.value("frequency").isDouble() ||
                !band.value("gain").isDouble() ||
                !band.value("q").isDouble() ||
                !band.value("type").isDouble() ||
                !band.value("enabled").isBool() ||
                !band.value("name").isString())
                return false;

            const double frequency = band.value("frequency").toDouble();
            const double gain = band.value("gain").toDouble();
            const double q = band.value("q").toDouble();
            const double type = band.value("type").toDouble();

            if (!std::isfinite(frequency) ||
                frequency < 20 || frequency > 20000 ||
                !std::isfinite(gain) ||
                gain < -18 || gain > 18 ||
                !std::isfinite(q) ||
                q < 0.1 || q > 30 ||
                !std::isfinite(type) ||
                type < 0 || type > 5 ||
                std::floor(type) != type ||
                band.value("name").toString().size() > 64)
                return false;
        }
    }

    return true;
}

bool PresetManager::savePreset(const QString &name,
                               const QString &settingsPath)
{
    if (!validName(name)) {
        setError("Invalid preset name.");
        return false;
    }

    QJsonObject object;

    if (!readJson(settingsPath, object))
        return false;

    if (!validateSettings(object)) {
        setError("Settings format is invalid.");
        return false;
    }

    object["presetName"] = name;
    object["presetSchemaVersion"] = 1;

    if (!writeJson(presetPath(name), object))
        return false;

    emit presetsChanged();
    return true;
}

bool PresetManager::loadPreset(const QString &name,
                               const QString &settingsPath)
{
    if (!validName(name)) {
        setError("Invalid preset name.");
        return false;
    }

    QJsonObject object;

    if (!readJson(presetPath(name), object))
        return false;

    if (!validateSettings(object)) {
        setError("Preset validation failed.");
        return false;
    }

    // Only write the validated configuration.
    // The EQ controller will reload it afterward.
    return writeJson(settingsPath, object);
}

bool PresetManager::deletePreset(const QString &name)
{
    if (!validName(name)) {
        setError("Invalid preset name.");
        return false;
    }

    if (!QFile::remove(presetPath(name))) {
        setError("Cannot delete preset.");
        return false;
    }

    setError({});
    emit presetsChanged();
    return true;
}

bool PresetManager::renamePreset(const QString &oldName,
                                 const QString &newName)
{
    if (!validName(oldName) || !validName(newName) ||
        QFile::exists(presetPath(newName))) {
        setError("Invalid or duplicate preset name.");
        return false;
    }

    QJsonObject object;

    if (!readJson(presetPath(oldName), object))
        return false;

    if (!validateSettings(object)) {
        setError("Source preset is invalid.");
        return false;
    }

    object["presetName"] = newName;

    if (!writeJson(presetPath(newName), object))
        return false;

    if (!QFile::remove(presetPath(oldName))) {
        QFile::remove(presetPath(newName));
        setError("Could not remove old preset.");
        return false;
    }

    emit presetsChanged();
    return true;
}

bool PresetManager::duplicatePreset(const QString &source,
                                    const QString &destination)
{
    if (!validName(source) || !validName(destination) ||
        QFile::exists(presetPath(destination))) {
        setError("Invalid or duplicate destination.");
        return false;
    }

    QJsonObject object;

    if (!readJson(presetPath(source), object))
        return false;

    if (!validateSettings(object)) {
        setError("Source preset is invalid.");
        return false;
    }

    object["presetName"] = destination;

    if (!writeJson(presetPath(destination), object))
        return false;

    emit presetsChanged();
    return true;
}

bool PresetManager::exportPreset(const QString &name,
                                 const QString &destinationPath)
{
    if (!validName(name)) {
        setError("Invalid preset name.");
        return false;
    }

    QJsonObject object;

    if (!readJson(presetPath(name), object))
        return false;

    if (!validateSettings(object)) {
        setError("Preset validation failed.");
        return false;
    }

    return writeJson(destinationPath, object);
}

bool PresetManager::importPreset(const QString &sourcePath,
                                 const QString &name)
{
    if (!validName(name) || QFile::exists(presetPath(name))) {
        setError("Invalid or duplicate preset name.");
        return false;
    }

    QJsonObject object;

    if (!readJson(sourcePath, object))
        return false;

    if (!validateSettings(object)) {
        setError("Imported preset is invalid.");
        return false;
    }

    object["presetName"] = name;
    object["presetSchemaVersion"] = 1;

    if (!writeJson(presetPath(name), object))
        return false;

    emit presetsChanged();
    return true;
}

void PresetManager::refresh()
{
    emit presetsChanged();
}
