#!/bin/bash


# load
SCRIPTS_DIR=`dirname $0`
source ${SCRIPTS_DIR}/config.sh

cd $WORK_DIR

# source DL
download_srcs() {
    clear; echo "DL srsc"

    cd $SRC_DIR
    # autoconf
    wget -nc ftp://ftp.gnu.org/gnu/autoconf/autoconf-${AUTOCONF_VER}.tar.xz
    # automake
    wget -nc ftp://ftp.gnu.org/gnu/automake/automake-${AUTOMAKE_VER}.tar.xz
    # libtool
#    wget -nc ftp://ftp.gnu.org/gnu/libtool/libtool-${LIBTOOL_VER}.tar.xz
    wget -nc ftp://alpha.gnu.org/gnu/libtool/libtool-${LIBTOOL_VER}.tar.xz

    cd $WORK_DIR
    return 0
}

# autoconf
build_autoconf() {
    clear; echo "Build autoconf ${AUTOCONF_VER}"

    if [ ! -d ${BUILD_DIR}/autoconf-${AUTOCONF_VER} ] ; then
        cd $BUILD_DIR
        tar xf ${SRC_DIR}/autoconf-${AUTOCONF_VER}.tar.xz
    fi
    cd ${BUILD_DIR}/autoconf-${AUTOCONF_VER}

    if [ ! -f ${BUILD_DIR}/autoconf-${AUTOCONF_VER}/patched_01.marker ] ; then
        patch -p1 < ${PATCHES_DIR}/autoconf/001-atomic.all.patch
        touch ${BUILD_DIR}/autoconf-${AUTOCONF_VER}/patched_01.marker
    fi

    if [ ! -f ${BUILD_DIR}/autoconf-${AUTOCONF_VER}/patched_02.marker ] ; then
        patch -p1 < ${PATCHES_DIR}/autoconf/002-stricter-versioning.all.patch
        touch ${BUILD_DIR}/autoconf-${AUTOCONF_VER}/patched_02.marker
    fi

    if [ ! -f ${BUILD_DIR}/autoconf-${AUTOCONF_VER}/patched_03.marker ] ; then
        patch -p1 < ${PATCHES_DIR}/autoconf/003-m4sh.m4.all.patch
        touch ${BUILD_DIR}/autoconf-${AUTOCONF_VER}/patched_03.marker
    fi

    if [ ! -f ${BUILD_DIR}/autoconf-${AUTOCONF_VER}/patched_04.marker ] ; then
        patch -p1 < ${PATCHES_DIR}/autoconf/004-autoconf2.5-2.69-1.src.all.patch
        touch ${BUILD_DIR}/autoconf-${AUTOCONF_VER}/patched_04.marker
    fi

    if [ ! -f ${BUILD_DIR}/autoconf-${AUTOCONF_VER}/patched_05.marker ] ; then
        patch -p1 < ${PATCHES_DIR}/autoconf/005-autoconf.git-a357718b081f1678748ead5d7cb67c766c930441.all.patch
        touch ${BUILD_DIR}/autoconf-${AUTOCONF_VER}/patched_05.marker
    fi

    if [ ! -f ${BUILD_DIR}/autoconf-${AUTOCONF_VER}/patched_06.marker ] ; then
        patch -p1 < ${PATCHES_DIR}/autoconf/007-allow-lns-on-msys2.all.patch
        touch ${BUILD_DIR}/autoconf-${AUTOCONF_VER}/patched_06.marker
    fi

    if [ ! -f ${BUILD_DIR}/autoconf-${AUTOCONF_VER}/patched_07.marker ] ; then
        patch -p1 < ${PATCHES_DIR}/autoconf/008-fix-cr-for-awk-in-configure.all.patch
        touch ${BUILD_DIR}/autoconf-${AUTOCONF_VER}/patched_07.marker
    fi

    if [ ! -f ${BUILD_DIR}/autoconf-${AUTOCONF_VER}/patched_08.marker ] ; then
        patch -p1 < ${PATCHES_DIR}/autoconf/009-fix-cr-for-awk-in-status.all.patch
        touch ${BUILD_DIR}/autoconf-${AUTOCONF_VER}/patched_08.marker
    fi

    for arch in i686 x86_64
    do
        source cpath nogcc
        if [ "$arch" == "i686" ] ; then
            local PREFIX_DIR=/mingw32
            local MINGW_DIR=${WORK_DIR}/mingw32
        else
            local PREFIX_DIR=/mingw64
            local MINGW_DIR=${WORK_DIR}/mingw64
        fi
        PATH=${MINGW_DIR}/bin:$PATH
        export PATH

        ./configure --prefix=$PREFIX_DIR        \
                    --build=${arch}-w64-mingw32 \
                    --host=${arch}-w64-mingw32

        make clean
        make -j$jobs -O || exit 1
        make install-strip DESTDIR=$WORK_DIR || exit 1
        make distclean
    done

    cd $WORK_DIR
    return 0
}

# automake
build_automake() {
    clear; echo "Build automake ${AUTOMAKE_VER}"

    if [ ! -d ${BUILD_DIR}/automake-${AUTOMAKE_VER} ] ; then
        cd $BUILD_DIR
        tar xf ${SRC_DIR}/automake-${AUTOMAKE_VER}.tar.xz
    fi
    cd ${BUILD_DIR}/automake-${AUTOMAKE_VER}

    if [ ! -f ${BUILD_DIR}/automake-${AUTOMAKE_VER}/patched_01.marker ] ; then
        patch -p1 < ${PATCHES_DIR}/automake/001-fix-cr-for-awk-in-configure.all.patch
        touch ${BUILD_DIR}/automake-${AUTOMAKE_VER}/patched_01.marker
    fi

    for arch in i686 x86_64
    do
        source cpath nogcc
        if [ "$arch" == "i686" ] ; then
            local PREFIX_DIR=/mingw32
            local MINGW_DIR=${WORK_DIR}/mingw32
        else
            local PREFIX_DIR=/mingw64
            local MINGW_DIR=${WORK_DIR}/mingw64
        fi
        PATH=${MINGW_DIR}/bin:$PATH
        export PATH

        ./configure --prefix=$PREFIX_DIR        \
                    --build=${arch}-w64-mingw32 \
                    --host=${arch}-w64-mingw32

        make clean
        make -j$jobs -O || exit 1
        make install-strip DESTDIR=$WORK_DIR || exit 1
        make distclean
    done

    cd $WORK_DIR
    return 0
}

# libtool
build_libtool() {
    clear; echo "Build libtool ${LIBTOOL_VER}"

    if [ ! -d ${BUILD_DIR}/libtool-${LIBTOOL_VER} ] ; then
        cd $BUILD_DIR
        tar xf ${SRC_DIR}/libtool-${LIBTOOL_VER}.tar.xz
    fi
    cd ${BUILD_DIR}/libtool-${LIBTOOL_VER}

    if [ ! -f ${BUILD_DIR}/libtool-${LIBTOOL_VER}/patched_01.marker ] ; then
        patch -p1 < ${PATCHES_DIR}/libtool/0002-cygwin-mingw-Create-UAC-manifest-files.mingw.patch
        touch ${BUILD_DIR}/libtool-${LIBTOOL_VER}/patched_01.marker
    fi

    if [ ! -f ${BUILD_DIR}/libtool-${LIBTOOL_VER}/patched_02.marker ] ; then
        patch -p1 < ${PATCHES_DIR}/libtool/0003-Pass-various-runtime-library-flags-to-GCC.mingw.patch
        touch ${BUILD_DIR}/libtool-${LIBTOOL_VER}/patched_02.marker
    fi

    if [ ! -f ${BUILD_DIR}/libtool-${LIBTOOL_VER}/patched_03.marker ] ; then
        patch -p1 < ${PATCHES_DIR}/libtool/0004-Fix-linking-with-fstack-protector.mingw.patch
        touch ${BUILD_DIR}/libtool-${LIBTOOL_VER}/patched_03.marker
    fi

    if [ ! -f ${BUILD_DIR}/libtool-${LIBTOOL_VER}/patched_04.marker ] ; then
        patch -p1 < ${PATCHES_DIR}/libtool/0005-Fix-seems-to-be-moved.patch
        touch ${BUILD_DIR}/libtool-${LIBTOOL_VER}/patched_04.marker
    fi

    if [ ! -f ${BUILD_DIR}/libtool-${LIBTOOL_VER}/patched_05.marker ] ; then
        patch -p1 < ${PATCHES_DIR}/libtool/0006-Fix-strict-ansi-vs-posix.patch
        touch ${BUILD_DIR}/libtool-${LIBTOOL_VER}/patched_05.marker
    fi

    if [ ! -f ${BUILD_DIR}/libtool-${LIBTOOL_VER}/patched_06.marker ] ; then
        patch -p1 < ${PATCHES_DIR}/libtool/0007-fix-cr-for-awk-in-configure.all.patch
        touch ${BUILD_DIR}/libtool-${LIBTOOL_VER}/patched_06.marker
    fi

    if [ ! -f ${BUILD_DIR}/libtool-${LIBTOOL_VER}/patched_07.marker ] ; then
        patch -p1 < ${PATCHES_DIR}/libtool/0008-find-external-libraries.patch
        touch ${BUILD_DIR}/libtool-${LIBTOOL_VER}/patched_07.marker
    fi

    for arch in i686 x86_64
    do
        source cpath nogcc
        if [ "$arch" == "i686" ] ; then
            local PREFIX_DIR=/mingw32
            local MINGW_DIR=${WORK_DIR}/mingw32
        else
            local PREFIX_DIR=/mingw64
            local MINGW_DIR=${WORK_DIR}/mingw64
        fi
        PATH=${MINGW_DIR}/bin:$PATH
        export PATH

        ./configure --prefix=$PREFIX_DIR        \
                    --build=${arch}-w64-mingw32 \
                    --host=${arch}-w64-mingw32

        make clean
        make -j$jobs -O || exit 1
        make install-strip DESTDIR=$WORK_DIR || exit 1
        make distclean
    done

    cd $WORK_DIR
    return 0
}

# clean
cleanup() {
    clear; echo "cleanup"

    rm -fr ${WORK_DIR}/mingw32/include
    rm -fr ${WORK_DIR}/mingw64/include
    rm -f ${WORK_DIR}/mingw32/lib/{*.a,*.la}
    rm -f ${WORK_DIR}/mingw64/lib/{*.a,*.la}

    cd $WORK_DIR
    return 0
}

download_srcs

build_autoconf
build_automake
build_libtool

cleanup

clear; echo "Everything has been successfully completed!"
