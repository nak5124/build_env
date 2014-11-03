# libiconv: Libiconv is a conversion library
# Download the src and decompress it.
function download_iconv_src() {
    # Download the src.
    if [ ! -f ${BUILD_DIR}/libiconv/src/libiconv-${ICONV_VER}.tar.gz ]; then
        printf "===> Downloading libiconv %s...\n" $ICONV_VER
        pushd ${BUILD_DIR}/libiconv/src > /dev/null
        dl_files http http://ftp.gnu.org/gnu/libiconv/libiconv-${ICONV_VER}.tar.gz
        popd > /dev/null
        echo "done"
    fi

    # Decompress the src archive.
    if [ ! -d ${BUILD_DIR}/libiconv/src/libiconv-$ICONV_VER ]; then
        printf "===> Extracting libiconv %s...\n" $ICONV_VER
        pushd ${BUILD_DIR}/libiconv/src > /dev/null
        decomp_arch ${BUILD_DIR}/libiconv/src/libiconv-${ICONV_VER}.tar.gz
        popd > /dev/null
        echo "done"
    fi

    return 0
}

# Apply patches and libtoolize.
function prepare_iconv() {
    # Apply patches.
    printf "===> Applying patches to libiconv %s...\n" $ICONV_VER
    pushd ${BUILD_DIR}/libiconv/src/libiconv-$ICONV_VER > /dev/null
    if [ ! -f ${BUILD_DIR}/libiconv/src/libiconv-${ICONV_VER}/patched_01.marker ]; then
        # http://apolloron.org/software/libiconv-1.14-ja/
        patch -p1 -i ${PATCHES_DIR}/libiconv/0001-libiconv-1.14-ja-1.patch \
            > ${LOGS_DIR}/libiconv/libiconv_patch.log 2>&1 || exit 1
        touch ${BUILD_DIR}/libiconv/src/libiconv-${ICONV_VER}/patched_01.marker
    fi
    if [ ! -f ${BUILD_DIR}/libiconv/src/libiconv-${ICONV_VER}/patched_02.marker ]; then
        # For --enable-relocatable.
        patch -p1 -i ${PATCHES_DIR}/libiconv/0002-compile-relocatable-in-gnulib.mingw.patch \
            >> ${LOGS_DIR}/libiconv/libiconv_patch.log 2>&1 || exit 1
        touch ${BUILD_DIR}/libiconv/src/libiconv-${ICONV_VER}/patched_02.marker
    fi
    if [ ! -f ${BUILD_DIR}/libiconv/src/libiconv-${ICONV_VER}/patched_03.marker ]; then
        patch -p1 -i ${PATCHES_DIR}/libiconv/0003-fix-cr-for-awk-in-configure.all.patch \
            >> ${LOGS_DIR}/libiconv/libiconv_patch.log 2>&1 || exit 1
        touch ${BUILD_DIR}/libiconv/src/libiconv-${ICONV_VER}/patched_03.marker
    fi
    if [ ! -f ${BUILD_DIR}/libiconv/src/libiconv-${ICONV_VER}/patched_04.marker ]; then
        patch -p1 -i ${PATCHES_DIR}/libiconv/0004-use-GetConsoleOutputCP.patch \
            >> ${LOGS_DIR}/libiconv/libiconv_patch.log 2>&1 || exit 1
        touch ${BUILD_DIR}/libiconv/src/libiconv-${ICONV_VER}/patched_04.marker
    fi
    echo "done"

    # Libtoolize
    printf "===> Libtoolizing libiconv %s...\n" $ICONV_VER
    # For building with -fstack-protector*.
    libtoolize -i > /dev/null 2>&1
    sed -i "s/macro_version='2.4'/macro_version='2.4.2.458.26-92994'/" configure
    sed -i "s/macro_revision='1.3293'/macro_revision='2.4.3'/" configure
    cd ${BUILD_DIR}/libiconv/src/libiconv-${ICONV_VER}/libcharset
    libtoolize -i > /dev/null 2>&1
    sed -i "s/macro_version='2.4'/macro_version='2.4.2.458.26-92994'/" configure
    sed -i "s/macro_revision='1.3293'/macro_revision='2.4.3'/" configure
    popd > /dev/null
    echo "done"

    return 0
}

# Build and install.
function build_iconv() {
    clear; printf "Build libiconv %s\n" $ICONV_VER

    # Option handling.
    local _rebuild=true
    local _2nd_build=false

    local _opt
    for _opt in "${@}"
    do
        case "${_opt}" in
            --rebuild=* )
                _rebuild="${_opt#*=}"
                ;;
            --2nd )
                _2nd_build=true
                ;;
            * )
                printf "build_iconv: Unknown Option: '%s'\n" $_opt
                echo "...exit"
                exit 1
                ;;
        esac
    done

    # Setup.
    if ${_rebuild}; then
        download_iconv_src
        prepare_iconv
    fi

    local _arch
    for _arch in ${TARGET_ARCH[@]}
    do
        local _bitval=$(get_arch_bit ${_arch})

        if ${_rebuild}; then
            cd ${BUILD_DIR}/libiconv/build_$_arch
            # Cleanup the build dir.
            rm -fr ${BUILD_DIR}/libiconv/build_${_arch}/*

            # PATH exporting.
            source cpath $_arch
            PATH=${DST_DIR}/mingw${_bitval}/bin:$PATH
            export PATH

            # NLS
            if ${_2nd_build}; then
                local _intl="--enable-nls \
                             --with-libiconv-prefix=${DST_DIR}/mingw$_bitval --with-libintl-prefix=${DST_DIR}/mingw$_bitval"
            else
                local _intl="--disable-nls"
            fi

            # For eh of i686 bins, which are built with MSVC.
            if [ "${_arch}" = "i686" ]; then
                local _slgcc="-static-libgcc"
            else
                local _slgcc=""
            fi

            # Configure.
            printf "===> Configuring libiconv %s...\n" $_arch
            ../src/libiconv-${ICONV_VER}/configure      \
                --prefix=/mingw$_bitval                 \
                --build=${_arch}-w64-mingw32            \
                --host=${_arch}-w64-mingw32             \
                --enable-relocatable                    \
                --enable-extra-encodings                \
                --disable-static                        \
                --enable-shared                         \
                --enable-fast-install                   \
                --disable-rpath                         \
                ${_intl}                                \
                --with-gnu-ld                           \
                CFLAGS="-march=${_arch/_/-} ${CFLAGS_}" \
                LDFLAGS="${LDFLAGS_} ${_slgcc}"         \
                CPPFLAGS="${CPPFLAGS_}"                 \
                > ${LOGS_DIR}/libiconv/libiconv_config_${_arch}.log 2>&1 || exit 1
            echo "done"

            # Make.
            printf "===> Making libiconv %s...\n" $_arch
            make $MAKEFLAGS_ > ${LOGS_DIR}/libiconv/libiconv_make_${_arch}.log 2>&1 || exit 1
            echo "done"

            # Install.
            printf "===> Installing libiconv %s...\n" $_arch
            make DESTDIR=${PREIN_DIR}/libiconv install > ${LOGS_DIR}/libiconv/libiconv_install_${_arch}.log 2>&1 || exit 1
            # Remove unneeded files.
            rm -f ${PREIN_DIR}/libiconv/mingw${_bitval}/bin/libcharset-*.dll
            rm -f ${PREIN_DIR}/libiconv/mingw${_bitval}/include/libcharset.h
            rm -f ${PREIN_DIR}/libiconv/mingw${_bitval}/lib/libcharset.dll.a
            rm -f ${PREIN_DIR}/libiconv/mingw${_bitval}/lib/charset.alias
            remove_empty_dirs ${PREIN_DIR}/libiconv/mingw$_bitval
            remove_la_files   ${PREIN_DIR}/libiconv/mingw$_bitval
            # Strip files.
            strip_files ${PREIN_DIR}/libiconv/mingw$_bitval
            echo "done"
        fi

        if ! ( ! ${_rebuild} && ${_2nd_build} ); then
            # Copy to DST_DIR.
            printf "===> Copying libiconv %s to %s/mingw%s...\n" $_arch $DST_DIR $_bitval
            cp -fra ${PREIN_DIR}/libiconv/mingw$_bitval $DST_DIR
            echo "done"
        fi
    done

    cd $ROOT_DIR
    return 0
}
