# GMP: A free library for arbitrary precision arithmetic
# download src
function download_gmp_src() {
    if [ ! -f ${BUILD_DIR}/gcc_libs/gmp/src/gmp-${GMP_VER}a.tar.lz ] ; then
        printf "===> downloading GMP %s\n" $GMP_VER
        pushd ${BUILD_DIR}/gcc_libs/gmp/src > /dev/null
        wget -c ftp://ftp.gmplib.org/pub/gmp/gmp-${GMP_VER}a.tar.lz
        popd > /dev/null
        echo "done"
    fi

    if [ ! -d ${BUILD_DIR}/gcc_libs/gmp/src/gmp-$GMP_VER ] ; then
        printf "===> extracting GMP %s\n" $GMP_VER
        pushd ${BUILD_DIR}/gcc_libs/gmp/src > /dev/null
        tar xf ${BUILD_DIR}/gcc_libs/gmp/src/gmp-${GMP_VER}a.tar.lz
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
        rm -fr ${BUILD_DIR}/gcc_libs/gmp/build_${arch}/*

        local bitval=$(get_arch_bit ${arch})

        if [ "${arch}" = "i686" ] ; then
            local GMP_MPN="x86/coreisbr x86/pentium4/sse2 x86/pentium4/mmx x86/pentium4 \
                            x86/pentium/mmx x86/pentium x86 generic"
        else
            local GMP_MPN="x86_64/coreisbr x86_64/fastavx x86_64/coreinhm x86_64/fastsse \
                            x86_64/core2 x86_64/pentium4 x86_64 generic"
        fi

        source cpath $arch
        printf "===> configuring GMP %s\n" $arch
        ../src/gmp-${GMP_VER}/configure \
            --prefix=/mingw$bitval      \
            --build=${arch}-w64-mingw32 \
            --host=${arch}-w64-mingw32  \
            --disable-shared            \
            --enable-static             \
            --enable-cxx                \
            --enable-assembly           \
            MPN_PATH="${GMP_MPN}"       \
            CPPFLAGS="${_CPPFLAGS}"     \
            CFLAGS="${_CFLAGS}"         \
            CXXFLAGS="${_CXXFLAGS}"     \
            LDFLAGS="${_LDFLAGS}"       \
            > ${LOGS_DIR}/gcc_libs/gmp/gmp_config_${arch}.log 2>&1 || exit 1
        echo "done"

        printf "===> making GMP %s\n" $arch
        make $MAKEFLAGS all > ${LOGS_DIR}/gcc_libs/gmp/gmp_make_${arch}.log 2>&1 || exit 1
        echo "done"

        printf "===> installing GMP %s\n" $arch
        make DESTDIR=$LIBS_DIR install > ${LOGS_DIR}/gcc_libs/gmp/gmp_install_${arch}.log 2>&1 || exit 1
        remove_la_files ${LIBS_DIR}/mingw$bitval
        echo "done"
    done

    cd $ROOT_DIR
    return 0
}
