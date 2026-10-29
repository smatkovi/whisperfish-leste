// Hildon shell helpers for src/leste.rs (Maemo Leste builds only).
#pragma once
#include <QtCore/QString>
#include <QtCore/QVariant>

#ifdef WHISPERFISH_LESTE
#include <QtCore/QHash>
#include <QtCore/QPointer>
#include <QtCore/QUrl>
#include <QtCore/QDebug>
#include <QtDBus/QDBusConnection>
#include <QtDBus/QDBusMessage>
#include <QtQml/QQmlEngine>
#include <QtQuick/QQuickItem>
#include <QtQuickWidgets/QQuickWidget>
#include <QtWidgets/QAction>
#include <QtWidgets/QApplication>
#include <QtWidgets/QMainWindow>
#include <QtWidgets/QMenuBar>

static QQmlEngine *wf_engine = nullptr;
static QHash<int, QPointer<QMainWindow>> wf_windows;
static int wf_next_window = 0;

static QMainWindow *wf_window(int id)
{
    QPointer<QMainWindow> w = wf_windows.value(id);
    return w.data();
}

static QObject *wf_root(int id)
{
    QMainWindow *w = wf_window(id);
    if (!w)
        return nullptr;
    QQuickWidget *view = qobject_cast<QQuickWidget *>(w->centralWidget());
    return view ? view->rootObject() : nullptr;
}

// Window 0 is the main window; all others are stacked on top of it.
static int wf_open_window(const QUrl &url, const QVariantMap &props, const QString &title)
{
    if (!wf_engine)
        return -1;
    const int id = wf_next_window++;
    QMainWindow *parent = id == 0 ? nullptr : wf_window(0);
    QMainWindow *w = new QMainWindow(parent);
    if (parent) {
        w->setAttribute(Qt::WA_DeleteOnClose);
        w->setProperty("X-Maemo-StackedWindow", 1);
    }
    w->setWindowTitle(title);
    wf_windows.insert(id, w);
    QObject::connect(w, &QObject::destroyed, [id]() { wf_windows.remove(id); });

    QQuickWidget *view = new QQuickWidget(wf_engine, w);
    view->setResizeMode(QQuickWidget::SizeRootObjectToView);
    view->setSource(url);
    if (view->status() == QQuickWidget::Error) {
        for (const QQmlError &e : view->errors())
            qWarning() << e.toString();
    }
    if (QQuickItem *root = view->rootObject()) {
        root->setProperty("windowId", id);
        for (auto it = props.constBegin(); it != props.constEnd(); ++it)
            root->setProperty(it.key().toUtf8().constData(), it.value());
    }
    w->setCentralWidget(view);

    // Without a window manager (tests on a virtual screen) nothing
    // maximises the window: WHISPERFISH_WINDOW_SIZE=WIDTHxHEIGHT.
    const QList<QByteArray> size = qgetenv("WHISPERFISH_WINDOW_SIZE").split('x');
    if (size.size() == 2)
        w->resize(size[0].toInt(), size[1].toInt());
    w->show();
    return id;
}

static void wf_set_menu(int id, const QStringList &items)
{
    QMainWindow *w = wf_window(id);
    if (!w)
        return;
    QMenuBar *bar = w->menuBar();
    bar->clear();
    for (int i = 0; i < items.size(); ++i) {
        QAction *a = bar->addAction(items[i]);
        QObject::connect(a, &QAction::triggered, [id, i]() {
            if (QObject *root = wf_root(id))
                QMetaObject::invokeMethod(root, "hildonMenuTriggered", Q_ARG(QVariant, QVariant(i)));
        });
    }
}

static QDBusMessage wf_notifications_call(const QString &method)
{
    return QDBusMessage::createMethodCall(
        QStringLiteral("org.freedesktop.Notifications"),
        QStringLiteral("/org/freedesktop/Notifications"),
        QStringLiteral("org.freedesktop.Notifications"), method);
}
#endif
