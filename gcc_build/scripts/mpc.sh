# MPC: Multiple precision complex arithmetic library
# download src
function download_mpc_src() {
    if [ ! -f ${BUILD_DIR}/gcc_libs/mpc/src/mpc-${MPC_VER}.tar.gz ] ; then
        printf "===> downloading MPC %s\n" $MPC_VER
        pushd ${BUILD_DIR}/gcc_libs/mpc/src > /dev/null
        dl_files ftp ftp://ftp.gnu.org/gnu/mpc/mpc-${MPC_VER}.tar.gz
        popd > /dev/null
        echo "done"
    fi

    if [ ! -d ${BUILD_DIR}/gcc_libs/mpc/src/mpc-$MPC_VER ] ; then
        printf "===> extracting MPC %s\n" $MPC_VER
        pushd ${BUILD_DIR}/gcc_libs/mpc/src > /dev/null
        decomp_arch ${BUILD_DIR}/gcc_libs/mpc/src/mpc-${MPC_VER}.tar.gz
        popd > /dev/null
        echo "done"
    fi

    return 0
}

# build
function build_mpc() {
    clear; printf "Build MPC %s\n" $MPC_VER

    download_mpc_src

    cd ${BUILD_DIR}/gcc_libs/mpc/src/mpc-$MPC_VER
    autoreconf -fi > /dev/null 2>&1

    for arch in ${TARGET_ARCH[@]}
    do
        cd ${BUILD_DIR}/gcc_libs/mpc/build_$arch
        rm -fr ${BUILD_DIR}/gcc_libs/mpc/build_${arch}/*

        local bitval=$(get_arch_bit ${arch})
        local _aof=$(arch_optflags ${arch})

        source cpath $arch
        PATH=${DST_DIR}/mingw${bitval}/bin:$PATH
        export PATH

        printf "===> configuring MPC %s\n" $arch
        ../src/mpc-${MPC_VER}/configure         \
            --prefix=/mingw$bitval              \
            --build=${arch}-w64-mingw32         \
            --host=${arch}-w64-mingw32          \
            --enable-shared                     \
            --disable-static                    \
            --with-mpfr=${DST_DIR}/mingw$bitval \
            --with-gmp=${DST_DIR}/mingw$bitval  \
            --with-gnu-ld                       \
            CPPFLAGS="${_CPPFLAGS}"             \
            CFLAGS="${_aof} ${_CFLAGS}"         \
            LDFLAGS="${_LDFLAGS}"               \
            > ${LOGS_DIR}/gcc_libs/mpc/mpc_config_${arch}.log 2>&1 || exit 1
        echo "done"

        printf "===> making MPC %s\n" $arch
        make $MAKEFLAGS > ${LOGS_DIR}/gcc_libs/mpc/mpc_make_${arch}.log 2>&1 || exit 1
        echo "done"

        printf "===> installing MPC %s\n" $arch
        make DESTDIR=${PREIN_DIR}/gcc_libs/mpc install > ${LOGS_DIR}/gcc_libs/mpc/mpc_install_${arch}.log 2>&1 || exit 1
        # Remove unneeded file.
        rm -fr ${PREIN_DIR}/gcc_libs/mpc/mingw${bitval}/share
        del_empty_dir ${PREIN_DIR}/gcc_libs/mpc/mingw$bitval
        remove_la_files ${PREIN_DIR}/gcc_libs/mpc/mingw$bitval
        strip_files ${PREIN_DIR}/gcc_libs/mpc/mingw$bitval
        echo "done"

        printf "===> copying MPC %s to %s/mingw%s\n" $arch $DST_DIR $bitval
        cp -fra ${PREIN_DIR}/gcc_libs/mpc/mingw$bitval $DST_DIR
        echo "done"
    done

    cd $ROOT_DIR
    return 0
}

# copy only
function copy_mpc() {
    clear; printf "MPC %s\n" $MPC_VER

    for arch in ${TARGET_ARCH[@]}
    do
        local bitval=$(get_arch_bit ${arch})

        printf "===> copying MPC %s to %s/mingw%s\n" $arch $DST_DIR $bitval
        cp -fra ${PREIN_DIR}/gcc_libs/mpc/mingw$bitval $DST_DIR
        echo "done"
    done

    cd $ROOT_DIR
    return 0
}
