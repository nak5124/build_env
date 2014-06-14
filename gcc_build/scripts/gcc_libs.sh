#!/usr/bin/env bash


# Prerequisites for GCC
# http://gcc.gnu.org/install/prerequisites.html

# load
SCRIPTS_DIR=$(cd $(dirname $0);pwd)
source ${SCRIPTS_DIR}/config.sh

cd $WORK_DIR

# init
init_directories() {
    clear; echo "init directories"

    if [ ! -d $SRC_DIR ] ; then
        mkdir -p $SRC_DIR
    fi
    if [ ! -d $PATCHES_DIR ] ; then
        mkdir -p $PATCHES_DIR
    fi

    for arch in i686 x86_64
    do
        if [ ! -d ${LIBS_DIR}/$arch ] ; then
            mkdir -p ${LIBS_DIR}/$arch
        fi
    done

    if [ ! -d $LOGS_DIR ] ; then
        mkdir -p $LOGS_DIR
    fi

    cd $WORK_DIR
    return 0
}

# sources DL
download_srcs() {
    clear; echo "downloading srcs..."

    if [ ! -d $SRC_DIR ] ; then
        mkdir -p $SRC_DIR
    fi
    cd $SRC_DIR

    wget -nc ftp://ftp.gmplib.org/pub/gmp/gmp-${GMP_VER}a.tar.lz \
        > /dev/null 2>&1
    wget -nc http://www.mpfr.org/mpfr-current/mpfr-${MPFR_VER}.tar.bz2 \
        > /dev/null 2>&1
    wget -nc ftp://ftp.gnu.org/gnu/mpc/mpc-${MPC_VER}.tar.gz > /dev/null 2>&1
    wget -nc http://isl.gforge.inria.fr/isl-${ISL_VER}.tar.xz > /dev/null 2>&1
    wget -nc http://ftp.lfs-matrix.net/pub/clfs/conglomeration/cloog/cloog-${CLOOG_VER}.tar.gz \
        > /dev/null 2>&1

    cd $WORK_DIR
    return 0
}

# patches DL
download_patch() {
    if [ ! -d ${PATCHES_DIR}/mpfr ] ; then
        mkdir -p ${PATCHES_DIR}/mpfr
    fi
    cd ${PATCHES_DIR}/mpfr
    rm -f ${PATCHES_DIR}/mpfr/allpatches
    wget http://www.mpfr.org/mpfr-current/allpatches > /dev/null 2>&1

    cd $WORK_DIR
    return 0
}

# GMP
build_gmp() {
    clear; echo "Build GMP ${GMP_VER}"

    cd $BUILD_DIR
    if [ ! -d ${BUILD_DIR}/gmp-${GMP_VER} ] ; then
        tar xf ${SRC_DIR}/gmp-${GMP_VER}a.tar.lz
    fi
    cd ${BUILD_DIR}/gmp-${GMP_VER}

    for arch in i686 x86_64
    do
        if [ "$arch" == "i686" ] ; then
            local GMP_MPN="x86/coreisbr x86/pentium4/sse2 x86/pentium4/mmx x86/pentium4 x86/pentium/mmx x86/pentium x86 generic"
        else
            local GMP_MPN="x86_64/coreisbr x86_64/fastavx x86_64/coreinhm x86_64/fastsse x86_64/core2 x86_64/pentium4 x86_64 generic"
        fi
        source cpath $arch
        echo "===> configure GMP ${arch}"
        ./configure --prefix=${LIBS_DIR}/$arch  \
                    --build=${arch}-w64-mingw32 \
                    --host=${arch}-w64-mingw32  \
                    --disable-shared            \
                    --enable-static             \
                    --enable-cxx                \
                    --enable-assembly           \
                    MPN_PATH="${GMP_MPN}"       \
                    CFLAGS="${_CFLAGS}"         \
                    CXXFLAGS="${_CXXFLAGS}"     \
                    CPPFLAGS="${_CPPFLAGS}"     \
                    LDFLAGS="${_LDFLAGS}"       \
        > ${LOGS_DIR}/gmp_config_${arch}.log 2>&1 || exit 1
        echo "done"

        make clean > /dev/null 2>&1
        echo "===> make GMP ${arch}"
        make -j$jobs -O all > ${LOGS_DIR}/gmp_make_${arch}.log 2>&1 || exit 1
        echo "done"

        echo "===> install GMP ${arch}"
        make install-strip > ${LOGS_DIR}/gmp_install_${arch}.log 2>&1 || exit 1
        echo "done"
        make distclean > /dev/null 2>&1
    done

    cd $WORK_DIR
    return 0
}

# MPFR
build_mpfr() {
    clear; echo "Build MPFR ${MPFR_VER}"

    cd $BUILD_DIR
    if [ ! -d ${BUILD_DIR}/mpfr-${MPFR_VER} ] ; then
        tar xjf ${SRC_DIR}/mpfr-${MPFR_VER}.tar.bz2
    else
        rm -fr ${BUILD_DIR}/mpfr-${MPFR_VER}
        tar xjf ${SRC_DIR}/mpfr-${MPFR_VER}.tar.bz2
    fi
    cd ${BUILD_DIR}/mpfr-${MPFR_VER}

    patch -p1 < ${PATCHES_DIR}/mpfr/allpatches \
        > ${LOGS_DIR}/mpfr_patches.log 2>&1 || exit 1

    for arch in i686 x86_64
    do
        source cpath $arch
        echo "===> configure MPFR ${arch}"
        ./configure --prefix=${LIBS_DIR}/$arch   \
                    --build=${arch}-w64-mingw32  \
                    --host=${arch}-w64-mingw32   \
                    --disable-shared             \
                    --enable-static              \
                    --with-gmp=${LIBS_DIR}/$arch \
                    --enable-thread-safe         \
                    CFLAGS="${_CFLAGS}"          \
                    CXXFLAGS="${_CXXFLAGS}"      \
                    CPPFLAGS="${_CPPFLAGS}"      \
                    LDFLAGS="${_LDFLAGS}"        \
        > ${LOGS_DIR}/mpfr_config_${arch}.log 2>&1 || exit 1
        echo "done"

        make clean > /dev/null 2>&1
        echo "===> make MPFR ${arch}"
        make -j$jobs -O all > ${LOGS_DIR}/mpfr_make_${arch}.log 2>&1 || exit 1
        echo "done"

        echo "===> install MPFR ${arch}"
        make install-strip \
            > ${LOGS_DIR}/mpfr_install_${arch}.log 2>&1 || exit 1
        echo "done"
        make distclean > /dev/null 2>&1
    done

    cd $WORK_DIR
    return 0
}

# MPC
build_mpc() {
    clear; echo "Build MPC ${MPC_VER}"

    cd $BUILD_DIR
    if [ ! -d ${BUILD_DIR}/mpc-${MPC_VER} ] ; then
        tar xzf ${SRC_DIR}/mpc-${MPC_VER}.tar.gz
    fi
    cd ${BUILD_DIR}/mpc-${MPC_VER}

    for arch in i686 x86_64
    do
        source cpath $arch
        echo "===> configure MPC ${arch}"
        ./configure --prefix=${LIBS_DIR}/$arch    \
                    --build=${arch}-w64-mingw32   \
                    --host=${arch}-w64-mingw32    \
                    --disable-shared              \
                    --enable-static               \
                    --with-gmp=${LIBS_DIR}/$arch  \
                    --with-mpfr=${LIBS_DIR}/$arch \
                    CFLAGS="${_CFLAGS}"           \
                    CXXFLAGS="${_CXXFLAGS}"       \
                    CPPFLAGS="${_CPPFLAGS}"       \
                    LDFLAGS="${_LDFLAGS}"         \
        > ${LOGS_DIR}/mpc_config_${arch}.log 2>&1 || exit 1
        echo "done"

        make clean > /dev/null 2>&1
        echo "===> make MPC ${arch}"
        make -j$jobs -O all > ${LOGS_DIR}/mpc_make_${arch}.log 2>&1 || exit 1
        echo "done"

        echo "===> install MPC ${arch}"
        make install-strip > ${LOGS_DIR}/mpc_install_${arch}.log 2>&1 || exit 1
        echo "done"
        make distclean > /dev/null 2>&1
    done

    cd $WORK_DIR
    return 0
}

# ISL
build_isl() {
    clear; echo "Build ISL ${ISL_VER}"

    cd $BUILD_DIR
    if [ ! -d ${BUILD_DIR}/isl-${ISL_VER} ] ; then
        tar Jxf ${SRC_DIR}/isl-${ISL_VER}.tar.xz
    fi
    cd ${BUILD_DIR}/isl-${ISL_VER}

    for arch in i686 x86_64
    do
        source cpath $arch
        echo "===> configure ISL ${arch}"
        ./configure --prefix=${LIBS_DIR}/$arch          \
                    --build=${arch}-w64-mingw32         \
                    --host=${arch}-w64-mingw32          \
                    --disable-shared                    \
                    --enable-static                     \
                    --with-gmp=system                   \
                    --with-gmp-prefix=${LIBS_DIR}/$arch \
                    --with-piplib=no                    \
                    --with-clang=no                     \
                    CFLAGS="${_CFLAGS}"                 \
                    CXXFLAGS="${_CXXFLAGS}"             \
                    CPPFLAGS="${_CPPFLAGS}"             \
                    LDFLAGS="${_LDFLAGS}"               \
        > ${LOGS_DIR}/isl_config_${arch}.log 2>&1 || exit 1
        echo "done"

        make clean > /dev/null 2>&1
        echo "===> make ISL ${arch}"
        make -j$jobs -O all > ${LOGS_DIR}/isl_make_${arch}.log 2>&1 || exit 1
        echo "done"

        echo "===> install ISL ${arch}"
        make install-strip > ${LOGS_DIR}/isl_install_${arch}.log 2>&1 || exit 1
        echo "done"
        make distclean > /dev/null 2>&1
    done

    cd $WORK_DIR
    return 0
}

# CLooG
build_cloog() {
    clear; echo "Build CLooG ${CLOOG_VER}"

    cd $BUILD_DIR
    if [ ! -d ${BUILD_DIR}/cloog-${CLOOG_VER} ] ; then
        tar xzf ${SRC_DIR}/cloog-${CLOOG_VER}.tar.gz
    fi
    cd ${BUILD_DIR}/cloog-${CLOOG_VER}

    if [ ! -f ${BUILD_DIR}/cloog-${CLOOG_VER}/patched_01.marker ] ; then
        patch -p1 < ${PATCHES_DIR}/cloog/cloog-0.18.1-isl-compat.patch \
            > ${LOGS_DIR}/cloog_patches.log 2>&1 || exit 1
        touch ${BUILD_DIR}/cloog-${CLOOG_VER}/patched_01.marker
    fi

    for arch in i686 x86_64
    do
        source cpath $arch
        echo "===> configure CLooG ${arch}"
        ./configure --prefix=${LIBS_DIR}/$arch          \
                    --build=${arch}-w64-mingw32         \
                    --host=${arch}-w64-mingw32          \
                    --disable-shared                    \
                    --enable-static                     \
                    --with-gmp-prefix=${LIBS_DIR}/$arch \
                    --with-bits=gmp                     \
                    --with-isl=system                   \
                    --with-isl-prefix=${LIBS_DIR}/$arch \
                    --with-osl=no                       \
                    CFLAGS="${_CFLAGS}"                 \
                    CXXFLAGS="${_CXXFLAGS}"             \
                    CPPFLAGS="${_CPPFLAGS}"             \
                    LDFLAGS="${_LDFLAGS}"               \
        > ${LOGS_DIR}/cloog_config_${arch}.log 2>&1 || exit 1
        echo "done"

        sed -i '/cmake/d' Makefile

        make clean > /dev/null 2>&1
        echo "===> make CLooG ${arch}"
        make -j$jobs -O all > ${LOGS_DIR}/cloog_make_${arch}.log 2>&1 || exit 1
        echo "done"

        echo "===> install GLooG ${arch}"
        make install-strip \
            > ${LOGS_DIR}/cloog_install_${arch}.log 2>&1 || exit 1
        echo "done"
        make distclean > /dev/null 2>&1
    done

    cd $WORK_DIR
    return 0
}

init_directories
download_srcs
download_patch

build_gmp
build_mpfr
build_mpc
build_isl
build_cloog

clear; echo "Everything has been successfully completed!"
