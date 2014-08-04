# CLooG: Library that generates loops for scanning polyhedra
# download src
function download_cloog_src() {
    if [ ! -f ${BUILD_DIR}/gcc_libs/cloog/src/cloog-${CLOOG_VER}.tar.gz ] ; then
        printf "===> downloading CLooG %s\n" $CLOOG_VER
        pushd ${BUILD_DIR}/gcc_libs/cloog/src > /dev/null
        dl_files http http://www.bastoul.net/cloog/pages/download/cloog-${CLOOG_VER}.tar.gz
        popd > /dev/null
        echo "done"
    fi

    if [ ! -d ${BUILD_DIR}/gcc_libs/cloog/src/cloog-$CLOOG_VER ] ; then
        printf "===> extracting CLooG %s\n" $CLOOG_VER
        pushd ${BUILD_DIR}/gcc_libs/cloog/src > /dev/null
        decomp_arch ${BUILD_DIR}/gcc_libs/cloog/src/cloog-${CLOOG_VER}.tar.gz
        popd > /dev/null
        echo "done"
    fi

    return 0
}

# patch
function patch_cloog() {
    pushd ${BUILD_DIR}/gcc_libs/cloog/src/cloog-$CLOOG_VER > /dev/null

    if [ ! -f ${BUILD_DIR}/gcc_libs/cloog/src/cloog-${CLOOG_VER}/patched_01.marker ] ; then
        # combination of upstream commits b561f860, 2d8b7c6b and 22643c94
        patch -p1 < ${PATCHES_DIR}/cloog/0001-cloog-0.18.1-isl-compat.patch \
            > ${LOGS_DIR}/gcc_libs/cloog/cloog_patch.log 2>&1 || exit 1
        touch ${BUILD_DIR}/gcc_libs/cloog/src/cloog-${CLOOG_VER}/patched_01.marker
    fi
    if [ ! -f ${BUILD_DIR}/gcc_libs/cloog/src/cloog-${CLOOG_VER}/patched_02.marker ] ; then
        patch -p1 < ${PATCHES_DIR}/cloog/0002-cloog-0.18.1-no-undefined.patch \
            >> ${LOGS_DIR}/gcc_libs/cloog/cloog_patch.log 2>&1 || exit 1
        touch ${BUILD_DIR}/gcc_libs/cloog/src/cloog-${CLOOG_VER}/patched_02.marker
    fi

    autoreconf -fi > /dev/null 2>&1

    popd > /dev/null

    return 0
}

# build
function build_cloog() {
    clear; printf "Build CLooG %s\n" $CLOOG_VER

    download_cloog_src
    patch_cloog

    for arch in ${TARGET_ARCH[@]}
    do
        cd ${BUILD_DIR}/gcc_libs/cloog/build_$arch
        rm -fr ${BUILD_DIR}/gcc_libs/cloog/build_${arch}/*

        local bitval=$(get_arch_bit ${arch})

        source cpath $arch
        printf "===> configuring CLooG %s\n" $arch
        ../src/cloog-${CLOOG_VER}/configure            \
            --prefix=/mingw$bitval                     \
            --build=${arch}-w64-mingw32                \
            --host=${arch}-w64-mingw32                 \
            --disable-shared                           \
            --enable-static                            \
            --with-bits=gmp                            \
            --with-gmp-prefix=${LIBS_DIR}/mingw$bitval \
            --with-isl=system                          \
            --with-isl-prefix=${LIBS_DIR}/mingw$bitval \
            --program-suffix=-isl                      \
            --with-osl=no                              \
            CPPFLAGS="${_CPPFLAGS}"                    \
            CFLAGS="${_CFLAGS}"                        \
            CXXFLAGS="${_CXXFLAGS}"                    \
            LDFLAGS="${_LDFLAGS}"                      \
            > ${LOGS_DIR}/gcc_libs/cloog/cloog_config_${arch}.log 2>&1 || exit 1
        echo "done"

        printf "===> making CLooG %s\n" $arch
        make $MAKEFLAGS all > ${LOGS_DIR}/gcc_libs/cloog/cloog_make_${arch}.log 2>&1 || exit 1
        echo "done"

        printf "===> installing CLooG %s\n" $arch
        make DESTDIR=$LIBS_DIR install > ${LOGS_DIR}/gcc_libs/cloog/cloog_install_${arch}.log 2>&1 || exit 1
        remove_la_files ${LIBS_DIR}/mingw$bitval
        echo "done"
    done

    cd $ROOT_DIR
    return 0
}
