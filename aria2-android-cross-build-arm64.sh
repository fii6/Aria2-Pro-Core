#!/usr/bin/env bash
#
# Copyright (c) 2020 P3TERX <https://p3terx.com>
#
# This is free software, licensed under the GNU General Public License v3.
# See /LICENSE for more information.
#
# https://github.com/P3TERX/Aria2-Pro-Core
# File name: aria2-android-cross-build-arm64.sh
# Description: Aria2 Android aarch64 cross build using the official NDK
# System Required: Debian/Ubuntu (glibc >= 2.31), Fedora, Arch Linux
# Version: 1.0
#

set -e
[ $EUID != 0 ] && SUDO=sudo
$SUDO echo
SCRIPT_DIR=$(dirname $(readlink -f $0))

## CONFIG ##
ARCH="arm64"
HOST="aarch64-linux-android"
ANDROID_API="${ANDROID_API:-24}"
NDK_TARGET="${HOST}${ANDROID_API}"
OPENSSL_ARCH="android-arm64"
ARIA2_OS="android"
BUILD_DIR="/tmp"
ARIA2_CODE_DIR="$BUILD_DIR/aria2"
OUTPUT_DIR="$HOME/output"
PREFIX="$BUILD_DIR/aria2-android-build-libs-$ARCH"
ARIA2_PREFIX="/data/data/com.termux/files/usr"
NDK_PARENT="${NDK_PARENT:-/opt}"
NDK_ROOT="${ANDROID_NDK_ROOT:-$NDK_PARENT/android-ndk}"
NDK_TOOLCHAIN="$NDK_ROOT/toolchains/llvm/prebuilt/linux-x86_64"
BUILD_HOST="$(uname -m)-pc-linux-gnu"

export PKG_CONFIG_PATH="$PREFIX/lib/pkgconfig"
export LD_LIBRARY_PATH="$PREFIX/lib"
# Make sure CA bundle env vars don't leak the host paths into curl invocations.
unset CURL_CA_BUNDLE

## DEPENDENCES ##
source $SCRIPT_DIR/dependences

## TOOLCHAIN ##
source $SCRIPT_DIR/snippet/android-toolchain

TOOLCHAIN() {
    if [ -x "$(command -v apt-get)" ]; then
        DEBIAN_INSTALL
    elif [ -x "$(command -v dnf)" ]; then
        FEDORA_INSTALL
    elif [ -x "$(command -v pacman)" ]; then
        ARCH_INSTALL
    else
        echo "This operating system is not supported !"
        exit 1
    fi
    NDK_INSTALL

    # NDK r23+ ships standalone clang wrappers with API level baked in.
    # We only export them here, after NDK_INSTALL has populated $NDK_TOOLCHAIN.
    export PATH="$NDK_TOOLCHAIN/bin:$PATH"
    export CC="$NDK_TOOLCHAIN/bin/${NDK_TARGET}-clang"
    export CXX="$NDK_TOOLCHAIN/bin/${NDK_TARGET}-clang++"
    export AR="$NDK_TOOLCHAIN/bin/llvm-ar"
    export AS="$CC"
    export LD="$NDK_TOOLCHAIN/bin/ld"
    export RANLIB="$NDK_TOOLCHAIN/bin/llvm-ranlib"
    export STRIP="$NDK_TOOLCHAIN/bin/llvm-strip"
    export CPP="$CC -E"
    if [ ! -x "$CC" ]; then
        echo "Expected NDK clang at $CC but it was not found." >&2
        exit 1
    fi
}

## BUILD ##
source $SCRIPT_DIR/snippet/android-build

## ARIA2 CODE ##
source $SCRIPT_DIR/snippet/aria2-code

## ARIA2 BIN ##
source $SCRIPT_DIR/snippet/aria2-bin

## CLEAN ##
source $SCRIPT_DIR/snippet/clean

## BUILD PROCESS ##
TOOLCHAIN
ZLIB_BUILD
EXPAT_BUILD
C_ARES_BUILD
OPENSSL_BUILD
SQLITE3_BUILD
LIBSSH2_BUILD
#JEMALLOC_BUILD
ARIA2_BUILD
#ARIA2_BIN
ARIA2_PACKAGE
#ARIA2_INSTALL
CLEANUP_ALL

echo "finished!"
