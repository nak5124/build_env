# libintl: GNU Internationalization runtime library
# Download the src and decompress it.
function download_intl_src() {
    # Download the src.
    if [ ! -f ${BUILD_DIR}/libintl/src/gettext-${INTL_VER}.tar.xz ]; then
        printf "===> Downloading libintl %s...\n" $INTL_VER
        pushd ${BUILD_DIR}/libintl/src > /dev/null
        dl_files http http://ftp.gnu.org/pub/gnu/gettext/gettext-${INTL_VER}.tar.xz
        popd > /dev/null
        echo "done"
    fi

    # Decompress the src archive.
    if [ ! -d ${BUILD_DIR}/libintl/src/gettext-$INTL_VER ]; then
        printf "===> Extracting libintl %s...\n" $INTL_VER
        pushd ${BUILD_DIR}/libintl/src > /dev/null
        decomp_arch ${BUILD_DIR}/libintl/src/gettext-${INTL_VER}.tar.xz
        popd > /dev/null
        echo "done"
    fi

    return 0
}

# Apply patches and libtoolize.
function prepare_intl() {
    # Apply patches.
    printf "===> Applying patches to libintl %s...\n" $INTL_VER
    pushd ${BUILD_DIR}/libintl/src/gettext-$INTL_VER > /dev/null
    if [ ! -f ${BUILD_DIR}/libintl/src/gettext-${INTL_VER}/patched_01.marker ]; then
        # For --enable-relocatable.
        patch -p1 -i ${PATCHES_DIR}/libintl/0001-relocatex-libintl-0.18.3.1.patch \
            > ${LOGS_DIR}/libintl/libintl_patch.log 2>&1 || exit 1
        touch ${BUILD_DIR}/libintl/src/gettext-${INTL_VER}/patched_01.marker
    fi
    if [ ! -f ${BUILD_DIR}/libintl/src/gettext-${INTL_VER}/patched_02.marker ]; then
        patch -p0 -i ${PATCHES_DIR}/libintl/0002-always-use-libintl-vsnprintf.mingw.patch \
            >> ${LOGS_DIR}/libintl/libintl_patch.log 2>&1 || exit 1
        touch ${BUILD_DIR}/libintl/src/gettext-${INTL_VER}/patched_02.marker
    fi
    if [ ! -f ${BUILD_DIR}/libintl/src/gettext-${INTL_VER}/patched_03.marker ]; then
        # Fix linking to gcc dynamically.
        patch -p1 -i ${PATCHES_DIR}/libintl/0003-static-locale_charset.patch \
            >> ${LOGS_DIR}/libintl/libintl_patch.log 2>&1 || exit 1
        touch ${BUILD_DIR}/libintl/src/gettext-${INTL_VER}/patched_03.marker
    fi
    if [ ! -f ${BUILD_DIR}/libintl/src/gettext-${INTL_VER}/patched_04.marker ]; then
        patch -p1 -i ${PATCHES_DIR}/libintl/0004-use-GetConsoleOutputCP.patch \
            >> ${LOGS_DIR}/libintl/libintl_patch.log 2>&1 || exit 1
        touch ${BUILD_DIR}/libintl/src/gettext-${INTL_VER}/patched_04.marker
    fi
    if [ ! -f ${BUILD_DIR}/libintl/src/gettext-${INTL_VER}/patched_05.marker ]; then
        # Fix linking to gcc with -fstack-protector*.
        patch -p1 -i ${PATCHES_DIR}/libintl/0005-dont-use-disable-auto-import.patch \
            >> ${LOGS_DIR}/libintl/libintl_patch.log 2>&1 || exit 1
        touch ${BUILD_DIR}/libintl/src/gettext-${INTL_VER}/patched_05.marker
    fi
    echo "done"

    # Libtoolize
    printf "===> Libtoolizing libintl %s...\n" $INTL_VER
    # For building with -fstack-protector*.
    cd ${BUILD_DIR}/libintl/src/gettext-${INTL_VER}/gettext-runtime
    libtoolize -i > /dev/null 2>&1
    sed -i "s/macro_version='2.4.2'/macro_version='2.4.2.458.26-92994'/" configure
    sed -i "s/macro_revision='1.3337'/macro_revision='2.4.3'/" configure
    popd > /dev/null
    echo "done"

    return 0
}

# Build and install.
function build_intl() {
    clear; printf "Build libintl %s\n" $INTL_VER

    # Option handling.
    local _rebuild=true

    local _opt
    for _opt in "${@}"
    do
        case "${_opt}" in
            --rebuild=* )
                _rebuild="${_opt#*=}"
                ;;
            * )
                printf "build_intl: Unknown Option: '%s'\n" $_opt
                echo "...exit"
                exit 1
                ;;
        esac
    done

    # Setup.
    if ${_rebuild}; then
        download_intl_src
        prepare_intl
    fi

    local _arch
    for _arch in ${TARGET_ARCH[@]}
    do
        local _bitval=$(get_arch_bit ${_arch})

        if ${_rebuild}; then
            cd ${BUILD_DIR}/libintl/build_$_arch
            # Cleanup the build dir.
            rm -fr ${BUILD_DIR}/libintl/build_${_arch}/*

            # PATH exporting.
            source cpath $_arch
            PATH=${DST_DIR}/mingw${_bitval}/bin:$PATH
            export PATH

            # Configure.
            printf "===> Configuring libintl %s...\n" $_arch
            ../src/gettext-${INTL_VER}/gettext-runtime/configure \
                --prefix=/mingw$_bitval                          \
                --build=${_arch}-w64-mingw32                     \
                --host=${_arch}-w64-mingw32                      \
                --disable-silent-rules                           \
                --disable-java                                   \
                --disable-native-java                            \
                --disable-csharp                                 \
                --enable-threads=windows                         \
                --enable-shared                                  \
                --disable-static                                 \
                --enable-fast-install                            \
                --disable-rpath                                  \
                --disable-c++                                    \
                --enable-relocatable                             \
                --disable-libasprintf                            \
                --with-gnu-ld                                    \
                --with-libiconv-prefix=${DST_DIR}/mingw$_bitval  \
                CFLAGS="-march=${_arch/_/-} ${CFLAGS_}"          \
                LDFLAGS="${LDFLAGS_}"                            \
                CPPFLAGS="${CPPFLAGS_}"                          \
                CXXFLAGS="-march=${_arch/_/-} ${CXXFLAGS_}"      \
                > ${LOGS_DIR}/libintl/libintl_config_${_arch}.log 2>&1 || exit 1
            echo "done"

            # Make.
            printf "===> Making libintl %s...\n" $_arch
            make $MAKEFLAGS_ > ${LOGS_DIR}/libintl/libintl_make_${_arch}.log 2>&1 || exit 1
            echo "done"

            # Install.
            printf "===> Installing libintl %s...\n" $_arch
            make DESTDIR=${PREIN_DIR}/libintl install > ${LOGS_DIR}/libintl/libintl_install_${_arch}.log 2>&1 || exit 1
            # Remove unneeded files.
            rm -f  ${PREIN_DIR}/libintl/mingw${_bitval}/bin/{*.sh,*.exe}
            rm -fr ${PREIN_DIR}/libintl/mingw${_bitval}/share
            remove_empty_dirs ${PREIN_DIR}/libintl/mingw$_bitval
            remove_la_files   ${PREIN_DIR}/libintl/mingw$_bitval
            # Strip files.
            strip_files ${PREIN_DIR}/libintl/mingw$_bitval
            echo "done"
        fi

        # Copy to DST_DIR.
        printf "===> Copying libintl %s to %s/mingw%s...\n" $_arch $DST_DIR $_bitval
        cp -fra ${PREIN_DIR}/libintl/mingw$_bitval $DST_DIR
        echo "done"
    done

    cd $ROOT_DIR
    return 0
}
