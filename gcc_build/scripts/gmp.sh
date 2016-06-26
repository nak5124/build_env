# GMP: A free library for arbitrary precision arithmetic
# Download the src and decompress it.
function download_gmp_src() {
    # Download the src.
    if [ ! -f "${BUILD_DIR}"/gcc_libs/gmp/src/gmp-${GMP_VER}.tar.lz ]; then
        printf "===> Downloading GMP %s...\n" "${GMP_VER}"
        pushd "${BUILD_DIR}"/gcc_libs/gmp/src > /dev/null
        dl_files ftp ftp://ftp.gmplib.org/pub/gmp/gmp-${GMP_VER}.tar.lz
        popd > /dev/null # "${BUILD_DIR}"/gcc_libs/gmp/src
        echo 'done'
    fi

    # Decompress the src archive.
    if [ ! -d "${BUILD_DIR}"/gcc_libs/gmp/src/gmp-$GMP_VER ]; then
        printf "===> Extracting GMP %s...\n" "${GMP_VER}"
        pushd "${BUILD_DIR}"/gcc_libs/gmp/src > /dev/null
        decomp_arch "${BUILD_DIR}"/gcc_libs/gmp/src/gmp-${GMP_VER}.tar.lz
        popd > /dev/null # "${BUILD_DIR}"/gcc_libs/gmp/src
        echo 'done'
    fi

    return 0
}

# Apply patches and autoreconf.
function apply_patch_gmp() {
    apply_patch "${1}" "${BUILD_DIR}"/gcc_libs/gmp/src/gmp-$GMP_VER "${LOGS_DIR}"/gcc_libs/gmp/gmp_patch.log "${2}"
}

function prepare_gmp() {
    # Applay the patch.
#    printf "===> Applaying the patch to GMP %s...\n" "${GMP_VER}"


#    echo 'done'

    # Autoreconf.
    printf "===> Autoreconfing GMP %s...\n" "${GMP_VER}"
    pushd "${BUILD_DIR}"/gcc_libs/gmp/src/gmp-$GMP_VER > /dev/null
    autoreconf -is > /dev/null 2>&1
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

            # MPN_PATH
            local _mpn_path
            if [ "${_arch}" = 'i686' ]; then
                _mpn_path=' x86/coreisbr x86/p6/sse2 x86/p6/p3mmx x86/p6/mmx x86/p6 x86/mmx x86/fat x86 generic'
            else
                _mpn_path=' x86_64/skylake x86_64/coreibwl x86_64/coreihwl x86_64/fastavx x86_64/coreisbr x86_64/coreinhm x86_64/core2 x86_64/fastsse x86_64/fat x86_64 generic'
            fi

            # Configure.
            printf "===> Configuring GMP %s...\n" "${_arch}"
            ../src/gmp-${GMP_VER}/configure  \
                --prefix=/mingw$_bitval      \
                --build=${_arch}-w64-mingw32 \
                --host=${_arch}-w64-mingw32  \
                --disable-silent-rules       \
                --disable-cxx                \
                --enable-shared              \
                --disable-static             \
                --enable-fast-install        \
                --with-gnu-ld                \
                --enable-assembly            \
                --enable-fft                 \
                --enable-fat                 \
                CFLAGS="${CFLAGS_}"          \
                LDFLAGS="${LDFLAGS_}"        \
                CPPFLAGS="${CPPFLAGS_}"      \
                CXXFLAGS="${CXXFLAGS_}"      \
                > "${LOGS_DIR}"/gcc_libs/gmp/gmp_config_${_arch}.log 2>&1 || exit 1
            echo 'done'


                # MPN_PATH="${_mpn_path}"      \


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

        # Copy logs
        printf "===> Copying GMP %s logs to %s/mingw%s/logs...\n" "${_arch}" "${DST_DIR}" "${_bitval}"
        mkdir -p "${DST_DIR}"/mingw${_bitval}/logs/gcc_libs/gmp
        cp -af "${LOGS_DIR}"/gcc_libs/gmp/*${_arch}*    "${DST_DIR}"/mingw${_bitval}/logs/gcc_libs/gmp
        cp -af "${LOGS_DIR}"/gcc_libs/gmp/gmp_patch.log "${DST_DIR}"/mingw${_bitval}/logs/gcc_libs/gmp
        echo 'done'
    done

    cd "${ROOT_DIR}"
    return 0
}
