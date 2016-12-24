# MPFR: Multiple-precision floating-point library
# Download the src and decompress it.
function download_mpfr_src() {
    # Download the src.
    if [ ! -f "${BUILD_DIR}"/gcc_libs/mpfr/src/mpfr-${MPFR_VER}.tar.xz ]; then
        printf "===> Downloading MPFR %s...\n" "${MPFR_VER}"
        pushd "${BUILD_DIR}"/gcc_libs/mpfr/src > /dev/null
        dl_files http http://www.mpfr.org/mpfr-current/mpfr-${MPFR_VER}.tar.xz
        popd > /dev/null # "${BUILD_DIR}"/gcc_libs/mpfr/src
        echo 'done'
    fi

    # Decompress the src archive.
    printf "===> Extracting MPFR %s...\n" "${MPFR_VER}"
    pushd "${BUILD_DIR}"/gcc_libs/mpfr/src > /dev/null
    if [ -d "${BUILD_DIR}"/gcc_libs/mpfr/src/mpfr-$MPFR_VER ]; then
        # Redecompress every time.
        rm -fr "${BUILD_DIR}"/gcc_libs/mpfr/src/mpfr-$MPFR_VER
    fi
    decomp_arch "${BUILD_DIR}"/gcc_libs/mpfr/src/mpfr-${MPFR_VER}.tar.xz
    popd > /dev/null # "${BUILD_DIR}"/gcc_libs/mpfr/src
    echo 'done'

    return 0
}

# Download the latest patch, apply it and autoreconf.
function prepare_mpfr() {
    local _have_allpatches=false
    local _rd='>'

    if wget --spider --recursive --no-directories  http://www.mpfr.org/mpfr-current/allpatches > /dev/null 2>&1; then
        _have_allpatches=true
        _rd='>>'

        # Download the latest patch.
        if [ ! -d "${PATCHES_DIR}"/mpfr ]; then
            mkdir -p "${PATCHES_DIR}"/mpfr
        fi
        printf "===> Downloading the latest MPFR %s patch...\n" "${MPFR_VER}"
        pushd "${PATCHES_DIR}"/mpfr > /dev/null
        if [ -f "${PATCHES_DIR}"/mpfr/allpatches ]; then
            rm -f "${PATCHES_DIR}"/mpfr/allpatches
        fi
        dl_files http http://www.mpfr.org/mpfr-current/allpatches
        popd > /dev/null # "${PATCHES_DIR}"/mpfr
        echo 'done'
    fi

    # Applay the patch.
    printf "===> Applaying the patch to MPFR %s...\n" "${MPFR_VER}"
    pushd "${BUILD_DIR}"/gcc_libs/mpfr/src/mpfr-$MPFR_VER > /dev/null
    if ${_have_allpatches}; then
        patch -p1 -i "${PATCHES_DIR}"/mpfr/allpatches > "${LOGS_DIR}"/gcc_libs/mpfr/mpfr_patch.log 2>&1 || exit 1
    fi
    eval patch -p1 -i "${PATCHES_DIR}"/mpfr/0001-Add-mparam-h-for-sandybridge.patch \
        $_rd "${LOGS_DIR}"/gcc_libs/mpfr/mpfr_patch.log 2>&1 || exit 1
    echo 'done'

    # Autoreconf.
    printf "===> Autoreconfing MPFR %s...\n" "${MPFR_VER}"
    autoreconf -fis > /dev/null 2>&1
    popd > /dev/null # "${BUILD_DIR}"/gcc_libs/mpfr/src/mpfr-$MPFR_VER
    echo 'done'

    return 0
}

# Build and install.
function build_mpfr() {
    clear; printf "Build MPFR %s\n" "${MPFR_VER}"

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
                printf "build_mpfr: Unknown Option: '%s'\n" "${_opt}"
                echo '...exit'
                exit 1
                ;;
        esac
    done

    # Setup.
    if ${_rebuild}; then
        download_mpfr_src
        prepare_mpfr
    fi

    local _arch
    for _arch in ${TARGET_ARCH[@]}
    do
        local _bitval=$(get_arch_bit ${_arch})

        if ${_rebuild}; then
            cd "${BUILD_DIR}"/gcc_libs/mpfr/build_$_arch
            # Cleanup the build dir.
            rm -fr "${BUILD_DIR}"/gcc_libs/mpfr/build_${_arch}/*

            # PATH exporting.
            set_path $_arch

            # Configure.
            printf "===> Configuring MPFR %s...\n" "${_arch}"
            ../src/mpfr-${MPFR_VER}/configure         \
                --prefix=/mingw$_bitval               \
                --build=${_arch}-w64-mingw32          \
                --host=${_arch}-w64-mingw32           \
                --disable-silent-rules                \
                --enable-thread-safe                  \
                --enable-shared                       \
                --disable-static                      \
                --enable-fast-install                 \
                --with-gmp="${DST_DIR}"/mingw$_bitval \
                --with-gnu-ld                         \
                CFLAGS="${CFLAGS_}"                   \
                LDFLAGS="${LDFLAGS_}"                 \
                CPPFLAGS="${CPPFLAGS_}"               \
                > "${LOGS_DIR}"/gcc_libs/mpfr/mpfr_config_${_arch}.log 2>&1 || exit 1
            echo 'done'

            # Make.
            printf "===> Making MPFR %s...\n" "${_arch}"
            make $MAKEFLAGS_ > "${LOGS_DIR}"/gcc_libs/mpfr/mpfr_make_${_arch}.log 2>&1 || exit 1
            echo 'done'

            # Install.
            printf "===> Installing MPFR %s...\n" "${_arch}"
            make DESTDIR="${PREIN_DIR}"/gcc_libs/mpfr install \
                > "${LOGS_DIR}"/gcc_libs/mpfr/mpfr_install_${_arch}.log 2>&1 || exit 1
            # Remove unneeded files.
            rm -fr "${PREIN_DIR}"/gcc_libs/mpfr/mingw${_bitval}/share
            remove_la_files   "${PREIN_DIR}"/gcc_libs/mpfr/mingw$_bitval
            # Strip files.
            strip_files "${PREIN_DIR}"/gcc_libs/mpfr/mingw$_bitval
            echo 'done'
        fi

        # Copy to DST_DIR.
        printf "===> Copying MPFR %s to %s/mingw%s...\n" "${_arch}" "${DST_DIR}" "${_bitval}"
        cp -af "${PREIN_DIR}"/gcc_libs/mpfr/mingw$_bitval "${DST_DIR}"
        echo 'done'

        # Copy logs
        printf "===> Copying MPFR %s logs to %s/mingw%s/logs...\n" "${_arch}" "${DST_DIR}" "${_bitval}"
        mkdir -p "${DST_DIR}"/mingw${_bitval}/logs/gcc_libs/mpfr
        cp -af "${LOGS_DIR}"/gcc_libs/mpfr/*${_arch}*     "${DST_DIR}"/mingw${_bitval}/logs/gcc_libs/mpfr
        cp -af "${LOGS_DIR}"/gcc_libs/mpfr/mpfr_patch.log "${DST_DIR}"/mingw${_bitval}/logs/gcc_libs/mpfr
        echo 'done'
    done

    cd "${ROOT_DIR}"
    return 0
}
