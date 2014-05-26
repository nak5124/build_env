#!/usr/bin/bash


# PATH
WORK_DIR=${HOME}/gcc_build
BUILD_DIR=${WORK_DIR}/builds
PATCHES_DIR=${WORK_DIR}/patches
SRC_DIR=${WORK_DIR}/src
LIBS_DIR=${WORK_DIR}/libs
LOGS_DIR=${WORK_DIR}/logs

# flags
_CFLAGS="-pipe -Os -msse4 -fomit-frame-pointer -D__USE_MINGW_ANSI_STDIO=1"
_CXXFLAGS="-pipe -Os -msse4 -fomit-frame-pointer -D__USE_MINGW_ANSI_STDIO=1"
_CPPFLAGS="-D__USE_MINGW_ANSI_STDIO=1"
_LDFLAGS="-pipe -Wl,-O1 -Wl,--as-needed -Wl,-s -Wl,--nxcompat -Wl,--dynamicbase"
jobs=3

# version
GCC_VER="4.9.0"
BINUTILS_VER="2.24"
ICONV_VER="1.14"
BZIP2_VER="1.0.6"
GMP_VER="6.0.0"
MPFR_VER="3.1.2"
MPC_VER="1.0.2"
CLOOG_VER="0.18.2"
# isl 0.13 is not compilable with CLooG 0.18.2.
# ISL_VER="0.13"
ISL_VER="0.12.2"
AUTOCONF_VER="2.69"
AUTOMAKE_VER="1.14.1"
LIBTOOL_VER="2.4.2.418"

# rebuild
ICONV_REBUILD="no"
ZLIB_REBUILD="no"
HEADERS_REBUILD="yes"
BINUTILS_REBUILD="yes"
BZIP2_REBUILD="no"
WINPTHREADS_REBUILD="yes"
CRT_REBUILD="yes"
AUTOCONF_REBUILD="yes"
AUTOMAKE_REBUILD="yes"
LIBTOOL_REBUILD="yes"
