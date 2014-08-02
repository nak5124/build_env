# zlib: Compression library implementing the deflate compression method found in gzip and PKZIP
# download src
function download_zlib_src() {
    if [ ! -f ${BUILD_DIR}/zlib/src/zlib-${ZLIB_VER}.tar.xz ] ; then
        printf "===> downloading zlib %s\n" $ZLIB_VER
        pushd ${BUILD_DIR}/zlib/src > /dev/null
        wget -c http://zlib.net/current/zlib-${ZLIB_VER}.tar.xz
        popd > /dev/null
        echo "done"
    fi

    if [ ! -d ${BUILD_DIR}/zlib/src/zlib-$ZLIB_VER ] ; then
        printf "===> extracting zlib %s\n" $ZLIB_VER
        pushd ${BUILD_DIR}/zlib/src > /dev/null
        tar Jxf ${BUILD_DIR}/zlib/src/zlib-${ZLIB_VER}.tar.xz
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
    if [ ! -f ${BUILD_DIR}/zlib/src/zlib-${ZLIB_VER}/patched_03.marker ] ; then
        patch -p2 < ${PATCHES_DIR}/zlib/0002-dont-put-sodir-into-L.mingw.patch \
            >> ${LOGS_DIR}/zlib/zlib_patch.log 2>&1 || exit 1
        touch ${BUILD_DIR}/zlib/src/zlib-${ZLIB_VER}/patched_03.marker
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
        cp -fra ${BUILD_DIR}/zlib/src/zlib-${ZLIB_VER}/* ${BUILD_DIR}/zlib/build_$arch

        if [ "${arch}" = "i686" ] ; then
            cp -fa ${BUILD_DIR}/zlib/build_${arch}/contrib/asm686/match.S ${BUILD_DIR}/zlib/build_${arch}/match.S
        else
            cp -fa ${BUILD_DIR}/zlib/build_${arch}/contrib/amd64/amd64-match.S ${BUILD_DIR}/zlib/build_${arch}/match.S
        fi

        local bitval=$(get_arch_bit ${arch})

        source cpath $arch
        printf "===> configuring zlib %s\n" $arch
        CHOST=${arch}-w64-mingw32 CFLAGS="${_CFLAGS}" LDFLAGS="${_LDFLAGS}" \
            ./configure --prefix=/mingw$bitval --static                     \
            > ${LOGS_DIR}/zlib/zlib_config_${arch}.log 2>&1 || exit 1
        echo "done"

        printf "===> making zlib %s\n" $arch
        make -j1 all LOC=-DASMV OBJA=match.o > ${LOGS_DIR}/zlib/zlib_make_${arch}.log 2>&1 || exit 1
        echo "done"

        printf "===> installing zlib %s\n" $arch
        make DESTDIR=${PREIN_DIR}/zlib install > ${LOGS_DIR}/zlib/zlib_install_${arch}.log 2>&1 || exit 1
        del_empty_dir ${PREIN_DIR}/zlib/mingw$bitval
        remove_la_files ${PREIN_DIR}/zlib/mingw$bitval
        strip_files ${PREIN_DIR}/zlib/mingw$bitval
        echo "done"

        printf "===> copying zlib %s to %s/mingw%s\n" $arch $DST_DIR $bitval
        cp -fra ${PREIN_DIR}/zlib/mingw$bitval $DST_DIR
        echo "done"
    done

    cd $ROOT_DIR
    return 0
}

# copy only
function copy_only_zlib() {
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
