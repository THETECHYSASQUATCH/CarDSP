#include "Audio/PcmStreamDevice.hpp"
#include "Audio/PlaybackEq.hpp"
#include <QCoreApplication>
#include <QTemporaryFile>
#include <iostream>
#include <stdexcept>
#include <limits>

void require(bool ok, const char* message) {
    if (!ok) throw std::runtime_error(message);
}
QVariantList bands(int type, bool enabled = true) {
    return {QVariantMap{{"type", type}, {"frequency", 1000.0},
                        {"gain", -6.0}, {"q", 0.71}, {"enabled", enabled}}};
}
void regression() {
    QString error;
    cardsp::StereoProcessor<> processor;
    require(!configurePlaybackProcessor(processor, bands(6), error), "invalid type accepted");
    auto invalid = bands(0); auto map = invalid[0].toMap();
    map["q"] = std::numeric_limits<double>::quiet_NaN(); invalid[0] = map;
    require(!configurePlaybackProcessor(processor, invalid, error), "NaN Q accepted");
    require(configurePlaybackProcessor(processor, bands(0, false), error), "disabled band rejected");
    for (int type = 0; type < 6; ++type) {
        require(configurePlaybackProcessor(processor, bands(type), error), "valid type rejected");
        cardsp::StereoProcessor<> expected;
        cardsp::BiquadCoefficients c;
        switch(type) {
        case 0: c = cardsp::makePeakingEQ(48000, 1000, .71f, -6); break;
        case 1: c = cardsp::makeLowShelf(48000, 1000, -6); break;
        case 2: c = cardsp::makeHighShelf(48000, 1000, -6); break;
        case 3: c = cardsp::makeLowPass(48000, 1000, .71f); break;
        case 4: c = cardsp::makeHighPass(48000, 1000, .71f); break;
        case 5: c = cardsp::makeNotch(48000, 1000, .71f); break;
        }
        require(expected.add(c), "filter rejected");
        std::array<float,2048> a{}, b{}; a[0]=b[0]=1;
        processor.processInterleaved(a.data(),1024); expected.processInterleaved(b.data(),1024);
        for (size_t sample = 0; sample < a.size(); ++sample) {
            if (!std::isfinite(a[sample]) || !std::isfinite(b[sample]) ||
                std::abs(a[sample] - b[sample]) > 1e-5f) {
                std::cerr << "filter type mapping mismatch: type=" << type
                          << " sample=" << sample << " actual=" << a[sample]
                          << " expected=" << b[sample] << '\\n';
                throw std::runtime_error("filter type mapping mismatch");
            }
        }
        require(a[0] != 1, "filter did not change impulse");
        for(size_t i=1;i<a.size();i+=2) require(a[i]==0, "channel leakage");
    }
    QTemporaryFile file; require(file.open(), "temp open failed");
    std::array<float,128> source{};
    for(size_t i=0;i<source.size();++i) source[i]=float(i)/256;
    file.write(reinterpret_cast<const char*>(source.data()),sizeof(source)); file.seek(0);
    PcmStreamDevice stream(&file,&processor); stream.setBypass(true);
    require(stream.open(QIODevice::ReadOnly), "stream open failed");
    QByteArray result;
    while(!stream.atEnd()) { auto chunk=stream.read(13); require(!chunk.isEmpty(), "short-read stall"); result+=chunk; }
    require(result == QByteArray(reinterpret_cast<const char*>(source.data()),sizeof(source)), "bypass or odd read changed bytes");
    stream.close(); file.resize(0); file.seek(0);
    float bad[2]={std::numeric_limits<float>::infinity(),0};
    file.write(reinterpret_cast<char*>(bad),sizeof(bad)); file.seek(0);
    require(stream.open(QIODevice::ReadOnly), "reopen failed");
    char buffer[64]; require(stream.read(buffer,sizeof(buffer)) == -1, "non-finite input accepted");
    stream.close(); file.resize(0); file.seek(0);
    file.write("bad", 3); file.seek(0);
    require(stream.open(QIODevice::ReadOnly), "malformed reopen failed");
    require(stream.read(buffer,sizeof(buffer)) == -1, "incomplete frame accepted");
    std::cout << "Playback regression checks passed\n";
}
void inspectSong(const QString& path) {
    // No QAudioSink is created: this executable cannot send audio to a device.
    for(int mode=-2; mode<6; ++mode) {
        QFile file(path), reference(path);
        require(file.open(QIODevice::ReadOnly) && reference.open(QIODevice::ReadOnly), "song open failed");
        require(file.size()>0 && file.size()%8==0, "invalid PCM size");
        cardsp::StereoProcessor<> processor; QString error;
        require(configurePlaybackProcessor(processor, mode<0 ? QVariantList{} : bands(mode),error), "song EQ rejected");
        PcmStreamDevice stream(&file,&processor); stream.setBypass(mode==-2); stream.open(QIODevice::ReadOnly);
        qint64 total=0, changed=0, over=0; double peak=0, energy=0;
        char bytes[8192];
        while(true) {
            qint64 n=stream.read(bytes,sizeof(bytes)); require(n>=0,"song stream failed"); if(!n) break;
            auto original=reference.read(n); require(original.size()==n,"reference length mismatch");
            require(n%8==0,"partial output frame");
            for(qint64 i=0;i<n;i+=4) {
                float sample, input; std::memcpy(&sample,bytes+i,4); std::memcpy(&input,original.constData()+i,4);
                require(std::isfinite(sample),"non-finite output");
                peak=std::max(peak,double(std::abs(sample))); energy+=double(sample)*sample;
                changed+=sample!=input; over+=std::abs(sample)>1;
            }
            total+=n;
        }
        require(total==file.size(),"truncated song output");
        require(mode<0 ? changed==0 : changed>0,"unexpected processing result");
        std::cout << "mode=" << mode << " frames=" << total/8 << " seconds=" << double(total)/384000
                  << " peak=" << peak << " rms=" << std::sqrt(energy/(total/4))
                  << " samples_over_full_scale=" << over << " changed=" << changed << '\n';
    }
}
int main(int argc,char** argv) {
    QCoreApplication app(argc,argv);
    try { regression(); if(argc>1) inspectSong(QString::fromLocal8Bit(argv[1])); }
    catch(const std::exception& e) { std::cerr<<e.what()<<'\n'; return 1; }
}
