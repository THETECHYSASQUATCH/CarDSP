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

    QQmlApplicationEngine engine;

    EqController eqController;
    PresetManager presetManager;

    engine.rootContext()->setContextProperty(
        "eqController", &eqController
    );

    engine.rootContext()->setContextProperty(
        "presetManager", &presetManager
    );

    engine.loadFromModule("CarDSP", "Main");

    if (engine.rootObjects().isEmpty())
        return -1;

    return app.exec();
}


