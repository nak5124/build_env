# libiconv: Libiconv is a conversion library
# Download the src and decompress it.
function download_iconv_src() {
    if ! ${use_win_iconv}; then
        # Download the src.
        if [ ! -f "${BUILD_DIR}"/libiconv/src/libiconv-${ICONV_VER}.tar.gz ]; then
            printf "===> Downloading libiconv %s...\n" "${ICONV_VER}"
            pushd "${BUILD_DIR}"/libiconv/src > /dev/null
            dl_files http http://ftp.gnu.org/gnu/libiconv/libiconv-${ICONV_VER}.tar.gz
            popd > /dev/null # "${BUILD_DIR}"/libiconv/src
            echo 'done'
        fi

        # Decompress the src archive.
        if [ ! -d "${BUILD_DIR}"/libiconv/src/libiconv-$ICONV_VER ]; then
            printf "===> Extracting libiconv %s...\n" "${ICONV_VER}"
            pushd "${BUILD_DIR}"/libiconv/src > /dev/null
            decomp_arch "${BUILD_DIR}"/libiconv/src/libiconv-${ICONV_VER}.tar.gz
            popd > /dev/null # "${BUILD_DIR}"/libiconv/src
            echo 'done'
        fi
    else
        # Git clone.
        if [ ! -d "${BUILD_DIR}"/libiconv/src/win-iconv ]; then
            echo '===> Cloning win-iconv git repo...'
            pushd "${BUILD_DIR}"/libiconv/src > /dev/null
            dl_files git https://github.com/win-iconv/win-iconv.git win-iconv
            popd > /dev/null # "${BUILD_DIR}"/libiconv/src
            echo 'done'
        fi
    fi

    return 0
}

# Apply patches and libtoolize.
function apply_patch_iconv() {
    apply_patch "${1}" "${BUILD_DIR}"/libiconv/src/libiconv-$ICONV_VER "${LOGS_DIR}"/libiconv/libiconv_patch.log "${2}"
}

function prepare_iconv() {
    # Apply patches.
    printf "===> Applying patches to libiconv %s...\n" "${ICONV_VER}"

    # http://apolloron.org/software/libiconv-1.14-ja/
    apply_patch_iconv "${PATCHES_DIR}"/libiconv/0001-libiconv-1.14-ja-1.patch            true
    # For --enable-relocatable.
    apply_patch_iconv "${PATCHES_DIR}"/libiconv/0002-compile-relocatable-in-gnulib.patch false
    # Remove CR.
    apply_patch_iconv "${PATCHES_DIR}"/libiconv/0003-fix-cr-for-awk-in-configure.patch   false
    # GetACP -> GetConsoleOutputCP.
    apply_patch_iconv "${PATCHES_DIR}"/libiconv/0004-use-GetConsoleOutputCP.patch        false

    # Disable automatic image base calculation.
    pushd "${BUILD_DIR}"/libiconv/src/libiconv-$ICONV_VER > /dev/null
    sed -i 's/enable-auto-image-base/disable-auto-image-base/g' {.,preload,libcharset}/configure
    popd > /dev/null # "${BUILD_DIR}"/libiconv/src/libiconv-$ICONV_VER

    echo 'done'

    return 0
}

# Build and install.
function build_iconv() {
    clear; printf "Build libiconv %s\n" "${ICONV_VER}"

    # Option handling.
    local _rebuild=true

    local _opt
    for _opt in "${@}"
    do
        case "${_opt}" in
            --rebuild=* )
                _rebuild=${_opt#*=}
                ;;
            * )
                printf "build_iconv: Unknown Option: '%s'\n" "${_opt}"
                echo '...exit'
                exit 1
                ;;
        esac
    done

    # Setup.
    if ${_rebuild}; then
        download_iconv_src
        if ! ${use_win_iconv}; then
            prepare_iconv
        fi
    fi

    local _arch
    for _arch in ${TARGET_ARCH[@]}
    do
        local _bitval=$(get_arch_bit ${_arch})

        if ${_rebuild}; then
            cd "${BUILD_DIR}"/libiconv/build_$_arch
            # Cleanup the build dir.
            rm -fr "${BUILD_DIR}"/libiconv/build_${_arch}/*

            # PATH exporting.
            set_path $_arch

            if ! ${use_win_iconv}; then
                # Configure.
                printf "===> Configuring libiconv %s...\n" "${_arch}"
                ../src/libiconv-${ICONV_VER}/configure \
                    --prefix=/mingw$_bitval            \
                    --build=${_arch}-w64-mingw32       \
                    --host=${_arch}-w64-mingw32        \
                    --enable-relocatable               \
                    --enable-extra-encodings           \
                    --disable-static                   \
                    --enable-shared                    \
                    --enable-fast-install              \
                    --disable-rpath                    \
                    --disable-nls                      \
                    --with-gnu-ld                      \
                    CFLAGS="${CFLAGS_}"                \
                    LDFLAGS="${LDFLAGS_}"              \
                    CPPFLAGS="${CPPFLAGS_}"            \
                    > "${LOGS_DIR}"/libiconv/libiconv_config_${_arch}.log 2>&1 || exit 1
                echo 'done'

                # Make.
                printf "===> Making libiconv %s...\n" "${_arch}"
                make $MAKEFLAGS_ > "${LOGS_DIR}"/libiconv/libiconv_make_${_arch}.log 2>&1 || exit 1
                echo 'done'

                # Install.
                printf "===> Installing libiconv %s...\n" "${_arch}"
                make DESTDIR="${PREIN_DIR}"/libiconv install > "${LOGS_DIR}"/libiconv/libiconv_install_${_arch}.log 2>&1 || exit 1
                # Remove unneeded files.
                rm -f "${PREIN_DIR}"/libiconv/mingw${_bitval}/bin/libcharset-*.dll
                rm -f "${PREIN_DIR}"/libiconv/mingw${_bitval}/include/libcharset.h
                rm -f "${PREIN_DIR}"/libiconv/mingw${_bitval}/lib/libcharset.dll.a
                rm -f "${PREIN_DIR}"/libiconv/mingw${_bitval}/lib/charset.alias
                remove_la_files   "${PREIN_DIR}"/libiconv/mingw$_bitval
                # Strip files.
                strip_files "${PREIN_DIR}"/libiconv/mingw$_bitval
                echo 'done'
            else
:
            fi
        fi

        # Copy to DST_DIR.
        printf "===> Copying libiconv %s to %s/mingw%s...\n" "${_arch}" "${DST_DIR}" "${_bitval}"
        cp -af "${PREIN_DIR}"/libiconv/mingw$_bitval "${DST_DIR}"
        echo 'done'
    done

    cd "${ROOT_DIR}"
    return 0
}
