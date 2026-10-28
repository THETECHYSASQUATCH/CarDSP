#include "Audio/AudioFileDecoder.hpp"
#include <QCoreApplication>
#include <QDataStream>
#include <QEventLoop>
#include <QFileInfo>
#include <QTemporaryDir>
#include <QTimer>
#include <QDebug>
#include <cmath>
#include <cstring>
#include <stdexcept>

static void check(bool ok, const char* message) {
    if (!ok) throw std::runtime_error(message);
}
static QString wav(const QString& path, int rate, int channels) {
    QFile file(path);
    check(file.open(QIODevice::WriteOnly), "open WAV fixture");
    const quint32 frames = rate / 4;
    const quint32 bytes = frames * channels * 2;
    QDataStream out(&file);
    out.setByteOrder(QDataStream::LittleEndian);
    out.writeRawData("RIFF", 4); out << quint32(36 + bytes);
    out.writeRawData("WAVEfmt ", 8);
    out << quint32(16) << quint16(1) << quint16(channels)
        << quint32(rate) << quint32(rate * channels * 2)
        << quint16(channels * 2) << quint16(16);
    out.writeRawData("data", 4); out << bytes;
    for (quint32 frame = 0; frame < frames; ++frame)
        for (int channel = 0; channel < channels; ++channel)
            out << qint16(std::sin(6.283185307179586 * 440 * frame / rate) * (channel ? 4000 : 8000));
    check(out.status() == QDataStream::Ok && file.flush(), "write WAV fixture");
    return path;
}
struct Result { QString path, error; bool timedOut = false; };
static Result decode(AudioFileDecoder& decoder, const QString& input) {
    Result result;
    QEventLoop loop;
    QTimer timeout;
    timeout.setSingleShot(true);
    auto ready = QObject::connect(&decoder, &AudioFileDecoder::ready, &loop, [&](const QString& path) {
        result.path = path; loop.quit();
    });
    auto failed = QObject::connect(&decoder, &AudioFileDecoder::failed, &loop, [&](const QString& error) {
        result.error = error; loop.quit();
    });
    QObject::connect(&timeout, &QTimer::timeout, &loop, [&] { result.timedOut = true; loop.quit(); });
    timeout.start(15000);
    const bool started = decoder.decode(input);
    if (started && result.path.isEmpty() && result.error.isEmpty()) loop.exec();
    QObject::disconnect(ready); QObject::disconnect(failed);
    check(!result.timedOut, "decoder timed out");
    return result;
}
static void inspect(const Result& result) {
    if (!result.error.isEmpty()) qCritical() << result.error;
    check(result.error.isEmpty() && !result.path.isEmpty(), "valid WAV rejected");
    QFile pcm(result.path);
    check(pcm.open(QIODevice::ReadOnly), "decoded PCM unavailable");
    const QByteArray bytes = pcm.readAll();
    check(!bytes.isEmpty() && bytes.size() % 8 == 0, "incomplete decoded frames");
    // One quarter second at 48 kHz; allow bounded resampler tail differences.
    check(std::abs(bytes.size() / 8 - 12000) <= 128, "incorrect converted sample rate/duration");
    bool nonzero = false;
    for (qsizetype offset = 0; offset < bytes.size(); offset += 4) {
        float sample;
        std::memcpy(&sample, bytes.constData() + offset, 4);
        check(std::isfinite(sample), "non-finite decoded sample");
        nonzero |= sample != 0;
    }
    check(nonzero, "decoded signal became silence");
}
int main(int argc, char** argv) {
    QCoreApplication app(argc, argv);
    try {
        QTemporaryDir fixtures;
        check(fixtures.isValid(), "fixture directory");
        const auto stereo = wav(fixtures.filePath("stereo.wav"), 48000, 2);
        const auto mono = wav(fixtures.filePath("mono.wav"), 44100, 1);
        QString previous;
        {
            AudioFileDecoder decoder;
            auto result = decode(decoder, stereo);
            inspect(result);
            previous = result.path;
            result = decode(decoder, mono);
            check(!QFileInfo::exists(previous), "replacement leaked temporary PCM");
            inspect(result);
            previous = result.path;
            decoder.cancel();
            check(!QFileInfo::exists(previous), "cancel leaked temporary PCM");
            decoder.cancel();

            QFile bad(fixtures.filePath("malformed.wav"));
            check(bad.open(QIODevice::WriteOnly), "malformed fixture");
            bad.write("not a WAV file"); bad.close();
            result = decode(decoder, bad.fileName());
            check(result.path.isEmpty() && !result.error.isEmpty(), "malformed input accepted");

            int signals = 0;
            auto ready = QObject::connect(&decoder, &AudioFileDecoder::ready, &app, [&] { ++signals; });
            auto failed = QObject::connect(&decoder, &AudioFileDecoder::failed, &app, [&] { ++signals; });
            check(decoder.decode(stereo), "cancel test start");
            decoder.cancel();
            QEventLoop pending;
            QTimer::singleShot(100, &pending, &QEventLoop::quit);
            pending.exec();
            check(signals == 0, "cancelled decoder delivered stale completion");
            QObject::disconnect(ready); QObject::disconnect(failed);
            result = decode(decoder, stereo);
            inspect(result);
            previous = result.path;
        }
        check(!QFileInfo::exists(previous), "destructor leaked temporary PCM");
        qInfo() << "Decoder WAV conversion, failure, cancellation and cleanup tests passed";
        return 0;
    } catch (const std::exception& error) {
        qCritical() << error.what();
        return 1;
    }
}
