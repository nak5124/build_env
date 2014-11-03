# zlib: Compression library implementing the deflate compression method found in gzip and PKZIP
# Download the src and decompress it.
function download_zlib_src() {
    # Download the src.
    if [ ! -f ${BUILD_DIR}/zlib/src/zlib-${ZLIB_VER}.tar.xz ]; then
        printf "===> Downloading zlib %s...\n" $ZLIB_VER
        pushd ${BUILD_DIR}/zlib/src > /dev/null
        dl_files http http://zlib.net/zlib-${ZLIB_VER}.tar.xz
        popd > /dev/null
        echo "done"
    fi

    # Decompress the src archive.
    if [ ! -d ${BUILD_DIR}/zlib/src/zlib-$ZLIB_VER ]; then
        printf "===> Extracting zlib %s...\n" $ZLIB_VER
        pushd ${BUILD_DIR}/zlib/src > /dev/null
        decomp_arch ${BUILD_DIR}/zlib/src/zlib-${ZLIB_VER}.tar.xz
        popd > /dev/null
        echo "done"
    fi

    return 0
}

# Apply patches.
function prepare_zlib() {
    # Apply patches.
    printf "===> Applying patches to zlib %s...\n" $ZLIB_VER
    pushd ${BUILD_DIR}/zlib/src/zlib-$ZLIB_VER > /dev/null
    if [ ! -f ${BUILD_DIR}/zlib/src/zlib-${ZLIB_VER}/patched_01.marker ]; then
        patch -p2 -i ${PATCHES_DIR}/zlib/0001-zlib-1.2.7-1-buildsys.mingw.patch \
            > ${LOGS_DIR}/zlib/zlib_patch.log 2>&1 || exit 1
        touch ${BUILD_DIR}/zlib/src/zlib-${ZLIB_VER}/patched_01.marker
    fi
    if [ ! -f ${BUILD_DIR}/zlib/src/zlib-${ZLIB_VER}/patched_02.marker ]; then
        patch -p2 -i ${PATCHES_DIR}/zlib/0002-no-undefined.mingw.patch >> ${LOGS_DIR}/zlib/zlib_patch.log 2>&1 || exit 1
        touch ${BUILD_DIR}/zlib/src/zlib-${ZLIB_VER}/patched_02.marker
    fi
    if [ ! -f ${BUILD_DIR}/zlib/src/zlib-${ZLIB_VER}/patched_03.marker ]; then
        patch -p2 -i ${PATCHES_DIR}/zlib/0003-dont-put-sodir-into-L.mingw.patch \
            >> ${LOGS_DIR}/zlib/zlib_patch.log 2>&1 || exit 1
        touch ${BUILD_DIR}/zlib/src/zlib-${ZLIB_VER}/patched_03.marker
    fi
    popd > /dev/null
    echo "done"

    return 0
}

# Build and install.
function build_zlib() {
    clear; printf "Build zlib %s\n" $ZLIB_VER

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
                printf "build_zlib: Unknown Option: '%s'\n" $_opt
                echo "...exit"
                exit 1
                ;;
        esac
    done

    # Setup.
    if ${_rebuild}; then
        download_zlib_src
        prepare_zlib
    fi

    local _arch
    for _arch in ${TARGET_ARCH[@]}
    do
        local _bitval=$(get_arch_bit ${_arch})

        if ${_rebuild}; then
            cd ${BUILD_DIR}/zlib/build_$_arch
            # Cleanup the build dir.
            rm -fr ${BUILD_DIR}/zlib/build_${_arch}/*
            # zlib cannot be built out of tree.
            cp -fra ${BUILD_DIR}/zlib/src/zlib-${ZLIB_VER}/* ${BUILD_DIR}/zlib/build_$_arch

            # PATH exporting.
            source cpath $_arch
            PATH=${DST_DIR}/mingw${_bitval}/bin:$PATH
            export PATH

            # Use an assembly code.
            # And for eh of i686 bins, which are built with MSVC.
            if [ "${_arch}" = "i686" ]; then
                cp -fa ${BUILD_DIR}/zlib/build_${_arch}/contrib/asm686/match.S      ${BUILD_DIR}/zlib/build_${_arch}/match.S
                local _slgcc="-static-libgcc"
            else
                cp -fa ${BUILD_DIR}/zlib/build_${_arch}/contrib/amd64/amd64-match.S ${BUILD_DIR}/zlib/build_${_arch}/match.S
                local _slgcc=""
            fi

            # Configure.
            printf "===> Configuring zlib %s...\n" $_arch
            CFLAGS="-march=${_arch/_/-} ${CFLAGS_} ${CPPFLAGS_}" \
            LDFLAGS="${LDFLAGS_} ${_slgcc}"                      \
            ./configure                                          \
                --prefix=/mingw$_bitval                          \
                --shared                                         \
                > ${LOGS_DIR}/zlib/libz_config_${_arch}.log 2>&1 || exit 1
            echo "done"

            # Make.
            printf "===> Making zlib %s...\n" $_arch
            make $MAKEFLAGS_ shared LOC=-DASMV OBJA=match.o > ${LOGS_DIR}/zlib/libz_make_${_arch}.log 2>&1 || exit 1
            echo "done"

            # Install.
            printf "===> Installing zlib %s...\n" $_arch
            make DESTDIR=${PREIN_DIR}/zlib install > ${LOGS_DIR}/zlib/libz_install_${_arch}.log 2>&1 || exit 1
            # Remove unneeded files.
            rm -f  ${PREIN_DIR}/zlib/mingw${_bitval}/lib/libz.a
            rm -fr ${PREIN_DIR}/zlib/mingw${_bitval}/share
            remove_empty_dirs ${PREIN_DIR}/zlib/mingw$_bitval
            remove_la_files   ${PREIN_DIR}/zlib/mingw$_bitval
            # Strip files.
            strip_files ${PREIN_DIR}/zlib/mingw$_bitval
            echo "done"
        fi

        # Copy to DST_DIR.
        printf "===> Copying zlib %s to %s/mingw%s...\n" $_arch $DST_DIR $_bitval
        cp -fra ${PREIN_DIR}/zlib/mingw$_bitval $DST_DIR
        echo "done"
    done

    cd $ROOT_DIR
    return 0
}
