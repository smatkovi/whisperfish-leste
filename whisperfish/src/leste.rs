//! Maemo Leste (Hildon) shell for the QML user interface.
//!
//! Every page is a `QMainWindow` holding a `QQuickWidget` that shares the
//! application's QML engine. With Leste's Qt platform plugin (`maemo`) this
//! gives the real Maemo 5 window behaviour: the main window's `QMenuBar`
//! becomes the Hildon application menu (tap on the title bar), further
//! windows are stacked windows with the back arrow, and `X-Maemo-Progress`
//! shows the spinning progress indicator in the title bar.
//!
//! Banners and notifications go to hildon-home over D-Bus
//! (`org.freedesktop.Notifications`).
//!
//! The C++ side is only compiled with the `leste` feature (cpp_build parses
//! all modules regardless of `cfg`, hence the `WHISPERFISH_LESTE` guard).

use cpp::cpp;
use qmetaobject::prelude::*;

use crate::platform::QQmlEngine;

cpp! {{
    #include "leste_shell.h"
}}

pub fn set_engine(engine: &mut QQmlEngine) {
    cpp!(unsafe [engine as "QQmlEngine *"] {
#ifdef WHISPERFISH_LESTE
        wf_engine = engine;
#else
        (void)engine;
#endif
    });
}

/// Opens a QML file in a new window; the first one is the main window.
pub fn open_window(url: QString, props: QVariant, title: QString) -> i32 {
    cpp!(unsafe [url as "QString", props as "QVariant", title as "QString"] -> i32 as "int" {
#ifdef WHISPERFISH_LESTE
        QUrl u = url.contains(QStringLiteral("://")) ? QUrl(url) : QUrl::fromLocalFile(url);
        return wf_open_window(u, props.toMap(), title);
#else
        (void)url; (void)props; (void)title;
        return -1;
#endif
    })
}

/// The `Hildon` object of the QML user interface.
#[derive(QObject, Default)]
#[allow(non_snake_case)]
pub struct HildonShell {
    base: qt_base_class!(trait QObject),

    openWindow: qt_method!(fn(&self, url: QString, props: QVariant, title: QString) -> i32),
    closeWindow: qt_method!(fn(&self, id: i32)),
    setTitle: qt_method!(fn(&self, id: i32, title: QString)),
    setMenu: qt_method!(fn(&self, id: i32, items: QVariant)),
    setBusy: qt_method!(fn(&self, id: i32, busy: bool)),
    banner: qt_method!(fn(&self, text: QString)),
    notify: qt_method!(fn(&self, replaces: u32, summary: QString, body: QString) -> u32),
    closeNotification: qt_method!(fn(&self, id: u32)),
}

#[allow(non_snake_case)]
impl HildonShell {
    fn openWindow(&self, url: QString, props: QVariant, title: QString) -> i32 {
        open_window(url, props, title)
    }

    fn closeWindow(&self, id: i32) {
        cpp!(unsafe [id as "int"] {
#ifdef WHISPERFISH_LESTE
            if (QMainWindow *w = wf_window(id))
                w->close();
#else
            (void)id;
#endif
        });
    }

    fn setTitle(&self, id: i32, title: QString) {
        cpp!(unsafe [id as "int", title as "QString"] {
#ifdef WHISPERFISH_LESTE
            if (QMainWindow *w = wf_window(id))
                w->setWindowTitle(title);
#else
            (void)id; (void)title;
#endif
        });
    }

    /// Entries of the Hildon application menu; a click calls
    /// `hildonMenuTriggered(index)` on the window's root item.
    fn setMenu(&self, id: i32, items: QVariant) {
        cpp!(unsafe [id as "int", items as "QVariant"] {
#ifdef WHISPERFISH_LESTE
            wf_set_menu(id, items.toStringList());
#else
            (void)id; (void)items;
#endif
        });
    }

    /// The progress indicator in the title bar.
    fn setBusy(&self, id: i32, busy: bool) {
        cpp!(unsafe [id as "int", busy as "bool"] {
#ifdef WHISPERFISH_LESTE
            if (QMainWindow *w = wf_window(id))
                w->setProperty("X-Maemo-Progress", busy ? 1 : 0);
#else
            (void)id; (void)busy;
#endif
        });
    }

    /// A short information banner (hildon-home's SystemNoteInfoprint).
    fn banner(&self, text: QString) {
        cpp!(unsafe [text as "QString"] {
#ifdef WHISPERFISH_LESTE
            QDBusMessage m = wf_notifications_call(QStringLiteral("SystemNoteInfoprint"));
            m << text;
            QDBusConnection::sessionBus().call(m, QDBus::NoBlock);
#else
            (void)text;
#endif
        });
    }

    /// A notification (desktop notification spec); returns its id, which
    /// can be passed as `replaces` to update it.
    fn notify(&self, replaces: u32, summary: QString, body: QString) -> u32 {
        cpp!(unsafe [replaces as "uint", summary as "QString", body as "QString"] -> u32 as "uint" {
#ifdef WHISPERFISH_LESTE
            QDBusMessage m = wf_notifications_call(QStringLiteral("Notify"));
            QVariantMap hints;
            hints.insert(QStringLiteral("category"), QStringLiteral("whisperfish-message"));
            m << QStringLiteral("Whisperfish") << replaces
              << QStringLiteral("harbour-whisperfish") << summary << body
              << QStringList() << hints << int(-1);
            QDBusMessage r = QDBusConnection::sessionBus().call(m, QDBus::Block, 2000);
            if (r.type() == QDBusMessage::ReplyMessage && !r.arguments().isEmpty())
                return r.arguments().first().toUInt();
            return 0;
#else
            (void)replaces; (void)summary; (void)body;
            return 0;
#endif
        })
    }

    fn closeNotification(&self, id: u32) {
        cpp!(unsafe [id as "uint"] {
#ifdef WHISPERFISH_LESTE
            QDBusMessage m = wf_notifications_call(QStringLiteral("CloseNotification"));
            m << id;
            QDBusConnection::sessionBus().call(m, QDBus::NoBlock);
#else
            (void)id;
#endif
        });
    }
}
