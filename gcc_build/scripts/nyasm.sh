# NASM: An 80x86 assembler designed for portability and modularity
# Download the src and decompress it.
function download_nasm_src() {
    local _nasm_ver
    if [ ! -z "${NASM_SS}" ]; then
        _nasm_ver=${NASM_VER}-$NASM_SS
    else
        _nasm_ver=$NASM_VER
    fi

    # Download the src.
    if [ ! -f ${BUILD_DIR}/nyasm/nasm/src/nasm-${NASM_VER}.tar.xz ]; then
        printf "===> Downloading NASM %s...\n" $NASM_VER
        pushd ${BUILD_DIR}/nyasm/nasm/src > /dev/null
        if [ ! -z "${NASM_SS}" ]; then
            dl_files http http://www.nasm.us/pub/nasm/snapshots/${NASM_SS}/nasm-${NASM_VER}-${NASM_SS}.tar.xz
        else
            dl_files http http://www.nasm.us/pub/nasm/releasebuilds/${NASM_VER}/nasm-${NASM_VER}.tar.xz
        fi
        popd > /dev/null
        echo "done"
    fi

    # Decompress the src archive.
    if [ ! -d ${BUILD_DIR}/nyasm/nasm/src/nasm-$_nasm_ver ]; then
        printf "===> Extracting NASM %s...\n" $NASM_VER
        pushd ${BUILD_DIR}/nyasm/nasm/src > /dev/null
        decomp_arch ${BUILD_DIR}/nyasm/nasm/src/nasm-${_nasm_ver}.tar.xz
        popd > /dev/null
        echo "done"
    fi

    return 0
}

# Apply patches.
function prepare_nasm() {
    # Apply patches.
    printf "===> Applying patches to NASM %s...\n" $NASM_VER
    local _nasm_ver
    if [ ! -z "${NASM_SS}" ]; then
        _nasm_ver=${NASM_VER}-$NASM_SS
    else
        _nasm_ver=$NASM_VER
    fi
    pushd ${BUILD_DIR}/nyasm/nasm/src/nasm-$_nasm_ver > /dev/null
    if [ ! -f ${BUILD_DIR}/nyasm/nasm/src/nasm-${_nasm_ver}/patched_01.marker ]; then
        patch -p1 -i ${PATCHES_DIR}/nasm/0001-mingw-printf.patch > ${LOGS_DIR}/nyasm/nasm/nasm_patch.log 2>&1 || exit 1
        touch ${BUILD_DIR}/nyasm/nasm/src/nasm-${_nasm_ver}/patched_01.marker
    fi
    popd > /dev/null
    echo "done"

    return 0
}

# Build and install.
function build_nasm() {
    clear; printf "Build NASM %s\n" $NASM_VER

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
                printf "build_nasm: Unknown Option: '%s'\n" $_opt
                echo "...exit"
                exit 1
                ;;
        esac
    done

    # Setup.
    if ${_rebuild}; then
        download_nasm_src
        prepare_nasm
    fi

    local _nasm_ver
    if [ ! -z "${NASM_SS}" ]; then
        _nasm_ver=${NASM_VER}-$NASM_SS
    else
        _nasm_ver=$NASM_VER
    fi

    local _arch
    for _arch in ${TARGET_ARCH[@]}
    do
        local _bitval=$(get_arch_bit ${_arch})

        if ${_rebuild}; then
            cd ${BUILD_DIR}/nyasm/nasm/build_$_arch
            # Cleanup the build dir.
            rm -fr ${BUILD_DIR}/nyasm/nasm/build_${_arch}/*
            # NASM cannot be built out of tree.
            cp -fra ${BUILD_DIR}/nyasm/nasm/src/nasm-${_nasm_ver}/* ${BUILD_DIR}/nyasm/nasm/build_$_arch

            # PATH exporting.
            source cpath $_arch
            PATH=${DST_DIR}/mingw${_bitval}/bin:$PATH
            export PATH

            # Use the new GCC for 2nd build
            CC=${DST_DIR}/mingw${_bitval}/bin/gcc-${GCC_VER/-*}
            CPP=${DST_DIR}/mingw${_bitval}/bin/cpp-${GCC_VER/-*}
            CXX=${DST_DIR}/mingw${_bitval}/bin/g++-${GCC_VER/-*}
            export CC CPP CXX

            # Autoreconf.
            autoreconf -fi > /dev/null 2>&1

            # Configure.
            printf "===> Configuring NASM %s...\n" $_arch
            ./configure                          \
                --prefix=/mingw$_bitval          \
                --build=${_arch}-w64-mingw32     \
                --host=${_arch}-w64-mingw32      \
                CFLAGS="${CFLAGS_} ${CPPFLAGS_}" \
                LDFLAGS="${CFLAGS_} ${LDFLAGS_}" \
                > ${LOGS_DIR}/nyasm/nasm/nasm_config_${_arch}.log 2>&1 || exit 1
            echo "done"

            # Make.
            printf "===> Making NASM %s...\n" $_arch
            # Setting -j$(($(nproc)+1)) sometimes makes error.
            make > ${LOGS_DIR}/nyasm/nasm/nasm_make_${_arch}.log 2>&1 || exit 1
            echo "done"

            # Install.
            printf "===> Installing NASM %s...\n" $_arch
            # NASM doesn't use DESTDIR but INSTALLROOT.
            make INSTALLROOT=${PREIN_DIR}/nyasm/nasm install > ${LOGS_DIR}/nyasm/nasm/nasm_install_${_arch}.log 2>&1 || exit 1
            # Remove unneeded files.
            rm -f ${PREIN_DIR}/nyasm/nasm/mingw${_bitval}/bin/ndisasm.exe
            rm -f ${PREIN_DIR}/nyasm/nasm/mingw${_bitval}/share/man/man1/ndisasm.1
            remove_empty_dirs ${PREIN_DIR}/nyasm/nasm/mingw$_bitval
            remove_la_files   ${PREIN_DIR}/nyasm/nasm/mingw$_bitval
            # Strip files.
            strip_files ${PREIN_DIR}/nyasm/nasm/mingw$_bitval
            echo "done"
        fi

        # Copy to DST_DIR.
        printf "===> Copying NASM %s to %s/mingw%s...\n" $_arch $DST_DIR $_bitval
        cp -fra ${PREIN_DIR}/nyasm/nasm/mingw$_bitval $DST_DIR
        echo "done"
    done

    cd $ROOT_DIR
    return 0
}

# Yasm: A rewrite of NASM to allow for multiple syntax supported (NASM, TASM, GAS, etc.)
# Download the src and decompress it.
function download_yasm_src() {
    # Download the src.
    if [ ! -f ${BUILD_DIR}/nyasm/yasm/src/yasm-${YASM_VER}.tar.gz ]; then
        printf "===> Downloading Yasm %s...\n" $YASM_VER
        pushd ${BUILD_DIR}/nyasm/yasm/src > /dev/null
        dl_files http http://www.tortall.net/projects/yasm/releases/yasm-${YASM_VER}.tar.gz
        popd > /dev/null
        echo "done"
    fi

    # Decompress the src archive.
    if [ ! -d ${BUILD_DIR}/nyasm/yasm/src/yasm-$YASM_VER ]; then
        printf "===> Extracting Yasm %s...\n" $YASM_VER
        pushd ${BUILD_DIR}/nyasm/yasm/src > /dev/null
        decomp_arch ${BUILD_DIR}/nyasm/yasm/src/yasm-${YASM_VER}.tar.gz
        popd > /dev/null
        echo "done"
    fi

    return 0
}

# Autoreconf.
function prepare_yasm() {
    # Autoreconf.
    printf "===> Autoreconfing Yasm %s...\n" $YASM_VER
    pushd ${BUILD_DIR}/nyasm/yasm/src/yasm-$YASM_VER > /dev/null
    autoreconf -fi > /dev/null 2>&1
    popd > /dev/null
    echo "done"

    return 0
}

# Build and install.
function build_yasm() {
    clear; printf "Build Yasm %s\n" $YASM_VER

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
                printf "build_yasm: Unknown Option: '%s'\n" $_opt
                echo "...exit"
                exit 1
                ;;
        esac
    done

    # Setup.
    if ${_rebuild}; then
        download_yasm_src
        prepare_yasm
    fi

    local _arch
    for _arch in ${TARGET_ARCH[@]}
    do
        local _bitval=$(get_arch_bit ${_arch})

        if ${_rebuild}; then
            cd ${BUILD_DIR}/nyasm/yasm/build_$_arch
            # Cleanup the build dir.
            rm -fr ${BUILD_DIR}/nyasm/yasm/build_${_arch}/*

            # PATH exporting.
            source cpath $_arch
            PATH=${DST_DIR}/mingw${_bitval}/bin:$PATH
            export PATH

            # Use the new GCC for 2nd build
            CC=${DST_DIR}/mingw${_bitval}/bin/gcc-${GCC_VER/-*}
            CPP=${DST_DIR}/mingw${_bitval}/bin/cpp-${GCC_VER/-*}
            CXX=${DST_DIR}/mingw${_bitval}/bin/g++-${GCC_VER/-*}
            export CC CPP CXX

            # Configure.
            printf "===> Configuring Yasm %s...\n" $_arch
            ../src/yasm-${YASM_VER}/configure \
                --prefix=/mingw$_bitval       \
                --build=${_arch}-w64-mingw32  \
                --host=${_arch}-w64-mingw32   \
                --disable-silent-rules        \
                --with-gnu-ld                 \
                CFLAGS="${CFLAGS_}"           \
                LDFLAGS="${LDFLAGS_}"         \
                CPPFLAGS="${CPPFLAGS_}"       \
                > ${LOGS_DIR}/nyasm/yasm/yasm_config_${_arch}.log 2>&1 || exit 1
            echo "done"

            # Make.
            printf "===> Making Yasm %s...\n" $_arch
            make $MAKEFLAGS_ > ${LOGS_DIR}/nyasm/yasm/yasm_make_${_arch}.log 2>&1 || exit 1
            echo "done"

            # Install.
            printf "===> Installing Yasm %s...\n" $_arch
            make DESTDIR=${PREIN_DIR}/nyasm/yasm install > ${LOGS_DIR}/nyasm/yasm/yasm_install_${_arch}.log 2>&1 || exit 1
            # Remove unneeded files.
            rm -f  ${PREIN_DIR}/nyasm/yasm/mingw${_bitval}/bin/{vsyasm.exe,ytasm.exe}
            rm -fr ${PREIN_DIR}/nyasm/yasm/mingw${_bitval}/lib
            rm -fr ${PREIN_DIR}/nyasm/yasm/mingw${_bitval}/include
            rm -fr ${PREIN_DIR}/nyasm/yasm/mingw${_bitval}/share/man/man7
            remove_empty_dirs ${PREIN_DIR}/nyasm/yasm/mingw$_bitval
            remove_la_files   ${PREIN_DIR}/nyasm/yasm/mingw$_bitval
            # Strip files.
            strip_files ${PREIN_DIR}/nyasm/yasm/mingw$_bitval
            echo "done"
        fi

        # Copy to DST_DIR.
        printf "===> Copying Yasm %s to %s/mingw%s...\n" $_arch $DST_DIR $_bitval
        cp -fra ${PREIN_DIR}/nyasm/yasm/mingw$_bitval $DST_DIR
        echo "done"
    done

    cd $ROOT_DIR
    return 0
}
