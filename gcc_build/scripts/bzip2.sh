# bzip2: A high-quality data compression program
# download src
function download_bzip2_src() {
    if [ ! -f ${BUILD_DIR}/bzip2/src/bzip2-${BZIP2_VER}.tar.gz ] ; then
        printf "===> downloading bzip2 %s\n" $BZIP2_VER
        pushd ${BUILD_DIR}/bzip2/src > /dev/null
        dl_files http http://www.bzip.org/${BZIP2_VER}/bzip2-${BZIP2_VER}.tar.gz
        popd > /dev/null
        echo "done"
    fi

    if [ ! -d ${BUILD_DIR}/bzip2/src/bzip2-$BZIP2_VER ] ; then
        printf "===> extracting bzip2 %s\n" $BZIP2_VER
        pushd ${BUILD_DIR}/bzip2/src > /dev/null
        decomp_arch ${BUILD_DIR}/bzip2/src/bzip2-${BZIP2_VER}.tar.gz
        popd > /dev/null
        echo "done"
    fi

    return 0
}

# patch
function patch_bzip2() {
    pushd ${BUILD_DIR}/bzip2/src/bzip2-$BZIP2_VER > /dev/null

    if [ ! -f ${BUILD_DIR}/bzip2/src/bzip2-${BZIP2_VER}/patched_01.marker ] ; then
        patch -p1 -i ${PATCHES_DIR}/bzip2/0001-bzip2-cygming-1.0.6.src.all.patch \
            > ${LOGS_DIR}/bzip2/bzip2_patch.log 2>&1 || exit 1
        touch ${BUILD_DIR}/bzip2/src/bzip2-${BZIP2_VER}/patched_01.marker
    fi
    if [ ! -f ${BUILD_DIR}/bzip2/src/bzip2-${BZIP2_VER}/patched_02.marker ] ; then
        patch -p1 -i ${PATCHES_DIR}/bzip2/0002-bzip2-buildsystem.all.patch >> ${LOGS_DIR}/bzip2/bzip2_patch.log 2>&1 || exit 1
        touch ${BUILD_DIR}/bzip2/src/bzip2-${BZIP2_VER}/patched_02.marker
    fi

    autoreconf -fi > /dev/null 2>&1

    popd > /dev/null

    return 0
}

# build
function build_bzip2() {
    clear; printf "Build bzip2 %s\n" $BZIP2_VER

    download_bzip2_src
    patch_bzip2

    for arch in ${TARGET_ARCH[@]}
    do
        cd ${BUILD_DIR}/bzip2/build_$arch
        rm -fr ${BUILD_DIR}/bzip2/build_${arch}/*

        local bitval=$(get_arch_bit ${arch})
        local _aof=$(arch_optflags ${arch})

        source cpath $arch
        PATH=${DST_DIR}/mingw${bitval}/bin:$PATH
        export PATH

        if [ "${arch}" = "i686" ] ; then
            local _slgssp="-static-libgcc -fstack-protector-strong --param=ssp-buffer-size=4"
        else
            local _slgssp="-fstack-protector-strong --param=ssp-buffer-size=4"
        fi

        printf "===> configuring bzip2 %s\n" $arch
        ../src/bzip2-${BZIP2_VER}/configure          \
            --prefix=/mingw$bitval                   \
            --build=${arch}-w64-mingw32              \
            --host=${arch}-w64-mingw32               \
            --enable-shared                          \
            CFLAGS="${_aof} ${_CFLAGS} ${_CPPFLAGS}" \
            LDFLAGS="${_LDFLAGS} ${_slgssp}"         \
            > ${LOGS_DIR}/bzip2/bzip2_config_${arch}.log 2>&1 || exit 1
        echo "done"

        printf "===> making bzip2 %s\n" $arch
        make $MAKEFLAGS all-dll-shared > ${LOGS_DIR}/bzip2/bzip2_make_${arch}.log 2>&1 || exit 1
        echo "done"

        printf "===> installing bzip2 %s\n" $arch
        rm -fr ${PREIN_DIR}/bzip2/mingw${bitval}/*
        make DESTDIR=${PREIN_DIR}/bzip2 install > ${LOGS_DIR}/bzip2/bzip2_install_${arch}.log 2>&1 || exit 1
        # Remove unneeded file.
        rm -f ${PREIN_DIR}/bzip2/mingw${bitval}/bin/b*
        rm -f ${PREIN_DIR}/bzip2/mingw${bitval}/lib/libbz2.a
        rm -fr ${PREIN_DIR}/bzip2/mingw${bitval}/share
        del_empty_dir ${PREIN_DIR}/bzip2/mingw$bitval
        remove_la_files ${PREIN_DIR}/bzip2/mingw$bitval
        strip_files ${PREIN_DIR}/bzip2/mingw$bitval
        echo "done"

        printf "===> copying bzip2 %s to %s/mingw%s\n" $arch $DST_DIR $bitval
        symcopy ${PREIN_DIR}/bzip2/mingw$bitval $DST_DIR
        echo "done"
    done

    cd $ROOT_DIR
    return 0
}

# copy only
function copy_bzip2() {
    clear; printf "bzip2 %s\n" $BZIP2_VER

    for arch in ${TARGET_ARCH[@]}
    do
        local bitval=$(get_arch_bit ${arch})

        printf "===> copying bzip2 %s to %s/mingw%s\n" $arch $DST_DIR $bitval
        symcopy ${PREIN_DIR}/bzip2/mingw$bitval $DST_DIR
        echo "done"
    done

    cd $ROOT_DIR
    return 0
}
