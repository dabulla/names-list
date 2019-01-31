#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQmlEngine>
#include "indexmodel.h"

int main(int argc, char *argv[])
{
    QCoreApplication::setAttribute(Qt::AA_EnableHighDpiScaling);

    QGuiApplication app(argc, argv);

    qmlRegisterType<TestModel>("de.danielbulla", 1, 0, "IndexModel");

    QQmlApplicationEngine engine;
    engine.load(QUrl(QStringLiteral("qrc:/main_native.qml")));
    if (engine.rootObjects().isEmpty())
        return -1;

    return app.exec();
}
