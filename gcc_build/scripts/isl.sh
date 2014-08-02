# ISL: Library for manipulating sets and relations of integer points bounded by linear constraints
# download src
function download_isl_src() {
    if [ ! -f ${BUILD_DIR}/gcc_libs/isl/src/isl-${ISL_VER}.tar.xz ] ; then
        printf "===> downloading ISL %s\n" $ISL_VER
        pushd ${BUILD_DIR}/gcc_libs/isl/src > /dev/null
        wget -c http://isl.gforge.inria.fr/isl-${ISL_VER}.tar.xz
        popd > /dev/null
        echo "done"
    fi

    if [ ! -d ${BUILD_DIR}/gcc_libs/isl/src/isl-$ISL_VER ] ; then
        printf "===> extracting ISL %s\n" $ISL_VER
        pushd ${BUILD_DIR}/gcc_libs/isl/src > /dev/null
        tar Jxf ${BUILD_DIR}/gcc_libs/isl/src/isl-${ISL_VER}.tar.xz
        popd > /dev/null
        echo "done"
    fi

    return 0
}

# patch
function patch_isl() {
    pushd ${BUILD_DIR}/gcc_libs/isl/src/isl-$ISL_VER > /dev/null

    if [ ! -f ${BUILD_DIR}/gcc_libs/isl/src/isl-${ISL_VER}/patched_01.marker ] ; then
        patch -p1 < ${PATCHES_DIR}/isl/0001-isl-no-undefined.patch > ${LOGS_DIR}/gcc_libs/isl/isl_patch.log 2>&1 || exit 1
        touch ${BUILD_DIR}/gcc_libs/isl/src/isl-${ISL_VER}/patched_01.marker
    fi

    autoreconf -fi > /dev/null 2>&1

    popd > /dev/null

    return 0
}

# build
function build_isl() {
    clear; printf "Build ISL %s\n" $ISL_VER

    download_isl_src
    patch_isl

    for arch in ${TARGET_ARCH[@]}
    do
        cd ${BUILD_DIR}/gcc_libs/isl/build_$arch
        rm -fr ${BUILD_DIR}/gcc_libs/isl/build_${arch}/*

        local bitval=$(get_arch_bit ${arch})

        source cpath $arch
        printf "===> configuring ISL %s\n" $arch
        ../src/isl-${ISL_VER}/configure                \
            --prefix=/mingw$bitval                     \
            --build=${arch}-w64-mingw32                \
            --host=${arch}-w64-mingw32                 \
            --disable-shared                           \
            --enable-static                            \
            --with-gmp=system                          \
            --with-gmp-prefix=${LIBS_DIR}/mingw$bitval \
            --with-piplib=no                           \
            --with-clang=no                            \
            CPPFLAGS="${_CPPFLAGS}"                    \
            CFLAGS="${_CFLAGS}"                        \
            CXXFLAGS="${_CXXFLAGS}"                    \
            LDFLAGS="${_LDFLAGS}"                      \
            > ${LOGS_DIR}/gcc_libs/isl/isl_config_${arch}.log 2>&1 || exit 1
        echo "done"

        printf "===> making ISL %s\n" $arch
        make $MAKEFLAGS all > ${LOGS_DIR}/gcc_libs/isl/isl_make_${arch}.log 2>&1 || exit 1
        echo "done"

        printf "===> installing ISL %s\n" $arch
        make DESTDIR=$LIBS_DIR install > ${LOGS_DIR}/gcc_libs/isl/isl_install_${arch}.log 2>&1 || exit 1
        remove_la_files ${LIBS_DIR}/mingw$bitval
        echo "done"
    done

    cd $ROOT_DIR
    return 0
}
