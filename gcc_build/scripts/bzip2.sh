# bzip2: A high-quality data compression program
# Download the src and decompress it.
function download_bzip2_src() {
    # Download the src.
    if [ ! -f ${BUILD_DIR}/bzip2/src/bzip2-${BZIP2_VER}.tar.gz ]; then
        printf "===> Downloading bzip2 %s...\n" $BZIP2_VER
        pushd ${BUILD_DIR}/bzip2/src > /dev/null
        dl_files http http://www.bzip.org/${BZIP2_VER}/bzip2-${BZIP2_VER}.tar.gz
        popd > /dev/null
        echo "done"
    fi

    # Decompress the src archive.
    if [ ! -d ${BUILD_DIR}/bzip2/src/bzip2-$BZIP2_VER ]; then
        printf "===> Extracting bzip2 %s...\n" $BZIP2_VER
        pushd ${BUILD_DIR}/bzip2/src > /dev/null
        decomp_arch ${BUILD_DIR}/bzip2/src/bzip2-${BZIP2_VER}.tar.gz
        popd > /dev/null
        echo "done"
    fi

    return 0
}

# Apply patches and autoreconf.
function prepare_bzip2() {
    # Apply patches.
    printf "===> Applying patches to bzip2 %s...\n" $BZIP2_VER
    pushd ${BUILD_DIR}/bzip2/src/bzip2-$BZIP2_VER > /dev/null
    if [ ! -f ${BUILD_DIR}/bzip2/src/bzip2-${BZIP2_VER}/patched_01.marker ]; then
        patch -p1 -i ${PATCHES_DIR}/bzip2/0001-bzip2-cygming-1.0.6.src.all.patch \
            > ${LOGS_DIR}/bzip2/bzip2_patch.log 2>&1 || exit 1
        touch ${BUILD_DIR}/bzip2/src/bzip2-${BZIP2_VER}/patched_01.marker
    fi
    if [ ! -f ${BUILD_DIR}/bzip2/src/bzip2-${BZIP2_VER}/patched_02.marker ]; then
        # Generate autotoolized configure.
        patch -p1 -i ${PATCHES_DIR}/bzip2/0002-bzip2-buildsystem.all.patch >> ${LOGS_DIR}/bzip2/bzip2_patch.log 2>&1 || exit 1
        touch ${BUILD_DIR}/bzip2/src/bzip2-${BZIP2_VER}/patched_02.marker
    fi
    echo "done"

    # Autoreconf.
    printf "===> Autoreconfing bzip2 %s...\n" $BZIP2_VER
    autoreconf -fi > /dev/null 2>&1
    popd > /dev/null
    echo "done"

    return 0
}

# Build and install.
function build_bzip2() {
    clear; printf "Build bzip2 %s\n" $BZIP2_VER

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
                printf "build_bzip2: Unknown Option: '%s'\n" $_opt
                echo "...exit"
                exit 1
                ;;
        esac
    done

    # Setup.
    if ${_rebuild}; then
        download_bzip2_src
        prepare_bzip2
    fi

    local _arch
    for _arch in ${TARGET_ARCH[@]}
    do
        local _bitval=$(get_arch_bit ${_arch})

        if ${_rebuild}; then
            cd ${BUILD_DIR}/bzip2/build_$_arch
            # Cleanup the build dir.
            rm -fr ${BUILD_DIR}/bzip2/build_${_arch}/*

            # PATH exporting.
            source cpath $_arch
            PATH=${DST_DIR}/mingw${_bitval}/bin:$PATH
            export PATH

            # Configure.
            printf "===> Configuring bzip2 %s...\n" $_arch
            ../src/bzip2-${BZIP2_VER}/configure                      \
                --prefix=/mingw$_bitval                              \
                --build=${_arch}-w64-mingw32                         \
                --host=${_arch}-w64-mingw32                          \
                --enable-shared                                      \
                CFLAGS="-march=${_arch/_/-} ${CFLAGS_} ${CPPFLAGS_}" \
                LDFLAGS="${CFLAGS_} ${LDFLAGS_}"                     \
                > ${LOGS_DIR}/bzip2/bzip2_config_${_arch}.log 2>&1 || exit 1
            echo "done"

            # Make.
            printf "===> Making bzip2 %s...\n" $_arch
            make $MAKEFLAGS_ all-dll-shared > ${LOGS_DIR}/bzip2/bzip2_make_${_arch}.log 2>&1 || exit 1
            echo "done"

            # Install.
            printf "===> Installing bzip2 %s...\n" $_arch
            make DESTDIR=${PREIN_DIR}/bzip2 install > ${LOGS_DIR}/bzip2/bzip2_install_${_arch}.log 2>&1 || exit 1
            # Remove unneeded files.
            rm -f  ${PREIN_DIR}/bzip2/mingw${_bitval}/bin/b*
            rm -f  ${PREIN_DIR}/bzip2/mingw${_bitval}/lib/libbz2.a
            rm -fr ${PREIN_DIR}/bzip2/mingw${_bitval}/share
            remove_empty_dirs ${PREIN_DIR}/bzip2/mingw$_bitval
            remove_la_files   ${PREIN_DIR}/bzip2/mingw$_bitval
            # Strip files.
            strip_files ${PREIN_DIR}/bzip2/mingw$_bitval
            echo "done"
        fi

        # Copy to DST_DIR.
        printf "===> Copying bzip2 %s to %s/mingw%s...\n" $_arch $DST_DIR $_bitval
        cp -fra ${PREIN_DIR}/bzip2/mingw$_bitval $DST_DIR
        echo "done"
    done

    cd $ROOT_DIR
    return 0
}
