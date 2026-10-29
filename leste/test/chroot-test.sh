#!/bin/bash
# Tries the package on the phone without touching Maemo Leste's own root:
# in a chroot of an overlay on a Leste image (mounted read-only; the
# changes go to an upper layer below $W), the package installed with apt,
# Hildon (hildon-desktop) and Whisperfish on a virtual screen (Xvfb) of
# the Pro1X's size, with the session environment of the phone, and
# screenshots taken after the steps in $STEPS.
#
# As root on the phone (apt needs the network):
#
#   STEPS="shot:start click:600,500 sleep:5 shot:next" \
#       bash leste/test/chroot-test.sh whisperfish-leste_*_arm64.deb
#
# Steps: shot:NAME (xwd of the screen into $W/shots/NAME.xwd),
# sleep:SECONDS, click:X,Y, key:KEYSYM, type:TEXT.
# FRESH=1 starts with an empty home directory (no Signal data).
set -euo pipefail
DEB=$(readlink -f "${1:?usage: chroot-test.sh package.deb}")
LOWER=${LOWER:-/host/meego-leste.img}
W=${W:-/host/wf-leste}
STEPS=${STEPS:-"sleep:40 shot:start"}
SIZE=${SIZE:-2160x1080}
FRESH=${FRESH:-1}

[ -f "$LOWER" ] || { echo "no $LOWER"; exit 1; }
[ -z "$(losetup -j "$LOWER")" ] ||
	{ echo "$LOWER is attached to a loop device (losetup -j): in use"; exit 1; }

R=$W/root
mkdir -p "$W/lower" "$W/upper" "$W/work" "$R" "$W/shots"
cleanup() {
	for m in dev/pts dev sys proc; do
		! mountpoint -q "$R/$m" || umount "$R/$m" || umount -l "$R/$m"
	done
	! mountpoint -q "$R" || umount "$R"
	! mountpoint -q "$W/lower" || umount "$W/lower"
}
trap cleanup EXIT
mount -o loop,ro "$LOWER" "$W/lower" 2> /dev/null || mount -o loop,ro,noload "$LOWER" "$W/lower"
mount -t overlay overlay -o "lowerdir=$W/lower,upperdir=$W/upper,workdir=$W/work" "$R"
for m in proc sys dev dev/pts; do
	mount --bind "/$m" "$R/$m"
done
rm -f "$R/etc/resolv.conf"
cp -L /etc/resolv.conf "$R/etc/resolv.conf"
printf '#!/bin/sh\nexit 101\n' > "$R/usr/sbin/policy-rc.d"
chmod 755 "$R/usr/sbin/policy-rc.d"
cp "$DEB" "$R/tmp/whisperfish-leste.deb"

chroot "$R" /bin/bash -euo pipefail <<'SETUP'
export DEBIAN_FRONTEND=noninteractive
apt-get update -qq || true
# the dependencies, then the package itself (again, if its version did
# not change)
apt-get install -y -qq --no-install-recommends /tmp/whisperfish-leste.deb \
	qt5-style-plugins qt-platform-maemo xvfb x11-apps x11-utils xdotool dbus-x11 hildon-desktop > /tmp/apt.log 2>&1 ||
	{ tail -30 /tmp/apt.log; exit 1; }
dpkg -i /tmp/whisperfish-leste.deb > /dev/null
dpkg -l whisperfish-leste | tail -1
SETUP

if [ "$FRESH" = 1 ]; then
	rm -rf "${R:?}/tmp/wf-home"
fi
mkdir -p "$R/tmp/wf-home"
cat > "$R/tmp/wf-run.sh" <<RUN
#!/bin/bash
# the session environment of hildon-desktop on the phone
export HOME=/tmp/wf-home DISPLAY=:7 LANG=en_US.utf-8
export CLUTTER_BACKEND=x11 GDK_DPI_SCALE=0.5 GDK_SCALE=2 HILDON_SCALE=2.25
export GTK2_RC_FILES=/etc/hildon/theme/gtk-2.0/gtkrc
export QT_ENABLE_HIGHDPI_SCALING=1 QT_QPA_PLATFORM=maemo QT_SCALE_FACTOR_ROUNDING_POLICY=PassThrough
export QT_STYLE_OVERRIDE=maemo5 QT_QUICK_BACKEND=software LIBGL_ALWAYS_SOFTWARE=1
Xvfb :7 -screen 0 ${SIZE}x24 -noreset -nolisten tcp > /tmp/xvfb.log 2>&1 &
xvfb=\$!
sleep 3
hildon-desktop > /tmp/hildon-desktop.log 2>&1 &
hd=\$!
sleep 10
harbour-whisperfish > /tmp/whisperfish.log 2>&1 &
wf=\$!
for s in $STEPS; do
	a=\${s%%:*}; v=\${s#*:}
	case \$a in
	shot) xwd -root -silent > /tmp/wf-shots/\$v.xwd; echo "shot \$v" ;;
	sleep) sleep "\$v" ;;
	click) xdotool mousemove \${v%,*} \${v#*,} click 1; sleep 2 ;;
	key) xdotool key "\$v"; sleep 1 ;;
	type) xdotool type --delay 50 "\$v"; sleep 1 ;;
	esac
done
echo "--- windows"; xwininfo -root -tree | grep -v "has no name" | head -20
echo "--- whisperfish.log"; tail -40 /tmp/whisperfish.log
echo "--- hildon-desktop.log"; tail -15 /tmp/hildon-desktop.log
if kill -0 \$hd 2> /dev/null; then echo "hildon-desktop running"; else echo "hildon-desktop ended"; fi
if kill -0 \$wf 2> /dev/null; then echo "whisperfish running"; else echo "whisperfish ended"; fi
kill \$wf \$hd \$xvfb 2> /dev/null || true
sleep 2
RUN
chmod 755 "$R/tmp/wf-run.sh"
rm -rf "${R:?}/tmp/wf-shots"
mkdir -p "$R/tmp/wf-shots"
chroot "$R" dbus-run-session -- /tmp/wf-run.sh || true
cp "$R"/tmp/wf-shots/*.xwd "$W/shots/" 2> /dev/null || true
ls -la "$W/shots"
