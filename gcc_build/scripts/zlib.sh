# zlib: Compression library implementing the deflate compression method found in gzip and PKZIP
# Download the src and decompress it.
function apply_patch_z() {
    apply_patch "${1}" "${BUILD_DIR}"/zlib/src/zlib-$ZLIB_VER "${LOGS_DIR}"/zlib/zlib_patch.log "${2}"
}

function download_zlib_src() {
    # Git clone.
    if [ ! -d "${BUILD_DIR}"/zlib/src/zlib-$ZLIB_VER ]; then
        echo '===> Cloning zlib git repo...'
        pushd "${BUILD_DIR}"/zlib/src > /dev/null
        dl_files git https://github.com/Dead2/zlib-ng.git zlib-$ZLIB_VER
        popd > /dev/null # "${BUILD_DIR}"/zlib/src
        echo 'done'
    fi

    # Git pull.
    echo '===> Updating zlib git-repo...'
    pushd "${BUILD_DIR}"/zlib/src/zlib-$ZLIB_VER > /dev/null
    git clean -fdx > /dev/null 2>&1
    git reset --hard > /dev/null 2>&1
    git pull > /dev/null 2>&1
    git log -1 --format="%h" > "${LOGS_DIR}"/zlib/zlib.hash 2>&1
    git rev-list HEAD | wc -l >> "${LOGS_DIR}"/zlib/zlib.hash 2>&1
    echo 'done'

    # Apply patches.
    printf "===> Applying patches to zlib %s...\n" "${ZLIB_VER}"

    # Buildsystem of zlib-ng is useless.
    apply_patch_z "${PATCHES_DIR}"/zlib/0001-Improve-buildsystem-for-MinGW-w64.patch true
    # LFS
    apply_patch_z "${PATCHES_DIR}"/zlib/0002-Fix-LFS-on-MinGW-w64.patch              false
    # To build toolchain.
    apply_patch_z "${PATCHES_DIR}"/zlib/0003-Use-typedef-instead-of-define.patch     false

    popd > /dev/null # "${BUILD_DIR}"/zlib/src/zlib-$ZLIB_VER
    echo 'done'

    return 0
}

# Build and install.
function build_zlib() {
    clear; printf "Build zlib %s\n" "${ZLIB_VER}"

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
                printf "build_zlib: Unknown Option: '%s'\n" "${_opt}"
                echo '...exit'
                exit 1
                ;;
        esac
    done

    # Setup.
    if ${_rebuild}; then
        download_zlib_src
    fi

    local _arch
    for _arch in ${TARGET_ARCH[@]}
    do
        local _bitval=$(get_arch_bit ${_arch})

        if ${_rebuild}; then
            cd "${BUILD_DIR}"/zlib/build_$_arch
            # Cleanup the build dir.
            rm -fr "${BUILD_DIR}"/zlib/build_${_arch}/*

            # PATH exporting.
            set_path $_arch

            # Configure.
            printf "===> Configuring zlib %s...\n" "${_arch}"
            CFLAGS="${CFLAGS_} ${CPPFLAGS_}"  \
            LDFLAGS="${LDFLAGS_}"             \
            ../src/zlib-${ZLIB_VER}/configure \
                --prefix=/mingw$_bitval       \
                --enable-shared               \
                --disable-static              \
                > "${LOGS_DIR}"/zlib/libz_config_${_arch}.log 2>&1 || exit 1
            echo 'done'

            # Make.
            printf "===> Making zlib %s...\n" "${_arch}"
            make $MAKEFLAGS_ shared > "${LOGS_DIR}"/zlib/libz_make_${_arch}.log 2>&1 || exit 1
            echo 'done'

            # Install.
            printf "===> Installing zlib %s...\n" "${_arch}"
            make DESTDIR="${PREIN_DIR}"/zlib install > "${LOGS_DIR}"/zlib/libz_install_${_arch}.log 2>&1 || exit 1
            # Strip files.
            strip_files "${PREIN_DIR}"/zlib/mingw$_bitval
            echo 'done'
        fi

        # Copy to DST_DIR.
        printf "===> Copying zlib %s to %s/mingw%s...\n" "${_arch}" "${DST_DIR}" "${_bitval}"
        cp -af "${PREIN_DIR}"/zlib/mingw$_bitval "${DST_DIR}"
        echo 'done'
    done

    cd "${ROOT_DIR}"
    return 0
}
