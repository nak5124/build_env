#!/usr/bin/bash


# load
SCRIPTS_DIR=`dirname $0`
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
        if [ "$arch" == "i686" ] ; then
            local MINGW_DIR=${WORK_DIR}/mingw32
        else
            local MINGW_DIR=${WORK_DIR}/mingw64
        fi
        if [[ ! -d ${MINGW_DIR}/${arch}-w64-mingw32/{include,lib} ]] ; then
            mkdir -p ${MINGW_DIR}/${arch}-w64-mingw32/{include,lib}
        fi

        if [[ ! -d ${WORK_DIR}/prein_${arch}/{libiconv,mingw-w64-headers,binutils,winpthreads,mingw-w64-crt,{zlib,bzip2}/{include,lib}} ]] ; then
            mkdir -p ${WORK_DIR}/prein_${arch}/{libiconv,mingw-w64-headers,binutils,winpthreads,mingw-w64-crt,{zlib,bzip2}/{include,lib}}
        fi
    done
    if [ ! -d $LOGS_DIR ] ; then
        mkdir -p $LOGS_DIR
    fi

    cd $WORK_DIR
    return 0
}

# source DL
download_srcs() {
    clear; echo "DL srcs"

    cd $SRC_DIR
    # libiconv
    wget -nc http://ftp.gnu.org/gnu/libiconv/libiconv-${ICONV_VER}.tar.gz > /dev/null 2>&1
    # binutils
    wget -nc http://ftp.gnu.org/gnu/binutils/binutils-${BINUTILS_VER}.tar.bz2 > /dev/null 2>&1
    # bzip2
    wget -nc http://www.bzip.org/${BZIP2_VER}/bzip2-${BZIP2_VER}.tar.gz > /dev/null 2>&1
    # GCC
    wget -nc ftp://gcc.gnu.org/pub/gcc/releases/gcc-${GCC_VER}/gcc-${GCC_VER}.tar.bz2 > /dev/null 2>&1

    cd $BUILD_DIR
    # zlib
    if [ ! -d ${BUILD_DIR}/zlib ] ; then
        git clone git://github.com/madler/zlib.git > /dev/null 2>&1
    fi
    # MinGW-w64-headers
    if [ ! -d ${BUILD_DIR}/mingw-w64-headers ] ; then
#        svn co svn://svn.code.sf.net/p/mingw-w64/code/trunk/mingw-w64-headers
        svn co http://svn.code.sf.net/p/mingw-w64/code/trunk/mingw-w64-headers > /dev/null 2>&1
    fi
    # winpthreads
    if [ ! -d ${BUILD_DIR}/winpthreads ] ; then
#        svn co svn://svn.code.sf.net/p/mingw-w64/code/trunk/mingw-w64-libraries/winpthreads
        svn co http://svn.code.sf.net/p/mingw-w64/code/trunk/mingw-w64-libraries/winpthreads > /dev/null 2>&1
    fi
    # MinGW-w64-crt
    if [ ! -d ${BUILD_DIR}/mingw-w64-crt ] ; then
#        svn co svn://svn.code.sf.net/p/mingw-w64/code/trunk/mingw-w64-crt
        svn co http://svn.code.sf.net/p/mingw-w64/code/trunk/mingw-w64-crt > /dev/null 2>&1
    fi

    cd $WORK_DIR
    return 0
}

# libiconv
build_iconv() {
    clear; echo "Build libiconv ${ICONV_VER}"

    if [ ! -d ${BUILD_DIR}/libiconv-${ICONV_VER} ] ; then
        cd $BUILD_DIR
        tar xzf ${SRC_DIR}/libiconv-${ICONV_VER}.tar.gz
    fi
    cd ${BUILD_DIR}/libiconv-${ICONV_VER}

    if [ ! -f ${BUILD_DIR}/libiconv-${ICONV_VER}/patched_01.marker ] ; then
        patch -p1 < ${PATCHES_DIR}/libiconv/libiconv-1.14-ja-1.patch > /dev/null 2>&1 || exit 1
        touch ${BUILD_DIR}/libiconv-${ICONV_VER}/patched_01.marker
    fi

    if [ ! -f ${BUILD_DIR}/libiconv-${ICONV_VER}/patched_02.marker ] ; then
        patch -p1 < ${PATCHES_DIR}/libiconv/0001-compile-relocatable-in-gnulib.mingw.patch > /dev/null 2>&1 || exit 1
        touch ${BUILD_DIR}/libiconv-${ICONV_VER}/patched_02.marker
    fi

    if [ ! -f ${BUILD_DIR}/libiconv-${ICONV_VER}/patched_03.marker ] ; then
        patch -p1 < ${PATCHES_DIR}/libiconv/0002-fix-cr-for-awk-in-configure.all.patch > /dev/null 2>&1 || exit 1
        touch ${BUILD_DIR}/libiconv-${ICONV_VER}/patched_03.marker
    fi

    if [ ! -d ${BUILD_DIR}/libiconv-${ICONV_VER}/build ] ; then
        mkdir -p ${BUILD_DIR}/libiconv-${ICONV_VER}/build
    fi
    cd ${BUILD_DIR}/libiconv-${ICONV_VER}/build

    for arch in i686 x86_64
    do
        source cpath $arch
        rm -fr ${BUILD_DIR}/libiconv-${ICONV_VER}/build/*
        echo "===> configure libiconv ${arch}"
        ../configure --prefix=${WORK_DIR}/prein_${arch}/libiconv   \
                     --build=${arch}-w64-mingw32                   \
                     --host=${arch}-w64-mingw32                    \
                     --disable-shared --enable-static              \
                     --enable-extra-encodings                      \
                     --enable-relocatable                          \
                     --disable-rpath --disable-nls                 \
                     --enable-silent-rules                         \
                     CFLAGS="${_CFLAGS}" CXXFLAGS="${_CXXFLAGS}"   \
                     CPPFLAGS="${_CPPFLAGS}" LDFLAGS="${_LDFLAGS}" \
        > ${LOGS_DIR}/iconv_config_${arch}.log 2>&1 || exit 1
        echo "done"

        echo "===> make libiconv ${arch}"
        make -j$jobs -O all > ${LOGS_DIR}/iconv_make_${arch}.log 2>&1 || exit 1
        echo "done"

        echo "===> install libiconv ${arch}"
        make install-lib > ${LOGS_DIR}/iconv_install_${arch}.log 2>&1 || exit 1
        echo "done"

        if [ "$arch" == "i686" ] ; then
            local MINGW_DIR=${WORK_DIR}/mingw32
        else
            local MINGW_DIR=${WORK_DIR}/mingw64
        fi
        echo "===> copy libiconv ${arch} to ${MINGW_DIR}"
        cp -fa ${WORK_DIR}/prein_${arch}/libiconv/include/*.h ${MINGW_DIR}/${arch}-w64-mingw32/include
        cp -fa ${WORK_DIR}/prein_${arch}/libiconv/lib/*.a ${MINGW_DIR}/${arch}-w64-mingw32/lib
        echo "done"
    done

    cd $WORK_DIR
    return 0
}

copy_only_iconv() {
    clear; echo "libiconv ${ICONV_VER}"

    for arch in i686 x86_64
    do
        if [ "$arch" == "i686" ] ; then
            local MINGW_DIR=${WORK_DIR}/mingw32
        else
            local MINGW_DIR=${WORK_DIR}/mingw64
        fi
        echo "===> copy libiconv ${arch} to ${MINGW_DIR}"
        cp -fa ${WORK_DIR}/prein_${arch}/libiconv/include/*.h ${MINGW_DIR}/${arch}-w64-mingw32/include
        cp -fa ${WORK_DIR}/prein_${arch}/libiconv/lib/*.a ${MINGW_DIR}/${arch}-w64-mingw32/lib
        echo "done"
    done

    cd $WORK_DIR
    return 0
}

# zlib
build_zlib() {
    clear; echo "Build zlib git-develop"

    cd ${BUILD_DIR}/zlib
    git checkout develop > /dev/null 2>&1
    git clean -fdx > /dev/null 2>&1
    git reset --hard > /dev/null 2>&1
    git pull --rebase > /dev/null 2>&1
    git describe > ${LOGS_DIR}/zlib.hash
    git_hash >> ${LOGS_DIR}/zlib.hash
    git_rev >> ${LOGS_DIR}/zlib.hash

    for arch in i686 x86_64
    do
        source cpath $arch
        if [ "$arch" == "i686" ] ; then
            cp -fa ${BUILD_DIR}/zlib/contrib/asm686/match.S ${BUILD_DIR}/zlib/match.S
        else
            cp -fa ${BUILD_DIR}/zlib/contrib/amd64/amd64-match.S ${BUILD_DIR}/zlib/match.S
        fi

        make clean -f ${BUILD_DIR}/zlib/win32/Makefile.gcc > /dev/null 2>&1
        echo "===> make zlib ${arch}"
        make -j$jobs -O libz.a -f ${BUILD_DIR}/zlib/win32/Makefile.gcc              \
            CFLAGS="${_CFLAGS} -D_LARGEFILE64_SOURCE=1" LOC="-DASMV" OBJA="match.o" \
            > ${LOGS_DIR}/zlib_make_${arch}.log 2>&1 || exit 1
        echo "done"

        echo "===> install zlib ${arch}"
        cp -fa ${BUILD_DIR}/zlib/zlib.h ${BUILD_DIR}/zlib/zconf.h ${WORK_DIR}/prein_${arch}/zlib/include
        cp -fa ${BUILD_DIR}/zlib/libz.a ${WORK_DIR}/prein_${arch}/zlib/lib
        echo "done"

        if [ "$arch" == "i686" ] ; then
            local MINGW_DIR=${WORK_DIR}/mingw32
        else
            local MINGW_DIR=${WORK_DIR}/mingw64
        fi
        echo "===> copy zlib ${arch} to ${MINGW_DIR}"
        cp -fra ${WORK_DIR}/prein_${arch}/zlib/* ${MINGW_DIR}/${arch}-w64-mingw32
        echo "done"

        git clean -fdx > /dev/null 2>&1
        git reset --hard > /dev/null 2>&1
    done

    cd $WORK_DIR
    return 0
}

copy_only_zlib() {
    clear; echo "zlib git-master"

    for arch in i686 x86_64
    do
        if [ "$arch" == "i686" ] ; then
            local MINGW_DIR=${WORK_DIR}/mingw32
        else
            local MINGW_DIR=${WORK_DIR}/mingw64
        fi
        echo "===> copy zlib ${arch} to ${MINGW_DIR}"
        cp -fra ${WORK_DIR}/prein_${arch}/zlib/* ${MINGW_DIR}/${arch}-w64-mingw32
        echo "done"
    done

    cd $WORK_DIR
    return 0
}

# MinGW-w64-headers
build_headers() {
    clear; echo "Build MinGW-w64 headers svn-trunk"

    cd ${BUILD_DIR}/mingw-w64-headers
    svn cleanup > /dev/null 2>&1
    svn revert --recursive . > /dev/null 2>&1
    svn update > /dev/null 2>&1
    svnversion -c > ${LOGS_DIR}/headers.hash

    if [ ! -d ${BUILD_DIR}/mingw-w64-headers/build ] ; then
        mkdir -p ${BUILD_DIR}/mingw-w64-headers/build
    fi
    cd ${BUILD_DIR}/mingw-w64-headers/build

    for arch in i686 x86_64
    do
        source cpath $arch
        rm -fr ${BUILD_DIR}/mingw-w64-headers/build/*
        echo "===> configure MinGW-w64 headers ${arch}"
        ../configure --prefix=${WORK_DIR}/prein_${arch}/mingw-w64-headers \
                     --build=${arch}-w64-mingw32                          \
                     --host=${arch}-w64-mingw32                           \
                     --enable-sdk=all --enable-secure-api                 \
                     CFLAGS="${_CFLAGS}" CXXFLAGS="${_CXXFLAGS}"          \
                     CPPFLAGS="${_CPPFLAGS}" LDFLAGS="${_LDFLAGS}"        \
        > ${LOGS_DIR}/headers_config_${arch}.log 2>&1 || exit 1
        echo "done"

        echo "===> make MinGW-w64 headers ${arch}"
        make -j$jobs -O all > ${LOGS_DIR}/headers_make_${arch}.log 2>&1 || exit 1
        echo "done"

        echo "===> install MinGW-w64 headers ${arch}"
        rm -fr ${WORK_DIR}/prein_${arch}/mingw-w64-headers/*
        make install-strip > ${LOGS_DIR}/headers_install_${arch}.log 2>&1 || exit 1
        echo "done"

        if [ "$arch" == "i686" ] ; then
            local MINGW_DIR=${WORK_DIR}/mingw32
        else
            local MINGW_DIR=${WORK_DIR}/mingw64
        fi
        echo "===> copy MinGW-w64 headers ${arch} to ${MINGW_DIR}"
        cp -fra ${WORK_DIR}/prein_${arch}/mingw-w64-headers/* ${MINGW_DIR}/${arch}-w64-mingw32
        ln -s ${MINGW_DIR}/${arch}-w64-mingw32 ${MINGW_DIR}/mingw
        echo "done"
    done

    cd $WORK_DIR
    return 0
}

copy_only_headers() {
    clear; echo "MinGW-w64 headers svn-trunk"

    for arch in i686 x86_64
    do
        if [ "$arch" == "i686" ] ; then
            local MINGW_DIR=${WORK_DIR}/mingw32
        else
            local MINGW_DIR=${WORK_DIR}/mingw64
        fi
        echo "===> copy MinGW-w64 headers ${arch} to ${MINGW_DIR}"
        cp -fra ${WORK_DIR}/prein_${arch}/mingw-w64-headers/* ${MINGW_DIR}/${arch}-w64-mingw32
        ln -s ${MINGW_DIR}/${arch}-w64-mingw32 ${MINGW_DIR}/mingw
        echo "done"
    done

    cd $WORK_DIR
    return 0
}

# Binutils
build_binutils() {
    clear; echo "Build Binutils ${BINUTILS_VER}"

    if [ ! -d ${BUILD_DIR}/binutils-${BINUTILS_VER} ] ; then
        cd $BUILD_DIR
        tar xjf ${SRC_DIR}/binutils-${BINUTILS_VER}.tar.bz2
    fi
    cd ${BUILD_DIR}/binutils-${BINUTILS_VER}

    if [ ! -f ${BUILD_DIR}/binutils-${BINUTILS_VER}/patched_01.marker ] ; then
        # do not install libiberty
        sed -i 's/install_to_$(INSTALL_DEST) //' libiberty/Makefile.in
        touch ${BUILD_DIR}/binutils-${BINUTILS_VER}/patched_01.marker
    fi

    if [ ! -f ${BUILD_DIR}/binutils-${BINUTILS_VER}/patched_02.marker ] ; then
        # hack! - libiberty configure tests for header files using "$CPP $CPPFLAGS"
        sed -i "/ac_cpp=/s/\$CPPFLAGS/\$CPPFLAGS -Os/" libiberty/configure
        touch ${BUILD_DIR}/binutils-${BINUTILS_VER}/patched_02.marker
    fi

    if [ ! -f ${BUILD_DIR}/binutils-${BINUTILS_VER}/patched_03.marker ] ; then
        patch -p1 < ${PATCHES_DIR}/binutils/100-dont-escape-arguments-that-dont-need-it-in-pex-win32.c.patch \
            > /dev/null 2>&1 || exit 1
        touch ${BUILD_DIR}/binutils-${BINUTILS_VER}/patched_03.marker
    fi

    if [ ! -f ${BUILD_DIR}/binutils-${BINUTILS_VER}/patched_04.marker ] ; then
        patch -p1 < ${PATCHES_DIR}/binutils/020-add-bigobj-format.patch \
            > /dev/null 2>&1 || exit 1
        touch ${BUILD_DIR}/binutils-${BINUTILS_VER}/patched_04.marker
    fi

    if [ ! -f ${BUILD_DIR}/binutils-${BINUTILS_VER}/patched_05.marker ] ; then
        patch -p1 < ${PATCHES_DIR}/binutils/030-binutils-mingw-gnu-print.patch \
            > /dev/null 2>&1 || exit 1
        touch ${BUILD_DIR}/binutils-${BINUTILS_VER}/patched_05.marker
    fi

    if [ ! -f ${BUILD_DIR}/binutils-${BINUTILS_VER}/patched_06.marker ] ; then
        # Fixes bug https://sourceware.org/bugzilla/show_bug.cgi?id=16858#c3
        patch -p1 < ${PATCHES_DIR}/binutils/120-Bug-16858-weak-external-reference-has-wrong-value.patch \
            > /dev/null 2>&1 || exit 1
        touch ${BUILD_DIR}/binutils-${BINUTILS_VER}/patched_06.marker
    fi

    if [ ! -d ${BUILD_DIR}/binutils-${BINUTILS_VER}/build ] ; then
        mkdir -p ${BUILD_DIR}/binutils-${BINUTILS_VER}/build
    fi
    cd ${BUILD_DIR}/binutils-${BINUTILS_VER}/build

    for arch in i686 x86_64
    do
        if [ "$arch" == "i686" ] ; then
            local MINGW_DIR=${WORK_DIR}/mingw32
            local _64_bit_bfd=""
            local _LAA=" -Wl,--large-address-aware"
        else
            local MINGW_DIR=${WORK_DIR}/mingw64
            local _64_bit_bfd="--enable-64-bit-bfd"
            local _LAA=""
        fi

        source cpath $arch
        rm -fr ${BUILD_DIR}/binutils-${BINUTILS_VER}/build/*
        echo "===> configure Binutils ${arch}"
        ../configure --prefix=${WORK_DIR}/prein_${arch}/binutils               \
                     --with-sysroot=${MINGW_DIR}/${arch}-w64-mingw32           \
                     --build=${arch}-w64-mingw32                               \
                     --target=${arch}-w64-mingw32                              \
                     --disable-shared --enable-static                          \
                     --disable-multilib                                        \
                     --enable-lto                                              \
                     --disable-rpath --disable-nls                             \
                     --disable-werror                                          \
                     --disable-install-libbfd                                  \
                     --with-libiconv-prefix=${WORK_DIR}/prein_${arch}/libiconv \
                     ${_64_bit_bfd}                                            \
                     CFLAGS="${_CFLAGS}" CXXFLAGS="${_CXXFLAGS}"               \
                     CPPFLAGS="${_CPPFLAGS}" LDFLAGS="${_LDFLAGS} ${_LAA}"     \
        > ${LOGS_DIR}/binutils_config_${arch}.log 2>&1 || exit 1
        echo "done"

        echo "===> make Binutils ${arch}"
        make -j$jobs -O all > ${LOGS_DIR}/binutils_make_${arch}.log 2>&1 || exit 1
        echo "done"

        echo "===> install Binutils ${arch}"
        rm -fr ${WORK_DIR}/prein_${arch}/binutils/*
        make install-strip > ${LOGS_DIR}/binutils_install_${arch}.log 2>&1 || exit 1
        echo "done"

        echo "===> copy Binutils ${arch} to ${MINGW_DIR}"
        cp -fra ${WORK_DIR}/prein_${arch}/binutils/bin $MINGW_DIR
        cp -fra ${WORK_DIR}/prein_${arch}/binutils/${arch}-w64-mingw32/* ${MINGW_DIR}/${arch}-w64-mingw32
        if [ -d ${MINGW_DIR}/mingw ] ; then
            rm -fr ${MINGW_DIR}/mingw
        fi
        echo "done"
    done

    cd $WORK_DIR
    return 0
}

copy_only_binutils() {
    clear; echo "Binutils ${BINUTILS_VER}"

    for arch in i686 x86_64
    do
        if [ "$arch" == "i686" ] ; then
            local MINGW_DIR=${WORK_DIR}/mingw32
        else
            local MINGW_DIR=${WORK_DIR}/mingw64
        fi
        echo "===> copy Binutils ${arch} to ${MINGW_DIR}"
        cp -fra ${WORK_DIR}/prein_${arch}/binutils/bin $MINGW_DIR
        cp -fra ${WORK_DIR}/prein_${arch}/binutils/${arch}-w64-mingw32/* ${MINGW_DIR}/${arch}-w64-mingw32
        if [ -d ${MINGW_DIR}/mingw ] ; then
            rm -fr ${MINGW_DIR}/mingw
        fi
        echo "done"
    done

    cd $WORK_DIR
    return 0
}

# bzip2
build_bzip2() {
    clear; echo "Build bzip2 ${BZIP2_VER}"

    if [ ! -d ${BUILD_DIR}/bzip2-${BZIP2_VER} ] ; then
        cd $BUILD_DIR
        tar xzf ${SRC_DIR}/bzip2-${BZIP2_VER}.tar.gz
    fi
    cd ${BUILD_DIR}/bzip2-${BZIP2_VER}

    if [ ! -f ${BUILD_DIR}/bzip2-${BZIP2_VER}/patched_01.marker ] ; then
        patch -p1 < ${PATCHES_DIR}/bzip2/bzip2-use-cdecl-calling-convention.patch \
            > /dev/null 2>&1 || exit 1
        touch ${BUILD_DIR}/bzip2-${BZIP2_VER}/patched_01.marker
    fi

    for arch in i686 x86_64
    do
        source cpath $arch
        make distclean > /dev/null 2>&1
        echo "===> make bzip2 ${arch}"
        make libbz2.a CFLAGS="${_CFLAGS} -D_FILE_OFFSET_BITS=64" \
            > ${LOGS_DIR}/bzip2_make_${arch}.log 2>&1 || exit 1
        echo "done"

        echo "===> install bzip2 ${arch}"
        cp -fa ${BUILD_DIR}/bzip2-${BZIP2_VER}/bzlib.h ${WORK_DIR}/prein_${arch}/bzip2/include
        cp -fa ${BUILD_DIR}/bzip2-${BZIP2_VER}/libbz2.a ${WORK_DIR}/prein_${arch}/bzip2/lib
        echo "done"

        if [ "$arch" == "i686" ] ; then
            local MINGW_DIR=${WORK_DIR}/mingw32
        else
            local MINGW_DIR=${WORK_DIR}/mingw64
        fi
        echo "===> copy bzip2 ${arch} to ${MINGW_DIR}"
        cp -fra ${WORK_DIR}/prein_${arch}/bzip2/* ${MINGW_DIR}/${arch}-w64-mingw32
        echo "done"
    done

    cd $WORK_DIR
    return 0
}

copy_only_bzip2() {
    clear; echo "bzip2 ${BZIP2_VER}"

    for arch in i686 x86_64
    do
        if [ "$arch" == "i686" ] ; then
            local MINGW_DIR=${WORK_DIR}/mingw32
        else
            local MINGW_DIR=${WORK_DIR}/mingw64
        fi
        echo "===> copy bzip2 ${arch} to ${MINGW_DIR}"
        cp -fra ${WORK_DIR}/prein_${arch}/bzip2/* ${MINGW_DIR}/${arch}-w64-mingw32
        echo "done"
    done

    cd $WORK_DIR
    return 0
}

# winpthreads
build_winpthreads() {
    clear; echo "Build winpthreads svn-trunk"

    cd ${BUILD_DIR}/winpthreads
    svn cleanup > /dev/null 2>&1
    svn revert --recursive . > /dev/null 2>&1
    svn update > /dev/null 2>&1
    svnversion -c > ${LOGS_DIR}/winpthreads.hash

    if [ ! -d ${BUILD_DIR}/winpthreads/build ] ; then
        mkdir -p ${BUILD_DIR}/winpthreads/build
    fi
    cd ${BUILD_DIR}/winpthreads/build

    for arch in i686 x86_64
    do
        source cpath $arch
        rm -fr ${BUILD_DIR}/winpthreads/build/*
        echo "===> configure winpthreads ${arch}"
        ../configure --prefix=${WORK_DIR}/prein_${arch}/winpthreads \
                     --build=${arch}-w64-mingw32                    \
                     --host=${arch}-w64-mingw32                     \
                     --disable-shared --enable-static               \
                     CFLAGS="${_CFLAGS}" CXXFLAGS="${_CXXFLAGS}"    \
                     CPPFLAGS="${_CPPFLAGS}" LDFLAGS="${_LDFLAGS}"  \
        > ${LOGS_DIR}/winpthreads_config_${arch}.log 2>&1 || exit 1
        echo "done"

        echo "===> make winpthreads ${arch}"
        make -j$jobs -O all > ${LOGS_DIR}/winpthreads_make_${arch}.log 2>&1 || exit 1
        echo "done"

        echo "===> install winpthreads ${arch}"
        rm -fr ${WORK_DIR}/prein_${arch}/winpthreads/*
        make install-strip > ${LOGS_DIR}/winpthreads_install_${arch}.log 2>&1 || exit 1
        echo "done"

        if [ "$arch" == "i686" ] ; then
            local MINGW_DIR=${WORK_DIR}/mingw32
        else
            local MINGW_DIR=${WORK_DIR}/mingw64
        fi
        echo "===> copy winpthreads ${arch} to ${MINGW_DIR}"
        cp -fra ${WORK_DIR}/prein_${arch}/winpthreads/include/*.h ${MINGW_DIR}/${arch}-w64-mingw32/include
        cp -fra ${WORK_DIR}/prein_${arch}/winpthreads/lib/*.a ${MINGW_DIR}/${arch}-w64-mingw32/lib
        if [ -d ${MINGW_DIR}/mingw ] ; then
            rm -fr ${MINGW_DIR}/mingw
        fi
        ln -s ${MINGW_DIR}/${arch}-w64-mingw32 ${MINGW_DIR}/mingw
        echo "done"
    done

    cd $WORK_DIR
    return 0
}

copy_only_winpthreads() {
    clear; echo "winpthreads svn-trunk"

    for arch in i686 x86_64
    do
        if [ "$arch" == "i686" ] ; then
            local MINGW_DIR=${WORK_DIR}/mingw32
        else
            local MINGW_DIR=${WORK_DIR}/mingw64
        fi
        echo "===> copy winpthreads ${arch} to ${MINGW_DIR}"
        cp -fra ${WORK_DIR}/prein_${arch}/winpthreads/include/*.h ${MINGW_DIR}/${arch}-w64-mingw32/include
        cp -fra ${WORK_DIR}/prein_${arch}/winpthreads/lib/*.a ${MINGW_DIR}/${arch}-w64-mingw32/lib
        if [ -d ${MINGW_DIR}/mingw ] ; then
            rm -fr ${MINGW_DIR}/mingw
        fi
        ln -s ${MINGW_DIR}/${arch}-w64-mingw32 ${MINGW_DIR}/mingw
        echo "done"
    done

    cd $WORK_DIR
    return 0
}

# GCC1
build_gcc1() {
    clear; echo "Build GCC 1st step ${GCC_VER}"

    if [ ! -d ${BUILD_DIR}/gcc-${GCC_VER} ] ; then
        cd $BUILD_DIR
        tar xjf ${SRC_DIR}/gcc-${GCC_VER}.tar.bz2
    fi
    cd ${BUILD_DIR}/gcc-${GCC_VER}

    if [ ! -f ${BUILD_DIR}/gcc-${GCC_VER}/patched_01.marker ] ; then
        # do not install libiberty
        sed -i 's/install_to_$(INSTALL_DEST) //' libiberty/Makefile.in
        touch ${BUILD_DIR}/gcc-${GCC_VER}/patched_01.marker
    fi

    if [ ! -f ${BUILD_DIR}/gcc-${GCC_VER}/patched_02.marker ] ; then
        # hack! - some configure tests for header files using "$CPP $CPPFLAGS"
        sed -i "/ac_cpp=/s/\$CPPFLAGS/\$CPPFLAGS -Os/" {libiberty,gcc}/configure
        touch ${BUILD_DIR}/gcc-${GCC_VER}/patched_02.marker
    fi

    if [ ! -f ${BUILD_DIR}/gcc-${GCC_VER}/patched_03.marker ] ; then
        patch -p1 < ${PATCHES_DIR}/gcc-${GCC_VER}/gcc-4.8-libstdc++export.patch \
            > /dev/null 2>&1 || exit 1
        touch ${BUILD_DIR}/gcc-${GCC_VER}/patched_03.marker
    fi

    if [ ! -f ${BUILD_DIR}/gcc-${GCC_VER}/patched_04.marker ] ; then
        patch -p1 < ${PATCHES_DIR}/gcc-${GCC_VER}/gcc-4.7-stdthreads.patch \
            > /dev/null 2>&1 || exit 1
        touch ${BUILD_DIR}/gcc-${GCC_VER}/patched_04.marker
    fi

    if [ ! -f ${BUILD_DIR}/gcc-${GCC_VER}/patched_05.marker ] ; then
        # Don't waste valuable commandline chars on double-quotes around "arguments"
        # that don't need them.
        patch -p1 < ${PATCHES_DIR}/gcc-${GCC_VER}/dont-escape-arguments-that-dont-need-it-in-pex-win32.patch \
            > /dev/null 2>&1 || exit 1
        touch ${BUILD_DIR}/gcc-${GCC_VER}/patched_05.marker
    fi

    if [ ! -f ${BUILD_DIR}/gcc-${GCC_VER}/patched_06.marker ] ; then
        # Make Windows behave the same as Posix in the consideration of whether folder
        # "/exists/doesnt-exist/.." is a valid path.. in Posix, it isn't.
        patch -p1 < ${PATCHES_DIR}/gcc-${GCC_VER}/fix-for-windows-not-minding-non-existent-parent-dirs.patch \
            > /dev/null 2>&1 || exit 1
        touch ${BUILD_DIR}/gcc-${GCC_VER}/patched_06.marker
    fi

    if [ ! -f ${BUILD_DIR}/gcc-${GCC_VER}/patched_07.marker ] ; then
        # Don't make a lowercase backslashed path from argv[0]
        #   that then fail to strcmp with prefix(es) .. they're also ugly.
        patch -p1 < ${PATCHES_DIR}/gcc-${GCC_VER}/windows-lrealpath-no-force-lowercase-nor-backslash.patch \
            > /dev/null 2>&1 || exit 1
        touch ${BUILD_DIR}/gcc-${GCC_VER}/patched_07.marker
    fi

    if [ ! -f ${BUILD_DIR}/gcc-${GCC_VER}/patched_08.marker ] ; then
        # Kai's libgomp fix.
        patch -p1 < ${PATCHES_DIR}/gcc-${GCC_VER}/ktietz-libgomp.patch \
            > /dev/null 2>&1 || exit 1
        touch ${BUILD_DIR}/gcc-${GCC_VER}/patched_08.marker
    fi

    if [ ! -f ${BUILD_DIR}/gcc-${GCC_VER}/patched_09.marker ] ; then
        # http://gcc.gnu.org/bugzilla/show_bug.cgi?id=60902
        patch -p1 < ${PATCHES_DIR}/gcc-${GCC_VER}/PR60902.patch \
            > /dev/null 2>&1 || exit 1
        touch ${BUILD_DIR}/gcc-${GCC_VER}/patched_09.marker
    fi

    if [ ! -f ${BUILD_DIR}/gcc-${GCC_VER}/patched_10.marker ] ; then
        # http://gcc.gnu.org/bugzilla/show_bug.cgi?id=57440
        patch -p1 < ${PATCHES_DIR}/gcc-${GCC_VER}/PR57440.patch \
            > /dev/null 2>&1 || exit 1
        touch ${BUILD_DIR}/gcc-${GCC_VER}/patched_10.marker
    fi

    if [ ! -f ${BUILD_DIR}/gcc-${GCC_VER}/patched_11.marker ] ; then
        # http://gcc.gnu.org/bugzilla/show_bug.cgi?id=57653
        patch -p0 < ${PATCHES_DIR}/gcc-${GCC_VER}/PR57653.patch \
            > /dev/null 2>&1 || exit 1
        touch ${BUILD_DIR}/gcc-${GCC_VER}/patched_11.marker
    fi

    for arch in i686 x86_64
    do
        if [ ! -d ${BUILD_DIR}/gcc-${GCC_VER}/build/$arch ] ; then
            mkdir -p ${BUILD_DIR}/gcc-${GCC_VER}/build/$arch
        fi
        cd ${BUILD_DIR}/gcc-${GCC_VER}/build/$arch
        rm -fr ${BUILD_DIR}/gcc-${GCC_VER}/build/${arch}/*

        if [ "$arch" == "i686" ] ; then
            local MINGW_DIR=${WORK_DIR}/mingw32
            local _optimization="--with-arch=i686 --with-tune=generic"
            local _LAA=" -Wl,--large-address-aware"
        else
            local MINGW_DIR=${WORK_DIR}/mingw64
            local _optimization="--with-arch=x86-64 --with-tune=generic"
            local _LAA=""
        fi

        source cpath $arch
        echo "===> configure GCC 1st step ${arch}"
        ../../configure --prefix=${MINGW_DIR}                                      \
                        --with-sysroot=${MINGW_DIR}                                \
                        --build=${arch}-w64-mingw32                                \
                        --target=${arch}-w64-mingw32                               \
                        --disable-shared --enable-static                           \
                        --disable-multilib                                         \
                        --enable-languages=c,c++,lto                               \
                        --enable-threads=win32                                     \
                        --enable-lto                                               \
                        --enable-version-specific-runtime-libs                     \
                        --enable-fully-dynamic-string                              \
                        --enable-libgomp                                           \
                        --disable-libssp --disable-libquadmath                     \
                        --disable-bootstrap                                        \
                        --disable-win32-registry                                   \
                        --disable-rpath --disable-nls                              \
                        --disable-werror --disable-symvers                         \
                        --disable-libstdcxx-pch                                    \
                        --disable-libstdcxx-debug                                  \
                        --with-{gmp,mpfr,mpc,isl,cloog}=${LIBS_DIR}/$arch          \
                        --disable-isl-version-check                                \
                        --disable-cloog-version-check                              \
                        --enable-cloog-backend=isl                                 \
                        --with-libiconv-prefix=${WORK_DIR}/prein_${arch}/libiconv  \
                        --with-system-zlib                                         \
                        ${_optimization}                                           \
                        CFLAGS="${_CFLAGS}" CFLAGS_FOR_TARGET="${_CFLAGS}"         \
                        CXXFLAGS="${_CXXFLAGS}" CXXFLAGS_FOR_TARGET="${_CXXFLAGS}" \
                        CPPFLAGS="${_CPPFLAGS}" CPPFLAGS_FOR_TARGET="${_CPPFLAGS}" \
                        LDFLAGS="${_LDFLAGS} ${_LAA}"                              \
                        LDFLAGS_FOR_TARGET="${_LDFLAGS} ${_LAA}"                   \
        > ${LOGS_DIR}/gcc1_config_${arch}.log 2>&1 || exit 1
        echo "done"

        echo "===> make GCC 1st step ${arch}"
        make_num=0
        while [ "$make_num" -lt 3 ]
        do
            make_num_old=$make_num
            make -j$jobs -O all-gcc > ${LOGS_DIR}/gcc1_make_${arch}.log 2>&1 \
                || make_num=$(($make_num + 1))
            if [ "$make_num_old" -eq "$make_num" ] ; then
                break
            fi
        done
        if [ "$make_num" -eq 3 ] ; then
            exit 1
        fi
        echo "done"

        echo "===> install GCC 1st step ${arch}"
        make install-gcc > ${LOGS_DIR}/gcc1_install_${arch}.log 2>&1 || exit 1
        echo "done"
    done

    cd $WORK_DIR
    return 0
}

# MinGW-w64-crt
build_crt() {
    clear; echo "Build MinGW-w64 crt svn-trunk"

    cd ${BUILD_DIR}/mingw-w64-crt
    svn cleanup > /dev/null 2>&1
    svn revert --recursive . > /dev/null 2>&1
    svn update > /dev/null 2>&1
    svnversion -c > ${LOGS_DIR}/crt.hash

    if [ ! -d ${BUILD_DIR}/mingw-w64-crt/build ] ; then
        mkdir -p ${BUILD_DIR}/mingw-w64-crt/build
    fi
    cd ${BUILD_DIR}/mingw-w64-crt/build

    for arch in i686 x86_64
    do
        source cpath nogcc
        rm -fr ${BUILD_DIR}/mingw-w64-crt/build/*

        if [ "$arch" == "i686" ] ; then
            local MINGW_DIR=${WORK_DIR}/mingw32
            local _libs_conf="--enable-lib32 --disable-lib64"
        else
            local MINGW_DIR=${WORK_DIR}/mingw64
            local _libs_conf="--disable-lib32 --enable-lib64"
        fi
        PATH=${MINGW_DIR}/bin:$PATH
        export PATH

        echo "===> configure MinGW-w64 crt ${arch}"
        ../configure --prefix=${WORK_DIR}/prein_${arch}/mingw-w64-crt    \
                     --build=${arch}-w64-mingw32                         \
                     --host=${arch}-w64-mingw32                          \
                     ${_libs_conf}                                       \
                     --disable-libce                                     \
                     --with-sysroot=${MINGW_DIR}/${arch}-w64-mingw32     \
                     --enable-wildcard                                   \
                     CFLAGS="${_CFLAGS/-D__USE_MINGW_ANSI_STDIO=1/}"     \
                     CXXFLAGS="${_CXXFLAGS/-D__USE_MINGW_ANSI_STDIO=1/}" \
                     CPPFLAGS="${_CPPFLAGS/-D__USE_MINGW_ANSI_STDIO=1/}" \
                     LDFLAGS="${_LDFLAGS}"                               \
        > ${LOGS_DIR}/crt_config_${arch}.log 2>&1 || exit 1
        echo "done"

        echo "===> make MinGW-w64 crt ${arch}"
        make -j$jobs -O all > ${LOGS_DIR}/crt_make_${arch}.log 2>&1 || exit 1
        echo "done"

        echo "===> install MinGW-w64 crt ${arch}"
        rm -fr ${WORK_DIR}/prein_${arch}/mingw-w64-crt/*
        make install-strip > ${LOGS_DIR}/crt_install_${arch}.log 2>&1 || exit 1
        echo "done"

        echo "===> copy MinGW-w64 crt ${arch} to ${MINGW_DIR}"
        cp -fra ${WORK_DIR}/prein_${arch}/mingw-w64-crt/* ${MINGW_DIR}/${arch}-w64-mingw32
        echo "done"
    done

    cd $WORK_DIR
    return 0
}

copy_only_crt() {
    clear; echo "MinGW-w64 crt svn-trunk"

    for arch in i686 x86_64
    do
        if [ "$arch" == "i686" ] ; then
            local MINGW_DIR=${WORK_DIR}/mingw32
        else
            local MINGW_DIR=${WORK_DIR}/mingw64
        fi
        echo "===> copy MinGW-w64 crt ${arch} to ${MINGW_DIR}"
        cp -fra ${WORK_DIR}/prein_${arch}/mingw-w64-crt/* ${MINGW_DIR}/${arch}-w64-mingw32
        echo "done"
    done

    cd $WORK_DIR
    return 0
}

# GCC2
build_gcc2() {
    clear; echo "Build GCC 2nd step ${GCC_VER}"

    for arch in i686 x86_64
    do
        if [ ! -d ${BUILD_DIR}/gcc-${GCC_VER}/build/$arch ] ; then
            echo "GCC 1st step should be done!"
            exit 1
        fi
        cd ${BUILD_DIR}/gcc-${GCC_VER}/build/$arch

        if [ "$arch" == "i686" ] ; then
            local MINGW_DIR=${WORK_DIR}/mingw32
        else
            local MINGW_DIR=${WORK_DIR}/mingw64
        fi
        source cpath nogcc
        PATH=${MINGW_DIR}/bin:$PATH
        export PATH

        echo "===> make GCC 2nd step ${arch}"
        make_num=0
        while [ "$make_num" -lt 3 ]
        do
            make_num_old=$make_num
            make -j$jobs -O all > ${LOGS_DIR}/gcc2_make_${arch}.log 2>&1 \
                || make_num=$(($make_num + 1))
            if [ "$make_num_old" -eq "$make_num" ] ; then
                break
            fi
        done
        if [ "$make_num" -eq 3 ] ; then
            exit 1
        fi
        echo "done"

        echo "===> install GCC 2nd ${arch}"
        make install-strip > ${LOGS_DIR}/gcc2_install_${arch}.log 2>&1 || exit 1
        echo "done"

        echo "===> clean up GCC 2nd ${arch}"
        rm -fr ${BUILD_DIR}/gcc-${GCC_VER}/build/${arch}/*
        rm -fr ${MINGW_DIR}/{mingw,share,include}
        rm -fr ${MINGW_DIR}/lib/gcc/${arch}-w64-mingw32/${GCC_VER}/finclude
        rm -f ${MINGW_DIR}/lib/gcc/${arch}-w64-mingw32/${GCC_VER}/{libstdc++.a-gdb.py,*.la}
        rm -f ${MINGW_DIR}/libexec/gcc/${arch}-w64-mingw32/${GCC_VER}/*.la

        ln -s ${MINGW_DIR}/bin/cpp.exe ${MINGW_DIR}/lib
        ln -s ${MINGW_DIR}/bin/gcc.exe ${MINGW_DIR}/bin/cc.exe
        echo "done"
    done

    cd $WORK_DIR
    return 0
}

init_directories
download_srcs

if [ "$ICONV_REBUILD" == "yes" ] ; then
    build_iconv
else
    copy_only_iconv
fi
if [ "$ZLIB_REBUILD" == "yes" ] ; then
    build_zlib
else
    copy_only_zlib
fi
if [ "$HEADERS_REBUILD" == "yes" ] ; then
    build_headers
else
    copy_only_headers
fi
if [ "$BINUTILS_REBUILD" == "yes" ] ; then
    build_binutils
else
    copy_only_binutils
fi
if [ "$BZIP2_REBUILD" == "yes" ] ; then
    build_bzip2
else
    copy_only_bzip2
fi
if [ "$WINPTREADS_REBUILD" == "yes" ] ; then
    build_winpthreads
else
    copy_only_winpthreads
fi
build_gcc1
if [ "$CRT_REBUILD" == "yes" ] ; then
    build_crt
else
    copy_only_crt
fi
build_gcc2

clear; echo "Everything has been successfully completed!"
