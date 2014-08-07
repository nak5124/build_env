# Binutils: A set of programs to assemble and manipulate binary and object files
# download src
function download_binutils_src() {
    if [ ! -f ${BUILD_DIR}/binutils/src/binutils-${BINUTILS_VER}.tar.bz2 ] ; then
        printf "===> downloading Binutils %s\n" $BINUTILS_VER
        pushd ${BUILD_DIR}/binutils/src > /dev/null
        dl_files http http://ftp.gnu.org/gnu/binutils/binutils-${BINUTILS_VER}.tar.bz2
        popd > /dev/null
        echo "done"
    fi

    if [ ! -d ${BUILD_DIR}/binutils/src/binutils-$BINUTILS_VER ] ; then
        printf "===> extracting Binutils %s\n" $BINUTILS_VER
        pushd ${BUILD_DIR}/binutils/src > /dev/null
        decomp_arch ${BUILD_DIR}/binutils/src/binutils-${BINUTILS_VER}.tar.bz2
        popd > /dev/null
        echo "done"
    fi

    return 0
}

# patch
function patch_binutils() {
    pushd ${BUILD_DIR}/binutils/src/binutils-$BINUTILS_VER > /dev/null

    if [ ! -f ${BUILD_DIR}/binutils/src/binutils-${BINUTILS_VER}/patched_01.marker ] ; then
        # hack! - libiberty configure tests for header files using "$CPP $CPPFLAGS"
        sed -i "/ac_cpp=/s/\$CPPFLAGS/\$CPPFLAGS -Os/" libiberty/configure
        touch ${BUILD_DIR}/binutils/src/binutils-${BINUTILS_VER}/patched_01.marker
    fi
    if [ ! -f ${BUILD_DIR}/binutils/src/binutils-${BINUTILS_VER}/patched_02.marker ] ; then
        patch -p1 < ${PATCHES_DIR}/binutils/0001-2.23.52-install-libiberty.patch \
            > ${LOGS_DIR}/binutils/binutils_patch.log 2>&1 || exit 1
        touch ${BUILD_DIR}/binutils/src/binutils-${BINUTILS_VER}/patched_02.marker
    fi
    if [ ! -f ${BUILD_DIR}/binutils/src/binutils-${BINUTILS_VER}/patched_03.marker ] ; then
        patch -p1 < ${PATCHES_DIR}/binutils/0002-add-bigobj-format.patch \
            >> ${LOGS_DIR}/binutils/binutils_patch.log 2>&1 || exit 1
        touch ${BUILD_DIR}/binutils/src/binutils-${BINUTILS_VER}/patched_03.marker
    fi
    if [ ! -f ${BUILD_DIR}/binutils/src/binutils-${BINUTILS_VER}/patched_04.marker ] ; then
        patch -p1 < ${PATCHES_DIR}/binutils/0003-binutils-mingw-gnu-print.patch \
            >> ${LOGS_DIR}/binutils/binutils_patch.log 2>&1 || exit 1
        touch ${BUILD_DIR}/binutils/src/binutils-${BINUTILS_VER}/patched_04.marker
    fi
    if [ ! -f ${BUILD_DIR}/binutils/src/binutils-${BINUTILS_VER}/patched_05.marker ] ; then
        patch -p1 < ${PATCHES_DIR}/binutils/0004-dont-escape-arguments-that-dont-need-it-in-pex-win32.c.patch \
            >> ${LOGS_DIR}/binutils/binutils_patch.log 2>&1 || exit 1
        touch ${BUILD_DIR}/binutils/src/binutils-${BINUTILS_VER}/patched_05.marker
    fi
    if [ ! -f ${BUILD_DIR}/binutils/src/binutils-${BINUTILS_VER}/patched_06.marker ] ; then
        # https://sourceware.org/bugzilla/show_bug.cgi?id=16858
        patch -p1 < ${PATCHES_DIR}/binutils/0005-PR16858.patch >> ${LOGS_DIR}/binutils/binutils_patch.log 2>&1 || exit 1
        touch ${BUILD_DIR}/binutils/src/binutils-${BINUTILS_VER}/patched_06.marker
    fi
    if [ ! -f ${BUILD_DIR}/binutils/src/binutils-${BINUTILS_VER}/patched_07.marker ] ; then
        patch -p1 < ${PATCHES_DIR}/binutils/0006-make-relocbase-unsigned.patch \
            >> ${LOGS_DIR}/binutils/binutils_patch.log 2>&1 || exit 1
        touch ${BUILD_DIR}/binutils/src/binutils-${BINUTILS_VER}/patched_07.marker
    fi
    if [ ! -f ${BUILD_DIR}/binutils/src/binutils-${BINUTILS_VER}/patched_08.marker ] ; then
        # https://sourceware.org/bugzilla/show_bug.cgi?id=13557
        patch -p1 < ${PATCHES_DIR}/binutils/0007-PR13557.patch >> ${LOGS_DIR}/binutils/binutils_patch.log 2>&1 || exit 1
        touch ${BUILD_DIR}/binutils/src/binutils-${BINUTILS_VER}/patched_08.marker
    fi

    popd > /dev/null

    return 0
}

# build
function build_binutils() {
    clear; printf "Build Binutils %s\n" $BINUTILS_VER

    download_binutils_src
    patch_binutils

    for arch in ${TARGET_ARCH[@]}
    do
        cd ${BUILD_DIR}/binutils/build_$arch
        rm -fr ${BUILD_DIR}/binutils/build_${arch}/*

        local bitval=$(get_arch_bit ${arch})

        if [ "${arch}" = "i686" ] ; then
            local _64_bit_bfd=""
            local _LAA=" -Wl,--large-address-aware"
        else
            local _64_bit_bfd="--enable-64-bit-bfd"
            local _LAA=""
        fi

        source cpath $arch
        if [ "${1}" = "-2nd" ] ; then
            PATH=${DST_DIR}/mingw${bitval}/bin:/usr/local/bin:/usr/bin:/bin
            export PATH
        fi

        printf "===> configuring Binutils %s\n" $arch
        ../src/binutils-${BINUTILS_VER}/configure          \
            --prefix=/mingw$bitval                         \
            --with-sysroot=/mingw$bitval                   \
            --with-build-sysroot=${DST_DIR}/mingw$bitval   \
            --build=${arch}-w64-mingw32                    \
            --target=${arch}-w64-mingw32                   \
            --disable-multilib                             \
            --enable-lto                                   \
            --disable-rpath                                \
            --disable-nls                                  \
            --disable-werror                               \
            --enable-install-libiberty                     \
            --with-libiconv-prefix=${DST_DIR}/mingw$bitval \
            ${_64_bit_bfd}                                 \
            CPPFLAGS="${_CPPFLAGS}"                        \
            CFLAGS="${_CFLAGS} ${_CPPFLAGS}"               \
            CXXFLAGS="${_CXXFLAGS} ${_CPPFLAGS}"           \
            LDFLAGS="${_LDFLAGS} ${_LAA}"                  \
            > ${LOGS_DIR}/binutils/binutils_config_${arch}.log 2>&1 || exit 1
        echo "done"

        printf "===> making Binutils %s\n" $arch
        make $MAKEFLAGS all > ${LOGS_DIR}/binutils/binutils_make_${arch}.log 2>&1 || exit 1
        echo "done"

        printf "===> installing Binutils %s\n" $arch
        make DESTDIR=${PREIN_DIR}/binutils install > ${LOGS_DIR}/binutils/binutils_install_${arch}.log 2>&1 || exit 1
        del_empty_dir ${PREIN_DIR}/binutils/mingw$bitval
        remove_la_files ${PREIN_DIR}/binutils/mingw$bitval
        strip_files ${PREIN_DIR}/binutils/mingw$bitval
        echo "done"

        printf "===> copying Binutils %s to %s/mingw%s\n" $arch $DST_DIR $bitval
        cp -fra ${PREIN_DIR}/binutils/mingw$bitval $DST_DIR
        echo "done"
    done

    cd $ROOT_DIR
    return 0
}

# copy only
function copy_only_binutils() {
    clear; printf "Binutils %s\n" $BINUTILS_VER

    for arch in ${TARGET_ARCH[@]}
    do
        local bitval=$(get_arch_bit ${arch})

        printf "===> copying Binutils %s to %s/mingw%s\n" $arch $DST_DIR $bitval
        cp -fra ${PREIN_DIR}/binutils/mingw$bitval $DST_DIR
        echo "done"
    done

    cd $ROOT_DIR
    return 0
}
