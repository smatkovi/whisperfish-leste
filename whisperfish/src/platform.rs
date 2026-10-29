#[cfg(feature = "sailfish")]
mod sailfish_inner {
    pub use sailors::sailfishapp::{QQmlEngine, QmlApp};
}

// Maemo Leste (Hildon): a plain QApplication (so that QtQuick.Controls 1
// renders through the Maemo 5 QStyle) with a QQmlApplicationEngine, from
// qmetaobject's QmlEngine. The QML lives in /usr/share/harbour-whisperfish
// (or $WHISPERFISH_QML_ROOT when running from the source tree).
#[cfg(all(feature = "leste", not(feature = "sailfish")))]
mod sailfish_inner {
    use cpp::cpp;
    use qmetaobject::prelude::*;
    use qmetaobject::{QObjectPinned, QmlEngine};

    cpp! {{
        #include <QtCore/QCoreApplication>
        #include <QtCore/QLocale>
        #include <QtCore/QTranslator>
        #include <QtGui/QGuiApplication>
        #include <QtQml/QQmlContext>
        #include <QtQml/QQmlEngine>
    }}

    /// Opaque stand-in for the C++ `QQmlEngine`, only handed to `cpp!` blocks.
    #[repr(C)]
    pub struct QQmlEngine {
        _private: [u8; 0],
    }

    pub struct QmlApp {
        engine: QmlEngine,
    }

    pub fn data_root() -> String {
        std::env::var("WHISPERFISH_QML_ROOT")
            .unwrap_or_else(|_| "/usr/share/harbour-whisperfish".into())
    }

    impl QmlApp {
        pub fn application(app: String) -> Self {
            let engine = QmlEngine::new();
            let app = QString::from(app);
            cpp!(unsafe [app as "QString"] {
                QCoreApplication::setApplicationName(app);
                QCoreApplication::setOrganizationName(QStringLiteral("be.rubdos"));
            });
            QmlApp { engine }
        }

        pub fn path_to(path: String) -> String {
            format!("{}/{}", data_root(), path)
        }

        pub fn set_property(&mut self, name: QString, value: QVariant) {
            self.engine.set_property(name, value);
        }

        pub fn set_object_property<T: QObject + Sized>(
            &mut self,
            name: QString,
            obj: QObjectPinned<'_, T>,
        ) {
            self.engine.set_object_property(name, obj);
        }

        pub fn set_title(&mut self, title: QString) {
            cpp!(unsafe [title as "QString"] {
                QGuiApplication::setApplicationDisplayName(title);
            });
        }

        pub fn set_application_version(&mut self, version: QString) {
            cpp!(unsafe [version as "QString"] {
                QCoreApplication::setApplicationVersion(version);
            });
        }

        pub fn install_default_translator(&mut self) -> Option<()> {
            let dir = QString::from(format!("{}/translations", data_root()));
            cpp!(unsafe [dir as "QString"] {
                QTranslator *t = new QTranslator(QCoreApplication::instance());
                if (t->load(QLocale(), QStringLiteral("harbour-whisperfish"),
                            QStringLiteral("-"), dir))
                    QCoreApplication::installTranslator(t);
                else
                    delete t;
            });
            Some(())
        }

        pub fn set_quit_on_last_window_closed(&mut self, quit: bool) {
            cpp!(unsafe [quit as "bool"] {
                QGuiApplication::setQuitOnLastWindowClosed(quit);
            });
        }

        pub fn promote_gui_app_to_qml_context(&mut self, name: QString) {
            let engine = self.engine.cpp_ptr();
            cpp!(unsafe [engine as "QQmlEngine *", name as "QString"] {
                engine->rootContext()->setContextProperty(name, QCoreApplication::instance());
            });
        }

        pub fn set_source(&mut self, source: String) {
            self.engine.load_file(source.into());
        }

        // The root item is a visible Window; hildon-desktop maximises it.
        pub fn show_full_screen(&mut self) {}

        pub fn exec(self) {
            self.engine.exec();
        }

        pub fn engine(&mut self) -> &mut QQmlEngine {
            unsafe { &mut *(self.engine.cpp_ptr() as *mut QQmlEngine) }
        }
    }
}

#[cfg(not(any(feature = "sailfish", feature = "leste")))]
mod sailfish_inner {
    use qmetaobject::qttypes::{QString, QVariant};

    // This is a noop implementation of QmlApp that will crash
    // when you try to launch it.
    // Enable the `sailfish` feature to build the app correctly

    pub struct QmlApp;
    pub struct QQmlEngine;

    impl QmlApp {
        pub fn application(_app: String) -> Self {
            QmlApp
        }

        pub fn path_to(path: String) -> String {
            path
        }

        pub fn set_property(&mut self, _name: QString, _value: QVariant) {}
        pub fn set_object_property<T>(&mut self, _name: QString, _item: T) {}
        pub fn set_title(&mut self, _title: QString) {}
        pub fn set_application_version(&mut self, _version: QString) {}
        pub fn install_default_translator(&mut self) -> Option<()> {
            Some(())
        }
        pub fn set_quit_on_last_window_closed(&mut self, _quit: bool) {}
        pub fn promote_gui_app_to_qml_context(&mut self, _name: QString) {}
        pub fn set_source(&mut self, _source: String) {}
        pub fn show_full_screen(&mut self) {}
        pub fn exec(self) {
            panic!(
                "Whisperfish has been compiled in development mode. The application will not work. Please compile Whisperfish with the `sailfish` feature to have a working application."
            );
        }
        pub fn engine(&mut self) -> &mut QQmlEngine {
            panic!(
                "Whisperfish has been compiled in development mode. The application will not work. Please compile Whisperfish with the `sailfish` feature to have a working application."
            );
        }
    }
}

pub use self::sailfish_inner::*;

#[cfg(feature = "harbour")]
mod harbour_inner {
    pub struct MayExit;

    impl MayExit {
        pub fn new() -> Self {
            MayExit
        }

        pub fn may_exit(&self) -> bool {
            true
        }

        pub fn set_may_exit(&mut self, _may_exit: bool) {}
    }

    pub fn is_harbour() -> bool {
        true
    }
}

#[cfg(not(feature = "harbour"))]
mod harbour_inner {
    pub struct MayExit {
        may_exit: bool,
    }

    impl MayExit {
        pub fn new() -> Self {
            MayExit { may_exit: true }
        }

        pub fn may_exit(&self) -> bool {
            self.may_exit
        }

        pub fn set_may_exit(&mut self, may_exit: bool) {
            self.may_exit = may_exit;
        }
    }

    pub fn is_harbour() -> bool {
        false
    }
}

pub use self::harbour_inner::{MayExit, is_harbour};

impl Default for MayExit {
    fn default() -> Self {
        MayExit::new()
    }
}
