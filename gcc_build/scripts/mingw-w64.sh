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
        printf "===> configuring MinGW-w64 headers %s\n" $arch
        ../../src/mingw-w64-${MINGW_VER}/mingw-w64-headers/configure \
            --prefix=/mingw${bitval}/${arch}-w64-mingw32             \
            --build=${arch}-w64-mingw32                              \
            --host=${arch}-w64-mingw32                               \
            --enable-sdk=all                                         \
            --enable-secure-api                                      \
            CPPFLAGS="${_CPPFLAGS}"                                  \
            CFLAGS="${_CFLAGS}"                                      \
            CXXFLAGS="${_CXXFLAGS}"                                  \
            LDFLAGS="${_LDFLAGS}"                                    \
            > ${LOGS_DIR}/mingw-w64/headers/headers_config_${arch}.log 2>&1 || exit 1
        echo "done"

        printf "===> making MinGW-w64 headers %s\n" $arch
        make $MAKEFLAGS all > ${LOGS_DIR}/mingw-w64/headers/headers_make_${arch}.log 2>&1 || exit 1
        echo "done"

        printf "===> installing MinGW-w64 headers %s\n" $arch
        make DESTDIR=${PREIN_DIR}/mingw-w64/headers install \
            > ${LOGS_DIR}/mingw-w64/headers/headers_install_${arch}.log 2>&1 || exit 1
        echo "done"

        printf "===> copying MinGW-w64 headers %s to %s/mingw%s\n" $arch $DST_DIR $bitval
        cp -fra ${PREIN_DIR}/mingw-w64/headers/mingw$bitval $DST_DIR
        ln -s ${DST_DIR}/mingw${bitval}/${arch}-w64-mingw32 ${DST_DIR}/mingw${bitval}/mingw
        echo "done"
    done

    cd $ROOT_DIR
    return 0
}

# copy only
function copy_only_headers() {
    clear; printf "MinGW-w64 headers %s\n" $MINGW_VER

    for arch in ${TARGET_ARCH[@]}
    do
        local bitval=$(get_arch_bit ${arch})

        printf "===> copying MinGW-w64 headers %s to %s/mingw%s\n" $arch $DST_DIR $bitval
        cp -fra ${PREIN_DIR}/mingw-w64/headers/mingw$bitval $DST_DIR
        ln -s ${DST_DIR}/mingw${bitval}/${arch}-w64-mingw32 ${DST_DIR}/mingw${bitval}/mingw
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
        rm -fr ${BUILD_DIR}/mingw-w64/winpthreads/build_${arch}/*

        local bitval=$(get_arch_bit ${arch})

        source cpath $arch
        if [ "${1}" = "-2nd" ] ; then
            PATH=${DST_DIR}/mingw${bitval}/bin:/usr/local/bin:/usr/bin:/bin
            export PATH
        fi

        printf "===> configuring MinGW-w64 winpthreads %s\n" $arch
        ../../src/mingw-w64-${MINGW_VER}/mingw-w64-libraries/winpthreads/configure \
            --prefix=/mingw${bitval}/${arch}-w64-mingw32                           \
            --build=${arch}-w64-mingw32                                            \
            --host=${arch}-w64-mingw32                                             \
            --enable-shared                                                        \
            --enable-static                                                        \
            CPPFLAGS="${_CPPFLAGS}"                                                \
            CFLAGS="${_CFLAGS}"                                                    \
            CXXFLAGS="${_CXXFLAGS}"                                                \
            LDFLAGS="${_LDFLAGS}"                                                  \
            > ${LOGS_DIR}/mingw-w64/winpthreads/winpthreads_config_${arch}.log 2>&1 || exit 1
        echo "done"

        printf "===> making MinGW-w64 winpthreads %s\n" $arch
        make $MAKEFLAGS all > ${LOGS_DIR}/mingw-w64/winpthreads/winpthreads_make_${arch}.log 2>&1 || exit 1
        echo "done"

        printf "===> installing MinGW-w64 winpthreads %s\n" $arch
        make DESTDIR=${PREIN_DIR}/mingw-w64/winpthreads install \
            > ${LOGS_DIR}/mingw-w64/winpthreads/winpthreads_install_${arch}.log 2>&1 || exit 1
        mkdir -p ${PREIN_DIR}/mingw-w64/winpthreads/mingw${bitval}/bin
        cp -fa ${PREIN_DIR}/mingw-w64/winpthreads/mingw${bitval}/${arch}-w64-mingw32/bin/*.dll \
            ${PREIN_DIR}/mingw-w64/winpthreads/mingw${bitval}/bin
        del_empty_dir ${PREIN_DIR}/mingw-w64/winpthreads/mingw$bitval
        remove_la_files ${PREIN_DIR}/mingw-w64/winpthreads/mingw$bitval
        strip_files ${PREIN_DIR}/mingw-w64/winpthreads/mingw$bitval
        echo "done"

        printf "===> copying MinGW-w64 winpthreads %s to %s/mingw%s\n" $arch $DST_DIR $bitval
        cp -fra ${PREIN_DIR}/mingw-w64/winpthreads/mingw$bitval $DST_DIR
        if [ -d ${DST_DIR}/mingw${bitval}/mingw ] ; then
            rm -fr ${DST_DIR}/mingw${bitval}/mingw
        fi
        if [ "${1}" != "-2nd" ] ; then
            ln -s ${DST_DIR}/mingw${bitval}/${arch}-w64-mingw32 ${DST_DIR}/mingw${bitval}/mingw
        fi
        echo "done"
    done

    cd $ROOT_DIR
    return 0
}

# copy only
function copy_only_threads() {
    clear; printf "MinGW-w64 winpthreads %s\n" $MINGW_VER

    for arch in ${TARGET_ARCH[@]}
    do
        local bitval=$(get_arch_bit ${arch})

        printf "===> copying MinGW-w64 winpthreads %s to %s/mingw%s\n" $arch $DST_DIR $bitval
        cp -fra ${PREIN_DIR}/mingw-w64/winpthreads/mingw$bitval $DST_DIR
        if [ -d ${DST_DIR}/mingw${bitval}/mingw ] ; then
            rm -fr ${DST_DIR}/mingw${bitval}/mingw
        fi
        ln -s ${DST_DIR}/mingw${bitval}/${arch}-w64-mingw32 ${DST_DIR}/mingw${bitval}/mingw
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
        rm -fr ${BUILD_DIR}/mingw-w64/crt/build_${arch}/*

        local bitval=$(get_arch_bit ${arch})

        if [ "${arch}" = "i686" ] ; then
            local _libs_conf="--enable-lib32 --disable-lib64"
        else
            local _libs_conf="--disable-lib32 --enable-lib64"
        fi

        source cpath $arch
        if [ "${1}" = "-2nd" ] ; then
            PATH=${DST_DIR}/mingw${bitval}/bin:/usr/local/bin:/usr/bin:/bin
            export PATH
        fi

        printf "===> configuring MinGW-w64 crt %s\n" $arch
        ../../src/mingw-w64-${MINGW_VER}/mingw-w64-crt/configure         \
            --prefix=/mingw${bitval}/${arch}-w64-mingw32                 \
            --with-sysroot=${DST_DIR}/mingw${bitval}/${arch}-w64-mingw32 \
            --build=${arch}-w64-mingw32                                  \
            --host=${arch}-w64-mingw32                                   \
            ${_libs_conf}                                                \
            --disable-libarm32                                           \
            --enable-wildcard                                            \
            CPPFLAGS="${_CPPFLAGS/-D__USE_MINGW_ANSI_STDIO=1/}"          \
            CFLAGS="${_CFLAGS}"                                          \
            CXXFLAGS="${_CXXFLAGS}"                                      \
            LDFLAGS="${_LDFLAGS}"                                        \
            > ${LOGS_DIR}/mingw-w64/crt/crt_config_${arch}.log 2>&1 || exit 1
        echo "done"

        printf "===> making MinGW-w64 crt %s\n" $arch
        make -j1 all > ${LOGS_DIR}/mingw-w64/crt/crt_make_${arch}.log 2>&1 || exit 1
        echo "done"

        printf "===> installing MinGW-w64 crt %s\n" $arch
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
function copy_only_crt() {
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
