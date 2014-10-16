# GCC: The GNU Compiler Collection
# download src
function download_gcc_src() {
    if [ ! -f ${BUILD_DIR}/gcc/src/gcc-${GCC_VER}.tar.bz2 ] ; then
        printf "===> downloading GCC %s\n" $GCC_VER
        pushd ${BUILD_DIR}/gcc/src > /dev/null
        if [ $(echo $GCC_VER | grep RC) ] ; then
            dl_files ftp ftp://gcc.gnu.org/pub/gcc/snapshots/${GCC_VER}/gcc-${GCC_VER}.tar.bz2
        else
            dl_files ftp ftp://gcc.gnu.org/pub/gcc/releases/gcc-${GCC_VER}/gcc-${GCC_VER}.tar.bz2
        fi
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
        patch -p1 -i ${PATCHES_DIR}/gcc/0001-gcc-4.8-libstdc++export.patch > ${LOGS_DIR}/gcc/gcc_patch.log 2>&1 || exit 1
        touch ${BUILD_DIR}/gcc/src/gcc-${GCC_VER}/patched_03.marker
    fi
    if [ ! -f ${BUILD_DIR}/gcc/src/gcc-${GCC_VER}/patched_04.marker ] ; then
        patch -p1 -i ${PATCHES_DIR}/gcc/0002-gcc-4.7-stdthreads.patch >> ${LOGS_DIR}/gcc/gcc_patch.log 2>&1 || exit 1
        touch ${BUILD_DIR}/gcc/src/gcc-${GCC_VER}/patched_04.marker
    fi
    if [ ! -f ${BUILD_DIR}/gcc/src/gcc-${GCC_VER}/patched_05.marker ] ; then
        # Don't waste valuable commandline chars on double-quotes around "arguments" that don't need them.
        patch -p1 -i ${PATCHES_DIR}/gcc/0003-dont-escape-arguments-that-dont-need-it-in-pex-win32.patch \
            >> ${LOGS_DIR}/gcc/gcc_patch.log 2>&1 || exit 1
        touch ${BUILD_DIR}/gcc/src/gcc-${GCC_VER}/patched_05.marker
    fi
    if [ ! -f ${BUILD_DIR}/gcc/src/gcc-${GCC_VER}/patched_06.marker ] ; then
        # Make Windows behave the same as Posix in the consideration of whether
        # folder "/exists/doesnt-exist/.." is a valid path.. in Posix, it isn't.
        patch -p1 -i ${PATCHES_DIR}/gcc/0004-fix-for-windows-not-minding-non-existent-parent-dirs.patch \
            >> ${LOGS_DIR}/gcc/gcc_patch.log 2>&1 || exit 1
        touch ${BUILD_DIR}/gcc/src/gcc-${GCC_VER}/patched_06.marker
    fi
    if [ ! -f ${BUILD_DIR}/gcc/src/gcc-${GCC_VER}/patched_07.marker ] ; then
        # Don't make a lowercase backslashed path from argv[0] that then fail to strcmp with prefix(es) .. they're also ugly.
        patch -p1 -i ${PATCHES_DIR}/gcc/0005-windows-lrealpath-no-force-lowercase-nor-backslash.patch \
            >> ${LOGS_DIR}/gcc/gcc_patch.log 2>&1 || exit 1
        touch ${BUILD_DIR}/gcc/src/gcc-${GCC_VER}/patched_07.marker
    fi
    if [ ! -f ${BUILD_DIR}/gcc/src/gcc-${GCC_VER}/patched_08.marker ] ; then
        # http://gcc.gnu.org/bugzilla/show_bug.cgi?id=57440
        patch -p1 -i ${PATCHES_DIR}/gcc/0006-PR57440.patch >> ${LOGS_DIR}/gcc/gcc_patch.log 2>&1 || exit 1
        touch ${BUILD_DIR}/gcc/src/gcc-${GCC_VER}/patched_08.marker
    fi
    if [ ! -f ${BUILD_DIR}/gcc/src/gcc-${GCC_VER}/patched_09.marker ] ; then
        patch -p1 -i ${PATCHES_DIR}/gcc/0007-isl.patch >> ${LOGS_DIR}/gcc/gcc_patch.log 2>&1 || exit 1
        touch ${BUILD_DIR}/gcc/src/gcc-${GCC_VER}/patched_09.marker
    fi
    if [ ! -f ${BUILD_DIR}/gcc/src/gcc-${GCC_VER}/patched_10.marker ] ; then
        # http://gcc.gnu.org/bugzilla/show_bug.cgi?id=57653
        patch -p1 -i ${PATCHES_DIR}/gcc/0008-PR57653.patch >> ${LOGS_DIR}/gcc/gcc_patch.log 2>&1 || exit 1
        touch ${BUILD_DIR}/gcc/src/gcc-${GCC_VER}/patched_10.marker
    fi
    if [ ! -f ${BUILD_DIR}/gcc/src/gcc-${GCC_VER}/patched_11.marker ] ; then
        # Kai's libgomp fix.
        patch -p1 -i ${PATCHES_DIR}/gcc/0009-ktietz-libgomp.patch >> ${LOGS_DIR}/gcc/gcc_patch.log 2>&1 || exit 1
        touch ${BUILD_DIR}/gcc/src/gcc-${GCC_VER}/patched_11.marker
    fi
    if [ ! -f ${BUILD_DIR}/gcc/src/gcc-${GCC_VER}/patched_12.marker ] ; then
        # Enable colorizing diagnostics
        patch -p1 -i ${PATCHES_DIR}/gcc/0010-color.patch >> ${LOGS_DIR}/gcc/gcc_patch.log 2>&1 || exit 1
        touch ${BUILD_DIR}/gcc/src/gcc-${GCC_VER}/patched_12.marker
    fi
    if [ ! -f ${BUILD_DIR}/gcc/src/gcc-${GCC_VER}/patched_13.marker ] ; then
        # Don't search dirs under ${prefix} but ${build_sysroot}.
        patch -p1 -i ${PATCHES_DIR}/gcc/0011-gcc-use-build-sysroot-dir.patch >> ${LOGS_DIR}/gcc/gcc_patch.log 2>&1 || exit 1
        touch ${BUILD_DIR}/gcc/src/gcc-${GCC_VER}/patched_13.marker
    fi
    if [ ! -f ${BUILD_DIR}/gcc/src/gcc-${GCC_VER}/patched_14.marker ] ; then
        # Add /mingw{32,64}/local/{include,lib} to search dirs, and make relocatable perfectly.
        patch -p1 -i ${PATCHES_DIR}/gcc/0012-local_path.patch >> ${LOGS_DIR}/gcc/gcc_patch.log 2>&1 || exit 1
        touch ${BUILD_DIR}/gcc/src/gcc-${GCC_VER}/patched_14.marker
    fi
    if [ ! -f ${BUILD_DIR}/gcc/src/gcc-${GCC_VER}/patched_15.marker ] ; then
        # when building executables, not DLLs. Add --large-address-aware.
        patch -p1 -i ${PATCHES_DIR}/gcc/0013-LAA-default.patch >> ${LOGS_DIR}/gcc/gcc_patch.log 2>&1 || exit 1
        touch ${BUILD_DIR}/gcc/src/gcc-${GCC_VER}/patched_15.marker
    fi
    if [ ! -f ${BUILD_DIR}/gcc/src/gcc-${GCC_VER}/patched_16.marker ] ; then
        patch -p1 -i ${PATCHES_DIR}/gcc/0014-force-linking-to-dll.a.patch >> ${LOGS_DIR}/gcc/gcc_patch.log 2>&1 || exit 1
        touch ${BUILD_DIR}/gcc/src/gcc-${GCC_VER}/patched_16.marker
    fi
    if [ ! -f ${BUILD_DIR}/gcc/src/gcc-${GCC_VER}/patched_17.marker ] ; then
        patch -p1 -i ${PATCHES_DIR}/gcc/0015-nls.patch >> ${LOGS_DIR}/gcc/gcc_patch.log 2>&1 || exit 1
        touch ${BUILD_DIR}/gcc/src/gcc-${GCC_VER}/patched_17.marker
    fi
    if [ ! -f ${BUILD_DIR}/gcc/src/gcc-${GCC_VER}/patched_18.marker ] ; then
        patch -p1 -i ${PATCHES_DIR}/gcc/0016-gcc-ASLR-HEASLR.patch >> ${LOGS_DIR}/gcc/gcc_patch.log 2>&1 || exit 1
        touch ${BUILD_DIR}/gcc/src/gcc-${GCC_VER}/patched_18.marker
    fi
    if [ ! -f ${BUILD_DIR}/gcc/src/gcc-${GCC_VER}/patched_19.marker ] ; then
        patch -p1 -i ${PATCHES_DIR}/gcc/0017-for-fstack-protector.patch >> ${LOGS_DIR}/gcc/gcc_patch.log 2>&1 || exit 1
        touch ${BUILD_DIR}/gcc/src/gcc-${GCC_VER}/patched_19.marker
    fi
    if [ ! -f ${BUILD_DIR}/gcc/src/gcc-${GCC_VER}/patched_20.marker ] ; then
        patch -p1 -i ${PATCHES_DIR}/gcc/0018-gcc-windows7-or-later-default.patch \
            >> ${LOGS_DIR}/gcc/gcc_patch.log 2>&1 || exit 1
        touch ${BUILD_DIR}/gcc/src/gcc-${GCC_VER}/patched_20.marker
    fi

    popd > /dev/null

    return 0
}

# cleanup
function symlink_gcc() {
    local _arch=${1}
    local _bitval=$(get_arch_bit ${_arch})

    pushd ${PREIN_DIR}/gcc/mingw${_bitval}/bin > /dev/null

    find . -type f -a \( -name "cpp*.exe" -o -name "g++*.exe" -o -name "gcc*.exe" -o -name "gcov*.exe" \) -printf '%f\n' | \
        xargs -I% ln -fsr % ./${_arch}-w64-mingw32-%
    find . -type f -a \( -name "cpp*.exe" -o -name "g++*.exe" -o -name "gcc*.exe" -o -name "gcov*.exe" \) -print0  | \
        while read -r -d '' fname; do ln -fsr $fname ${fname%%-${GCC_VER/-*}.exe}.exe; done
    find . -type f -a \( -name "cpp*.exe" -o -name "g++*.exe" -o -name "gcc*.exe" -o -name "gcov*.exe" \) -printf '%f\n' | \
        while read -r fname; do ln -fsr $fname ${_arch}-w64-mingw32-${fname%%-${GCC_VER/-*}.exe}.exe; done
    ln -fsr ./g++-${GCC_VER/-*}.exe ./c++-${GCC_VER/-*}.exe
    ln -fsr ./g++-${GCC_VER/-*}.exe ./c++.exe
    ln -fsr ./g++-${GCC_VER/-*}.exe ./${_arch}-w64-mingw32-c++-${GCC_VER/-*}.exe
    ln -fsr ./g++-${GCC_VER/-*}.exe ./${_arch}-w64-mingw32-c++.exe
    ln -fsr ./gcc.exe ./cc

    popd > /dev/null

    pushd ${PREIN_DIR}/gcc/mingw${_bitval}/lib/gcc/${arch}-w64-mingw32/${GCC_VER/-*} > /dev/null

    # for slim LTO
    mkdir -p ${PREIN_DIR}/gcc/mingw${_bitval}/lib/bfd-plugins
    ln -fsr ./liblto_plugin-*.dll ../../../bfd-plugins

    popd > /dev/null

    return 0
}

function term_gcc() {

    local _arch=${1}
    local _bitval=$(get_arch_bit ${_arch})

    local -ra _dlllist=(
        "libgmp-*.dll"
        "libmpfr-*.dll"
        "libmpc-*.dll"
        "libisl-*.dll"
        "libcloog-isl-*.dll"
    )

    # POSIX conformance launcher scripts for c89 and c99
    cat > ${DST_DIR}/mingw${_bitval}/bin/c89 <<"_EOF_"
#!/usr/bin/env bash
fl="-std=c89"
for opt;
do
    case "${opt}" in
        -ansi | -std=c89 | -std=iso9899:1990 )
            fl=""
            ;;
        -std=* )
            echo "`basename $0` called with non ANSI/ISO C option $opt" >&2
            exit 1
            ;;
    esac
done
exec gcc $fl ${1+"$@"}
_EOF_

    cat > ${DST_DIR}/mingw${_bitval}/bin/c99 <<"_EOF_"
#!/usr/bin/env bash
fl="-std=c99"
for opt;
do
    case "${opt}" in
        -std=c99 | -std=iso9899:1999 )
            fl=""
            ;;
        -std=* )
            echo "`basename $0` called with non ISO C99 option $opt" >&2
            exit 1
            ;;
    esac
done
exec gcc $fl ${1+"$@"}
_EOF_

    # relocate DLLs
    for _dll in ${_dlllist[@]}
    do
        mv -f ${DST_DIR}/mingw${_bitval}/bin/${_dll} ${DST_DIR}/mingw${_bitval}/lib/gcc/${_arch}-w64-mingw32/${GCC_VER/-*}
    done
    # delete headers & libs of gcc_libs
    rm -f ${DST_DIR}/mingw${_bitval}/include/gmp.h
    rm -f ${DST_DIR}/mingw${_bitval}/include/mpfr.h
    rm -f ${DST_DIR}/mingw${_bitval}/include/mpf2mpfr.h
    rm -f ${DST_DIR}/mingw${_bitval}/include/mpc.h
    rm -fr ${DST_DIR}/mingw${_bitval}/include/isl
    rm -fr ${DST_DIR}/mingw${_bitval}/include/cloog
    rm -f ${DST_DIR}/mingw${_bitval}/lib/libgmp.dll.a
    rm -f ${DST_DIR}/mingw${_bitval}/lib/libmpfr.dll.a
    rm -f ${DST_DIR}/mingw${_bitval}/lib/libmpc.dll.a
    rm -f ${DST_DIR}/mingw${_bitval}/lib/libisl.dll.a
    rm -f ${DST_DIR}/mingw${_bitval}/lib/libcloog-isl.dll.a

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
        local _aof=$(arch_optflags ${arch})

        # for relocatable
        mkdir -p ${BUILD_DIR}/gcc/build_${arch}/include/../lib
        ln -fs ${DST_DIR}/mingw${bitval}/{include,${arch}-w64-mingw32/include}/* ${BUILD_DIR}/gcc/build_${arch}/include
        ln -fs ${DST_DIR}/mingw${bitval}/{lib,${arch}-w64-mingw32/lib}/* ${BUILD_DIR}/gcc/build_${arch}/lib

        source cpath $arch
        PATH=${DST_DIR}/mingw${bitval}/bin:$PATH
        export PATH

        # for -fstack-protector-strong
        local _old_gcc_ver=$(gcc -dumpversion)
        ln -fs /mingw${bitval}/lib/gcc/${arch}-w64-mingw32/${_old_gcc_ver}/libssp*.a ${BUILD_DIR}/gcc/build_${arch}/lib
        local _stage1_ldflags="-static-libstdc++ -static-libgcc -fstack-protector-strong --param=ssp-buffer-size=4"

        if [ "${arch}" = "i686" ] ; then
            local _ehconf="--disable-sjlj-exceptions --with-dwarf2"
        else
            local _ehconf=""
        fi

        # Don't search build toolchain include dir.
        local _nshdir="${DST_DIR}/mingw${bitval}/${arch}-w64-mingw32/include"

        # package version
        local _pkgver="GCC $GCC_VER Rev.${GCC_PKGREV}, target: ${arch}-w64-mingw32, built on ${GCC_BUILT_DATE}"

        # Don't use win native symlink during building GCC.
        unset MSYS

        printf "===> configuring GCC %s\n" $arch
        ../src/gcc-${GCC_VER}/configure                                      \
            --prefix=/mingw$bitval                                           \
            --with-local-prefix=/mingw${bitval}/local                        \
            --with-build-sysroot=${DST_DIR}/mingw$bitval                     \
            --with-native-system-header-dir=${_nshdir}                       \
            --with-gxx-include-dir=/mingw${bitval}/include/c++/${GCC_VER/-*} \
            --libexecdir=/mingw${bitval}/lib                                 \
            --build=${arch}-w64-mingw32                                      \
            --host=${arch}-w64-mingw32                                       \
            --target=${arch}-w64-mingw32                                     \
            --enable-shared                                                  \
            --enable-static                                                  \
            --disable-multilib                                               \
            --enable-languages=c,c++,lto                                     \
            --enable-threads=$THREAD_MODEL                                   \
            --enable-libstdcxx-time=yes                                      \
            ${_ehconf}                                                       \
            --enable-lto                                                     \
            --enable-checking=release                                        \
            --enable-version-specific-runtime-libs                           \
            --enable-fully-dynamic-string                                    \
            --disable-libgomp                                                \
            --enable-libssp                                                  \
            --disable-libquadmath                                            \
            --enable-bootstrap                                               \
            --disable-win32-registry                                         \
            --enable-nls                                                     \
            --disable-rpath                                                  \
            --disable-werror                                                 \
            --disable-symvers                                                \
            --disable-libstdcxx-pch                                          \
            --disable-libstdcxx-debug                                        \
            --with-{gmp,mpfr,mpc,isl,cloog}=${DST_DIR}/mingw$bitval          \
            --disable-isl-version-check                                      \
            --disable-cloog-version-check                                    \
            --enable-cloog-backend=isl                                       \
            --enable-graphite                                                \
            --with-libiconv-prefix=${DST_DIR}/mingw$bitval                   \
            --with-libintl-prefix=${DST_DIR}/mingw$bitval                    \
            --with-system-zlib                                               \
            --with-arch=${arch/_/-}                                          \
            --with-tune=generic                                              \
            --with-pkgversion="${_pkgver}"                                   \
            --with-gnu-as                                                    \
            --with-gnu-ld                                                    \
            --program-suffix=-${GCC_VER/-*}                                  \
            --with-stage1-ldflags="${_stage1_ldflags}"                       \
            > ${LOGS_DIR}/gcc/gcc_config_${arch}.log 2>&1 || exit 1
        echo "done"

        printf "===> making GCC %s\n" $arch
        # Setting -j$(($(nproc)+1)) sometimes makes error.
        make                                                        \
            CPPFLAGS="${_CPPFLAGS}"                                 \
            CPPFLAGS_FOR_TARGET="${_CPPFLAGS}"                      \
            CFLAGS="${_aof} ${_CFLAGS} ${_CPPFLAGS}"                \
            CFLAGS_FOR_TARGET="${_aof} ${_CFLAGS} ${_CPPFLAGS}"     \
            BOOT_CFLAGS="${_aof} ${_CFLAGS} ${_CPPFLAGS}"           \
            CXXFLAGS="${_aof} ${_CXXFLAGS} ${_CPPFLAGS}"            \
            CXXFLAGS_FOR_TARGET="${_aof} ${_CXXFLAGS} ${_CPPFLAGS}" \
            BOOT_CXXFLAGS="${_aof} ${_CXXFLAGS} ${_CPPFLAGS}"       \
            LDFLAGS="${_LDFLAGS}"                                   \
            LDFLAGS_FOR_TARGET="${_LDFLAGS}"                        \
            BOOT_LDFLAGS="${_LDFLAGS}"                              \
            bootstrap > ${LOGS_DIR}/gcc/gcc_make_${arch}.log 2>&1 || exit 1
        echo "done"

        printf "===> installing GCC %s\n" $arch
        rm -fr ${PREIN_DIR}/gcc/mingw$bitval
        make DESTDIR=${PREIN_DIR}/gcc install > ${LOGS_DIR}/gcc/gcc_install_${arch}.log 2>&1 || exit 1
        # Move libgcc_s.a to GCC EXEC_PREFIX.
        mv -f ${PREIN_DIR}/gcc/mingw${bitval}/lib/gcc/${arch}-w64-mingw32/lib/libgcc_s.a \
            ${PREIN_DIR}/gcc/mingw${bitval}/lib/gcc/${arch}-w64-mingw32/${GCC_VER/-*}
        # Remove unneeded files.
        rm -f ${PREIN_DIR}/gcc/mingw${bitval}/lib/gcc/${arch}-w64-mingw32/${GCC_VER/-*}/*.py
        rm -fr ${PREIN_DIR}/gcc/mingw${bitval}/share/gcc-${GCC_VER/-*}
        del_empty_dir ${PREIN_DIR}/gcc/mingw$bitval
        remove_la_files ${PREIN_DIR}/gcc/mingw$bitval
        strip_files ${PREIN_DIR}/gcc/mingw$bitval
        echo "done"

        # Enable win native symlink.
        MSYS=winsymlinks:nativestrict
        export MSYS

        # symlink
        symlink_gcc $arch

        printf "===> copying GCC %s to %s/mingw%s\n" $arch $DST_DIR $bitval
        symcopy ${PREIN_DIR}/gcc/mingw$bitval $DST_DIR
        # relocate DLLs & cleanup.
        term_gcc $arch
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
        symcopy ${PREIN_DIR}/gcc/mingw$bitval $DST_DIR
        # relocate DLLs & cleanup.
        term_gcc $arch
        echo "done"
    done

    cd $ROOT_DIR
    return 0
}
