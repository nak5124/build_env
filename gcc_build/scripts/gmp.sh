# GMP: A free library for arbitrary precision arithmetic
# Download the src and decompress it.
function download_gmp_src() {
    # Download the src.
    if [ ! -f "${BUILD_DIR}"/gcc_libs/gmp/src/gmp-${GMP_VER}a.tar.lz ]; then
        printf "===> Downloading GMP %s...\n" "${GMP_VER}"
        pushd "${BUILD_DIR}"/gcc_libs/gmp/src > /dev/null
        dl_files ftp ftp://ftp.gmplib.org/pub/gmp/gmp-${GMP_VER}a.tar.lz
        popd > /dev/null # "${BUILD_DIR}"/gcc_libs/gmp/src
        echo 'done'
    fi

    # Decompress the src archive.
    if [ ! -d "${BUILD_DIR}"/gcc_libs/gmp/src/gmp-$GMP_VER ]; then
        printf "===> Extracting GMP %s...\n" "${GMP_VER}"
        pushd "${BUILD_DIR}"/gcc_libs/gmp/src > /dev/null
        decomp_arch "${BUILD_DIR}"/gcc_libs/gmp/src/gmp-${GMP_VER}a.tar.lz
        popd > /dev/null # "${BUILD_DIR}"/gcc_libs/gmp/src
        echo 'done'
    fi

    return 0
}

# Autoreconf.
function prepare_gmp() {
    # Autoreconf.
    printf "===> Autoreconfing GMP %s...\n" "${GMP_VER}"
    pushd "${BUILD_DIR}"/gcc_libs/gmp/src/gmp-$GMP_VER > /dev/null
    autoreconf -fis > /dev/null 2>&1
    popd > /dev/null # "${BUILD_DIR}"/gcc_libs/gmp/src/gmp-$GMP_VER
    echo 'done'

    return 0
}

# Build and install.
function build_gmp() {
    clear; printf "Build GMP %s\n" "${GMP_VER}"

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
                printf "build_gmp, Unknown Option: '%s'\n" "${_opt}"
                echo '...exit'
                exit 1
                ;;
        esac
    done

    # Setup.
    if ${_rebuild}; then
        download_gmp_src
        prepare_gmp
    fi

    local _arch
    for _arch in ${TARGET_ARCH[@]}
    do
        local _bitval=$(get_arch_bit ${_arch})

        if ${_rebuild}; then
            cd "${BUILD_DIR}"/gcc_libs/gmp/build_$_arch
            # Cleanup the build dir.
            rm -fr "${BUILD_DIR}"/gcc_libs/gmp/build_${_arch}/{.*,*} > /dev/null 2>&1

            # PATH exporting.
            set_path $_arch

            # Configure.
            printf "===> Configuring GMP %s...\n" "${_arch}"
            ../src/gmp-${GMP_VER}/configure  \
                --prefix=/mingw$_bitval      \
                --build=${_arch}-w64-mingw32 \
                --host=${_arch}-w64-mingw32  \
                --disable-silent-rules       \
                --disable-cxx                \
                --enable-assembly            \
                --enable-fft                 \
                --enable-fat                 \
                --enable-shared              \
                --disable-static             \
                --enable-fast-install        \
                --with-gnu-ld                \
                CFLAGS="${CFLAGS_}"          \
                LDFLAGS="${LDFLAGS_}"        \
                CPPFLAGS="${CPPFLAGS_}"      \
                CXXFLAGS="${CXXFLAGS_}"      \
                > "${LOGS_DIR}"/gcc_libs/gmp/gmp_config_${_arch}.log 2>&1 || exit 1
            echo 'done'

            # Make.
            printf "===> Making GMP %s...\n" "${_arch}"
            make $MAKEFLAGS_ > "${LOGS_DIR}"/gcc_libs/gmp/gmp_make_${_arch}.log 2>&1 || exit 1
            echo 'done'

            # Install.
            printf "===> Installing GMP %s...\n" "${_arch}"
            make DESTDIR="${PREIN_DIR}"/gcc_libs/gmp install \
                > "${LOGS_DIR}"/gcc_libs/gmp/gmp_install_${_arch}.log 2>&1 || exit 1
            # Remove unneeded files.
            rm -fr "${PREIN_DIR}"/gcc_libs/gmp/mingw${_bitval}/share
            remove_la_files   "${PREIN_DIR}"/gcc_libs/gmp/mingw$_bitval
            # Strip files.
            strip_files "${PREIN_DIR}"/gcc_libs/gmp/mingw$_bitval
            echo 'done'
        fi

        # Copy to DST_DIR.
        printf "===> Copying GMP %s to %s/mingw%s...\n" "${_arch}" "${DST_DIR}" "${_bitval}"
        cp -af "${PREIN_DIR}"/gcc_libs/gmp/mingw$_bitval "${DST_DIR}"
        echo 'done'
    done

    cd "${ROOT_DIR}"
    return 0
}
