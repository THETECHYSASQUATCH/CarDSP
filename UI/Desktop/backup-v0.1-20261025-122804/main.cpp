#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQuickStyle>

int main(int argc, char *argv[])
{
    QGuiApplication app(argc, argv);

    QQuickStyle::setStyle("Fusion");

    QQmlApplicationEngine engine;
    engine.loadFromModule("CarDSP", "Main");

    if (engine.rootObjects().isEmpty())
        return -1;

    return app.exec();
}