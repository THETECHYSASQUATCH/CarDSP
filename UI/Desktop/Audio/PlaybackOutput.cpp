#include "PlaybackOutput.hpp"

namespace {
class QtPlaybackOutput final : public PlaybackOutput {
    QAudioSink sink;
public:
    QtPlaybackOutput(const QAudioDevice& device, const QAudioFormat& format)
        : sink(device, format) {
        // 100 ms of stereo Float32 gives file I/O some scheduling headroom.
        sink.setBufferSize(4800 * 8);
        connect(&sink, &QAudioSink::stateChanged, this, &PlaybackOutput::stateChanged);
    }
    void start(QIODevice* source) override { sink.start(source); }
    void reset() override { sink.reset(); }
    void suspend() override { sink.suspend(); }
    void resume() override { sink.resume(); }
    void setVolume(double value) override { sink.setVolume(value); }
    qint64 processedUSecs() const override { return sink.processedUSecs(); }
    QAudio::Error error() const override { return sink.error(); }
};
}
std::unique_ptr<PlaybackOutput> PlaybackBackend::create(const QAudioDevice& d, const QAudioFormat& f) {
    return std::make_unique<QtPlaybackOutput>(d, f);
}
