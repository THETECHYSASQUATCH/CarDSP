#include "PresetManager.hpp"
#include <QFileInfo>
#include <QDir>
#include <QFile>
#include <QJsonArray>
#include <QJsonDocument>
#include <QJsonObject>
#include <QSaveFile>
#include <QStandardPaths>
#include "EqController.hpp"

#include <QVariantMap>
#include <algorithm>
#include <cmath>
#include <complex>

namespace {
constexpr double pi = 3.14159265358979323846;
static const QStringList defaultBandNames = {
        "Sub-Bass - Infrasonic",
        "Sub-Bass - Deep Rumble",
        "Sub-Bass - Deep Bass",
        "Sub-Bass - Bass Impact",
        "Bass - Subwoofer Punch",
        "Bass - Kick Drum",
        "Bass - Bass Weight",
        "Bass - Upper Bass",
        "Bass - Warmth",
        "Bass - Fullness",
        "Low Mids - Body",
        "Low Mids - Mud",
        "Low Mids - Resonance",
        "Low Mids - Boxiness",
        "Midrange - Instrument Body",
        "Midrange - Vocal Body",
        "Midrange - Vocal Presence",
        "Midrange - Vocal Clarity",
        "Midrange - Definition",
        "Upper Mids - Articulation",
        "Upper Mids - Vocal Detail",
        "Upper Mids - Presence",
        "Upper Mids - Attack",
        "Presence - Detail",
        "Presence - Clarity",
        "Treble - Brightness",
        "Treble - Sibilance",
        "Treble - Sparkle",
        "Treble - Air",
        "High Treble - Brilliance",
        "High Treble - Airiness",
        "High Treble - Extreme Highs"
};


constexpr double frequencies[32] = {
    20, 25, 31.5, 40, 50, 63, 80, 100,
    125, 160, 200, 250, 315, 400, 500, 630,
    800, 1000, 1250, 1600, 2000, 2500, 3150, 4000,
    5000, 6300, 8000, 10000, 12500, 14000, 16000, 20000
};
}

EqController::EqController(QObject *parent)
    : QObject(parent)
{
    m_channels.resize(9);
    m_bandNames.resize(9);

    m_saveTimer.setSingleShot(true);
    m_saveTimer.setInterval(750);

    connect(&m_saveTimer, &QTimer::timeout,
            this, &EqController::saveSettings);

    connect(this, &EqController::bandsChanged,
            this, &EqController::scheduleSave);

    for (auto &names : m_bandNames)
        names = defaultBandNames;

    for (auto &channel : m_channels) {
        channel.resize(32);

        for (int i = 0; i < 32; ++i)
            channel[i].frequency = frequencies[i];
    }

    // Restore settings only after all channels and bands exist.
    loadSettings();

}

QString EqController::settingsFilePath() const
{
    const QString directory =
        QStandardPaths::writableLocation(
            QStandardPaths::AppDataLocation
        );

    return QDir(directory).filePath("settings.json");
}

void EqController::scheduleSave()
{
    m_saveTimer.start();
}

bool EqController::saveSettings()
{
    const QString path = settingsFilePath();

    if (!QDir().mkpath(QFileInfo(path).absolutePath()))
        return false;

    QJsonObject root;
    root["formatVersion"] = 1;
    root["activeChannel"] = m_channel;

    QJsonArray channels;

    for (int channel = 0; channel < m_channels.size(); ++channel) {
        QJsonArray bands;

        for (int i = 0; i < m_channels[channel].size(); ++i) {
            const auto &band = m_channels[channel][i];

            QJsonObject item;
            item["frequency"] = band.frequency;
            item["gain"] = band.gain;
            item["q"] = band.q;
            item["enabled"] = band.enabled;
            item["type"] = band.type;
            item["name"] = m_bandNames[channel][i];

            bands.append(item);
        }

        QJsonObject channelObject;
        channelObject["bands"] = bands;
        channels.append(channelObject);
    }

    root["channels"] = channels;

    QSaveFile file(path);

    if (!file.open(QIODevice::WriteOnly))
        return false;

    const QByteArray json =
        QJsonDocument(root).toJson(QJsonDocument::Indented);

    if (file.write(json) != json.size()) {
        file.cancelWriting();
        return false;
    }

    return file.commit();
}

bool EqController::loadSettings()
{
    QFile file(settingsFilePath());

    if (!file.exists())
        return false;

    if (!file.open(QIODevice::ReadOnly))
        return false;

    QJsonParseError error;
    const QJsonDocument document =
        QJsonDocument::fromJson(file.readAll(), &error);

    if (error.error != QJsonParseError::NoError ||
        !document.isObject())
        return false;

    const QJsonObject root = document.object();

    if (root.value("formatVersion").toInt(-1) != 1)
        return false;

    const QJsonArray channels =
        root.value("channels").toArray();

    if (channels.size() != m_channels.size())
        return false;

    // Validate all channels before applying any settings.
    for (int channel = 0; channel < channels.size(); ++channel) {
        if (!channels[channel].isObject())
            return false;

        const QJsonArray bands =
            channels[channel].toObject().value("bands").toArray();

        if (bands.size() != 32)
            return false;

        for (const auto &value : bands) {
            if (!value.isObject())
                return false;

            const QJsonObject item = value.toObject();

            for (const auto *key : {
                "frequency", "gain", "q", "enabled", "type", "name"
            }) {
                if (!item.contains(key))
                    return false;
            }

            const double frequency = item["frequency"].toDouble(-1);
            const double gain = item["gain"].toDouble(-100);
            const double q = item["q"].toDouble(-1);
            const int type = item["type"].toInt(-1);

            if (!std::isfinite(frequency) ||
                frequency < 20 || frequency > 20000 ||
                !std::isfinite(gain) ||
                gain < -18 || gain > 18 ||
                !std::isfinite(q) ||
                q < 0.1 || q > 30 ||
                type < 0 || type > 5 ||
                !item["enabled"].isBool() ||
                !item["name"].isString() ||
                item["name"].toString().size() > 64)
                return false;
        }
    }

    m_saveTimer.stop();

    for (int channel = 0; channel < channels.size(); ++channel) {
        const QJsonArray bands =
            channels[channel].toObject().value("bands").toArray();

        for (int i = 0; i < bands.size(); ++i) {
            const QJsonObject item = bands[i].toObject();
            auto &band = m_channels[channel][i];

            band.frequency = item["frequency"].toDouble();
            band.gain = item["gain"].toDouble();
            band.q = item["q"].toDouble();
            band.enabled = item["enabled"].toBool();
            band.type = item["type"].toInt();

            m_bandNames[channel][i] = item["name"].toString();
        }
    }

    const int activeChannel = root.value("activeChannel").toInt(0);
    m_channel = std::clamp(activeChannel, 0, 8);

    emit channelChanged();
    emit bandsChanged();
    emit responseChanged();

    return true;
}
int EqController::channel() const
{
    return m_channel;
}

void EqController::setChannel(int channel)
{
    if (channel < 0 || channel >= m_channels.size() ||
        channel == m_channel)
        return;

    m_channel = channel;
    emit channelChanged();
    emit bandsChanged();
    emit responseChanged();
}

QVariantList EqController::bands() const
{
    QVariantList result;

    for (int i = 0; i < m_channels[m_channel].size(); ++i) {
        const auto &band = m_channels[m_channel][i];
        result.append(QVariantMap{
            {"name", m_bandNames[m_channel][i]},
            {"defaultName", defaultBandNames[i]},
            {"frequency", band.frequency},
            {"gain", band.gain},
            {"q", band.q},
            {"enabled", band.enabled},
            {"type", band.type}
        });
    }

    return result;
}

void EqController::setBandName(int index, const QString &name)
{
    if (index < 0 || index >= 32)
        return;

    const QString trimmed = name.trimmed().left(64);

    // An empty name restores the descriptive default.
    const QString effective =
        trimmed.isEmpty() ? defaultBandNames[index] : trimmed;

    if (m_bandNames[m_channel][index] == effective)
        return;

    m_bandNames[m_channel][index] = effective;
    emit bandsChanged();
}

void EqController::resetBandName(int index)
{
    if (index < 0 || index >= 32)
        return;

    setBandName(index, defaultBandNames[index]);
}
void EqController::setBand(int index, double frequency,
                           double gain, double q, bool enabled)
{
    if (index < 0 || index >= 32)
        return;

    if (!std::isfinite(frequency) || !std::isfinite(gain) ||
        !std::isfinite(q))
        return;

    auto &band = m_channels[m_channel][index];

    band.frequency = std::clamp(frequency, 20.0, 20000.0);
    band.gain = std::clamp(gain, -18.0, 18.0);
    band.q = std::clamp(q, 0.1, 30.0);
    band.enabled = enabled;

    emit bandsChanged();
    emit responseChanged();
}

void EqController::setBandType(int index, int type)
{
    if (index < 0 || index >= 32 || type < 0 || type > 5)
        return;

    auto &band = m_channels[m_channel][index];

    if (band.type == type)
        return;

    band.type = type;

    emit bandsChanged();
    emit responseChanged();
}
QVariantList EqController::response() const
{
    QVariantList result;
    constexpr int points = 512;

    struct Coefficients {
        double b0, b1, b2;
        double a0, a1, a2;
    };

    QVector<Coefficients> filters;

    for (const auto &band : m_channels[m_channel]) {
        if (!band.enabled)
            continue;

        if (band.type <= 2 && std::abs(band.gain) < 1e-9)
            continue;

        const double f = std::clamp(
            band.frequency, 20.0, m_sampleRate * 0.499
        );

        const double w0 = 2.0 * pi * f / m_sampleRate;
        const double cs = std::cos(w0);
        const double sn = std::sin(w0);
        const double Q = std::max(band.q, 0.1);
        const double alpha = sn / (2.0 * Q);
        const double A = std::pow(10.0, band.gain / 40.0);

        Coefficients c{};

        switch (band.type) {
        case 1: { // Low shelf
            const double s = 2.0 * std::sqrt(A) * alpha;

            c.b0 = A * ((A + 1) - (A - 1) * cs + s);
            c.b1 = 2 * A * ((A - 1) - (A + 1) * cs);
            c.b2 = A * ((A + 1) - (A - 1) * cs - s);

            c.a0 = (A + 1) + (A - 1) * cs + s;
            c.a1 = -2 * ((A - 1) + (A + 1) * cs);
            c.a2 = (A + 1) + (A - 1) * cs - s;
            break;
        }

        case 2: { // High shelf
            const double s = 2.0 * std::sqrt(A) * alpha;

            c.b0 = A * ((A + 1) + (A - 1) * cs + s);
            c.b1 = -2 * A * ((A - 1) + (A + 1) * cs);
            c.b2 = A * ((A + 1) + (A - 1) * cs - s);

            c.a0 = (A + 1) - (A - 1) * cs + s;
            c.a1 = 2 * ((A - 1) - (A + 1) * cs);
            c.a2 = (A + 1) - (A - 1) * cs - s;
            break;
        }

        case 3: // Low pass
            c.b0 = (1 - cs) / 2;
            c.b1 = 1 - cs;
            c.b2 = (1 - cs) / 2;
            c.a0 = 1 + alpha;
            c.a1 = -2 * cs;
            c.a2 = 1 - alpha;
            break;

        case 4: // High pass
            c.b0 = (1 + cs) / 2;
            c.b1 = -(1 + cs);
            c.b2 = (1 + cs) / 2;
            c.a0 = 1 + alpha;
            c.a1 = -2 * cs;
            c.a2 = 1 - alpha;
            break;

        case 5: // Notch
            c.b0 = 1;
            c.b1 = -2 * cs;
            c.b2 = 1;
            c.a0 = 1 + alpha;
            c.a1 = -2 * cs;
            c.a2 = 1 - alpha;
            break;

        default: // Peaking EQ
            c.b0 = 1 + alpha * A;
            c.b1 = -2 * cs;
            c.b2 = 1 - alpha * A;
            c.a0 = 1 + alpha / A;
            c.a1 = -2 * cs;
            c.a2 = 1 - alpha / A;
            break;
        }

        if (!std::isfinite(c.a0) || std::abs(c.a0) < 1e-12)
            continue;

        c.b0 /= c.a0;
        c.b1 /= c.a0;
        c.b2 /= c.a0;
        c.a1 /= c.a0;
        c.a2 /= c.a0;
        c.a0 = 1.0;

        filters.append(c);
    }

    for (int i = 0; i < points; ++i) {
        const double frequency =
            20.0 * std::pow(1000.0, double(i) / (points - 1));

        const double w = 2.0 * pi * frequency / m_sampleRate;
        const std::complex<double> z1 = std::polar(1.0, -w);
        const std::complex<double> z2 = z1 * z1;

        double totalDb = 0.0;

        for (const auto &c : filters) {
            const auto numerator =
                c.b0 + c.b1 * z1 + c.b2 * z2;

            const auto denominator =
                c.a0 + c.a1 * z1 + c.a2 * z2;

            const double magnitude =
                std::abs(numerator) /
                std::max(std::abs(denominator), 1e-15);

            totalDb += 20.0 * std::log10(
                std::max(magnitude, 1e-12)
            );
        }

        result.append(QVariantMap{
            {"frequency", frequency},
            {"gain", totalDb}
        });
    }

    return result;
}

bool EqController::activatePreset(const QString &name, QObject *manager)
{
    auto *presets = qobject_cast<PresetManager *>(manager);

    if (!presets)
        return false;

    // Finish any pending EQ autosave before replacing the settings file.
    m_saveTimer.stop();

    if (!saveSettings())
        return false;

    if (!presets->loadPreset(name, settingsFilePath()))
        return false;

    return loadSettings();
}
