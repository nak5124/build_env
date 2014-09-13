# MinGW-w64 common
function prepare_mingw_w64() {
    clear; printf "Prepare MinGW-w64 %s\n" $MINGW_VER

    if [ ! -d ${BUILD_DIR}/mingw-w64/src/mingw-w64-$MINGW_VER ] ; then
        cd ${BUILD_DIR}/mingw-w64/src
        printf "===> cloning MinGW-w64 %s\n" $MINGW_VER
        dl_files git git://git.code.sf.net/p/mingw-w64/mingw-w64 mingw-w64-$MINGW_VER
        echo "done"
    fi
    cd ${BUILD_DIR}/mingw-w64/src/mingw-w64-$MINGW_VER

    git clean -fdx > /dev/null 2>&1
    git reset --hard > /dev/null 2>&1
    git pull > /dev/null 2>&1
    git_hash > ${LOGS_DIR}/mingw-w64/mingw-w64.hash 2>&1
    git_rev >> ${LOGS_DIR}/mingw-w64/mingw-w64.hash 2>&1

    cd $ROOT_DIR
    return 0
}

# headers: MinGW-w64 headers for Windows
# build
function build_headers() {
    clear; printf "Build MinGW-w64 headers %s\n" $MINGW_VER

    for arch in ${TARGET_ARCH[@]}
    do
        cd ${BUILD_DIR}/mingw-w64/headers/build_$arch
        rm -fr ${BUILD_DIR}/mingw-w64/headers/build_${arch}/*

        local bitval=$(get_arch_bit ${arch})

        source cpath $arch
        PATH=${DST_DIR}/mingw${bitval}/bin:$PATH
        export PATH

        printf "===> configuring MinGW-w64 headers %s\n" $arch
        ../../src/mingw-w64-${MINGW_VER}/mingw-w64-headers/configure \
            --prefix=/mingw${bitval}/${arch}-w64-mingw32             \
            --build=${arch}-w64-mingw32                              \
            --host=${arch}-w64-mingw32                               \
            --enable-sdk=all                                         \
            --enable-secure-api                                      \
            > ${LOGS_DIR}/mingw-w64/headers/headers_config_${arch}.log 2>&1 || exit 1
        echo "done"

        printf "===> installing MinGW-w64 headers %s\n" $arch
        make DESTDIR=${PREIN_DIR}/mingw-w64/headers install \
            > ${LOGS_DIR}/mingw-w64/headers/headers_install_${arch}.log 2>&1 || exit 1
        # These headers are replaced by winpthreads.
        rm -f ${PREIN_DIR}/mingw-w64/headers/mingw${bitval}/${arch}-w64-mingw32/include/pthread*.h
        echo "done"

        printf "===> copying MinGW-w64 headers %s to %s/mingw%s\n" $arch $DST_DIR $bitval
        cp -fra ${PREIN_DIR}/mingw-w64/headers/mingw$bitval $DST_DIR
        echo "done"
    done

    cd $ROOT_DIR
    return 0
}

# copy only
function copy_headers() {
    clear; printf "MinGW-w64 headers %s\n" $MINGW_VER

    for arch in ${TARGET_ARCH[@]}
    do
        local bitval=$(get_arch_bit ${arch})

        printf "===> copying MinGW-w64 headers %s to %s/mingw%s\n" $arch $DST_DIR $bitval
        cp -fra ${PREIN_DIR}/mingw-w64/headers/mingw$bitval $DST_DIR
        echo "done"
    done

    cd $ROOT_DIR
    return 0
}

# winpthreads: MinGW-w64 winpthreads library
# build
function build_threads() {
    clear; printf "Build MinGW-w64 winpthreads %s\n" $MINGW_VER

    for arch in ${TARGET_ARCH[@]}
    do
        cd ${BUILD_DIR}/mingw-w64/winpthreads/build_$arch
        rm -fr ${BUILD_DIR}/mingw-w64/winpthreads/build_${arch}/{.*,*} > /dev/null 2>&1

        local bitval=$(get_arch_bit ${arch})
        local _aof=$(arch_optflags ${arch})

        source cpath $arch
        PATH=${DST_DIR}/mingw${bitval}/bin:$PATH
        export PATH

        printf "===> configuring MinGW-w64 winpthreads %s\n" $arch
        ../../src/mingw-w64-${MINGW_VER}/mingw-w64-libraries/winpthreads/configure \
            --prefix=/mingw${bitval}/${arch}-w64-mingw32                           \
            --build=${arch}-w64-mingw32                                            \
            --host=${arch}-w64-mingw32                                             \
            --enable-shared                                                        \
            --enable-static                                                        \
            --with-gnu-ld                                                          \
            CFLAGS="${_aof} ${_CFLAGS}"                                            \
            LDFLAGS="${_LDFLAGS}"                                                  \
            > ${LOGS_DIR}/mingw-w64/winpthreads/winpthreads_config_${arch}.log 2>&1 || exit 1
        echo "done"

        printf "===> making MinGW-w64 winpthreads %s\n" $arch
        # Setting -j$(($(nproc)+1)) sometimes makes error.
        make > ${LOGS_DIR}/mingw-w64/winpthreads/winpthreads_make_${arch}.log 2>&1 || exit 1
        echo "done"

        printf "===> installing MinGW-w64 winpthreads %s\n" $arch
        make DESTDIR=${PREIN_DIR}/mingw-w64/winpthreads install \
            > ${LOGS_DIR}/mingw-w64/winpthreads/winpthreads_install_${arch}.log 2>&1 || exit 1
        # Move DLL for GCC.
        mkdir -p ${PREIN_DIR}/mingw-w64/winpthreads/mingw${bitval}/bin
        mv -f ${PREIN_DIR}/mingw-w64/winpthreads/mingw${bitval}/${arch}-w64-mingw32/bin/*.dll \
            ${PREIN_DIR}/mingw-w64/winpthreads/mingw${bitval}/bin
        del_empty_dir ${PREIN_DIR}/mingw-w64/winpthreads/mingw$bitval
        remove_la_files ${PREIN_DIR}/mingw-w64/winpthreads/mingw$bitval
        strip_files ${PREIN_DIR}/mingw-w64/winpthreads/mingw$bitval
        echo "done"

        printf "===> copying MinGW-w64 winpthreads %s to %s/mingw%s\n" $arch $DST_DIR $bitval
        cp -fra ${PREIN_DIR}/mingw-w64/winpthreads/mingw$bitval $DST_DIR
        echo "done"
    done

    cd $ROOT_DIR
    return 0
}

# copy only
function copy_threads() {
    clear; printf "MinGW-w64 winpthreads %s\n" $MINGW_VER

    for arch in ${TARGET_ARCH[@]}
    do
        local bitval=$(get_arch_bit ${arch})

        printf "===> copying MinGW-w64 winpthreads %s to %s/mingw%s\n" $arch $DST_DIR $bitval
        cp -fra ${PREIN_DIR}/mingw-w64/winpthreads/mingw$bitval $DST_DIR
        echo "done"
    done

    cd $ROOT_DIR
    return 0
}

# crt: MinGW-w64 CRT for Windows
# build
function build_crt() {
    clear; printf "Build MinGW-w64 crt %s\n" $MINGW_VER

    for arch in ${TARGET_ARCH[@]}
    do
        cd ${BUILD_DIR}/mingw-w64/crt/build_$arch
        rm -fr ${BUILD_DIR}/mingw-w64/crt/build_${arch}/{.*,*} > /dev/null 2>&1

        local bitval=$(get_arch_bit ${arch})
        local _aof=$(arch_optflags ${arch})

        source cpath $arch
        PATH=${DST_DIR}/mingw${bitval}/bin:$PATH
        export PATH

        if [ "${arch}" = "i686" ] ; then
            local _libs_conf="--enable-lib32 --disable-lib64"
        else
            local _libs_conf="--disable-lib32 --enable-lib64"
        fi

        printf "===> configuring MinGW-w64 crt %s\n" $arch
        ../../src/mingw-w64-${MINGW_VER}/mingw-w64-crt/configure         \
            --prefix=/mingw${bitval}/${arch}-w64-mingw32                 \
            --build=${arch}-w64-mingw32                                  \
            --host=${arch}-w64-mingw32                                   \
            ${_libs_conf}                                                \
            --disable-libarm32                                           \
            --enable-wildcard                                            \
            --with-sysroot=${DST_DIR}/mingw${bitval}/${arch}-w64-mingw32 \
            CFLAGS="${_aof} ${_CFLAGS}"                                  \
            CXXFLAGS="${_aof} ${_CXXFLAGS}"                              \
            LDFLAGS="${_LDFLAGS}"                                        \
            > ${LOGS_DIR}/mingw-w64/crt/crt_config_${arch}.log 2>&1 || exit 1
        echo "done"

        printf "===> making MinGW-w64 crt %s\n" $arch
        # Setting -j$(($(nproc)+1)) sometimes makes error.
        make > ${LOGS_DIR}/mingw-w64/crt/crt_make_${arch}.log 2>&1 || exit 1
        echo "done"

        printf "===> installing MinGW-w64 crt %s\n" $arch
        # MinGW-w64 crt has many files, so not using strip_files but install-strip.
        make DESTDIR=${PREIN_DIR}/mingw-w64/crt install-strip \
            > ${LOGS_DIR}/mingw-w64/crt/crt_install_${arch}.log 2>&1 || exit 1
        echo "done"

        printf "===> copying MinGW-w64 crt %s to %s/mingw%s\n" $arch $DST_DIR $bitval
        cp -fra ${PREIN_DIR}/mingw-w64/crt/mingw$bitval $DST_DIR
        echo "done"
    done

    cd $ROOT_DIR
    return 0
}

# copy only
function copy_crt() {
    clear; printf "MinGW-w64 crt %s\n" $MINGW_VER

    for arch in ${TARGET_ARCH[@]}
    do
        local bitval=$(get_arch_bit ${arch})

        printf "===> copying MinGW-w64 crt %s to %s/mingw%s\n" $arch $DST_DIR $bitval
        cp -fra ${PREIN_DIR}/mingw-w64/crt/mingw$bitval $DST_DIR
        echo "done"
    done

    cd $ROOT_DIR
    return 0
}

# libmangle: MinGW-w64 libmangle
# build
function build_mangle() {
    clear; printf "Build MinGW-w64 libmangle %s\n" $MINGW_VER

    for arch in ${TARGET_ARCH[@]}
    do
        cd ${BUILD_DIR}/mingw-w64/libmangle/build_$arch
        rm -fr ${BUILD_DIR}/mingw-w64/libmangle/build_${arch}/* > /dev/null 2>&1

        local bitval=$(get_arch_bit ${arch})
        local _aof=$(arch_optflags ${arch})

        source cpath $arch
        PATH=${DST_DIR}/mingw${bitval}/bin:$PATH
        export PATH

        printf "===> configuring MinGW-w64 libmangle %s\n" $arch
        ../../src/mingw-w64-${MINGW_VER}/mingw-w64-libraries/libmangle/configure \
            --prefix=/mingw$bitval                                               \
            --build=${arch}-w64-mingw32                                          \
            --host=${arch}-w64-mingw32                                           \
            CPPFLAGS="${_CPPFLAGS}"                                              \
            CFLAGS="${_aof} ${_CFLAGS}"                                          \
            LDFLAGS="${_LDFLAGS}"                                                \
            > ${LOGS_DIR}/mingw-w64/libmangle/libmangle_config_${arch}.log 2>&1 || exit 1
        echo "done"

        printf "===> making MinGW-w64 libmangle %s\n" $arch
        make $MAKEFLAGS > ${LOGS_DIR}/mingw-w64/libmangle/libmangle_make_${arch}.log 2>&1 || exit 1
        echo "done"

        printf "===> installing MinGW-w64 libmangle %s\n" $arch
        make DESTDIR=${PREIN_DIR}/mingw-w64/libmangle install \
            > ${LOGS_DIR}/mingw-w64/libmangle/libmangle_install_${arch}.log 2>&1 || exit 1
        del_empty_dir ${PREIN_DIR}/mingw-w64/libmangle/mingw$bitval
        remove_la_files ${PREIN_DIR}/mingw-w64/libmangle/mingw$bitval
        strip_files ${PREIN_DIR}/mingw-w64/libmangle/mingw$bitval
        echo "done"

        printf "===> copying MinGW-w64 libmangle %s to %s/mingw%s\n" $arch $DST_DIR $bitval
        cp -fra ${PREIN_DIR}/mingw-w64/libmangle/mingw$bitval $DST_DIR
        echo "done"
    done

    cd $ROOT_DIR
    return 0
}

# copy only
function copy_mangle() {
    clear; printf "MinGW-w64 libmangle %s\n" $MINGW_VER

    for arch in ${TARGET_ARCH[@]}
    do
        local bitval=$(get_arch_bit ${arch})

        printf "===> copying MinGW-w64 libmangle %s to %s/mingw%s\n" $arch $DST_DIR $bitval
        cp -fra ${PREIN_DIR}/mingw-w64/libmangle/mingw$bitval $DST_DIR
        echo "done"
    done

    cd $ROOT_DIR
    return 0
}

# tools: MinGW-w64 tools
# build
function build_tools() {
    clear; printf "Build MinGW-w64 tools %s\n" $MINGW_VER

    for arch in ${TARGET_ARCH[@]}
    do
        cd ${BUILD_DIR}/mingw-w64/tools/build_$arch
        rm -fr ${BUILD_DIR}/mingw-w64/libmangle/build_${arch}/* > /dev/null 2>&1

        local bitval=$(get_arch_bit ${arch})
        local _aof=$(arch_optflags ${arch})

        source cpath $arch
        PATH=${DST_DIR}/mingw${bitval}/bin:$PATH
        export PATH

        for _tool in gendef genpeimg
        do
            mkdir -p ${BUILD_DIR}/mingw-w64/tools/build_${arch}/$_tool
            cd ${BUILD_DIR}/mingw-w64/tools/build_${arch}/$_tool

            if [ "${_tool}" = "gendef" ] ; then
                local _mangle="--with-mangle=${DESTDIR}/mingw$bitval"
            else
                local _mangle=""
            fi

            printf "===> configuring MinGW-w64 tools [%s] %s\n" $_tool $arch
            ../../../src/mingw-w64-${MINGW_VER}/mingw-w64-tools/${_tool}/configure \
                --prefix=/mingw$bitval                                             \
                --build=${arch}-w64-mingw32                                        \
                --host=${arch}-w64-mingw32                                         \
                ${_mangle}                                                         \
                CPPFLAGS="${_CPPFLAGS}"                                            \
                CFLAGS="${_aof} ${_CFLAGS}"                                        \
                LDFLAGS="${_LDFLAGS}"                                              \
                > ${LOGS_DIR}/mingw-w64/tools/${_tool}_config_${arch}.log 2>&1 || exit 1
            echo "done"

            printf "===> making MinGW-w64 tools [%s] %s\n" $_tool $arch
            make $MAKEFLAGS > ${LOGS_DIR}/mingw-w64/tools/${_tool}_make_${arch}.log 2>&1 || exit 1
            echo "done"

            printf "===> installing MinGW-w64 tools [%s] %s\n" $_tool $arch
            make DESTDIR=${PREIN_DIR}/mingw-w64/tools install \
                > ${LOGS_DIR}/mingw-w64/tools/${_tool}_install_${arch}.log 2>&1 || exit 1
            echo "done"
        done

        del_empty_dir ${PREIN_DIR}/mingw-w64/tools/mingw$bitval
        remove_la_files ${PREIN_DIR}/mingw-w64/tools/mingw$bitval
        strip_files ${PREIN_DIR}/mingw-w64/tools/mingw$bitval

        printf "===> copying MinGW-w64 tools %s to %s/mingw%s\n" $arch $DST_DIR $bitval
        cp -fra ${PREIN_DIR}/mingw-w64/tools/mingw$bitval $DST_DIR
        echo "done"
    done

    cd $ROOT_DIR
    return 0
}

# copy only
function copy_tools() {
    clear; printf "MinGW-w64 tools %s\n" $MINGW_VER

    for arch in ${TARGET_ARCH[@]}
    do
        local bitval=$(get_arch_bit ${arch})

        printf "===> copying MinGW-w64 tools %s to %s/mingw%s\n" $arch $DST_DIR $bitval
        cp -fra ${PREIN_DIR}/mingw-w64/tools/mingw$bitval $DST_DIR
        echo "done"
    done

    cd $ROOT_DIR
    return 0
}
