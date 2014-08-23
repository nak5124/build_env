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

    if [ ! -d ${BUILD_DIR}/gcc/src_bs/gcc-$GCC_VER ] ; then
        printf "===> extracting GCC %s\n" $GCC_VER
        pushd ${BUILD_DIR}/gcc/src_bs > /dev/null
        decomp_arch ${BUILD_DIR}/gcc/src/gcc-${GCC_VER}.tar.bz2
        popd > /dev/null
        echo "done"
    fi

    return 0
}

# patch
function patch_gcc() {
    pushd ${BUILD_DIR}/gcc/src_bs/gcc-$GCC_VER > /dev/null

    if [ ! -f ${BUILD_DIR}/gcc/src_bs/gcc-${GCC_VER}/patched_00.marker ] ; then
        patch -p1 < ${PATCHES_DIR}/gcc-bs/0000-gcc-4_9-branch-update-to-g4f3ec92.patch \
            > ${LOGS_DIR}/gcc/gcc_patch.log 2>&1 || exit 1
        touch ${BUILD_DIR}/gcc/src_bs/gcc-${GCC_VER}/patched_00.marker
    fi
    if [ ! -f ${BUILD_DIR}/gcc/src_bs/gcc-${GCC_VER}/patched_01.marker ] ; then
        # do not install libiberty
        sed -i 's/install_to_$(INSTALL_DEST) //' libiberty/Makefile.in
        touch ${BUILD_DIR}/gcc/src_bs/gcc-${GCC_VER}/patched_01.marker
    fi
    if [ ! -f ${BUILD_DIR}/gcc/src_bs/gcc-${GCC_VER}/patched_02.marker ] ; then
        # hack! - some configure tests for header files using "$CPP $CPPFLAGS"
        sed -i "/ac_cpp=/s/\$CPPFLAGS/\$CPPFLAGS -O2/" {libiberty,gcc}/configure
        touch ${BUILD_DIR}/gcc/src_bs/gcc-${GCC_VER}/patched_02.marker
    fi
    if [ ! -f ${BUILD_DIR}/gcc/src_bs/gcc-${GCC_VER}/patched_03.marker ] ; then
        patch -p1 < ${PATCHES_DIR}/gcc-bs/0001-gcc-4.8-libstdc++export.patch >> ${LOGS_DIR}/gcc/gcc_patch.log 2>&1 || exit 1
        touch ${BUILD_DIR}/gcc/src_bs/gcc-${GCC_VER}/patched_03.marker
    fi
    if [ ! -f ${BUILD_DIR}/gcc/src_bs/gcc-${GCC_VER}/patched_04.marker ] ; then
        patch -p1 < ${PATCHES_DIR}/gcc-bs/0002-gcc-4.7-stdthreads.patch >> ${LOGS_DIR}/gcc/gcc_patch.log 2>&1 || exit 1
        touch ${BUILD_DIR}/gcc/src_bs/gcc-${GCC_VER}/patched_04.marker
    fi
    if [ ! -f ${BUILD_DIR}/gcc/src_bs/gcc-${GCC_VER}/patched_05.marker ] ; then
        # Don't waste valuable commandline chars on double-quotes around "arguments" that don't need them.
        patch -p1 < ${PATCHES_DIR}/gcc-bs/0003-dont-escape-arguments-that-dont-need-it-in-pex-win32.patch \
            >> ${LOGS_DIR}/gcc/gcc_patch.log 2>&1 || exit 1
        touch ${BUILD_DIR}/gcc/src_bs/gcc-${GCC_VER}/patched_05.marker
    fi
    if [ ! -f ${BUILD_DIR}/gcc/src_bs/gcc-${GCC_VER}/patched_06.marker ] ; then
        # Make Windows behave the same as Posix in the consideration of whether
        # folder "/exists/doesnt-exist/.." is a valid path.. in Posix, it isn't.
        patch -p1 < ${PATCHES_DIR}/gcc-bs/0004-fix-for-windows-not-minding-non-existent-parent-dirs.patch \
            >> ${LOGS_DIR}/gcc/gcc_patch.log 2>&1 || exit 1
        touch ${BUILD_DIR}/gcc/src_bs/gcc-${GCC_VER}/patched_06.marker
    fi
    if [ ! -f ${BUILD_DIR}/gcc/src_bs/gcc-${GCC_VER}/patched_07.marker ] ; then
        # Don't make a lowercase backslashed path from argv[0] that then fail to strcmp with prefix(es) .. they're also ugly.
        patch -p1 < ${PATCHES_DIR}/gcc-bs/0005-windows-lrealpath-no-force-lowercase-nor-backslash.patch \
            >> ${LOGS_DIR}/gcc/gcc_patch.log 2>&1 || exit 1
        touch ${BUILD_DIR}/gcc/src_bs/gcc-${GCC_VER}/patched_07.marker
    fi
    if [ ! -f ${BUILD_DIR}/gcc/src_bs/gcc-${GCC_VER}/patched_08.marker ] ; then
        # http://gcc.gnu.org/bugzilla/show_bug.cgi?id=57440
        patch -p1 < ${PATCHES_DIR}/gcc-bs/0006-PR57440.patch >> ${LOGS_DIR}/gcc/gcc_patch.log 2>&1 || exit 1
        touch ${BUILD_DIR}/gcc/src_bs/gcc-${GCC_VER}/patched_08.marker
    fi
    if [ ! -f ${BUILD_DIR}/gcc/src_bs/gcc-${GCC_VER}/patched_09.marker ] ; then
        patch -p0 < ${PATCHES_DIR}/gcc-bs/0007-isl.patch >> ${LOGS_DIR}/gcc/gcc_patch.log 2>&1 || exit 1
        touch ${BUILD_DIR}/gcc/src_bs/gcc-${GCC_VER}/patched_09.marker
    fi
    if [ ! -f ${BUILD_DIR}/gcc/src_bs/gcc-${GCC_VER}/patched_10.marker ] ; then
        # http://gcc.gnu.org/bugzilla/show_bug.cgi?id=57653
        patch -p0 < ${PATCHES_DIR}/gcc-bs/0008-PR57653.patch >> ${LOGS_DIR}/gcc/gcc_patch.log 2>&1 || exit 1
        touch ${BUILD_DIR}/gcc/src_bs/gcc-${GCC_VER}/patched_10.marker
    fi
    if [ ! -f ${BUILD_DIR}/gcc/src_bs/gcc-${GCC_VER}/patched_11.marker ] ; then
        # Kai's libgomp fix.
        patch -p1 < ${PATCHES_DIR}/gcc-bs/0009-ktietz-libgomp.patch >> ${LOGS_DIR}/gcc/gcc_patch.log 2>&1 || exit 1
        touch ${BUILD_DIR}/gcc/src_bs/gcc-${GCC_VER}/patched_11.marker
    fi
    if [ ! -f ${BUILD_DIR}/gcc/src_bs/gcc-${GCC_VER}/patched_12.marker ] ; then
        # Enable colorizing diagnostics
        patch -p1 < ${PATCHES_DIR}/gcc-bs/0010-color.patch >> ${LOGS_DIR}/gcc/gcc_patch.log 2>&1 || exit 1
        touch ${BUILD_DIR}/gcc/src_bs/gcc-${GCC_VER}/patched_12.marker
    fi
    if [ ! -f ${BUILD_DIR}/gcc/src_bs/gcc-${GCC_VER}/patched_13.marker ] ; then
        # Don't search dirs under ${prefix} but ${build_sysroot}.
        patch -p1 < ${PATCHES_DIR}/gcc-bs/0011-gcc-use-build-sysroot-dir.patch >> ${LOGS_DIR}/gcc/gcc_patch.log 2>&1 || exit 1
        touch ${BUILD_DIR}/gcc/src_bs/gcc-${GCC_VER}/patched_13.marker
    fi
    if [ ! -f ${BUILD_DIR}/gcc/src_bs/gcc-${GCC_VER}/patched_14.marker ] ; then
        # Add /mingw{32,64}/local/{include,lib} to search dirs, and make relocatable perfectly.
        patch -p1 < ${PATCHES_DIR}/gcc-bs/0012-local_path.patch >> ${LOGS_DIR}/gcc/gcc_patch.log 2>&1 || exit 1
        touch ${BUILD_DIR}/gcc/src_bs/gcc-${GCC_VER}/patched_14.marker
    fi
    if [ ! -f ${BUILD_DIR}/gcc/src_bs/gcc-${GCC_VER}/patched_15.marker ] ; then
        # when building executables, not DLLs. Add --large-address-aware.
        patch -p1 < ${PATCHES_DIR}/gcc-bs/0013-LAA-default.patch >> ${LOGS_DIR}/gcc/gcc_patch.log 2>&1 || exit 1
        touch ${BUILD_DIR}/gcc/src_bs/gcc-${GCC_VER}/patched_15.marker
    fi

    popd > /dev/null

    return 0
}

# pre build
function build_gcc_pre() {
    clear; printf "Build GCC %s pre step\n" $GCC_VER

    download_gcc_src
    patch_gcc

    for arch in ${TARGET_ARCH[@]}
    do
        cd ${BUILD_DIR}/gcc/build_$arch
        rm -fr ${BUILD_DIR}/gcc/build_${arch}/*

        local bitval=$(get_arch_bit ${arch})

        mkdir -p ${BUILD_DIR}/gcc/build_${arch}/include/../lib
        ln -sf ${DST_DIR}/mingw${bitval}/{include,${arch}-w64-mingw32/include}/* ${BUILD_DIR}/gcc/build_${arch}/include
        ln -sf ${DST_DIR}/mingw${bitval}/{lib,${arch}-w64-mingw32/lib}/* ${BUILD_DIR}/gcc/build_${arch}/lib

        source cpath $arch
        PATH=${DST_DIR}/mingw${bitval}/bin:$PATH
        export PATH

        if [ "${arch}" = "i686" ] ; then
            local _optimization="--with-arch=i686 --with-tune=generic"
            local _ehconf="--disable-sjlj-exceptions --with-dwarf2"
        else
            local _optimization="--with-arch=x86-64 --with-tune=generic"
            local _ehconf=""
        fi

        if [ "${THREAD_MODEL}" = "posix" ] ; then
            local _threads="--enable-threads=posix --enable-libstdcxx-time=yes"
        else
            local _threads="--enable-threads=win32"
        fi

        # Don't use win native symlink during building GCC.
        unset MSYS

        printf "===> configuring GCC %s\n" $arch
        # Don't set any {CPP,C,CXX,LD}FLAGS.
        ../src_bs/gcc-${GCC_VER}/configure                                                        \
            --prefix=/mingw$bitval                                                                \
            --with-local-prefix=/mingw${bitval}/local                                             \
            --with-build-sysroot=${DST_DIR}/mingw$bitval                                          \
            --with-native-system-header-dir=${DST_DIR}/mingw${bitval}/${arch}-w64-mingw32/include \
            --with-gxx-include-dir=/mingw${bitval}/include/c++/${GCC_VER}                         \
            --libexecdir=/mingw${bitval}/lib                                                      \
            --build=${arch}-w64-mingw32                                                           \
            --host=${arch}-w64-mingw32                                                            \
            --target=${arch}-w64-mingw32                                                          \
            --enable-shared                                                                       \
            --enable-static                                                                       \
            --disable-multilib                                                                    \
            --enable-languages=c,c++,lto                                                          \
            ${_threads}                                                                           \
            ${_ehconf}                                                                            \
            --enable-lto                                                                          \
            --enable-checking=release                                                             \
            --enable-version-specific-runtime-libs                                                \
            --enable-fully-dynamic-string                                                         \
            --disable-libgomp                                                                     \
            --disable-libssp                                                                      \
            --disable-libquadmath                                                                 \
            --disable-bootstrap                                                                   \
            --disable-win32-registry                                                              \
            --disable-rpath                                                                       \
            --disable-nls                                                                         \
            --disable-werror                                                                      \
            --disable-symvers                                                                     \
            --disable-libstdcxx-pch                                                               \
            --disable-libstdcxx-debug                                                             \
            --with-{gmp,mpfr,mpc,isl,cloog}=${DST_DIR}/mingw$bitval                               \
            --disable-isl-version-check                                                           \
            --disable-cloog-version-check                                                         \
            --enable-cloog-backend=isl                                                            \
            --enable-graphite                                                                     \
            --with-libiconv-prefix=${DST_DIR}/mingw$bitval                                        \
            --with-libintl-prefix=${DST_DIR}/mingw$bitval                                         \
            --with-system-zlib                                                                    \
            ${_optimization}                                                                      \
            --with-gnu-as                                                                         \
            --with-gnu-ld                                                                         \
            > ${LOGS_DIR}/gcc/gcc_pre_config_${arch}.log 2>&1 || exit 1
        echo "done"

        printf "===> making GCC pre %s\n" $arch
        make $MAKEFLAGS all > ${LOGS_DIR}/gcc/gcc_pre_make_${arch}.log 2>&1 || exit 1
        echo "done"

        printf "===> installing GCC pre %s\n" $arch
        rm -fr ${PREIN_DIR}/gcc_pre/mingw$bitval
        make DESTDIR=${PREIN_DIR}/gcc_pre install > ${LOGS_DIR}/gcc/gcc_pre_install_${arch}.log 2>&1 || exit 1
        # Move libgcc_s.a to GCC EXEC_PREFIX.
        mv -f ${PREIN_DIR}/gcc_pre/mingw${bitval}/lib/gcc/${arch}-w64-mingw32/lib/libgcc_s.a \
            ${PREIN_DIR}/gcc_pre/mingw${bitval}/lib/gcc/${arch}-w64-mingw32/$GCC_VER
        # Remove unneeded files.
        rm -f ${PREIN_DIR}/gcc_pre/mingw${bitval}/lib/gcc/${arch}-w64-mingw32/${GCC_VER}/*.py
        rm -fr ${PREIN_DIR}/gcc_pre/mingw${bitval}/share/gcc-$GCC_VER
        del_empty_dir ${PREIN_DIR}/gcc_pre/mingw$bitval
        remove_la_files ${PREIN_DIR}/gcc_pre/mingw$bitval
        strip_files ${PREIN_DIR}/gcc_pre/mingw$bitval
        echo "done"

        # Enable win native symlink.
        MSYS=winsymlinks:nativestrict
        export MSYS

        printf "===> copying GCC pre %s to %s/mingw%s\n" $arch $DST_DIR $bitval
        cp -fra ${PREIN_DIR}/gcc_pre/mingw$bitval $DST_DIR
        cd ${DST_DIR}/mingw${bitval}/bin
        echo "done"
    done

    cd $ROOT_DIR
    return 0
}

# build
function build_gcc() {
    clear; printf "Build GCC %s\n" $GCC_VER

    download_gcc_src
    patch_gcc

    for arch in ${TARGET_ARCH[@]}
    do
        cd ${BUILD_DIR}/gcc/build_$arch
        rm -fr ${BUILD_DIR}/gcc/build_${arch}/*

        local bitval=$(get_arch_bit ${arch})

        mkdir -p ${BUILD_DIR}/gcc/build_${arch}/include/../lib
        ln -sf ${DST_DIR}/mingw${bitval}/{include,${arch}-w64-mingw32/include}/* ${BUILD_DIR}/gcc/build_${arch}/include
        ln -sf ${DST_DIR}/mingw${bitval}/{lib,${arch}-w64-mingw32/lib}/* ${BUILD_DIR}/gcc/build_${arch}/lib

        source cpath $arch
        PATH=${DST_DIR}/mingw${bitval}/bin:$PATH
        export PATH

        if [ "${arch}" = "i686" ] ; then
            local _optimization="--with-arch=i686 --with-tune=generic"
            local _ehconf="--disable-sjlj-exceptions --with-dwarf2"
        else
            local _optimization="--with-arch=x86-64 --with-tune=generic"
            local _ehconf=""
        fi

        if [ "${THREAD_MODEL}" = "posix" ] ; then
            local _threads="--enable-threads=posix --enable-libstdcxx-time=yes"
        else
            local _threads="--enable-threads=win32"
        fi

        # Don't use win native symlink during building GCC.
        unset MSYS

        printf "===> configuring GCC %s\n" $arch
        # Don't set any {CPP,C,CXX,LD}FLAGS.
        ../src_bs/gcc-${GCC_VER}/configure                                                        \
            --prefix=/mingw$bitval                                                                \
            --with-local-prefix=/mingw${bitval}/local                                             \
            --with-build-sysroot=${DST_DIR}/mingw$bitval                                          \
            --with-native-system-header-dir=${DST_DIR}/mingw${bitval}/${arch}-w64-mingw32/include \
            --with-gxx-include-dir=/mingw${bitval}/include/c++/${GCC_VER}                         \
            --libexecdir=/mingw${bitval}/lib                                                      \
            --build=${arch}-w64-mingw32                                                           \
            --host=${arch}-w64-mingw32                                                            \
            --target=${arch}-w64-mingw32                                                          \
            --enable-shared                                                                       \
            --enable-static                                                                       \
            --disable-multilib                                                                    \
            --enable-languages=c,c++,lto                                                          \
            ${_threads}                                                                           \
            ${_ehconf}                                                                            \
            --enable-lto                                                                          \
            --enable-checking=release                                                             \
            --enable-version-specific-runtime-libs                                                \
            --enable-fully-dynamic-string                                                         \
            --enable-libgomp                                                                      \
            --disable-libssp                                                                      \
            --disable-libquadmath                                                                 \
            --enable-bootstrap                                                                    \
            --disable-win32-registry                                                              \
            --disable-rpath                                                                       \
            --disable-nls                                                                         \
            --disable-werror                                                                      \
            --disable-symvers                                                                     \
            --disable-libstdcxx-pch                                                               \
            --disable-libstdcxx-debug                                                             \
            --with-{gmp,mpfr,mpc,isl,cloog}=${DST_DIR}/mingw$bitval                               \
            --disable-isl-version-check                                                           \
            --disable-cloog-version-check                                                         \
            --enable-cloog-backend=isl                                                            \
            --enable-graphite                                                                     \
            --with-libiconv-prefix=${DST_DIR}/mingw$bitval                                        \
            --with-libintl-prefix=${DST_DIR}/mingw$bitval                                         \
            --with-system-zlib                                                                    \
            ${_optimization}                                                                      \
            --with-gnu-as                                                                         \
            --with-gnu-ld                                                                         \
            > ${LOGS_DIR}/gcc/gcc_config_${arch}.log 2>&1 || exit 1
        echo "done"

        printf "===> making GCC %s\n" $arch
        # Setting -j$(($(nproc)+1)) sometimes makes error.
        make all > ${LOGS_DIR}/gcc/gcc_make_${arch}.log 2>&1 || exit 1
        echo "done"

        printf "===> installing GCC %s\n" $arch
        rm -fr ${PREIN_DIR}/gcc/mingw$bitval
        make DESTDIR=${PREIN_DIR}/gcc install > ${LOGS_DIR}/gcc/gcc_install_${arch}.log 2>&1 || exit 1
        # Move libgcc_s.a to GCC EXEC_PREFIX.
        mv -f ${PREIN_DIR}/gcc/mingw${bitval}/lib/gcc/${arch}-w64-mingw32/lib/libgcc_s.a \
            ${PREIN_DIR}/gcc/mingw${bitval}/lib/gcc/${arch}-w64-mingw32/$GCC_VER
        # Remove unneeded files.
        rm -f ${PREIN_DIR}/gcc/mingw${bitval}/lib/gcc/${arch}-w64-mingw32/${GCC_VER}/*.py
        rm -fr ${PREIN_DIR}/gcc/mingw${bitval}/share/gcc-$GCC_VER
        del_empty_dir ${PREIN_DIR}/gcc/mingw$bitval
        remove_la_files ${PREIN_DIR}/gcc/mingw$bitval
        strip_files ${PREIN_DIR}/gcc/mingw$bitval
        echo "done"

        # Enable win native symlink.
        MSYS=winsymlinks:nativestrict
        export MSYS

        printf "===> copying GCC %s to %s/mingw%s\n" $arch $DST_DIR $bitval
        cp -fra ${PREIN_DIR}/gcc/mingw$bitval $DST_DIR
        cd ${DST_DIR}/mingw${bitval}/bin
        # Symlink for compatibility.
        ln -fsr ../bin/gcc.exe ./cc.exe
        ln -fsr ../bin/cpp.exe ../lib
        # Symlink lto plugin into /mingw{32,64}/lib/bfd-plugins. This is needed for slim LTO.
        cd ${DST_DIR}/mingw${bitval}/lib/gcc/${arch}-w64-mingw32/$GCC_VER
        mkdir -p ${DST_DIR}/mingw${bitval}/lib/bfd-plugins
        ln -fsr ../${GCC_VER}/liblto_plugin-*.dll ../../../bfd-plugins
        echo "done"
    done

    cd $ROOT_DIR
    return 0
}

# copy only
function copy_gcc() {
    clear; printf "GCC %s\n" $GCC_VER

    for arch in ${TARGET_ARCH[@]}
    do
        local bitval=$(get_arch_bit ${arch})

        printf "===> copying GCC %s to %s/mingw%s\n" $arch $DST_DIR $bitval
        cp -fra ${PREIN_DIR}/gcc/mingw$bitval $DST_DIR
        cd ${DST_DIR}/mingw${bitval}/bin
        # Symlink for compatibility.
        ln -fsr ../bin/gcc.exe ./cc.exe
        ln -fsr ../bin/cpp.exe ../lib
        # Symlink lto plugin into /mingw{32,64}/lib/bfd-plugins. This is needed for slim LTO.
        cd ${DST_DIR}/mingw${bitval}/lib/gcc/${arch}-w64-mingw32/$GCC_VER
        mkdir -p ${DST_DIR}/mingw${bitval}/lib/bfd-plugins
        ln -fsr ../${GCC_VER}/liblto_plugin-*.dll ../../../bfd-plugins
        echo "done"
    done

    cd $ROOT_DIR
    return 0
}
