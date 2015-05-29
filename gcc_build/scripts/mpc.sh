# MPC: Multiple precision complex arithmetic library
# Download the src and decompress it.
function download_mpc_src() {
    # Download the src.
    if [ ! -f "${BUILD_DIR}"/gcc_libs/mpc/src/mpc-${MPC_VER}.tar.gz ]; then
        printf "===> Downloading MPC %s...\n" "${MPC_VER}"
        pushd "${BUILD_DIR}"/gcc_libs/mpc/src > /dev/null
        dl_files ftp ftp://ftp.gnu.org/gnu/mpc/mpc-${MPC_VER}.tar.gz
        popd > /dev/null # "${BUILD_DIR}"/gcc_libs/mpc/src
        echo 'done'
    fi

    # Decompress the src archive.
    if [ ! -d "${BUILD_DIR}"/gcc_libs/mpc/src/mpc-$MPC_VER ]; then
        printf "===> Extracting MPC %s...\n" "${MPC_VER}"
        pushd "${BUILD_DIR}"/gcc_libs/mpc/src > /dev/null
        decomp_arch "${BUILD_DIR}"/gcc_libs/mpc/src/mpc-${MPC_VER}.tar.gz
        popd > /dev/null # "${BUILD_DIR}"/gcc_libs/mpc/src
        echo 'done'
    fi

    return 0
}

# Autoreconf.
function prepare_mpc() {
    # Autoreconf.
    printf "===> Autoreconfing MPC %s...\n" "${MPC_VER}"
    pushd "${BUILD_DIR}"/gcc_libs/mpc/src/mpc-$MPC_VER > /dev/null
    autoreconf -fis > /dev/null 2>&1
    popd > /dev/null # "${BUILD_DIR}"/gcc_libs/mpc/src/mpc-$MPC_VER
    echo 'done'

    return 0
}

# Build and install.
function build_mpc() {
    clear; printf "Build MPC %s\n" "${MPC_VER}"

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
                printf "build_mpc: Unknown Option: '%s'\n" "${_opt}"
                echo '...exit'
                exit 1
                ;;
        esac
    done

    # Setup.
    if ${_rebuild}; then
        download_mpc_src
        prepare_mpc
    fi

    local _arch
    for _arch in ${TARGET_ARCH[@]}
    do
        local _bitval=$(get_arch_bit ${_arch})

        if ${_rebuild}; then
            cd "${BUILD_DIR}"/gcc_libs/mpc/build_$_arch
            # Cleanup the build dir.
            rm -fr "${BUILD_DIR}"/gcc_libs/mpc/build_${_arch}/*

            # PATH exporting.
            set_path $_arch

            # Configure.
            printf "===> Configuring MPC %s...\n" "${_arch}"
            ../src/mpc-${MPC_VER}/configure                  \
                --prefix=/mingw$_bitval                      \
                --build=${_arch}-w64-mingw32                 \
                --host=${_arch}-w64-mingw32                  \
                --disable-silent-rules                       \
                --enable-shared                              \
                --disable-static                             \
                --enable-fast-install                        \
                --with-{mpfr,gmp}="${DST_DIR}"/mingw$_bitval \
                --with-gnu-ld                                \
                CFLAGS="${CFLAGS_}"                          \
                LDFLAGS="${LDFLAGS_}"                        \
                CPPFLAGS="${CPPFLAGS_}"                      \
                > "${LOGS_DIR}"/gcc_libs/mpc/mpc_config_${_arch}.log 2>&1 || exit 1
            echo 'done'

            # Make.
            printf "===> Making MPC %s...\n" "${_arch}"
            make $MAKEFLAGS_ > "${LOGS_DIR}"/gcc_libs/mpc/mpc_make_${_arch}.log 2>&1 || exit 1
            echo 'done'

            # Install.
            printf "===> Installing MPC %s...\n" "${_arch}"
            make DESTDIR="${PREIN_DIR}"/gcc_libs/mpc install \
                > "${LOGS_DIR}"/gcc_libs/mpc/mpc_install_${_arch}.log 2>&1 || exit 1
            # Remove unneeded files.
            rm -fr "${PREIN_DIR}"/gcc_libs/mpc/mingw${_bitval}/share
            remove_la_files   "${PREIN_DIR}"/gcc_libs/mpc/mingw$_bitval
            # Strip files.
            strip_files "${PREIN_DIR}"/gcc_libs/mpc/mingw$_bitval
            echo 'done'
        fi

        # Copy to DST_DIR.
        printf "===> Copying MPC %s to %s/mingw%s...\n" "${_arch}" "${DST_DIR}" "${_bitval}"
        cp -af "${PREIN_DIR}"/gcc_libs/mpc/mingw$_bitval "${DST_DIR}"
        echo 'done'
    done

    cd "${ROOT_DIR}"
    return 0
}
