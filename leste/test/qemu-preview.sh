#!/bin/bash
# The QML with made-up data (leste/test/preview, a stand-in for the Rust
# be.rubdos.whisperfish types) in the arm64 sysroot under qemu-user, on a
# virtual screen; screenshots in $SHOTS (PNG, needs ImageMagick).
# The sysroot needs: xvfb x11-apps qmlscene and the QML modules of the
# package's Depends (apt-get install in a chroot of it).
#
#   LESTE_SYSROOT=/path/to/sysroot leste/test/qemu-preview.sh [main conversation]
set -eu
SRC=$(cd "$(dirname "$0")/../.." && pwd)
SR=${LESTE_SYSROOT:?set LESTE_SYSROOT}
SHOTS=${SHOTS:-$SRC/leste/out/shots}
PAGES=${*:-main conversation}
mkdir -p "$SHOTS"
sudo rm -rf "${SR:?}/opt/wf-preview"
sudo mkdir -p "$SR/opt/wf-preview/leste/test" "$SR/tmp/wf-shots"
sudo cp -r "$SRC/leste/qml" "$SR/opt/wf-preview/leste/qml"
sudo cp -r "$SRC/leste/test/preview" "$SR/opt/wf-preview/leste/test/preview"
tmp=$(mktemp)
cat > "$tmp" <<RUN
#!/bin/bash
export DISPLAY=:9 LANG=C.UTF-8 QT_QUICK_BACKEND=software QT_STYLE_OVERRIDE=\${QT_STYLE_OVERRIDE:-Fusion}
Xvfb :9 -screen 0 960x440x24 -noreset -nolisten tcp > /tmp/xvfb.log 2>&1 &
x=\$!
sleep 2
cd /opt/wf-preview
for n in $PAGES; do
	qmlscene -I leste/test/preview --resize-to-root leste/test/preview/\$n.qml > /tmp/prev-\$n.log 2>&1 &
	p=\$!
	sleep ${WAIT:-25}
	xwd -root -silent > /tmp/wf-shots/prev-\$n.xwd
	kill \$p; wait \$p 2> /dev/null || true
	grep -v "^\s*$" /tmp/prev-\$n.log | head -10
done
kill \$x; wait \$x 2> /dev/null || true
RUN
sudo cp "$tmp" "$SR/tmp/wf-prev.sh"
rm -f "$tmp"
sudo chmod 755 "$SR/tmp/wf-prev.sh"
for m in proc dev; do sudo mount --bind "/$m" "$SR/$m"; done
sudo chroot "$SR" /tmp/wf-prev.sh || true
for m in dev proc; do sudo umount "$SR/$m" || sudo umount -l "$SR/$m"; done
for n in $PAGES; do
	magick "xwd:$SR/tmp/wf-shots/prev-$n.xwd" "$SHOTS/preview-$n.png"
done
ls "$SHOTS"
