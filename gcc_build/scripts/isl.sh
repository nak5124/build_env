# ISL: Library for manipulating sets and relations of integer points bounded by linear constraints
# Download the src and decompress it.
function download_isl_src() {
    # Download the src.
    if [ ! -f "${BUILD_DIR}"/gcc_libs/isl/src/isl-${ISL_VER}.tar.xz ]; then
        printf "===> Downloading ISL %s...\n" "${ISL_VER}"
        pushd "${BUILD_DIR}"/gcc_libs/isl/src > /dev/null
        dl_files http http://isl.gforge.inria.fr/isl-${ISL_VER}.tar.xz
        popd > /dev/null # "${BUILD_DIR}"/gcc_libs/isl/src
        echo 'done'
    fi

    # Decompress the src archive.
    if [ ! -d "${BUILD_DIR}"/gcc_libs/isl/src/isl-$ISL_VER ]; then
        printf "===> Extracting ISL %s...\n" "${ISL_VER}"
        pushd "${BUILD_DIR}"/gcc_libs/isl/src > /dev/null
        decomp_arch "${BUILD_DIR}"/gcc_libs/isl/src/isl-${ISL_VER}.tar.xz
        popd > /dev/null # "${BUILD_DIR}"/gcc_libs/isl/src
        echo 'done'
    fi

    return 0
}

# Apply patches and autoreconf.
function apply_patch_isl() {
    apply_patch "${1}" "${BUILD_DIR}"/gcc_libs/isl/src/isl-$ISL_VER "${LOGS_DIR}"/gcc_libs/isl/isl_patch.log "${2}"
}

function prepare_isl() {
    # Apply patches.
    printf "===> Applying patches to ISL %s...\n" "${ISL_VER}"

    # Add -no-undefined to libisl_la_LDFLAGS.
    apply_patch_isl "${PATCHES_DIR}"/isl/0001-isl-no-undefined.patch true

    echo 'done'

    # Autoreconf.
    printf "===> Autoreconfing ISL %s...\n" "${ISL_VER}"
    pushd "${BUILD_DIR}"/gcc_libs/isl/src/isl-$ISL_VER > /dev/null
    autoreconf -fis > /dev/null 2>&1
    popd > /dev/null # "${BUILD_DIR}"/gcc_libs/isl/src/isl-$ISL_VER
    echo 'done'

    return 0
}

# Build and install.
function build_isl() {
    clear; printf "Build ISL %s\n" "${ISL_VER}"

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
                printf "build_isl: Unknown Option: '%s'\n" "${_opt}"
                echo '...exit'
                exit 1
                ;;
        esac
    done

    # Setup.
    if ${_rebuild}; then
        download_isl_src
        prepare_isl
    fi

    local _arch
    for _arch in ${TARGET_ARCH[@]}
    do
        local _bitval=$(get_arch_bit ${_arch})

        if ${_rebuild}; then
            cd "${BUILD_DIR}"/gcc_libs/isl/build_$_arch
            # Cleanup the build dir.
            rm -fr "${BUILD_DIR}"/gcc_libs/isl/build_${_arch}/{.*,*} > /dev/null 2>&1

            # PATH exporting.
            set_path $_arch

            # Configure.
            printf "===> Configuring ISL %s...\n" "${_arch}"
            ../src/isl-${ISL_VER}/configure                  \
                --prefix=/mingw$_bitval                      \
                --build=${_arch}-w64-mingw32                 \
                --host=${_arch}-w64-mingw32                  \
                --disable-silent-rules                       \
                --enable-shared                              \
                --disable-static                             \
                --enable-fast-install                        \
                --with-gnu-ld                                \
                --with-int=gmp                               \
                --with-gmp=system                            \
                --with-gmp-prefix="${DST_DIR}"/mingw$_bitval \
                --with-clang=no                              \
                CFLAGS="${CFLAGS_}"                          \
                LDFLAGS="${LDFLAGS_}"                        \
                CPPFLAGS="${CPPFLAGS_}"                      \
                CXXFLAGS="${CXXFLAGS_}"                      \
                > "${LOGS_DIR}"/gcc_libs/isl/isl_config_${_arch}.log 2>&1 || exit 1
            echo 'done'

            # Make.
            printf "===> Making ISL %s\n" "${_arch}"
            make $MAKEFLAGS_ > "${LOGS_DIR}"/gcc_libs/isl/isl_make_${_arch}.log 2>&1 || exit 1
            echo 'done'

            # Install.
            printf "===> Installing ISL %s...\n" "${_arch}"
            make DESTDIR="${PREIN_DIR}"/gcc_libs/isl install \
                > "${LOGS_DIR}"/gcc_libs/isl/isl_install_${_arch}.log 2>&1 || exit 1
            # Remove unneeded files.
            rm -f  "${PREIN_DIR}"/gcc_libs/isl/mingw${_bitval}/lib/*.py
            rm -fr "${PREIN_DIR}"/gcc_libs/isl/mingw${_bitval}/lib/pkgconfig
            remove_la_files   "${PREIN_DIR}"/gcc_libs/isl/mingw$_bitval
            # Strip files.
            strip_files "${PREIN_DIR}"/gcc_libs/isl/mingw$_bitval
            echo 'done'
        fi

        # Copy to DST_DIR.
        printf "===> Copying ISL %s to %s/mingw%s...\n" "${_arch}" "${DST_DIR}" "${_bitval}"
        cp -af "${PREIN_DIR}"/gcc_libs/isl/mingw$_bitval "${DST_DIR}"
        echo 'done'

        # Copy logs
        printf "===> Copying ISL %s logs to %s/mingw%s/logs...\n" "${_arch}" "${DST_DIR}" "${_bitval}"
        mkdir -p "${DST_DIR}"/mingw${_bitval}/logs/gcc_libs/isl
        cp -af "${LOGS_DIR}"/gcc_libs/isl/*${_arch}*    "${DST_DIR}"/mingw${_bitval}/logs/gcc_libs/isl
        cp -af "${LOGS_DIR}"/gcc_libs/isl/isl_patch.log "${DST_DIR}"/mingw${_bitval}/logs/gcc_libs/isl
        echo 'done'
    done

    cd "${ROOT_DIR}"
    return 0
}
