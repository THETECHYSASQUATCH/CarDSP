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
#ifdef CARDSP_UI_SMOKE_TEST
#include <QQuickItem>
#include <QQuickWindow>
#include <QTimer>
#endif

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

#ifdef CARDSP_UI_SMOKE_TEST
    if (app.arguments().contains("--ui-smoke-test")) {
        QTimer::singleShot(100, &app, [&]() {
            auto fail = [&](const char* message) {
                qCritical() << message;
                app.exit(1);
            };
            auto* root = qobject_cast<QQuickWindow*>(engine.rootObjects().first());
            auto* navigation = root ? root->findChild<QQuickItem*>("navigationShell") : nullptr;
            auto* stack = root ? root->findChild<QQuickItem*>("pageStack") : nullptr;
            auto* bands = root ? root->findChild<QObject*>("eqBandsModel") : nullptr;
            if (!root || !navigation || !stack || !bands) {
                fail("UI objects missing"); return;
            }
            if (bands->property("count").toInt() != 32 || stack->childItems().size() != 8) {
                fail("EQ bands or page count changed"); return;
            }
            for (int selected = 0; selected < 8; ++selected) {
                navigation->setProperty("currentIndex", selected);
                QCoreApplication::processEvents();
                for (int page = 0; page < 8; ++page) {
                    if (stack->childItems()[page]->isVisible() != (page == selected)) {
                        fail("Page visibility mismatch"); return;
                    }
                }
            }
            root->resize(640, 480);
            QCoreApplication::processEvents();
            auto* picker = root->findChild<QQuickItem*>("compactNavigation");
            auto* playback = root->findChild<QQuickItem*>("playbackToolbar");
            auto* microphone = root->findChild<QQuickItem*>("microphonePanel");
            if (!navigation->property("compact").toBool() || !picker || !picker->isVisible()
                || !playback || !playback->isVisible() || !microphone || !microphone->isVisible()
                || audioPlaybackEngine.playing() || microphoneManager.property("capturing").toBool()) {
                fail("Compact navigation or persistent controls failed"); return;
            }
            if (bands->property("count").toInt() != 32) {
                fail("Navigation changed EQ bands"); return;
            }
            qInfo() << "Full UI smoke test passed: eight pages, 32 bands, compact navigation, persistent controls";
            app.exit(0);
        });
    }
#endif
    return app.exec();
}
