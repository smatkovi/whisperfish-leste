# Source this to cross-compile Whisperfish for Maemo Leste arm64 on an
# x86_64 PC with clang/lld and a Debian bookworm arm64 sysroot
# (see leste/cross/make-sysroot.sh).
: "${LESTE_SYSROOT:?set LESTE_SYSROOT to the arm64 sysroot}"
export LESTE_SYSROOT
_here=$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd)
_t=aarch64-linux-gnu
_cflags="--target=$_t --sysroot=$LESTE_SYSROOT"
export QMAKE="$_here/qmake"
export CC_aarch64_unknown_linux_gnu="clang"
export CXX_aarch64_unknown_linux_gnu="clang++"
export AR_aarch64_unknown_linux_gnu="llvm-ar"
export CFLAGS_aarch64_unknown_linux_gnu="$_cflags"
export CXXFLAGS_aarch64_unknown_linux_gnu="$_cflags"
export CARGO_TARGET_AARCH64_UNKNOWN_LINUX_GNU_LINKER="clang"
export CARGO_TARGET_AARCH64_UNKNOWN_LINUX_GNU_RUSTFLAGS="-C link-arg=--target=$_t -C link-arg=--sysroot=$LESTE_SYSROOT -C link-arg=-fuse-ld=lld"
export BINDGEN_EXTRA_CLANG_ARGS_aarch64_unknown_linux_gnu="$_cflags"
export PKG_CONFIG_ALLOW_CROSS=1
export PKG_CONFIG_SYSROOT_DIR="$LESTE_SYSROOT"
export PKG_CONFIG_LIBDIR="$LESTE_SYSROOT/usr/lib/aarch64-linux-gnu/pkgconfig:$LESTE_SYSROOT/usr/share/pkgconfig"
# cmake-based -sys crates
export CMAKE_TOOLCHAIN_FILE_aarch64_unknown_linux_gnu="$_here/toolchain.cmake"
unset _here _t _cflags
