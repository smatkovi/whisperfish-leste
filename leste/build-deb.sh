#!/bin/bash
# Builds the Maemo Leste arm64 package of Whisperfish:
#
#   LESTE_SYSROOT=/path/to/arm64-sysroot leste/build-deb.sh
#
# Cross-compiles harbour-whisperfish with the `leste` feature (see
# leste/cross/env.sh; a Debian bookworm arm64 sysroot made by
# leste/cross/make-sysroot.sh) unless NOBUILD=1, then assembles
# whisperfish-leste_<version>_arm64.deb in $OUT (default: leste/out).
# dpkg-deb is used when present, otherwise the archive is put together
# with ar and tar.
set -euo pipefail
SRC=$(cd "$(dirname "$0")/.." && pwd)
OUT=${OUT:-$SRC/leste/out}
JOBS=${JOBS:-2}
export CARGO_TARGET_DIR=${CARGO_TARGET_DIR:-$SRC/target}
T=aarch64-unknown-linux-gnu
# 0.6.0-dev -> 0.6.0~dev, which sorts before 0.6.0
VERSION=${VERSION:-$(sed -n 's/^version = "\(.*\)"/\1/p' "$SRC/Cargo.toml" | head -1 | tr - '~')}
DEBREV=${DEBREV:-1}

if [ "${NOBUILD:-0}" != 1 ]; then
	# shellcheck source=cross/env.sh
	. "$SRC/leste/cross/env.sh"
	(cd "$SRC" && cargo build --release --target $T -j"$JOBS" -p harbour-whisperfish --features leste)
fi
BIN=$CARGO_TARGET_DIR/$T/release/harbour-whisperfish
[ -x "$BIN" ] || { echo "no $BIN"; exit 1; }

P=$OUT/pkg
rm -rf "${P:?}"
mkdir -p "$P/DEBIAN" "$P/usr/bin" "$P/usr/share/harbour-whisperfish" \
	"$P/usr/share/applications/hildon" "$P/usr/share/doc/whisperfish-leste"
llvm-strip -o "$P/usr/bin/harbour-whisperfish" "$BIN" 2> /dev/null ||
	aarch64-linux-gnu-strip -o "$P/usr/bin/harbour-whisperfish" "$BIN"
chmod 755 "$P/usr/bin/harbour-whisperfish"
cp -r "$SRC/leste/qml" "$P/usr/share/harbour-whisperfish/qml"
for s in 86x86 108x108 128x128 172x172; do
	mkdir -p "$P/usr/share/icons/hicolor/$s/apps"
	cp "$SRC/icons/$s/harbour-whisperfish.png" "$P/usr/share/icons/hicolor/$s/apps/"
done
# Hildon's application grid takes its 64x64 icons from hicolor too
mkdir -p "$P/usr/share/icons/hicolor/64x64/apps"
cp "$SRC/icons/86x86/harbour-whisperfish.png" "$P/usr/share/icons/hicolor/64x64/apps/"
cp "$SRC/leste/harbour-whisperfish.desktop" "$P/usr/share/applications/hildon/"
cp "$SRC/LICENSE" "$P/usr/share/doc/whisperfish-leste/copyright"
cp "$SRC/README.md" "$P/usr/share/doc/whisperfish-leste/README.md"

SIZE=$(du -sk --exclude=DEBIAN "$P" | cut -f1)
cat > "$P/DEBIAN/control" <<CONTROL
Package: whisperfish-leste
Version: $VERSION-$DEBREV
Architecture: arm64
Maintainer: Sebastian Matkovich <sebastian.matkovich@gmail.com>
Installed-Size: $SIZE
Depends: libc6 (>= 2.34), libgcc-s1, libstdc++6, libqt5core5a (>= 5.15), libqt5gui5, libqt5widgets5, libqt5dbus5, libqt5qml5, libqt5quick5, libqt5quickwidgets5, qml-module-qtquick2, qml-module-qtquick-window2, qml-module-qtquick-controls, qml-module-qtquick-layouts, qml-module-qtquick-dialogs, qml-module-qtquick-privatewidgets, qml-module-qt-labs-folderlistmodel, qml-module-qt-labs-settings
Recommends: qt5-style-plugins, qt-platform-maemo, xdg-utils
Section: net
Priority: optional
Homepage: https://github.com/smatkovi/whisperfish-leste
Description: Signal client (Whisperfish) for Maemo Leste
 Whisperfish, the unofficial Signal client of Sailfish OS, with a Hildon
 (Maemo 5) user interface: link it to the Signal app on your phone as a
 secondary device and send and receive messages and attachments.
CONTROL

mkdir -p "$OUT"
DEB=$OUT/whisperfish-leste_${VERSION}-${DEBREV}_arm64.deb
if command -v dpkg-deb > /dev/null; then
	fakeroot dpkg-deb --build -Zxz "$P" "$DEB"
else
	W=$OUT/deb-work
	rm -rf "${W:?}"
	mkdir -p "$W"
	echo 2.0 > "$W/debian-binary"
	(cd "$P/DEBIAN" && tar --owner=0 --group=0 --numeric-owner -cJf "$W/control.tar.xz" ./control)
	(cd "$P" && tar --owner=0 --group=0 --numeric-owner --exclude=./DEBIAN -cJf "$W/data.tar.xz" .)
	rm -f "$DEB"
	(cd "$W" && ar rc "$DEB" debian-binary control.tar.xz data.tar.xz)
	rm -rf "${W:?}"
fi
echo "$DEB"
