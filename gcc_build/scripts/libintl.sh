# libintl: GNU Internationalization runtime library
# download src
function download_intl_src() {
    if [ ! -f ${BUILD_DIR}/libintl/src/gettext-${INTL_VER}.tar.xz ] ; then
        printf "===> downloading libintl %s\n" $INTL_VER
        pushd ${BUILD_DIR}/libintl/src > /dev/null
        dl_files http http://ftp.gnu.org/pub/gnu/gettext/gettext-${INTL_VER}.tar.xz
        popd > /dev/null
        echo "done"
    fi

    if [ ! -d ${BUILD_DIR}/libintl/src/gettext-$INTL_VER ] ; then
        printf "===> extracting libintl %s\n" $INTL_VER
        pushd ${BUILD_DIR}/libintl/src > /dev/null
        decomp_arch ${BUILD_DIR}/libintl/src/gettext-${INTL_VER}.tar.xz
        popd > /dev/null
        echo "done"
    fi

    return 0
}

# patch
function patch_intl() {
    pushd ${BUILD_DIR}/libintl/src/gettext-$INTL_VER > /dev/null

    if [ ! -f ${BUILD_DIR}/libintl/src/gettext-${INTL_VER}/patched_01.marker ] ; then
        patch -p1 < ${PATCHES_DIR}/libintl/0001-relocatex-libintl-0.18.3.1.patch \
            > ${LOGS_DIR}/libintl/libintl_patch.log 2>&1 || exit 1
        touch ${BUILD_DIR}/libintl/src/gettext-${INTL_VER}/patched_01.marker
    fi
    if [ ! -f ${BUILD_DIR}/libintl/src/gettext-${INTL_VER}/patched_02.marker ] ; then
        patch -p0 < ${PATCHES_DIR}/libintl/0002-always-use-libintl-vsnprintf.mingw.patch \
            >> ${LOGS_DIR}/libintl/libintl_patch.log 2>&1 || exit 1
        touch ${BUILD_DIR}/libintl/src/gettext-${INTL_VER}/patched_02.marker
    fi
    if [ ! -f ${BUILD_DIR}/libintl/src/gettext-${INTL_VER}/patched_03.marker ] ; then
        patch -p0 < ${PATCHES_DIR}/libintl/0003-fix-asprintf-conflict.mingw.patch \
            >> ${LOGS_DIR}/libintl/libintl_patch.log 2>&1 || exit 1
        touch ${BUILD_DIR}/libintl/src/gettext-${INTL_VER}/patched_03.marker
    fi

    popd > /dev/null

    return 0
}

# build
function build_intl() {
    clear; printf "Build libintl %s\n" $INTL_VER

    download_intl_src
    patch_intl

    for arch in ${TARGET_ARCH[@]}
    do
        cd ${BUILD_DIR}/libintl/build_$arch
        rm -fr ${BUILD_DIR}/libintl/build_${arch}/*

        local bitval=$(get_arch_bit ${arch})
        local _aof=$(arch_optflags ${arch})

        source cpath $arch
        PATH=${DST_DIR}/mingw${bitval}/bin:$PATH
        export PATH

        printf "===> configuring libintl %s\n" $arch
        ../src/gettext-${INTL_VER}/gettext-runtime/configure \
            --prefix=/mingw$bitval                           \
            --build=${arch}-w64-mingw32                      \
            --host=${arch}-w64-mingw32                       \
            --disable-java                                   \
            --disable-native-java                            \
            --disable-csharp                                 \
            --enable-threads=win32                           \
            --enable-shared                                  \
            --enable-static                                  \
            --enable-relocatable                             \
            --with-gnu-ld                                    \
            --with-libiconv-prefix=${DST_DIR}/mingw$bitval   \
            CFLAGS="${_aof} ${_CFLAGS}"                      \
            LDFLAGS="${_LDFLAGS}"                            \
            > ${LOGS_DIR}/libintl/libintl_config_${arch}.log 2>&1 || exit 1
        echo "done"

        printf "===> making libintl %s\n" $arch
        make $MAKEFLAGS > ${LOGS_DIR}/libintl/libintl_make_${arch}.log 2>&1 || exit 1
        echo "done"

        printf "===> installing libintl %s\n" $arch
        make DESTDIR=${PREIN_DIR}/libintl install > ${LOGS_DIR}/libintl/libintl_install_${arch}.log 2>&1 || exit 1
        del_empty_dir ${PREIN_DIR}/libintl/mingw$bitval
        remove_la_files ${PREIN_DIR}/libintl/mingw$bitval
        strip_files ${PREIN_DIR}/libintl/mingw$bitval
        echo "done"

        printf "===> copying libintl %s to %s/mingw%s\n" $arch $DST_DIR $bitval
        cp -fra ${PREIN_DIR}/libintl/mingw$bitval $DST_DIR
        echo "done"
    done

    cd $ROOT_DIR
    return 0
}

# copy only
function copy_intl() {
    clear; printf "libintl %s\n" $INTL_VER

    for arch in ${TARGET_ARCH[@]}
    do
        local bitval=$(get_arch_bit ${arch})

        printf "===> copying libintl %s to %s/mingw%s\n" $arch $DST_DIR $bitval
        cp -fra ${PREIN_DIR}/libintl/mingw$bitval $DST_DIR
        echo "done"
    done

    cd $ROOT_DIR
    return 0
}
