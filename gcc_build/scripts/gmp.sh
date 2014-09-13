# GMP: A free library for arbitrary precision arithmetic
# download src
function download_gmp_src() {
    if [ ! -f ${BUILD_DIR}/gcc_libs/gmp/src/gmp-${GMP_VER}a.tar.lz ] ; then
        printf "===> downloading GMP %s\n" $GMP_VER
        pushd ${BUILD_DIR}/gcc_libs/gmp/src > /dev/null
        dl_files ftp ftp://ftp.gmplib.org/pub/gmp/gmp-${GMP_VER}a.tar.lz
        popd > /dev/null
        echo "done"
    fi

    if [ ! -d ${BUILD_DIR}/gcc_libs/gmp/src/gmp-$GMP_VER ] ; then
        printf "===> extracting GMP %s\n" $GMP_VER
        pushd ${BUILD_DIR}/gcc_libs/gmp/src > /dev/null
        decomp_arch ${BUILD_DIR}/gcc_libs/gmp/src/gmp-${GMP_VER}a.tar.lz
        popd > /dev/null
        echo "done"
    fi

    return 0
}

# build
function build_gmp() {
    clear; printf "Build GMP %s\n" $GMP_VER

    download_gmp_src

    for arch in ${TARGET_ARCH[@]}
    do
        cd ${BUILD_DIR}/gcc_libs/gmp/build_$arch
        rm -fr ${BUILD_DIR}/gcc_libs/gmp/build_${arch}/{.*,*} > /dev/null 2>&1

        local bitval=$(get_arch_bit ${arch})
        local _aof=$(arch_optflags ${arch})

        source cpath $arch
        PATH=${DST_DIR}/mingw${bitval}/bin:$PATH
        export PATH

        printf "===> configuring GMP %s\n" $arch
        ../src/gmp-${GMP_VER}/configure     \
            --prefix=/mingw$bitval          \
            --build=${arch}-w64-mingw32     \
            --host=${arch}-w64-mingw32      \
            --enable-cxx                    \
            --enable-fat                    \
            --enable-shared                 \
            --disable-static                \
            --with-gnu-ld                   \
            CPPFLAGS="${_CPPFLAGS}"         \
            CFLAGS="${_aof} ${_CFLAGS}"     \
            CXXFLAGS="${_aof} ${_CXXFLAGS}" \
            LDFLAGS="${_LDFLAGS}"           \
            > ${LOGS_DIR}/gcc_libs/gmp/gmp_config_${arch}.log 2>&1 || exit 1
        echo "done"

        printf "===> making GMP %s\n" $arch
        # Setting -j$(($(nproc)+1)) sometimes makes error.
        make > ${LOGS_DIR}/gcc_libs/gmp/gmp_make_${arch}.log 2>&1 || exit 1
        echo "done"

        printf "===> installing GMP %s\n" $arch
        make DESTDIR=${PREIN_DIR}/gcc_libs/gmp install > ${LOGS_DIR}/gcc_libs/gmp/gmp_install_${arch}.log 2>&1 || exit 1
        del_empty_dir ${PREIN_DIR}/gcc_libs/gmp/mingw$bitval
        remove_la_files ${PREIN_DIR}/gcc_libs/gmp/mingw$bitval
        strip_files ${PREIN_DIR}/gcc_libs/gmp/mingw$bitval
        echo "done"

        printf "===> copying GMP %s to %s/mingw%s\n" $arch $DST_DIR $bitval
        cp -fra ${PREIN_DIR}/gcc_libs/gmp/mingw$bitval $DST_DIR
        echo "done"
    done

    cd $ROOT_DIR
    return 0
}

# copy only
function copy_gmp() {
    clear; printf "GMP %s\n" $GMP_VER

    for arch in ${TARGET_ARCH[@]}
    do
        local bitval=$(get_arch_bit ${arch})

        printf "===> copying GMP %s to %s/mingw%s\n" $arch $DST_DIR $bitval
        cp -fra ${PREIN_DIR}/gcc_libs/gmp/mingw$bitval $DST_DIR
        echo "done"
    done

    cd $ROOT_DIR
    return 0
}
