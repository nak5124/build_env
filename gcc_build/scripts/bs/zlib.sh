# zlib: Compression library implementing the deflate compression method found in gzip and PKZIP
# download src
function download_zlib_src() {
    if [ ! -f ${BUILD_DIR}/zlib/src/zlib-${ZLIB_VER}.tar.xz ] ; then
        printf "===> downloading zlib %s\n" $ZLIB_VER
        pushd ${BUILD_DIR}/zlib/src > /dev/null
        dl_files http http://zlib.net/zlib-${ZLIB_VER}.tar.xz
        popd > /dev/null
        echo "done"
    fi

    if [ ! -d ${BUILD_DIR}/zlib/src/zlib-$ZLIB_VER ] ; then
        printf "===> extracting zlib %s\n" $ZLIB_VER
        pushd ${BUILD_DIR}/zlib/src > /dev/null
        decomp_arch ${BUILD_DIR}/zlib/src/zlib-${ZLIB_VER}.tar.xz
        popd > /dev/null
        echo "done"
    fi

    return 0
}

# patch
function patch_zlib() {
    pushd ${BUILD_DIR}/zlib/src/zlib-$ZLIB_VER > /dev/null

    if [ ! -f ${BUILD_DIR}/zlib/src/zlib-${ZLIB_VER}/patched_01.marker ] ; then
        patch -p2 < ${PATCHES_DIR}/zlib/0001-zlib-1.2.7-1-buildsys.mingw.patch > ${LOGS_DIR}/zlib/zlib_patch.log 2>&1 || exit 1
        touch ${BUILD_DIR}/zlib/src/zlib-${ZLIB_VER}/patched_01.marker
    fi
    if [ ! -f ${BUILD_DIR}/zlib/src/zlib-${ZLIB_VER}/patched_02.marker ] ; then
        patch -p2 < ${PATCHES_DIR}/zlib/0002-no-undefined.mingw.patch >> ${LOGS_DIR}/zlib/zlib_patch.log 2>&1 || exit 1
        touch ${BUILD_DIR}/zlib/src/zlib-${ZLIB_VER}/patched_02.marker
    fi
    if [ ! -f ${BUILD_DIR}/zlib/src/zlib-${ZLIB_VER}/patched_03.marker ] ; then
        patch -p2 < ${PATCHES_DIR}/zlib/0003-dont-put-sodir-into-L.mingw.patch \
            >> ${LOGS_DIR}/zlib/zlib_patch.log 2>&1 || exit 1
        touch ${BUILD_DIR}/zlib/src/zlib-${ZLIB_VER}/patched_03.marker
    fi
    if [ ! -f ${BUILD_DIR}/zlib/src/zlib-${ZLIB_VER}/patched_04.marker ] ; then
        patch -p2 < ${PATCHES_DIR}/zlib/0004-wrong-w8-check.mingw.patch >> ${LOGS_DIR}/zlib/zlib_patch.log 2>&1 || exit 1
        touch ${BUILD_DIR}/zlib/src/zlib-${ZLIB_VER}/patched_04.marker
    fi
    if [ ! -f ${BUILD_DIR}/zlib/src/zlib-${ZLIB_VER}/patched_05.marker ] ; then
        patch -p2 < ${PATCHES_DIR}/zlib/0005-fix-a-typo.mingw.patch >> ${LOGS_DIR}/zlib/zlib_patch.log 2>&1 || exit 1
        touch ${BUILD_DIR}/zlib/src/zlib-${ZLIB_VER}/patched_05.marker
    fi

    popd > /dev/null

    return 0
}

# build
function build_zlib() {
    clear; printf "Build zlib %s\n" $ZLIB_VER

    download_zlib_src
    patch_zlib

    for arch in ${TARGET_ARCH[@]}
    do
        cd ${BUILD_DIR}/zlib/build_$arch
        rm -fr ${BUILD_DIR}/zlib/build_${arch}/*
        # zlib cannot be built out of tree.
        cp -fra ${BUILD_DIR}/zlib/src/zlib-${ZLIB_VER}/* ${BUILD_DIR}/zlib/build_$arch

        # Use assembly code.
        if [ "${arch}" = "i686" ] ; then
            cp -fa ${BUILD_DIR}/zlib/build_${arch}/contrib/asm686/match.S ${BUILD_DIR}/zlib/build_${arch}/match.S
        else
            cp -fa ${BUILD_DIR}/zlib/build_${arch}/contrib/amd64/amd64-match.S ${BUILD_DIR}/zlib/build_${arch}/match.S
        fi

        local bitval=$(get_arch_bit ${arch})

        source cpath $arch
        PATH=${DST_DIR}/mingw${bitval}/bin:$PATH
        export PATH

        printf "===> configuring libz %s\n" $arch
        CHOST=${arch}-w64-mingw32 CFLAGS="${_CFLAGS}" LDFLAGS="${_LDFLAGS}" \
            ./configure --prefix=/mingw$bitval --shared                     \
            > ${LOGS_DIR}/zlib/libz_config_${arch}.log 2>&1 || exit 1
        echo "done"

        printf "===> making libz %s\n" $arch
        make $MAKEFLAGS all LOC=-DASMV OBJA=match.o > ${LOGS_DIR}/zlib/libz_make_${arch}.log 2>&1 || exit 1
        echo "done"

        printf "===> installing libz %s\n" $arch
        make DESTDIR=${PREIN_DIR}/zlib install > ${LOGS_DIR}/zlib/libz_install_${arch}.log 2>&1 || exit 1
        echo "done"

        # minizip
        cd ${BUILD_DIR}/zlib/build_${arch}/contrib/minizip
        autoreconf -fi > /dev/null 2>&1
        printf "===> configuring minizip %s\n" $arch
        ./configure \
            --prefix=/mingw$bitval \
            --build=${arch}-w64-mingw32                                              \
            --host=${arch}-w64-mingw32                                               \
            --enable-shared                                                          \
            --enable-static                                                          \
            --enable-demos                                                           \
            --with-gnu-ld                                                            \
            CPPFLAGS="${_CPPFLAGS} -DHAVE_BZIP2 -I${DST_DIR}/mingw${bitval}/include" \
            CFLAGS="${_CFLAGS}"                                                      \
            LDFLAGS="${_LDFLAGS} -L${DST_DIR}/mingw${bitval}/lib"                    \
            LIBS="-lbz2"                                                             \
            > ${LOGS_DIR}/zlib/minizip_config_${arch}.log 2>&1 || exit 1
        echo "done"

        printf "===> making minizip %s\n" $arch
        make $MAKEFLAGS > ${LOGS_DIR}/zlib/minizip_make_${arch}.log 2>&1 || exit 1
        echo "done"

        printf "===> installing minizip %s\n" $arch
        make DESTDIR=${PREIN_DIR}/zlib install > ${LOGS_DIR}/zlib/minizip_install_${arch}.log 2>&1 || exit 1
        del_empty_dir ${PREIN_DIR}/zlib/mingw$bitval
        remove_la_files ${PREIN_DIR}/zlib/mingw$bitval
        strip_files ${PREIN_DIR}/zlib/mingw$bitval
        if [ "${arch}" = "i686" ] ; then
            add_laa ${PREIN_DIR}/zlib/mingw$bitval
        fi
        echo "done"

        printf "===> copying zlib %s to %s/mingw%s\n" $arch $DST_DIR $bitval
        cp -fra ${PREIN_DIR}/zlib/mingw$bitval $DST_DIR
        echo "done"
    done

    cd $ROOT_DIR
    return 0
}

# copy only
function copy_zlib() {
    clear; printf "zlib %s\n" $ZLIB_VER

    for arch in ${TARGET_ARCH[@]}
    do
        local bitval=$(get_arch_bit ${arch})

        printf "===> copying zlib %s to %s/mingw%s\n" $arch $DST_DIR $bitval
        cp -fra ${PREIN_DIR}/zlib/mingw$bitval $DST_DIR
        echo "done"
    done

    cd $ROOT_DIR
    return 0
}
