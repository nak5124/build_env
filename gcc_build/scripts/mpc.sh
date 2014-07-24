# MPC: Multiple precision complex arithmetic library
# download src
function download_mpc_src() {
    if [ ! -f ${BUILD_DIR}/gcc_libs/mpc/src/mpc-${MPC_VER}.tar.gz ] ; then
        printf "===> downloading MPC %s\n" $MPC_VER
        pushd ${BUILD_DIR}/gcc_libs/mpc/src > /dev/null
        wget -c ftp://ftp.gnu.org/gnu/mpc/mpc-${MPC_VER}.tar.gz
        popd > /dev/null
        echo "done"
    fi

    if [ ! -d ${BUILD_DIR}/gcc_libs/mpc/src/mpc-$MPC_VER ] ; then
        printf "===> extracting MPC %s\n" $MPC_VER
        pushd ${BUILD_DIR}/gcc_libs/mpc/src > /dev/null
        tar xzf ${BUILD_DIR}/gcc_libs/mpc/src/mpc-${MPC_VER}.tar.gz
        popd > /dev/null
        echo "done"
    fi

    return 0
}

# build
function build_mpc() {
    clear; printf "Build MPC %s\n" $MPC_VER

    download_mpc_src

    for arch in ${TARGET_ARCH[@]}
    do
        cd ${BUILD_DIR}/gcc_libs/mpc/build_$arch
        rm -fr ${BUILD_DIR}/gcc_libs/mpc/build_${arch}/*

        local bitval=$(get_arch_bit ${arch})

        source cpath $arch
        printf "===> configure MPC %s\n" $arch
        ../src/mpc-${MPC_VER}/configure          \
            --prefix=/mingw$bitval               \
            --build=${arch}-w64-mingw32          \
            --host=${arch}-w64-mingw32           \
            --disable-shared                     \
            --enable-static                      \
            --with-gmp=${LIBS_DIR}/mingw$bitval  \
            --with-mpfr=${LIBS_DIR}/mingw$bitval \
            CPPFLAGS="${_CPPFLAGS}"              \
            CFLAGS="${_CFLAGS}"                  \
            CXXFLAGS="${_CXXFLAGS}"              \
            LDFLAGS="${_LDFLAGS}"                \
            > ${LOGS_DIR}/gcc_libs/mpc/mpc_config_${arch}.log 2>&1 || exit 1
        echo "done"

        printf "===> building MPC %s\n" $arch
        make $MAKEFLAGS all > ${LOGS_DIR}/gcc_libs/mpc/mpc_make_${arch}.log 2>&1 || exit 1
        echo "done"

        printf "===> installing MPC %s\n" $arch
        make DESTDIR=$LIBS_DIR install > ${LOGS_DIR}/gcc_libs/mpc/mpc_install_${arch}.log 2>&1 || exit 1
        remove_la_files ${LIBS_DIR}/mingw$bitval
        echo "done"
    done

    cd $ROOT_DIR
    return 0
}
