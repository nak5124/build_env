# MinGW-w64 common
# Clone git repo, git pull and autoreconf.
function prepare_mingw_w64() {
    clear; printf "Prepare MinGW-w64 %s\n" $MINGW_VER

    # Git clone.
    if [ ! -d ${BUILD_DIR}/mingw-w64/src/mingw-w64-$MINGW_VER ]; then
        echo "===> Cloning MinGW-w64 git repo..."
        pushd ${BUILD_DIR}/mingw-w64/src > /dev/null
        dl_files git http://git.code.sf.net/p/mingw-w64/mingw-w64 mingw-w64-$MINGW_VER
        popd > /dev/null
        echo "done"
    fi

    # Git pull.
    echo "===> Updating MinGW-w64 git-repo..."
    pushd ${BUILD_DIR}/mingw-w64/src/mingw-w64-$MINGW_VER > /dev/null
    git clean -fdx > /dev/null 2>&1
    git reset --hard > /dev/null 2>&1
    git pull > /dev/null 2>&1
    git_hash > ${LOGS_DIR}/mingw-w64/mingw-w64.hash 2>&1
    git_rev >> ${LOGS_DIR}/mingw-w64/mingw-w64.hash 2>&1
    echo "done"

    # Apply a patch
    printf "===> Applying patches to MinGW-w64 %s...\n" $MINGW_VER
    patch -p1 -i ${PATCHES_DIR}/winpthreads/0001-winpthreads-dont-use-fakelibs.patch \
        > ${LOGS_DIR}/mingw-w64/mingw-w64_patch.log 2>&1 || exit 1
    patch -p1 -i ${PATCHES_DIR}/headers/0001-Revert-time.h-Restore-POSIX-guards-around-_r-functio.patch \
        >> ${LOGS_DIR}/mingw-w64/mingw-w64_patch.log 2>&1 || exit 1
    patch -p1 -i ${PATCHES_DIR}/headers/0002-Add-strerror_r.patch >> ${LOGS_DIR}/mingw-w64/mingw-w64_patch.log 2>&1 || exit 1
    patch -p1 -i ${PATCHES_DIR}/crt/0001-Add-libmsvcr120.patch >> ${LOGS_DIR}/mingw-w64/mingw-w64_patch.log 2>&1 || exit 1
    echo "done"

    # Autoreconf.
    printf "===> Autoreconfing MinGW-w64 %s...\n" $MINGW_VER
    cd ${BUILD_DIR}/mingw-w64/src/mingw-w64-${MINGW_VER}/mingw-w64-headers
    autoreconf -fi > /dev/null 2>&1
    cd ${BUILD_DIR}/mingw-w64/src/mingw-w64-${MINGW_VER}/mingw-w64-crt
    autoreconf -fi > /dev/null 2>&1
    cd ${BUILD_DIR}/mingw-w64/src/mingw-w64-${MINGW_VER}/mingw-w64-libraries/winpthreads
    autoreconf -fi > /dev/null 2>&1
    cd ${BUILD_DIR}/mingw-w64/src/mingw-w64-${MINGW_VER}/mingw-w64-libraries/libmangle
    autoreconf -fi > /dev/null 2>&1
    cd ${BUILD_DIR}/mingw-w64/src/mingw-w64-${MINGW_VER}/mingw-w64-tools/gendef
    autoreconf -fi > /dev/null 2>&1
    cd ${BUILD_DIR}/mingw-w64/src/mingw-w64-${MINGW_VER}/mingw-w64-tools/genpeimg
    autoreconf -fi > /dev/null 2>&1
    popd > /dev/null
    echo "done"

    return 0
}

# headers: MinGW-w64 headers for Windows
# Build and install.
function build_headers() {
    clear; printf "Build MinGW-w64 headers %s\n" $MINGW_VER

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
                printf "build_headers: Unknown Option: '%s'\n" $_opt
                echo "...exit"
                exit 1
                ;;
        esac
    done

    local _arch
    for _arch in ${TARGET_ARCH[@]}
    do
        local _bitval=$(get_arch_bit ${_arch})

        if ${_rebuild}; then
            cd ${BUILD_DIR}/mingw-w64/headers/build_$_arch
            # Cleanup the build dir.
            rm -fr ${BUILD_DIR}/mingw-w64/headers/build_${_arch}/*

            # PATH exporting.
            source cpath $_arch
            PATH=${DST_DIR}/mingw${_bitval}/bin:$PATH
            export PATH

            # Configure.
            printf "===> Configuring MinGW-w64 headers %s...\n" $_arch
            ../../src/mingw-w64-${MINGW_VER}/mingw-w64-headers/configure \
                --prefix=/mingw${_bitval}/${_arch}-w64-mingw32           \
                --build=${_arch}-w64-mingw32                             \
                --host=${_arch}-w64-mingw32                              \
                --enable-sdk=all                                         \
                --enable-secure-api                                      \
                > ${LOGS_DIR}/mingw-w64/headers/headers_config_${_arch}.log 2>&1 || exit 1
            echo "done"

            # Install.
            printf "===> Installing MinGW-w64 headers %s...\n" $_arch
            make DESTDIR=${PREIN_DIR}/mingw-w64/headers install \
                > ${LOGS_DIR}/mingw-w64/headers/headers_install_${_arch}.log 2>&1 || exit 1
            # These headers are replaced by winpthreads.
            rm -f ${PREIN_DIR}/mingw-w64/headers/mingw${_bitval}/${_arch}-w64-mingw32/include/pthread*.h
            echo "done"
        fi

        # Copy to DST_DIR.
        printf "===> Copying MinGW-w64 headers %s to %s/mingw%s...\n" $_arch $DST_DIR $_bitval
        cp -fra ${PREIN_DIR}/mingw-w64/headers/mingw$_bitval $DST_DIR
        echo "done"
    done

    cd $ROOT_DIR
    return 0
}

# winpthreads: MinGW-w64 winpthreads library
# Build and install.
function build_threads() {
    clear; printf "Build MinGW-w64 winpthreads %s\n" $MINGW_VER

    # Option handling.
    local _rebuild=true
    local _2nd_build=false

    local _opt
    for _opt in "${@}"
    do
        case "${_opt}" in
            --rebuild=* )
                _rebuild="${_opt#*=}"
                ;;
            --2nd )
                _2nd_build=true
                ;;
            * )
                printf "build_threads: Unknown Option: '%s'... exit\n" $_opt
                exit 1
                ;;
        esac
    done

    local _arch
    for _arch in ${TARGET_ARCH[@]}
    do
        local _bitval=$(get_arch_bit ${_arch})

        if ${_rebuild}; then
            cd ${BUILD_DIR}/mingw-w64/winpthreads/build_$_arch
            # Cleanup the build dir.
            rm -fr ${BUILD_DIR}/mingw-w64/winpthreads/build_${_arch}/{.*,*} > /dev/null 2>&1

            # PATH exporting.
            source cpath $_arch
            PATH=${DST_DIR}/mingw${_bitval}/bin:$PATH
            export PATH

            # Don't pass -fstack-protector* to CFLAGS.
            local _cflags="${CFLAGS_/-fstack-protector-strong --param=ssp-buffer-size=4/}"

            # Configure.
            printf "===> Configuring MinGW-w64 winpthreads %s...\n" $_arch
            ../../src/mingw-w64-${MINGW_VER}/mingw-w64-libraries/winpthreads/configure \
                --prefix=/mingw${_bitval}/${_arch}-w64-mingw32                         \
                --build=${_arch}-w64-mingw32                                           \
                --host=${_arch}-w64-mingw32                                            \
                --disable-silent-rules                                                 \
                --enable-shared                                                        \
                --enable-static                                                        \
                --enable-fast-install                                                  \
                --with-gnu-ld                                                          \
                --with-sysroot=${DST_DIR}/mingw${_bitval}/${_arch}-w64-mingw32         \
                CFLAGS="${_cflags}"                                                    \
                LDFLAGS="${LDFLAGS_}"                                                  \
                > ${LOGS_DIR}/mingw-w64/winpthreads/winpthreads_config_${_arch}.log 2>&1 || exit 1
            echo "done"

            # Make.
            printf "===> Making MinGW-w64 winpthreads %s...\n" $_arch
            make $MAKEFLAGS_ > ${LOGS_DIR}/mingw-w64/winpthreads/winpthreads_make_${_arch}.log 2>&1 || exit 1
            echo "done"

            # Install.
            printf "===> Installing MinGW-w64 winpthreads %s...\n" $_arch
            make DESTDIR=${PREIN_DIR}/mingw-w64/winpthreads install \
                > ${LOGS_DIR}/mingw-w64/winpthreads/winpthreads_install_${_arch}.log 2>&1 || exit 1
            # Relocate DLL.
            mkdir -p ${PREIN_DIR}/mingw-w64/winpthreads/mingw${_bitval}/bin
            mv -f ${PREIN_DIR}/mingw-w64/winpthreads/mingw${_bitval}/${_arch}-w64-mingw32/bin/*.dll \
                ${PREIN_DIR}/mingw-w64/winpthreads/mingw${_bitval}/bin
            # Remove unneeded files.
            remove_empty_dirs ${PREIN_DIR}/mingw-w64/winpthreads/mingw$_bitval
            remove_la_files   ${PREIN_DIR}/mingw-w64/winpthreads/mingw$_bitval
            # Strip files.
            strip_files ${PREIN_DIR}/mingw-w64/winpthreads/mingw$_bitval
            echo "done"
        fi

        if ! ( ! ${_rebuild} && ${_2nd_build} ); then
            # Copy to DST_DIR.
            printf "===> Copying MinGW-w64 winpthreads %s to %s/mingw%s...\n" $_arch $DST_DIR $_bitval
            cp -fra ${PREIN_DIR}/mingw-w64/winpthreads/mingw$_bitval $DST_DIR
            echo "done"
        fi
    done

    cd $ROOT_DIR
    return 0
}

# crt: MinGW-w64 CRT for Windows
# Build and install.
function build_crt() {
    clear; printf "Build MinGW-w64 crt %s\n" $MINGW_VER

    # Option handling.
    local _rebuild=true
    local _2nd_build=false

    local _opt
    for _opt in "${@}"
    do
        case "${_opt}" in
            --rebuild=* )
                _rebuild="${_opt#*=}"
                ;;
            --2nd )
                _2nd_build=true
                ;;
            * )
                printf "build_crt: Unknown Option: '%s'... exit\n" $_opt
                exit 1
                ;;
        esac
    done

    local _arch
    for _arch in ${TARGET_ARCH[@]}
    do
        local _bitval=$(get_arch_bit ${_arch})

        if ${_rebuild}; then
            cd ${BUILD_DIR}/mingw-w64/crt/build_$_arch
            # Cleanup the build dir.
            rm -fr ${BUILD_DIR}/mingw-w64/crt/build_${_arch}/{.*,*} > /dev/null 2>&1

            # PATH exporting.
            source cpath $_arch
            PATH=${DST_DIR}/mingw${_bitval}/bin:$PATH
            export PATH

            # Arch specific config option.
            if [ "${_arch}" = "i686" ]; then
                local _libs_conf="--enable-lib32 --disable-lib64"
            else
                local _libs_conf="--disable-lib32 --enable-lib64"
            fi
            # Don't pass -fstack-protector* to CFLAGS/CXXFLAGS.
            local _cflags="${CFLAGS_/-fstack-protector-strong --param=ssp-buffer-size=4/}"
            local _cxxflags="${CXXFLAGS_/-fstack-protector-strong --param=ssp-buffer-size=4/}"

            # Configure.
            printf "===> Configuring MinGW-w64 crt %s...\n" $_arch
            ../../src/mingw-w64-${MINGW_VER}/mingw-w64-crt/configure           \
                --prefix=/mingw${_bitval}/${_arch}-w64-mingw32                 \
                --build=${_arch}-w64-mingw32                                   \
                --host=${_arch}-w64-mingw32                                    \
                --disable-silent-rules                                         \
                ${_libs_conf}                                                  \
                --disable-libarm32                                             \
                --enable-wildcard                                              \
                --enable-warnings=2                                            \
                --with-sysroot=${DST_DIR}/mingw${_bitval}/${_arch}-w64-mingw32 \
                CFLAGS="${_cflags}"                                            \
                LDFLAGS="${LDFLAGS_}"                                          \
                CXXFLAGS="${_cxxflags}"                                        \
                > ${LOGS_DIR}/mingw-w64/crt/crt_config_${_arch}.log 2>&1 || exit 1
            echo "done"

            # Make.
            printf "===> Making MinGW-w64 crt %s...\n" $_arch
            # Setting -j$(($(nproc)+1)) sometimes makes error.
            make > ${LOGS_DIR}/mingw-w64/crt/crt_make_${_arch}.log 2>&1 || exit 1
            echo "done"

            # Install.
            printf "===> Installing MinGW-w64 crt %s...\n" $_arch
            # MinGW-w64 crt has many files, so not using strip_files but install-strip.
            make DESTDIR=${PREIN_DIR}/mingw-w64/crt install-strip \
                > ${LOGS_DIR}/mingw-w64/crt/crt_install_${_arch}.log 2>&1 || exit 1
            echo "done"
        fi

        if ! ( ! ${_rebuild} && ${_2nd_build} ); then
            # Copy to DST_DIR.
            printf "===> Copying MinGW-w64 crt %s to %s/mingw%s...\n" $_arch $DST_DIR $_bitval
            cp -fra ${PREIN_DIR}/mingw-w64/crt/mingw$_bitval $DST_DIR
            echo "done"
        fi
    done

    cd $ROOT_DIR
    return 0
}

# libmangle: MinGW-w64 libmangle
# Build and install.
function build_mangle() {
    clear; printf "Build MinGW-w64 libmangle %s\n" $MINGW_VER

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
                printf "build_mangle: Unknown Option: '%s'... exit\n" $_opt
                exit 1
                ;;
        esac
    done

    local _arch
    for _arch in ${TARGET_ARCH[@]}
    do
        local _bitval=$(get_arch_bit ${_arch})

        if ${_rebuild}; then
            cd ${BUILD_DIR}/mingw-w64/libmangle/build_$_arch
            # Cleanup the build dir.
            rm -fr ${BUILD_DIR}/mingw-w64/libmangle/build_${_arch}/*

            # PATH exporting.
            source cpath $_arch
            PATH=${DST_DIR}/mingw${_bitval}/bin:$PATH
            export PATH

            # Don't pass -fstack-protector* to CFLAGS.
            local _cflags="${CFLAGS_/-fstack-protector-strong --param=ssp-buffer-size=4/}"

            # Configure.
            printf "===> Configuring MinGW-w64 libmangle %s...\n" $_arch
            ../../src/mingw-w64-${MINGW_VER}/mingw-w64-libraries/libmangle/configure \
                --prefix=/mingw${_bitval}/${_arch}-w64-mingw32                       \
                --build=${_arch}-w64-mingw32                                         \
                --host=${_arch}-w64-mingw32                                          \
                --disable-silent-rules                                               \
                CFLAGS="${_cflags}"                                                  \
                LDFLAGS="${LDFLAGS_}"                                                \
                > ${LOGS_DIR}/mingw-w64/libmangle/libmangle_config_${_arch}.log 2>&1 || exit 1
            echo "done"

            # Make.
            printf "===> Making MinGW-w64 libmangle %s...\n" $_arch
            make $MAKEFLAGS_ > ${LOGS_DIR}/mingw-w64/libmangle/libmangle_make_${_arch}.log 2>&1 || exit 1
            echo "done"

            # Install.
            printf "===> Installing MinGW-w64 libmangle %s...\n" $_arch
            make DESTDIR=${PREIN_DIR}/mingw-w64/libmangle install \
                > ${LOGS_DIR}/mingw-w64/libmangle/libmangle_install_${_arch}.log 2>&1 || exit 1
            # Remove unneeded files.
            remove_empty_dirs ${PREIN_DIR}/mingw-w64/libmangle/mingw$_bitval
            remove_la_files   ${PREIN_DIR}/mingw-w64/libmangle/mingw$_bitval
            # Strip files.
            strip_files ${PREIN_DIR}/mingw-w64/libmangle/mingw$_bitval
            echo "done"
        fi

        # Copy to DST_DIR.
        printf "===> Copying MinGW-w64 libmangle %s to %s/mingw%s...\n" $_arch $DST_DIR $_bitval
        cp -fra ${PREIN_DIR}/mingw-w64/libmangle/mingw$_bitval $DST_DIR
        echo "done"
    done

    cd $ROOT_DIR
    return 0
}

# tools: MinGW-w64 tools
# Build and install.
function build_tools() {
    clear; printf "Build MinGW-w64 tools %s\n" $MINGW_VER

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
                printf "build_tools: Unknown Option: '%s'... exit\n" $_opt
                exit 1
                ;;
        esac
    done

    # List of tools.
    local -ra _tools=(
        "gendef"
        "genpeimg"
    )

    local _arch
    for _arch in ${TARGET_ARCH[@]}
    do
        local _bitval=$(get_arch_bit ${_arch})

        if ${_rebuild}; then
            cd ${BUILD_DIR}/mingw-w64/tools/build_$_arch
            # Cleanup the build dir.
            rm -fr ${BUILD_DIR}/mingw-w64/tools/build_${_arch}/*

            # PATH exporting.
            source cpath $_arch
            PATH=${DST_DIR}/mingw${_bitval}/bin:$PATH
            export PATH

            local _tool
            for _tool in ${_tools[@]}
            do
                mkdir -p ${BUILD_DIR}/mingw-w64/tools/build_${_arch}/$_tool
                cd ${BUILD_DIR}/mingw-w64/tools/build_${_arch}/$_tool

                # gendef specific config option.
                if [ "${_tool}" = "gendef" ]; then
                    local _mangle="--with-mangle=${DESTDIR}/mingw${_bitval}/${_arch}-w64-mingw32"
                else
                    local _mangle=""
                fi

                # Configure.
                printf "===> Configuring MinGW-w64 tools [%s] %s...\n" $_tool $_arch
                ../../../src/mingw-w64-${MINGW_VER}/mingw-w64-tools/${_tool}/configure \
                    --prefix=/mingw$_bitval                                            \
                    --build=${_arch}-w64-mingw32                                       \
                    --host=${_arch}-w64-mingw32                                        \
                    --disable-silent-rules                                             \
                    ${_mangle}                                                         \
                    CFLAGS="${CFLAGS_}"                                                \
                    LDFLAGS="${LDFLAGS_}"                                              \
                    CPPFLAGS="${CPPFLAGS_}"                                            \
                    > ${LOGS_DIR}/mingw-w64/tools/${_tool}_config_${_arch}.log 2>&1 || exit 1
                echo "done"

                # Make.
                printf "===> Making MinGW-w64 tools [%s] %s...\n" $_tool $_arch
                make $MAKEFLAGS_ > ${LOGS_DIR}/mingw-w64/tools/${_tool}_make_${_arch}.log 2>&1 || exit 1
                echo "done"

                # Install.
                printf "===> Installing MinGW-w64 tools [%s] %s...\n" $_tool $_arch
                make DESTDIR=${PREIN_DIR}/mingw-w64/tools install \
                    > ${LOGS_DIR}/mingw-w64/tools/${_tool}_install_${_arch}.log 2>&1 || exit 1
                echo "done"
            done

            # Strip files.
            strip_files ${PREIN_DIR}/mingw-w64/tools/mingw$_bitval
        fi

        # Copy to DST_DIR.
        printf "===> Copying MinGW-w64 tools %s to %s/mingw%s...\n" $_arch $DST_DIR $_bitval
        cp -fra ${PREIN_DIR}/mingw-w64/tools/mingw$_bitval $DST_DIR
        echo "done"
    done

    cd $ROOT_DIR
    return 0
}
