#include "process.h"

#include <qqml.h>

Process::Process(QObject *parent)
: QObject(parent)
{
    connect(
        &m_process,
        &QProcess::readyReadStandardOutput,
        this,
        [this]() {
            emit outputReady(
                QString::fromUtf8(
                    m_process.readAllStandardOutput()
                )
            );
        }
    );

    connect(
        &m_process,
        &QProcess::errorOccurred,
        this,
        [this](QProcess::ProcessError) {
            emit errorOccurred(
                m_process.errorString()
            );
        }
    );

    connect(
        &m_process,
        qOverload<int, QProcess::ExitStatus>(&QProcess::finished),
            this,
            [this](int exitCode, QProcess::ExitStatus) {
                emit finished(exitCode);
            }
    );
}

void Process::start(
    const QString &program,
    const QStringList &arguments
)
{
    m_process.start(program, arguments);
}
