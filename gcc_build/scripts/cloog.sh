# CLooG: Library that generates loops for scanning polyhedra
# Download the src and decompress it.
function download_cloog_src() {
    # Download the src.
    if [ ! -f ${BUILD_DIR}/gcc_libs/cloog/src/cloog-${CLOOG_VER}.tar.gz ]; then
        printf "===> Downloading CLooG %s...\n" $CLOOG_VER
        pushd ${BUILD_DIR}/gcc_libs/cloog/src > /dev/null
        dl_files http http://www.bastoul.net/cloog/pages/download/cloog-${CLOOG_VER}.tar.gz
        popd > /dev/null
        echo "done"
    fi

    # Decompress the src archive.
    if [ ! -d ${BUILD_DIR}/gcc_libs/cloog/src/cloog-$CLOOG_VER ]; then
        printf "===> Extracting CLooG %s...\n" $CLOOG_VER
        pushd ${BUILD_DIR}/gcc_libs/cloog/src > /dev/null
        decomp_arch ${BUILD_DIR}/gcc_libs/cloog/src/cloog-${CLOOG_VER}.tar.gz
        popd > /dev/null
        echo "done"
    fi

    return 0
}

# Apply patches and autoreconf.
function prepare_cloog() {
    # Apply patches.
    printf "===> Applying patches to CLooG %s...\n" $CLOOG_VER
    pushd ${BUILD_DIR}/gcc_libs/cloog/src/cloog-$CLOOG_VER > /dev/null
    if [ ! -f ${BUILD_DIR}/gcc_libs/cloog/src/cloog-${CLOOG_VER}/patched_01.marker ]; then
        # Combination of upstream commits b561f860, 2d8b7c6b and 22643c94.
        patch -p1 -i ${PATCHES_DIR}/cloog/0001-cloog-0.18.1-isl-compat.patch \
            > ${LOGS_DIR}/gcc_libs/cloog/cloog_patch.log 2>&1 || exit 1
        touch ${BUILD_DIR}/gcc_libs/cloog/src/cloog-${CLOOG_VER}/patched_01.marker
    fi
    if [ ! -f ${BUILD_DIR}/gcc_libs/cloog/src/cloog-${CLOOG_VER}/patched_02.marker ]; then
        patch -p1 -i ${PATCHES_DIR}/cloog/0002-cloog-0.18.1-no-undefined.patch \
            >> ${LOGS_DIR}/gcc_libs/cloog/cloog_patch.log 2>&1 || exit 1
        touch ${BUILD_DIR}/gcc_libs/cloog/src/cloog-${CLOOG_VER}/patched_02.marker
    fi
    echo "done"

    # Autoreconf.
    printf "===> Autoreconfing CLooG %s...\n" $CLOOG_VER
    autoreconf -fi > /dev/null 2>&1
    popd > /dev/null
    echo "done"

    return 0
}

# Build and install.
function build_cloog() {
    clear; printf "Build CLooG %s\n" $CLOOG_VER

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
                printf "build_cloog: Unknown Option: '%s'\n" $_opt
                echo "...exit"
                exit 1
                ;;
        esac
    done

    # Setup.
    if ${_rebuild}; then
        download_cloog_src
        prepare_cloog
    fi

    local _arch
    for _arch in ${TARGET_ARCH[@]}
    do
        local _bitval=$(get_arch_bit ${_arch})

        if ${_rebuild}; then
            cd ${BUILD_DIR}/gcc_libs/cloog/build_$_arch
            # Cleanup the build dir.
            rm -fr ${BUILD_DIR}/gcc_libs/cloog/build_${_arch}/{.*,*} > /dev/null 2>&1

            # PATH exporting.
            source cpath $_arch
            PATH=${DST_DIR}/mingw${_bitval}/bin:$PATH
            export PATH

            # Configure.
            printf "===> Configuring CLooG %s...\n" $_arch
            ../src/cloog-${CLOOG_VER}/configure                  \
                --prefix=/mingw$_bitval                          \
                --build=${_arch}-w64-mingw32                     \
                --host=${_arch}-w64-mingw32                      \
                --disable-silent-rules                           \
                --enable-shared                                  \
                --disable-static                                 \
                --enable-fast-install                            \
                --with-gnu-ld                                    \
                --with-{isl,gmp}=system                          \
                --with-{isl,gmp}-prefix=${DST_DIR}/mingw$_bitval \
                --with-osl=no                                    \
                CFLAGS="-march=${_arch/_/-} ${CFLAGS_}"          \
                LDFLAGS="${LDFLAGS_}"                            \
                CPPFLAGS="${CPPFLAGS_}"                          \
                > ${LOGS_DIR}/gcc_libs/cloog/cloog_config_${_arch}.log 2>&1 || exit 1
            echo "done"

            # Make.
            printf "===> Making CLooG %s...\n" $_arch
            make $MAKEFLAGS_ > ${LOGS_DIR}/gcc_libs/cloog/cloog_make_${_arch}.log 2>&1 || exit 1
            echo "done"

            # Install.
            printf "===> Installing CLooG %s...\n" $_arch
            make DESTDIR=${PREIN_DIR}/gcc_libs/cloog install \
                > ${LOGS_DIR}/gcc_libs/cloog/cloog_install_${_arch}.log 2>&1 || exit 1
            # Remove unneeded files.
            rm -f  ${PREIN_DIR}/gcc_libs/cloog/mingw${_bitval}/bin/*.exe
            rm -fr ${PREIN_DIR}/gcc_libs/cloog/mingw${_bitval}/lib/{cloog-isl,isl,pkgconfig}
            remove_empty_dirs ${PREIN_DIR}/gcc_libs/cloog/mingw$_bitval
            remove_la_files   ${PREIN_DIR}/gcc_libs/cloog/mingw$_bitval
            # Strip files.
            strip_files ${PREIN_DIR}/gcc_libs/cloog/mingw$_bitval
            echo "done"
        fi

        # Copy to DST_DIR.
        printf "===> copying CLooG %s to %s/mingw%s\n" $_arch $DST_DIR $_bitval
        cp -fra ${PREIN_DIR}/gcc_libs/cloog/mingw$_bitval $DST_DIR
        echo "done"
    done

    cd $ROOT_DIR
    return 0
}
