# GCC: The GNU Compiler Collection
# download src
function download_gcc_src() {
    if [ ! -f ${BUILD_DIR}/gcc/src/gcc-${GCC_VER}.tar.bz2 ] ; then
        printf "===> downloading GCC %s\n" $GCC_VER
        pushd ${BUILD_DIR}/gcc/src > /dev/null
        dl_files ftp ftp://gcc.gnu.org/pub/gcc/releases/gcc-${GCC_VER}/gcc-${GCC_VER}.tar.bz2
        popd > /dev/null
        echo "done"
    fi

    if [ ! -d ${BUILD_DIR}/gcc/src/gcc-$GCC_VER ] ; then
        printf "===> extracting GCC %s\n" $GCC_VER
        pushd ${BUILD_DIR}/gcc/src > /dev/null
        decomp_arch ${BUILD_DIR}/gcc/src/gcc-${GCC_VER}.tar.bz2
        popd > /dev/null
        echo "done"
    fi

    return 0
}

# patch
function patch_gcc() {
    pushd ${BUILD_DIR}/gcc/src/gcc-$GCC_VER > /dev/null

    if [ ! -f ${BUILD_DIR}/gcc/src/gcc-${GCC_VER}/patched_01.marker ] ; then
        # do not install libiberty
        sed -i 's/install_to_$(INSTALL_DEST) //' libiberty/Makefile.in
        touch ${BUILD_DIR}/gcc/src/gcc-${GCC_VER}/patched_01.marker
    fi
    if [ ! -f ${BUILD_DIR}/gcc/src/gcc-${GCC_VER}/patched_02.marker ] ; then
        # hack! - some configure tests for header files using "$CPP $CPPFLAGS"
        sed -i "/ac_cpp=/s/\$CPPFLAGS/\$CPPFLAGS -Os/" {libiberty,gcc}/configure
        touch ${BUILD_DIR}/gcc/src/gcc-${GCC_VER}/patched_02.marker
    fi
    if [ ! -f ${BUILD_DIR}/gcc/src/gcc-${GCC_VER}/patched_03.marker ] ; then
        patch -p1 < ${PATCHES_DIR}/gcc/0001-gcc-4.8-libstdc++export.patch > ${LOGS_DIR}/gcc/gcc_patch.log 2>&1 || exit 1
        touch ${BUILD_DIR}/gcc/src/gcc-${GCC_VER}/patched_03.marker
    fi
    if [ ! -f ${BUILD_DIR}/gcc/src/gcc-${GCC_VER}/patched_04.marker ] ; then
        patch -p1 < ${PATCHES_DIR}/gcc/0002-gcc-4.7-stdthreads.patch >> ${LOGS_DIR}/gcc/gcc_patch.log 2>&1 || exit 1
        touch ${BUILD_DIR}/gcc/src/gcc-${GCC_VER}/patched_04.marker
    fi
    if [ ! -f ${BUILD_DIR}/gcc/src/gcc-${GCC_VER}/patched_05.marker ] ; then
        # Don't waste valuable commandline chars on double-quotes around "arguments" that don't need them.
        patch -p1 < ${PATCHES_DIR}/gcc/0003-dont-escape-arguments-that-dont-need-it-in-pex-win32.patch \
            >> ${LOGS_DIR}/gcc/gcc_patch.log 2>&1 || exit 1
        touch ${BUILD_DIR}/gcc/src/gcc-${GCC_VER}/patched_05.marker
    fi
    if [ ! -f ${BUILD_DIR}/gcc/src/gcc-${GCC_VER}/patched_06.marker ] ; then
        # Make Windows behave the same as Posix in the consideration of whether
        # folder "/exists/doesnt-exist/.." is a valid path.. in Posix, it isn't.
        patch -p1 < ${PATCHES_DIR}/gcc/0004-fix-for-windows-not-minding-non-existent-parent-dirs.patch \
            >> ${LOGS_DIR}/gcc/gcc_patch.log 2>&1 || exit 1
        touch ${BUILD_DIR}/gcc/src/gcc-${GCC_VER}/patched_06.marker
    fi
    if [ ! -f ${BUILD_DIR}/gcc/src/gcc-${GCC_VER}/patched_07.marker ] ; then
        # Don't make a lowercase backslashed path from argv[0] that then fail to strcmp with prefix(es) .. they're also ugly.
        patch -p1 < ${PATCHES_DIR}/gcc/0005-windows-lrealpath-no-force-lowercase-nor-backslash.patch \
            >> ${LOGS_DIR}/gcc/gcc_patch.log 2>&1 || exit 1
        touch ${BUILD_DIR}/gcc/src/gcc-${GCC_VER}/patched_07.marker
    fi
    if [ ! -f ${BUILD_DIR}/gcc/src/gcc-${GCC_VER}/patched_08.marker ] ; then
        # http://gcc.gnu.org/bugzilla/show_bug.cgi?id=57440
        patch -p1 < ${PATCHES_DIR}/gcc/0006-PR57440.patch >> ${LOGS_DIR}/gcc/gcc_patch.log 2>&1 || exit 1
        touch ${BUILD_DIR}/gcc/src/gcc-${GCC_VER}/patched_08.marker
    fi
    if [ ! -f ${BUILD_DIR}/gcc/src/gcc-${GCC_VER}/patched_09.marker ] ; then
        patch -p0 < ${PATCHES_DIR}/gcc/0007-isl.patch >> ${LOGS_DIR}/gcc/gcc_patch.log 2>&1 || exit 1
        touch ${BUILD_DIR}/gcc/src/gcc-${GCC_VER}/patched_09.marker
    fi
    if [ ! -f ${BUILD_DIR}/gcc/src/gcc-${GCC_VER}/patched_10.marker ] ; then
        # http://gcc.gnu.org/bugzilla/show_bug.cgi?id=57653
        patch -p0 < ${PATCHES_DIR}/gcc/0008-PR57653.patch >> ${LOGS_DIR}/gcc/gcc_patch.log 2>&1 || exit 1
        touch ${BUILD_DIR}/gcc/src/gcc-${GCC_VER}/patched_10.marker
    fi
    if [ ! -f ${BUILD_DIR}/gcc/src/gcc-${GCC_VER}/patched_11.marker ] ; then
        # Kai's libgomp fix.
        patch -p1 < ${PATCHES_DIR}/gcc/0009-ktietz-libgomp.patch >> ${LOGS_DIR}/gcc/gcc_patch.log 2>&1 || exit 1
        touch ${BUILD_DIR}/gcc/src/gcc-${GCC_VER}/patched_11.marker
    fi
    if [ ! -f ${BUILD_DIR}/gcc/src/gcc-${GCC_VER}/patched_12.marker ] ; then
        # In order to add /mingw${bitval}/include to include path
        patch -p1 < ${PATCHES_DIR}/gcc/0010-relocate.patch >> ${LOGS_DIR}/gcc/gcc_patch.log 2>&1 || exit 1
        touch ${BUILD_DIR}/gcc/src/gcc-${GCC_VER}/patched_12.marker
    fi
    if [ ! -f ${BUILD_DIR}/gcc/src/gcc-${GCC_VER}/patched_12.marker ] ; then
        # Instead of specifying '--with-gxx-include-dir=/mingw${bitval}/include/c++/$GCC_VER'
        patch -p1 < ${PATCHES_DIR}/gcc/0011-gxx-search-dir.patch >> ${LOGS_DIR}/gcc/gcc_patch.log 2>&1 || exit 1
        touch ${BUILD_DIR}/gcc/src/gcc-${GCC_VER}/patched_12.marker
    fi

    popd > /dev/null

    return 0
}

# 1st step
function build_gcc1() {
    clear; printf "Build GCC %s 1st step\n" $GCC_VER

    download_gcc_src
    patch_gcc

    for arch in ${TARGET_ARCH[@]}
    do
        cd ${BUILD_DIR}/gcc/build_$arch
        rm -fr ${BUILD_DIR}/gcc/build_${arch}/*

        local bitval=$(get_arch_bit ${arch})

        if [ "${arch}" = "i686" ] ; then
            local _optimization="--with-arch=i686 --with-tune=generic"
            local _ehconf="--disable-sjlj-exceptions --with-dwarf2"
            local _LAA=" -Wl,--large-address-aware"
        else
            local _optimization="--with-arch=x86-64 --with-tune=generic"
            local _ehconf=""
            local _LAA=""
        fi

        if [ "${THREAD_MODEL}" = "posix" ] ; then
            local _threads="--enable-threads=posix --enable-libstdcxx-time=yes"
        else
            local _threads="--enable-threads=win32"
        fi

        source cpath $arch
        printf "===> configuring GCC %s\n" $arch
        ../src/gcc-${GCC_VER}/configure                                 \
            --prefix=/mingw$bitval                                      \
            --with-local-prefix=/mingw${bitval}/local                   \
            --with-sysroot=/mingw$bitval                                \
            --with-build-sysroot=${DST_DIR}/mingw$bitval                \
            --libexecdir=/mingw${bitval}/lib                            \
            --build=${arch}-w64-mingw32                                 \
            --target=${arch}-w64-mingw32                                \
            --enable-shared                                             \
            --enable-static                                             \
            --disable-multilib                                          \
            --enable-languages=c,c++,lto                                \
            ${_threads}                                                 \
            ${_ehconf}                                                  \
            --enable-lto                                                \
            --enable-checking=release                                   \
            --enable-version-specific-runtime-libs                      \
            --enable-fully-dynamic-string                               \
            --enable-libgomp                                            \
            --disable-libssp                                            \
            --disable-libquadmath                                       \
            --disable-bootstrap                                         \
            --disable-win32-registry                                    \
            --disable-rpath                                             \
            --disable-nls                                               \
            --disable-werror                                            \
            --disable-symvers                                           \
            --disable-libstdcxx-pch                                     \
            --disable-libstdcxx-debug                                   \
            --with-{gmp,mpfr,mpc,isl,cloog}=${LIBS_DIR}/mingw$bitval    \
            --disable-isl-version-check                                 \
            --disable-cloog-version-check                               \
            --enable-cloog-backend=isl                                  \
            --with-libiconv-prefix=${DST_DIR}/mingw$bitval              \
            --with-system-zlib                                          \
            ${_optimization}                                            \
            CFLAGS="${_CFLAGS}"                                         \
            CFLAGS_FOR_TARGET="${_CFLAGS}"                              \
            CXXFLAGS="${_CXXFLAGS}"                                     \
            CXXFLAGS_FOR_TARGET="${_CXXFLAGS}"                          \
            CPPFLAGS="${_CPPFLAGS}"                                     \
            CPPFLAGS_FOR_TARGET="${_CPPFLAGS}"                          \
            LDFLAGS="${_LDFLAGS} ${_LAA}"                               \
            LDFLAGS_FOR_TARGET="${_LDFLAGS} ${_LAA}"                    \
            > ${LOGS_DIR}/gcc/gcc_config_${arch}.log 2>&1 || exit 1
        echo "done"

        printf "===> making GCC 1st step %s\n" $arch
        local -i make_num=0
        local -i make_num_old=0
        # retry 3 times
        while [ $make_num -lt 3 ]
        do
            make_num_old=$make_num
            make $MAKEFLAGS all-gcc > ${LOGS_DIR}/gcc/gcc1_make_${arch}.log 2>&1 || let make_num++
            if [ $make_num_old -eq $make_num ] ; then
                break
            fi
        done
        if [ $make_num -eq 3 ] ; then
            echo "While making GCC 1st step, some errors occur!"
            exit 1
        fi
        echo "done"

        printf "===> installing GCC 1st step %s\n" $arch
        rm -fr ${PREIN_DIR}/gcc/mingw$bitval
        make DESTDIR=${PREIN_DIR}/gcc install-gcc > ${LOGS_DIR}/gcc/gcc1_install_${arch}.log 2>&1 || exit 1
        del_empty_dir ${PREIN_DIR}/gcc/mingw$bitval
        remove_la_files ${PREIN_DIR}/gcc/mingw$bitval
        strip_files ${PREIN_DIR}/gcc/mingw$bitval
        echo "done"

        printf "===> copying GCC 1st step %s to %s/mingw%s\n" $arch $DST_DIR $bitval
        cp -fra ${PREIN_DIR}/gcc/mingw$bitval $DST_DIR
        echo "done"
    done

    cd $ROOT_DIR
    return 0
}

# 2nd step
function build_gcc2() {
    clear; printf "Build GCC %s 2nd step\n" $GCC_VER

    for arch in ${TARGET_ARCH[@]}
    do
        cd ${BUILD_DIR}/gcc/build_$arch

        local bitval=$(get_arch_bit ${arch})

        source cpath $arch
        PATH=${DST_DIR}/mingw${bitval}/bin:/usr/local/bin:/usr/bin:/bin
        export PATH

        printf "===> making GCC 2nd step %s\n" $arch
        local -i make_num=0
        local -i make_num_old=0
        # retry 3 times
        while [ $make_num -lt 3 ]
        do
            make_num_old=$make_num
            make $MAKEFLAGS all > ${LOGS_DIR}/gcc/gcc2_make_${arch}.log 2>&1 || let make_num++
            if [ $make_num_old -eq $make_num ] ; then
                break
            fi
        done
        if [ $make_num -eq 3 ] ; then
            echo "While making GCC 2nd step, some errors occur!"
            exit 1
        fi
        echo "done"

        printf "===> installing GCC 2nd step %s\n" $arch
        make DESTDIR=${PREIN_DIR}/gcc install > ${LOGS_DIR}/gcc/gcc2_install_${arch}.log 2>&1 || exit 1
        cp -fa ${PREIN_DIR}/gcc/mingw${bitval}/lib/gcc/${arch}-w64-mingw32/lib/libgcc_s.a \
            ${PREIN_DIR}/gcc/mingw${bitval}/lib/gcc/${arch}-w64-mingw32/${GCC_VER}
        rm -f ${PREIN_DIR}/gcc/mingw${bitval}/lib/gcc/${arch}-w64-mingw32/${GCC_VER}/*.py
        rm -fr ${PREIN_DIR}/gcc/mingw${bitval}/share/gcc-$GCC_VER
        del_empty_dir ${PREIN_DIR}/gcc/mingw$bitval
        remove_la_files ${PREIN_DIR}/gcc/mingw$bitval
        strip_files ${PREIN_DIR}/gcc/mingw$bitval
        rm -fr ${DST_DIR}/mingw${bitval}/mingw
        echo "done"

        printf "===> copying GCC 2nd step %s to %s/mingw%s\n" $arch $DST_DIR $bitval
        cp -fra ${PREIN_DIR}/gcc/mingw$bitval $DST_DIR
        cd ${DST_DIR}/mingw${bitval}/bin
        ln -sr ../bin/gcc.exe ./cc.exe
        echo "done"
    done

    cd $ROOT_DIR
    return 0

}

# copy only
function copy_only_gcc() {
    clear; printf "GCC %s\n" $GCC_VER

    for arch in ${TARGET_ARCH[@]}
    do
        local bitval=$(get_arch_bit ${arch})

        printf "===> copying GCC %s to %s/mingw%s\n" $arch $DST_DIR $bitval
        cp -fra ${PREIN_DIR}/gcc/mingw$bitval $DST_DIR
        if [ -d ${DST_DIR}/mingw${bitval}/mingw ] ; then
            rm -fr ${DST_DIR}/mingw${bitval}/mingw
        fi
        cd ${DST_DIR}/mingw${bitval}/bin
        ln -sr ../bin/gcc.exe ./cc.exe
        echo "done"
    done

    cd $ROOT_DIR
    return 0
}
