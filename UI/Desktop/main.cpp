#include <QDebug>
#include <QScreen>
#include "Audio/AudioPlaybackEngine.hpp"
#include "Audio/MicrophoneManager.hpp"
#include "Audio/SpectrumAnalyzer.hpp"
#include <QQmlContext>
#include "EqController.hpp"
#include "PresetManager.hpp"
#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQuickStyle>

int main(int argc, char *argv[])
{
    QQuickStyle::setStyle("Fusion");
    QGuiApplication app(argc, argv);

    if (auto *screen = QGuiApplication::primaryScreen()) {
        qInfo() << "Qt screen:" << screen->name();
        qInfo() << "Qt logical DPI:" << screen->logicalDotsPerInch();
        qInfo() << "Qt device pixel ratio:" << screen->devicePixelRatio();
        qInfo() << "QT_SCALE_FACTOR:" << qEnvironmentVariable("QT_SCALE_FACTOR");
    }

    QQmlApplicationEngine engine;

    EqController eqController;
    PresetManager presetManager;

    engine.rootContext()->setContextProperty(
        "eqController", &eqController
    );

    engine.rootContext()->setContextProperty(
        "presetManager", &presetManager
    );
    MicrophoneManager microphoneManager;
    engine.rootContext()->setContextProperty(
        "microphoneManager",
        &microphoneManager
    );
    SpectrumAnalyzer spectrumAnalyzer;

    QObject::connect(
        &microphoneManager,
        &MicrophoneManager::pcmAvailable,
        &spectrumAnalyzer,
        &SpectrumAnalyzer::processSamples
    );

    engine.rootContext()->setContextProperty(
        "spectrumAnalyzer",
        &spectrumAnalyzer
    );

    AudioPlaybackEngine audioPlaybackEngine;

    engine.rootContext()->setContextProperty(
        "audioPlaybackEngine",
        &audioPlaybackEngine
    );

    // Phase 4C: Synchronize EQ settings with audio playback.
    QObject::connect(
        &eqController,
        &EqController::bandsChanged,
        &audioPlaybackEngine,
        [&eqController, &audioPlaybackEngine]() {
            audioPlaybackEngine.configureEq(eqController.bands());
        }
    );

    audioPlaybackEngine.configureEq(eqController.bands());

    engine.loadFromModule("CarDSP", "Main");

    if (engine.rootObjects().isEmpty())
        return -1;

    return app.exec();
}
