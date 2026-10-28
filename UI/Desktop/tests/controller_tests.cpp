#include "Audio/AudioPlaybackEngine.hpp"
#include <QCoreApplication>
#include <QEvent>
#include <QTemporaryFile>
#include <QDebug>
#include <stdexcept>

static void check(bool ok, const char* message) {
    if (!ok) throw std::runtime_error(message);
}
class FakeOutput final : public PlaybackOutput {
public:
    QIODevice* input = nullptr;
    qint64 elapsed = 0;
    QAudio::Error failure = QAudio::NoError;
    bool suspended = false;
    double volume = 0;
    void start(QIODevice* device) override { input = device; }
    void reset() override {}
    void suspend() override { suspended = true; }
    void resume() override { suspended = false; }
    void setVolume(double value) override { volume = value; }
    qint64 processedUSecs() const override { return elapsed; }
    QAudio::Error error() const override { return failure; }
    void idle() { emit stateChanged(QAudio::IdleState); }
    void fail() { failure = QAudio::IOError; emit stateChanged(QAudio::StoppedState); }
};
class FakeBackend final : public PlaybackBackend {
public:
    bool connected = true, supported = true, failStart = false;
    FakeOutput* output = nullptr;
    int creates = 0;
    QList<QAudioDevice> devices() const override {
        return connected ? QList<QAudioDevice>{QAudioDevice{}} : QList<QAudioDevice>{};
    }
    bool supports(const QAudioDevice&, const QAudioFormat&) const override { return supported; }
    std::unique_ptr<PlaybackOutput> create(const QAudioDevice&, const QAudioFormat&) override {
        auto result = std::make_unique<FakeOutput>();
        result->failure = failStart ? QAudio::OpenError : QAudio::NoError;
        output = result.get(); ++creates;
        return result;
    }
};
static void deliver() { QCoreApplication::sendPostedEvents(nullptr, QEvent::MetaCall); }
int main(int argc, char** argv) {
    QCoreApplication app(argc, argv);
    try {
        QTemporaryFile file;
        check(file.open(), "fixture open");
        // Two seconds of silent 48 kHz stereo Float32 PCM, with no real output.
        check(file.write(QByteArray(48000 * 2 * 8, '\0')) == 48000 * 2 * 8, "fixture write");
        check(file.flush(), "fixture flush");
        auto backend = std::make_shared<FakeBackend>();
        AudioPlaybackEngine player(backend);
        check(!player.playPcm(file.fileName(), -1), "invalid device accepted");
        check(player.playPcm(file.fileName()), "play failed");
        check(player.playing() && player.duration() == 2000, "session/duration");
        player.pause(); player.pause();
        check(player.paused() && backend->output->suspended, "pause");
        check(player.seek(300), "paused seek failed");
        check(player.paused() && backend->output->suspended && player.position() == 300, "paused seek state");
        player.resume(); player.resume();
        check(!player.paused() && !backend->output->suspended, "resume");
        check(player.seek(-20) && player.position() == 0, "negative seek clamp");

        // Recovery must not truncate consumed time to whole milliseconds.
        // 12345 us corresponds to 592 complete frames, not 576.
        backend->output->elapsed = 12345;
        backend->output->idle(); deliver();
        check(backend->output->input->bytesAvailable() == file.size() - 592 * 8, "recovery replayed consumed frames");
        backend->output->elapsed = 1000;
        backend->output->idle(); deliver();
        check(backend->output->input->bytesAvailable() == file.size() - 640 * 8, "recovery lost fractional base");
        backend->output->idle(); deliver();
        backend->output->idle(); deliver();
        check(!player.playing() && !player.lastError().isEmpty(), "unbounded underrun recovery");

        check(player.playPcm(file.fileName()), "restart");
        player.pause();
        backend->connected = false;
        player.refreshOutputDevices();
        check(!player.playing() && !player.paused() && !player.lastError().isEmpty(), "paused disconnect");
        backend->connected = true;
        player.refreshOutputDevices();
        check(player.playPcm(file.fileName()), "reconnect");
        backend->output->fail(); deliver();
        check(!player.playing() && !player.lastError().isEmpty(), "output error");

        backend->failStart = true;
        check(!player.playPcm(file.fileName()) && !player.playing(), "failed start");
        backend->failStart = false;
        check(player.playPcm(file.fileName()), "restart after failed start");
        backend->output->idle(); // Queue callback from the old session.
        player.stop();
        check(player.playPcm(file.fileName()), "restart before stale callback");
        const int creates = backend->creates;
        deliver();
        check(player.playing() && backend->creates == creates, "stale callback affected new session");

        player.setVolume(2.0);
        check(player.volume() == 1.0 && backend->output->volume == 1.0, "volume clamp");
        check(player.seek(9999) && !player.playing() && player.position() == 2000, "end seek");
        check(player.playPcm(file.fileName()), "EOF restart");
        while (!backend->output->input->read(8192).isEmpty()) {}
        backend->output->idle(); deliver();
        check(!player.playing() && player.position() == player.duration(), "natural EOF");
        player.stop(); player.stop();
        check(!player.playing() && !player.paused() && !player.loading() && player.duration() == 0, "stop reset");
        backend->supported = false;
        check(!player.playPcm(file.fileName()), "unsupported format");
        qInfo() << "Controller regression tests passed";
        return 0;
    } catch (const std::exception& error) {
        qCritical() << error.what();
        return 1;
    }
}
