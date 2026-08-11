#pragma once

#include <QObject>
#include <QProcess>
#include <qqml.h>

class Process : public QObject
{
    Q_OBJECT
    QML_ELEMENT

public:
    explicit Process(QObject *parent = nullptr);

    Q_INVOKABLE void start(
        const QString &program,
        const QStringList &arguments
    );

signals:
    void outputReady(const QString &output);
    void errorOccurred(const QString &error);
    void finished(int exitCode);

private:
    QProcess m_process;
};
