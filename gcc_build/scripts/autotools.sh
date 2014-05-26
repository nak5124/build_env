#!/bin/bash


# load
SCRIPTS_DIR=`dirname $0`
source ${SCRIPTS_DIR}/config.sh

cd $WORK_DIR

# init
init_directories() {
    clear; echo "init directories"

    for arch in i686 x86_64
    do
        if [ ! -d ${WORK_DIR}/prein_${arch}/autoconf ] ; then
            mkdir -p ${WORK_DIR}/prein_${arch}/autoconf
        fi
        if [ ! -d ${WORK_DIR}/prein_${arch}/automake ] ; then
            mkdir -p ${WORK_DIR}/prein_${arch}/automake
        fi
        if [ ! -d ${WORK_DIR}/prein_${arch}/libtool ] ; then
            mkdir -p ${WORK_DIR}/prein_${arch}/libtool
        fi
    done

    cd $WORK_DIR
    return 0
}

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
        patch -p1 < ${PATCHES_DIR}/autoconf/001-atomic.all.patch \
            > ${LOGS_DIR}/autoconf_patches.log 2>&1 || exit 1
        touch ${BUILD_DIR}/autoconf-${AUTOCONF_VER}/patched_01.marker
    fi
    if [ ! -f ${BUILD_DIR}/autoconf-${AUTOCONF_VER}/patched_02.marker ] ; then
        patch -p1 < ${PATCHES_DIR}/autoconf/002-stricter-versioning.all.patch \
            >> ${LOGS_DIR}/autoconf_patches.log 2>&1 || exit 1
        touch ${BUILD_DIR}/autoconf-${AUTOCONF_VER}/patched_02.marker
    fi
    if [ ! -f ${BUILD_DIR}/autoconf-${AUTOCONF_VER}/patched_03.marker ] ; then
        patch -p1 < ${PATCHES_DIR}/autoconf/003-m4sh.m4.all.patch \
            >> ${LOGS_DIR}/autoconf_patches.log 2>&1 || exit 1
        touch ${BUILD_DIR}/autoconf-${AUTOCONF_VER}/patched_03.marker
    fi
    if [ ! -f ${BUILD_DIR}/autoconf-${AUTOCONF_VER}/patched_04.marker ] ; then
        patch -p1 < ${PATCHES_DIR}/autoconf/004-autoconf2.5-2.69-1.src.all.patch \
            >> ${LOGS_DIR}/autoconf_patches.log 2>&1 || exit 1
        touch ${BUILD_DIR}/autoconf-${AUTOCONF_VER}/patched_04.marker
    fi
    if [ ! -f ${BUILD_DIR}/autoconf-${AUTOCONF_VER}/patched_05.marker ] ; then
        patch -p1 < ${PATCHES_DIR}/autoconf/005-autoconf-ga357718.all.patch \
            >> ${LOGS_DIR}/autoconf_patches.log 2>&1 || exit 1
        touch ${BUILD_DIR}/autoconf-${AUTOCONF_VER}/patched_05.marker
    fi
    if [ ! -f ${BUILD_DIR}/autoconf-${AUTOCONF_VER}/patched_06.marker ] ; then
        patch -p1 < ${PATCHES_DIR}/autoconf/007-allow-lns-on-msys2.all.patch \
            >> ${LOGS_DIR}/autoconf_patches.log 2>&1 || exit 1
        touch ${BUILD_DIR}/autoconf-${AUTOCONF_VER}/patched_06.marker
    fi

    if [ ! -f ${BUILD_DIR}/autoconf-${AUTOCONF_VER}/patched_07.marker ] ; then
        patch -p1 < ${PATCHES_DIR}/autoconf/008-fix-cr-for-awk-in-configure.all.patch \
            >> ${LOGS_DIR}/autoconf_patches.log 2>&1 || exit 1
        touch ${BUILD_DIR}/autoconf-${AUTOCONF_VER}/patched_07.marker
    fi
    if [ ! -f ${BUILD_DIR}/autoconf-${AUTOCONF_VER}/patched_08.marker ] ; then
        patch -p1 < ${PATCHES_DIR}/autoconf/009-fix-cr-for-awk-in-status.all.patch \
            >> ${LOGS_DIR}/autoconf_patches.log 2>&1 || exit 1
        touch ${BUILD_DIR}/autoconf-${AUTOCONF_VER}/patched_08.marker
    fi

    if [ ! -d ${BUILD_DIR}/autoconf-${AUTOCONF_VER}/build ] ; then
        mkdir -p ${BUILD_DIR}/autoconf-${AUTOCONF_VER}/build
    fi
    cd ${BUILD_DIR}/autoconf-${AUTOCONF_VER}/build

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

        rm -fr ${BUILD_DIR}/autoconf-${AUTOCONF_VER}/build/*
        echo "===> configure autoconf ${arch}"
        ../configure --prefix=$PREFIX_DIR        \
                     --build=${arch}-w64-mingw32 \
                     --host=${arch}-w64-mingw32  \
        > ${LOGS_DIR}/autoconf_config_${arch}.log 2>&1 || exit 1
        echo "done"

        echo "===> make autoconf ${arch}"
        make -j$jobs -O > ${LOGS_DIR}/autoconf_make_${arch}.log 2>&1 || exit 1
        echo "done"

        echo "===> install autoconf ${arch}"
        make install-strip DESTDIR=${WORK_DIR}/prein_${arch}/autoconf \
            > ${LOGS_DIR}/autoconf_install_${arch}.log 2>&1 || exit 1
        echo "done"

        echo "===> copy autoconf ${arch} to ${MINGW_DIR}"
        cp -fa ${WORK_DIR}/prein_${arch}/autoconf${PREFIX_DIR}/* $MINGW_DIR
        echo "done"
    done

    cd $WORK_DIR
    return 0
}

copy_only_autoconf() {
    clear; echo "autoconf ${AUTOCONF_VER}"

    for arch in i686 x86_64
    do
        if [ "$arch" == "i686" ] ; then
            local PREFIX_DIR=/mingw32
            local MINGW_DIR=${WORK_DIR}/mingw32
        else
            local PREFIX_DIR=/mingw64
            local MINGW_DIR=${WORK_DIR}/mingw64
        fi
        echo "===> copy autoconf ${arch} to ${MINGW_DIR}"
        cp -fa ${WORK_DIR}/prein_${arch}/autoconf${PREFIX_DIR}/* $MINGW_DIR
        echo "done"
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
        patch -p1 < ${PATCHES_DIR}/automake/001-fix-cr-for-awk-in-configure.all.patch \
            > ${LOGS_DIR}/automake_patches.log 2>&1 || exit 1
        touch ${BUILD_DIR}/automake-${AUTOMAKE_VER}/patched_01.marker
    fi

    if [ ! -d ${BUILD_DIR}/automake-${AUTOMAKE_VER}/build ] ; then
        mkdir -p ${BUILD_DIR}/automake-${AUTOMAKE_VER}/build
    fi
    cd ${BUILD_DIR}/automake-${AUTOMAKE_VER}/build

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

        rm -fr ${BUILD_DIR}/automake-${AUTOMAKE_VER}/build/*
        echo "===> configure automake ${arch}"
        ../configure --prefix=$PREFIX_DIR        \
                     --build=${arch}-w64-mingw32 \
                     --host=${arch}-w64-mingw32  \
        > ${LOGS_DIR}/automake_config_${arch}.log 2>&1 || exit 1
        echo "done"

        echo "===> make automake ${arch}"
        make -j$jobs -O > ${LOGS_DIR}/automake_make_${arch}.log 2>&1 || exit 1
        echo "done"

        echo "===> install automake ${arch}"
        make install-strip DESTDIR=${WORK_DIR}/prein_${arch}/automake \
            > ${LOGS_DIR}/automake_install_${arch}.log 2>&1 || exit 1
        echo "done"

        echo "===> copy automake ${arch} to ${MINGW_DIR}"
        cp -fa ${WORK_DIR}/prein_${arch}/automake${PREFIX_DIR}/* $MINGW_DIR
        echo "done"
    done

    cd $WORK_DIR
    return 0
}

copy_only_automake() {
    clear; echo "automake ${AUTOMAKE_VER}"

    for arch in i686 x86_64
    do
        if [ "$arch" == "i686" ] ; then
            local PREFIX_DIR=/mingw32
            local MINGW_DIR=${WORK_DIR}/mingw32
        else
            local PREFIX_DIR=/mingw64
            local MINGW_DIR=${WORK_DIR}/mingw64
        fi
        echo "===> copy automake ${arch} to ${MINGW_DIR}"
        cp -fa ${WORK_DIR}/prein_${arch}/automake${PREFIX_DIR}/* $MINGW_DIR
        echo "done"
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
        patch -p1 < ${PATCHES_DIR}/libtool/0002-cygwin-mingw-Create-UAC-manifest-files.mingw.patch \
            > ${LOGS_DIR}/libtool_patches.log 2>&1 || exit 1
        touch ${BUILD_DIR}/libtool-${LIBTOOL_VER}/patched_01.marker
    fi
    if [ ! -f ${BUILD_DIR}/libtool-${LIBTOOL_VER}/patched_02.marker ] ; then
        patch -p1 < ${PATCHES_DIR}/libtool/0003-Pass-various-runtime-library-flags-to-GCC.mingw.patch \
            >> ${LOGS_DIR}/libtool_patches.log  2>&1 || exit 1
        touch ${BUILD_DIR}/libtool-${LIBTOOL_VER}/patched_02.marker
    fi
    if [ ! -f ${BUILD_DIR}/libtool-${LIBTOOL_VER}/patched_03.marker ] ; then
        patch -p1 < ${PATCHES_DIR}/libtool/0004-Fix-linking-with-fstack-protector.mingw.patch \
            >> ${LOGS_DIR}/libtool_patches.log 2>&1 || exit 1
        touch ${BUILD_DIR}/libtool-${LIBTOOL_VER}/patched_03.marker
    fi
    if [ ! -f ${BUILD_DIR}/libtool-${LIBTOOL_VER}/patched_04.marker ] ; then
        patch -p1 < ${PATCHES_DIR}/libtool/0005-Fix-seems-to-be-moved.patch \
            >> ${LOGS_DIR}/libtool_patches.log 2>&1 || exit 1
        touch ${BUILD_DIR}/libtool-${LIBTOOL_VER}/patched_04.marker
    fi
    if [ ! -f ${BUILD_DIR}/libtool-${LIBTOOL_VER}/patched_05.marker ] ; then
        patch -p1 < ${PATCHES_DIR}/libtool/0006-Fix-strict-ansi-vs-posix.patch \
            >> ${LOGS_DIR}/libtool_patches.log 2>&1 || exit 1
        touch ${BUILD_DIR}/libtool-${LIBTOOL_VER}/patched_05.marker
    fi
    if [ ! -f ${BUILD_DIR}/libtool-${LIBTOOL_VER}/patched_06.marker ] ; then
        patch -p1 < ${PATCHES_DIR}/libtool/0007-fix-cr-for-awk-in-configure.all.patch \
            >> ${LOGS_DIR}/libtool_patches.log 2>&1 || exit 1
        touch ${BUILD_DIR}/libtool-${LIBTOOL_VER}/patched_06.marker
    fi
    if [ ! -f ${BUILD_DIR}/libtool-${LIBTOOL_VER}/patched_07.marker ] ; then
        patch -p1 < ${PATCHES_DIR}/libtool/0008-find-external-libraries.patch \
            >> ${LOGS_DIR}/libtool_patches.log 2>&1 || exit 1
        touch ${BUILD_DIR}/libtool-${LIBTOOL_VER}/patched_07.marker
    fi

    if [ ! -d ${BUILD_DIR}/libtool-${LIBTOOL_VER}/build ] ; then
        mkdir -p ${BUILD_DIR}/libtool-${LIBTOOL_VER}/build
    fi
    cd ${BUILD_DIR}/libtool-${LIBTOOL_VER}/build

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

        rm -fr ${BUILD_DIR}/libtool-${LIBTOOL_VER}/build/*
        echo "===> configure libtool ${arch}"
        ../configure --prefix=$PREFIX_DIR        \
                     --build=${arch}-w64-mingw32 \
                     --host=${arch}-w64-mingw32  \
        > ${LOGS_DIR}/libtool_config_${arch}.log 2>&1 || exit 1
        echo "done"

        echo "===> make libtool ${arch}"
        make -j$jobs -O > ${LOGS_DIR}/libtool_make_${arch}.log 2>&1 || exit 1
        echo "done"

        echo "===> install libtool ${arch}"
        make install-strip DESTDIR=${WORK_DIR}/prein_${arch}/libtool \
            > ${LOGS_DIR}/libtool_install_${arch}.log 2>&1 || exit 1
        echo "done"

        echo "===> copy libtool ${arch} to ${MINGW_DIR}"
        cp -fa ${WORK_DIR}/prein_${arch}/libtool${PREFIX_DIR}/* $MINGW_DIR
        echo "done"
    done

    cd $WORK_DIR
    return 0
}

copy_only_libtool() {
    clear; echo "libtool ${LIBTOOL_VER}"

    for arch in i686 x86_64
    do
        if [ "$arch" == "i686" ] ; then
            local PREFIX_DIR=/mingw32
            local MINGW_DIR=${WORK_DIR}/mingw32
        else
            local PREFIX_DIR=/mingw64
            local MINGW_DIR=${WORK_DIR}/mingw64
        fi
        echo "===> copy libtool ${arch} to ${MINGW_DIR}"
        cp -fa ${WORK_DIR}/prein_${arch}/libtool${PREFIX_DIR}/* $MINGW_DIR
        echo "done"
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

init_directories
download_srcs

if [ "$AUTOCONF_REBUILD" == "yes" ] ; then
    build_autoconf
else
    copy_only_autoconf
fi
if [ "$AUTOMAKE_REBUILD" == "yes" ] ; then
    build_automake
else
    copy_only_automake
fi
if [ "$LIBTOOL_REBUILD" == "yes" ] ; then
    build_libtool
else
    copy_only_libtool
fi

cleanup

#clear; echo "Everything has been successfully completed!"
