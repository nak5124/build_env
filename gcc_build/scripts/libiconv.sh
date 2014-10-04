# libiconv: Libiconv is a conversion library
# download src
function download_iconv_src() {
    if [ ! -f ${BUILD_DIR}/libiconv/src/libiconv-${ICONV_VER}.tar.gz ] ; then
        printf "===> downloading libiconv %s\n" $ICONV_VER
        pushd ${BUILD_DIR}/libiconv/src > /dev/null
        dl_files http http://ftp.gnu.org/gnu/libiconv/libiconv-${ICONV_VER}.tar.gz
        popd > /dev/null
        echo "done"
    fi

    if [ ! -d ${BUILD_DIR}/libiconv/src/libiconv-$ICONV_VER ] ; then
        printf "===> extracting libiconv %s\n" $ICONV_VER
        pushd ${BUILD_DIR}/libiconv/src > /dev/null
        decomp_arch ${BUILD_DIR}/libiconv/src/libiconv-${ICONV_VER}.tar.gz
        popd > /dev/null
        echo "done"
    fi

    return 0
}

# patch
function patch_iconv() {
    pushd ${BUILD_DIR}/libiconv/src/libiconv-$ICONV_VER > /dev/null

    if [ ! -f ${BUILD_DIR}/libiconv/src/libiconv-${ICONV_VER}/patched_01.marker ] ; then
        # http://apolloron.org/software/libiconv-1.14-ja/
        patch -p1 -i ${PATCHES_DIR}/libiconv/0001-libiconv-1.14-ja-1.patch \
            > ${LOGS_DIR}/libiconv/libiconv_patch.log 2>&1 || exit 1
        touch ${BUILD_DIR}/libiconv/src/libiconv-${ICONV_VER}/patched_01.marker
    fi
    if [ ! -f ${BUILD_DIR}/libiconv/src/libiconv-${ICONV_VER}/patched_02.marker ] ; then
        patch -p1 -i ${PATCHES_DIR}/libiconv/0002-compile-relocatable-in-gnulib.mingw.patch \
            >> ${LOGS_DIR}/libiconv/libiconv_patch.log 2>&1 || exit 1
        touch ${BUILD_DIR}/libiconv/src/libiconv-${ICONV_VER}/patched_02.marker
    fi
    if [ ! -f ${BUILD_DIR}/libiconv/src/libiconv-${ICONV_VER}/patched_03.marker ] ; then
        patch -p1 -i ${PATCHES_DIR}/libiconv/0003-fix-cr-for-awk-in-configure.all.patch \
            >> ${LOGS_DIR}/libiconv/libiconv_patch.log 2>&1 || exit 1
        touch ${BUILD_DIR}/libiconv/src/libiconv-${ICONV_VER}/patched_03.marker
    fi
    if [ ! -f ${BUILD_DIR}/libiconv/src/libiconv-${ICONV_VER}/patched_04.marker ] ; then
        patch -p1 -i ${PATCHES_DIR}/libiconv/0004-use-GetConsoleOutputCP.patch \
            >> ${LOGS_DIR}/libiconv/libiconv_patch.log 2>&1 || exit 1
        touch ${BUILD_DIR}/libiconv/src/libiconv-${ICONV_VER}/patched_04.marker
    fi

    popd > /dev/null

    return 0
}

# build
function build_iconv() {
    clear; printf "Build libiconv %s\n" $ICONV_VER

    download_iconv_src
    patch_iconv

    for arch in ${TARGET_ARCH[@]}
    do
        cd ${BUILD_DIR}/libiconv/build_$arch
        rm -fr ${BUILD_DIR}/libiconv/build_${arch}/*

        local bitval=$(get_arch_bit ${arch})
        local _aof=$(arch_optflags ${arch})

        source cpath $arch
        PATH=${DST_DIR}/mingw${bitval}/bin:$PATH
        export PATH

        if [ "$1" = "-2nd" ] ; then
            local _intl="--enable-nls --with-libiconv-prefix=${DST_DIR}/mingw${bitval} \
                         --with-libintl-prefix=${DST_DIR}/mingw${bitval}"
        else
            local _intl="--disable-nls --without-libiconv-prefix --without-libintl-prefix"
        fi

        printf "===> configuring libiconv %s\n" $arch
        ../src/libiconv-${ICONV_VER}/configure \
            --prefix=/mingw$bitval             \
            --build=${arch}-w64-mingw32        \
            --host=${arch}-w64-mingw32         \
            --enable-relocatable               \
            --enable-extra-encodings           \
            --enable-shared                    \
            --disable-static                   \
            --disable-rpath                    \
            ${_intl}                           \
            CPPFLAGS="${_CPPFLAGS}"            \
            CFLAGS="${_aof} ${_CFLAGS}"        \
            LDFLAGS="${_LDFLAGS}"              \
            > ${LOGS_DIR}/libiconv/libiconv_config_${arch}.log 2>&1 || exit 1
        echo "done"

        printf "===> making libiconv %s\n" $arch
        make $MAKEFLAGS > ${LOGS_DIR}/libiconv/libiconv_make_${arch}.log 2>&1 || exit 1
        echo "done"

        printf "===> installing libiconv %s\n" $arch
        make DESTDIR=${PREIN_DIR}/libiconv install > ${LOGS_DIR}/libiconv/libiconv_install_${arch}.log 2>&1 || exit 1
        # Remove unneeded file.
        rm -f ${PREIN_DIR}/libiconv/mingw${bitval}/lib/charset.alias
        del_empty_dir ${PREIN_DIR}/libiconv/mingw$bitval
        remove_la_files ${PREIN_DIR}/libiconv/mingw$bitval
        strip_files ${PREIN_DIR}/libiconv/mingw$bitval
        echo "done"

        printf "===> copying libiconv %s to %s/mingw%s\n" $arch $DST_DIR $bitval
        cp -fra ${PREIN_DIR}/libiconv/mingw$bitval $DST_DIR
        echo "done"
    done

    cd $ROOT_DIR
    return 0
}

# copy only
function copy_iconv() {
    clear; printf "libiconv %s\n" $ICONV_VER

    for arch in ${TARGET_ARCH[@]}
    do
        local bitval=$(get_arch_bit ${arch})

        printf "===> copying libiconv %s to %s/mingw%s\n" $arch $DST_DIR $bitval
        cp -fra ${PREIN_DIR}/libiconv/mingw$bitval $DST_DIR
        echo "done"
    done

    cd $ROOT_DIR
    return 0
}
