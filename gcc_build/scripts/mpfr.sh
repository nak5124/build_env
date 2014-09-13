# MPFR: Multiple-precision floating-point library
# download src
function download_mpfr_src() {
    if [ ! -f ${BUILD_DIR}/gcc_libs/mpfr/src/mpfr-${MPFR_VER}.tar.bz2 ] ; then
        printf "===> downloading MPFR %s\n" $MPFR_VER
        pushd ${BUILD_DIR}/gcc_libs/mpfr/src > /dev/null
        dl_files http http://www.mpfr.org/mpfr-current/mpfr-${MPFR_VER}.tar.bz2
        popd > /dev/null
        echo "done"
    fi

    printf "===> extracting MPFR %s\n" $MPFR_VER
    pushd ${BUILD_DIR}/gcc_libs/mpfr/src > /dev/null
    if [ -d ${BUILD_DIR}/gcc_libs/mpfr/src/mpfr-$MPFR_VER ] ; then
        rm -fr ${BUILD_DIR}/gcc_libs/mpfr/src/mpfr-$MPFR_VER
    fi
    decomp_arch ${BUILD_DIR}/gcc_libs/mpfr/src/mpfr-${MPFR_VER}.tar.bz2
    popd > /dev/null
    echo "done"

    return 0
}

# download patch
function download_mpfr_patch() {
    if [ ! -d ${PATCHES_DIR}/mpfr ] ; then
        mkdir -p ${PATCHES_DIR}/mpfr
    fi
    pushd ${PATCHES_DIR}/mpfr > /dev/null
    echo "===> downloading MPFR patch"
    if [ -f ${PATCHES_DIR}/mpfr/allpatches ] ; then
        rm -f ${PATCHES_DIR}/mpfr/allpatches
    fi
    dl_files http http://www.mpfr.org/mpfr-current/allpatches
    popd > /dev/null
    echo "done"

    return 0
}

# build
function build_mpfr() {
    clear; printf "Build MPFR %s\n" $MPFR_VER

    download_mpfr_src
    download_mpfr_patch

    cd ${BUILD_DIR}/gcc_libs/mpfr/src/mpfr-$MPFR_VER
    patch -p1 < ${PATCHES_DIR}/mpfr/allpatches > ${LOGS_DIR}/gcc_libs/mpfr/mpfr_patches.log 2>&1 || exit 1

    for arch in ${TARGET_ARCH[@]}
    do
        cd ${BUILD_DIR}/gcc_libs/mpfr/build_$arch
        rm -fr ${BUILD_DIR}/gcc_libs/mpfr/build_${arch}/*

        local bitval=$(get_arch_bit ${arch})
        local _aof=$(arch_optflags ${arch})

        source cpath $arch
        PATH=${DST_DIR}/mingw${bitval}/bin:$PATH
        export PATH

        printf "===> configuring MPFR %s\n" $arch
        ../src/mpfr-${MPFR_VER}/configure      \
            --prefix=/mingw$bitval             \
            --build=${arch}-w64-mingw32        \
            --host=${arch}-w64-mingw32         \
            --enable-shared                    \
            --disable-static                   \
            --with-gmp=${DST_DIR}/mingw$bitval \
            --with-gnu-ld                      \
            CPPFLAGS="${_CPPFLAGS}"            \
            CFLAGS="${_aof} ${_CFLAGS}"        \
            LDFLAGS="${_LDFLAGS}"              \
            > ${LOGS_DIR}/gcc_libs/mpfr/mpfr_config_${arch}.log 2>&1 || exit 1
        echo "done"

        printf "===> making MPFR %s\n" $arch
        make $MAKEFLAGS > ${LOGS_DIR}/gcc_libs/mpfr/mpfr_make_${arch}.log 2>&1 || exit 1
        echo "done"

        printf "===> installing MPFR %s\n" $arch
        make DESTDIR=${PREIN_DIR}/gcc_libs/mpfr install > ${LOGS_DIR}/gcc_libs/mpfr/mpfr_install_${arch}.log 2>&1 || exit 1
        del_empty_dir ${PREIN_DIR}/gcc_libs/mpfr/mingw$bitval
        remove_la_files ${PREIN_DIR}/gcc_libs/mpfr/mingw$bitval
        strip_files ${PREIN_DIR}/gcc_libs/mpfr/mingw$bitval
        echo "done"

        printf "===> copying MPFR %s to %s/mingw%s\n" $arch $DST_DIR $bitval
        cp -fra ${PREIN_DIR}/gcc_libs/mpfr/mingw$bitval $DST_DIR
        echo "done"
    done

    cd $ROOT_DIR
    return 0
}

# copy only
function copy_mpfr() {
    clear; printf "MPFR %s\n" $MPFR_VER

    for arch in ${TARGET_ARCH[@]}
    do
        local bitval=$(get_arch_bit ${arch})

        printf "===> copying MPFR %s to %s/mingw%s\n" $arch $DST_DIR $bitval
        cp -fra ${PREIN_DIR}/gcc_libs/mpfr/mingw$bitval $DST_DIR
        echo "done"
    done

    cd $ROOT_DIR
    return 0
}
