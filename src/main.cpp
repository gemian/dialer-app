
/*
 * Copyright (C) 2012-2013 Canonical, Ltd.
 *
 * Authors:
 *  Olivier Tilloy <olivier.tilloy@canonical.com>
 *
 * This file is part of dialer-app.
 *
 * dialer-app is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; version 3.
 *
 * dialer-app is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

// Qt
#include <QDebug>
#include <QString>
#include <QTemporaryFile>
#include <QTextStream>
#include <QQmlDebuggingEnabler>
#include <QLockFile>
#include <QProcess>

// libc
#include <cerrno>
#include <cstdlib>
#include <cstring>

// local
#include "dialerapplication.h"
#include "config.h"

// make it possible to do QML profiling
static QQmlDebuggingEnabler debuggingEnabler(false);

int main(int argc, char** argv)
{
    QGuiApplication::setApplicationName("Dialer App");
    DialerApplication application(argc, argv);

    // Try to create lockfile
    QLockFile lockFile("/tmp/dialerapp.lock");
    if(!lockFile.tryLock(100)) {
        if (lockFile.error() == QLockFile::LockFailedError) {
            qint64 pid;
            QString hostname;
            QString appname;
            if (lockFile.getLockInfo(&pid, &hostname, &appname)) {
                // Kill original process and try again
	        qDebug() << "Dialer App already running - pid" << pid;
                QProcess::execute("kill " + QString::number(pid));
            }
        }

        // Try to create lockfile, second attempt
        if(!lockFile.tryLock(1000)) {
            qDebug() << "Dialer App already running, can't stop it.";
            return(0);
        }
    }

    if (!application.setup()) {
        return 0;
    }

    return application.exec();
}

