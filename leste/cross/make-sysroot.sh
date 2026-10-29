#!/bin/sh
# Creates the Debian bookworm arm64 sysroot for cross builds (Maemo Leste
# daedalus is built on Debian bookworm: same glibc 2.36 and Qt 5.15.8).
# Needs debootstrap and, on an x86_64 host, qemu-user binfmt for arm64.
#
#   sudo leste/cross/make-sysroot.sh /path/to/sysroot
set -eu
SR=${1:?usage: make-sysroot.sh DIR}
debootstrap --arch=arm64 --variant=minbase \
	--include=g++,libc6-dev,qtbase5-dev,qtdeclarative5-dev,qtbase5-private-dev,libqt5svg5-dev,zlib1g-dev,libdbus-1-dev,pkg-config,perl,make \
	bookworm "$SR" http://deb.debian.org/debian
