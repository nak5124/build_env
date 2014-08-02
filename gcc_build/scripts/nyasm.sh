# NASM: An 80x86 assembler designed for portability and modularity
# download src
function download_nasm_src() {
    if [ ! -f ${BUILD_DIR}/nyasm/nasm/src/nasm-${NASM_VER}.tar.xz ] ; then
        printf "===> downloading NASM %s\n" $NASM_VER
        pushd ${BUILD_DIR}/nyasm/nasm/src > /dev/null
        wget -c http://www.nasm.us/pub/nasm/releasebuilds/${NASM_VER}/nasm-${NASM_VER}.tar.xz
        popd > /dev/null
        echo "done"
    fi

    if [ ! -d ${BUILD_DIR}/nyasm/nasm/src/nasm-$NASM_VER ] ; then
        printf "===> extracting NASM %s\n" $NASM_VER
        pushd ${BUILD_DIR}/nyasm/nasm/src > /dev/null
        tar Jxf ${BUILD_DIR}/nyasm/nasm/src/nasm-${NASM_VER}.tar.xz
        popd > /dev/null
        echo "done"
    fi

    return 0
}

# build
function build_nasm() {
    clear; printf "Build NASM %s\n" $NASM_VER

    download_nasm_src

    for arch in ${TARGET_ARCH[@]}
    do
        cd ${BUILD_DIR}/nyasm/nasm/build_$arch
        rm -fr ${BUILD_DIR}/nyasm/nasm/build_${arch}/*
        cp -fra ${BUILD_DIR}/nyasm/nasm/src/nasm-${NASM_VER}/* ${BUILD_DIR}/nyasm/nasm/build_$arch

        local bitval=$(get_arch_bit ${arch})

        source cpath $arch
        PATH=${DST_DIR}/mingw${bitval}/bin:/usr/local/bin:/usr/bin:/bin
        export PATH

        printf "===> configuring NASM %s\n" $arch
        MSYS2_ARG_CONV_EXCL="-//OASIS"
        export MSYS2_ARG_CONV_EXCL
        ./configure                            \
            --prefix=/mingw$bitval             \
            --build=${arch}-w64-mingw32        \
            --host=${arch}-w64-mingw32         \
            CPPFLAGS="${_CPPFLAGS}"            \
            CFLAGS="${_CFLAGS}"                \
            CXXFLAGS="${_CXXFLAGS}"            \
            LDFLAGS="${_LDFLAGS}"              \
            > ${LOGS_DIR}/nyasm/nasm/nasm_config_${arch}.log 2>&1 || exit 1
        echo "done"

        printf "===> making NASM %s\n" $arch
        make -j1 -O all > ${LOGS_DIR}/nyasm/nasm/nasm_make_${arch}.log 2>&1 || exit 1
        echo "done"

        printf "===> installing NASM %s\n" $arch
        make INSTALLROOT=${PREIN_DIR}/nyasm/nasm install > ${LOGS_DIR}/nyasm/nasm/nasm_install_${arch}.log 2>&1 || exit 1
        del_empty_dir ${PREIN_DIR}/nyasm/nasm/mingw$bitval
        remove_la_files ${PREIN_DIR}/nyasm/nasm/mingw$bitval
        strip_files ${PREIN_DIR}/nyasm/nasm/mingw$bitval
        echo "done"

        printf "===> copying NASM %s to %s/mingw%s\n" $arch $DST_DIR $bitval
        cp -fra ${PREIN_DIR}/nyasm/nasm/mingw$bitval $DST_DIR
        echo "done"
    done

    cd $ROOT_DIR
    return 0
}

# copy only
function copy_only_nasm() {
    clear; printf "NASM %s\n" $NASM_VER

    for arch in ${TARGET_ARCH[@]}
    do
        local bitval=$(get_arch_bit ${arch})

        printf "===> copying NASM %s to %s/mingw%s\n" $arch $DST_DIR $bitval
        cp -fra ${PREIN_DIR}/nyasm/nasm/mingw$bitval $DST_DIR
        echo "done"
    done

    cd $ROOT_DIR
    return 0
}

# Yasm: A rewrite of NASM to allow for multiple syntax supported (NASM, TASM, GAS, etc.)
# download src
function download_yasm_src() {
    if [ ! -f ${BUILD_DIR}/nyasm/yasm/src/yasm-${YASM_VER}.tar.gz ] ; then
        printf "===> downloading Yasm %s\n" $YASM_VER
        pushd ${BUILD_DIR}/nyasm/yasm/src > /dev/null
        wget -c http://www.tortall.net/projects/yasm/releases/yasm-${YASM_VER}.tar.gz
        popd > /dev/null
        echo "done"
    fi

    if [ ! -d ${BUILD_DIR}/nyasm/yasm/src/yasm-$YASM_VER ] ; then
        printf "===> extracting Yasm %s\n" $YASM_VER
        pushd ${BUILD_DIR}/nyasm/yasm/src > /dev/null
        tar xzf ${BUILD_DIR}/nyasm/yasm/src/yasm-${YASM_VER}.tar.gz
        popd > /dev/null
        echo "done"
    fi

    return 0
}

# patch
function patch_yasm() {
    pushd ${BUILD_DIR}/nyasm/yasm/src/yasm-$YASM_VER > /dev/null

    if [ ! -f ${BUILD_DIR}/nyasm/yasm/src/yasm-${YASM_VER}/patched_01.marker ] ; then
        patch -p1 < ${PATCHES_DIR}/yasm/0001-use-a-larger-hash-table-size.patch \
            > ${LOGS_DIR}/nyasm/yasm/yasm_patch.log 2>&1 || exit 1
        touch ${BUILD_DIR}/nyasm/yasm/src/yasm-${YASM_VER}/patched_01.marker
    fi

    popd > /dev/null

    return 0
}

# build
function build_yasm() {
    clear; printf "Build Yasm %s\n" $YASM_VER

    download_yasm_src
    patch_yasm

    for arch in ${TARGET_ARCH[@]}
    do
        cd ${BUILD_DIR}/nyasm/yasm/build_$arch
        rm -fr ${BUILD_DIR}/nyasm/yasm/build_${arch}/*

        local bitval=$(get_arch_bit ${arch})

        source cpath $arch
        PATH=${DST_DIR}/mingw${bitval}/bin:/usr/local/bin:/usr/bin:/bin
        export PATH

        printf "===> configuring Yasm %s\n" $arch
        ../src/yasm-${YASM_VER}/configure      \
            --prefix=/mingw$bitval             \
            --build=${arch}-w64-mingw32        \
            --host=${arch}-w64-mingw32         \
            CPPFLAGS="${_CPPFLAGS}"            \
            CFLAGS="${_CFLAGS}"                \
            CXXFLAGS="${_CXXFLAGS}"            \
            LDFLAGS="${_LDFLAGS}"              \
            > ${LOGS_DIR}/nyasm/yasm/yasm_config_${arch}.log 2>&1 || exit 1
        echo "done"

        printf "===> making Yasm %s\n" $arch
        make $MAKEFLAGS all > ${LOGS_DIR}/nyasm/yasm/yasm_make_${arch}.log 2>&1 || exit 1
        echo "done"

        printf "===> installing Yasm %s\n" $arch
        make DESTDIR=${PREIN_DIR}/nyasm/yasm install > ${LOGS_DIR}/nyasm/yasm/yasm_install_${arch}.log 2>&1 || exit 1
        del_empty_dir ${PREIN_DIR}/nyasm/yasm/mingw$bitval
        remove_la_files ${PREIN_DIR}/nyasm/yasm/mingw$bitval
        strip_files ${PREIN_DIR}/nyasm/yasm/mingw$bitval
        echo "done"

        printf "===> copying Yasm %s to %s/mingw%s\n" $arch $DST_DIR $bitval
        cp -fra ${PREIN_DIR}/nyasm/yasm/mingw$bitval $DST_DIR
        echo "done"
    done

    cd $ROOT_DIR
    return 0
}

# copy only
function copy_only_yasm() {
    clear; printf "Yasm %s\n" $YASM_VER

    for arch in ${TARGET_ARCH[@]}
    do
        local bitval=$(get_arch_bit ${arch})

        printf "===> copying Yasm %s to %s/mingw%s\n" $arch $DST_DIR $bitval
        cp -fra ${PREIN_DIR}/nyasm/yasm/mingw$bitval $DST_DIR
        echo "done"
    done

    cd $ROOT_DIR
    return 0
}