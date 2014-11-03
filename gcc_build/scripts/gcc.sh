# GCC: The GNU Compiler Collection
# Download the src and decompress it.
function download_gcc_src() {
    # Download the src.
    if [ ! -f ${BUILD_DIR}/gcc/src/gcc-${GCC_VER}.tar.bz2 ]; then
        printf "===> Downloading GCC %s...\n" $GCC_VER
        pushd ${BUILD_DIR}/gcc/src > /dev/null
        if [ $(echo $GCC_VER | grep RC) ]; then
            dl_files ftp ftp://gcc.gnu.org/pub/gcc/snapshots/${GCC_VER}/gcc-${GCC_VER}.tar.bz2
        else
            dl_files ftp ftp://gcc.gnu.org/pub/gcc/releases/gcc-${GCC_VER}/gcc-${GCC_VER}.tar.bz2
        fi
        popd > /dev/null
        echo "done"
    fi

    # Decompress the src archive.
    if [ ! -d ${BUILD_DIR}/gcc/src/gcc-$GCC_VER ]; then
        printf "===> Extracting GCC %s...\n" $GCC_VER
        pushd ${BUILD_DIR}/gcc/src > /dev/null
        decomp_arch ${BUILD_DIR}/gcc/src/gcc-${GCC_VER}.tar.bz2
        popd > /dev/null
        echo "done"
    fi

    return 0
}

# Apply patches.
function prepare_gcc() {
    # Apply patches.
    printf "===> Applying patches to GCC %s...\n" $GCC_VER
    pushd ${BUILD_DIR}/gcc/src/gcc-$GCC_VER > /dev/null
    if [ ! -f ${BUILD_DIR}/gcc/src/gcc-${GCC_VER}/patched_01.marker ]; then
        # Do not install libiberty.
        sed -i 's/install_to_$(INSTALL_DEST) //' libiberty/Makefile.in
        touch ${BUILD_DIR}/gcc/src/gcc-${GCC_VER}/patched_01.marker
    fi
    if [ ! -f ${BUILD_DIR}/gcc/src/gcc-${GCC_VER}/patched_02.marker ]; then
        # Hack! - some configure tests for header files using "$CPP $CPPFLAGS".
        sed -i "/ac_cpp=/s/\$CPPFLAGS/\$CPPFLAGS -Os/" {libiberty,gcc}/configure
        touch ${BUILD_DIR}/gcc/src/gcc-${GCC_VER}/patched_02.marker
    fi
    if [ ! -f ${BUILD_DIR}/gcc/src/gcc-${GCC_VER}/patched_03.marker ]; then
        patch -p1 -i ${PATCHES_DIR}/gcc/0001-gcc-4.8-libstdc++export.patch > ${LOGS_DIR}/gcc/gcc_patch.log 2>&1 || exit 1
        touch ${BUILD_DIR}/gcc/src/gcc-${GCC_VER}/patched_03.marker
    fi
    if [ ! -f ${BUILD_DIR}/gcc/src/gcc-${GCC_VER}/patched_04.marker ]; then
        patch -p1 -i ${PATCHES_DIR}/gcc/0002-gcc-4.7-stdthreads.patch >> ${LOGS_DIR}/gcc/gcc_patch.log 2>&1 || exit 1
        touch ${BUILD_DIR}/gcc/src/gcc-${GCC_VER}/patched_04.marker
    fi
    if [ ! -f ${BUILD_DIR}/gcc/src/gcc-${GCC_VER}/patched_05.marker ]; then
        # Don't waste valuable commandline chars on double-quotes around "arguments" that don't need them.
        patch -p1 -i ${PATCHES_DIR}/gcc/0003-dont-escape-arguments-that-dont-need-it-in-pex-win32.patch \
            >> ${LOGS_DIR}/gcc/gcc_patch.log 2>&1 || exit 1
        touch ${BUILD_DIR}/gcc/src/gcc-${GCC_VER}/patched_05.marker
    fi
    if [ ! -f ${BUILD_DIR}/gcc/src/gcc-${GCC_VER}/patched_06.marker ]; then
        # Make Windows behave the same as Posix in the consideration of whether
        # folder "/exists/doesnt-exist/.." is a valid path.. in Posix, it isn't.
        patch -p1 -i ${PATCHES_DIR}/gcc/0004-fix-for-windows-not-minding-non-existent-parent-dirs.patch \
            >> ${LOGS_DIR}/gcc/gcc_patch.log 2>&1 || exit 1
        touch ${BUILD_DIR}/gcc/src/gcc-${GCC_VER}/patched_06.marker
    fi
    if [ ! -f ${BUILD_DIR}/gcc/src/gcc-${GCC_VER}/patched_07.marker ]; then
        # Don't make a lowercase backslashed path from argv[0] that then fail to strcmp with prefix(es) .. they're also ugly.
        patch -p1 -i ${PATCHES_DIR}/gcc/0005-windows-lrealpath-no-force-lowercase-nor-backslash.patch \
            >> ${LOGS_DIR}/gcc/gcc_patch.log 2>&1 || exit 1
        touch ${BUILD_DIR}/gcc/src/gcc-${GCC_VER}/patched_07.marker
    fi
    if [ ! -f ${BUILD_DIR}/gcc/src/gcc-${GCC_VER}/patched_08.marker ]; then
        # http://gcc.gnu.org/bugzilla/show_bug.cgi?id=57440
        patch -p1 -i ${PATCHES_DIR}/gcc/0006-PR57440.patch >> ${LOGS_DIR}/gcc/gcc_patch.log 2>&1 || exit 1
        touch ${BUILD_DIR}/gcc/src/gcc-${GCC_VER}/patched_08.marker
    fi
    if [ ! -f ${BUILD_DIR}/gcc/src/gcc-${GCC_VER}/patched_09.marker ]; then
        # For building with 0.13 or later isl.
        patch -p1 -i ${PATCHES_DIR}/gcc/0007-isl.patch >> ${LOGS_DIR}/gcc/gcc_patch.log 2>&1 || exit 1
        touch ${BUILD_DIR}/gcc/src/gcc-${GCC_VER}/patched_09.marker
    fi
    if [ ! -f ${BUILD_DIR}/gcc/src/gcc-${GCC_VER}/patched_10.marker ]; then
        # http://gcc.gnu.org/bugzilla/show_bug.cgi?id=57653
        patch -p1 -i ${PATCHES_DIR}/gcc/0008-PR57653.patch >> ${LOGS_DIR}/gcc/gcc_patch.log 2>&1 || exit 1
        touch ${BUILD_DIR}/gcc/src/gcc-${GCC_VER}/patched_10.marker
    fi
    if [ ! -f ${BUILD_DIR}/gcc/src/gcc-${GCC_VER}/patched_11.marker ]; then
        # Kai's libgomp fix.
        patch -p1 -i ${PATCHES_DIR}/gcc/0009-ktietz-libgomp.patch >> ${LOGS_DIR}/gcc/gcc_patch.log 2>&1 || exit 1
        touch ${BUILD_DIR}/gcc/src/gcc-${GCC_VER}/patched_11.marker
    fi
    if [ ! -f ${BUILD_DIR}/gcc/src/gcc-${GCC_VER}/patched_12.marker ]; then
        # Enable colorizing diagnostics
        patch -p1 -i ${PATCHES_DIR}/gcc/0010-color.patch >> ${LOGS_DIR}/gcc/gcc_patch.log 2>&1 || exit 1
        touch ${BUILD_DIR}/gcc/src/gcc-${GCC_VER}/patched_12.marker
    fi
    if [ ! -f ${BUILD_DIR}/gcc/src/gcc-${GCC_VER}/patched_13.marker ]; then
        # Don't search dirs under ${prefix} but ${build_sysroot}.
        patch -p1 -i ${PATCHES_DIR}/gcc/0011-gcc-use-build-sysroot-dir.patch >> ${LOGS_DIR}/gcc/gcc_patch.log 2>&1 || exit 1
        touch ${BUILD_DIR}/gcc/src/gcc-${GCC_VER}/patched_13.marker
    fi
    if [ ! -f ${BUILD_DIR}/gcc/src/gcc-${GCC_VER}/patched_14.marker ]; then
        # Add /mingw{32,64}/local/{include,lib} to search dirs, and make relocatable perfectly.
        patch -p1 -i ${PATCHES_DIR}/gcc/0012-local_path.patch >> ${LOGS_DIR}/gcc/gcc_patch.log 2>&1 || exit 1
        touch ${BUILD_DIR}/gcc/src/gcc-${GCC_VER}/patched_14.marker
    fi
    if [ ! -f ${BUILD_DIR}/gcc/src/gcc-${GCC_VER}/patched_15.marker ]; then
        # when building executables, not DLLs. Add --large-address-aware.
        patch -p1 -i ${PATCHES_DIR}/gcc/0013-LAA-default.patch >> ${LOGS_DIR}/gcc/gcc_patch.log 2>&1 || exit 1
        touch ${BUILD_DIR}/gcc/src/gcc-${GCC_VER}/patched_15.marker
    fi
    if [ ! -f ${BUILD_DIR}/gcc/src/gcc-${GCC_VER}/patched_16.marker ]; then
        # Dynamically linking to libintl and libiconv.
        patch -p1 -i ${PATCHES_DIR}/gcc/0014-force-linking-to-dll.a.patch >> ${LOGS_DIR}/gcc/gcc_patch.log 2>&1 || exit 1
        touch ${BUILD_DIR}/gcc/src/gcc-${GCC_VER}/patched_16.marker
    fi
    if [ ! -f ${BUILD_DIR}/gcc/src/gcc-${GCC_VER}/patched_17.marker ]; then
        # libstdc++: Fix detection of libintl.
        patch -p1 -i ${PATCHES_DIR}/gcc/0015-nls.patch >> ${LOGS_DIR}/gcc/gcc_patch.log 2>&1 || exit 1
        touch ${BUILD_DIR}/gcc/src/gcc-${GCC_VER}/patched_17.marker
    fi
    if [ ! -f ${BUILD_DIR}/gcc/src/gcc-${GCC_VER}/patched_18.marker ]; then
        # Enable nxcompat and (HE)ASLR by default.
        patch -p1 -i ${PATCHES_DIR}/gcc/0016-gcc-ASLR-HEASLR.patch >> ${LOGS_DIR}/gcc/gcc_patch.log 2>&1 || exit 1
        touch ${BUILD_DIR}/gcc/src/gcc-${GCC_VER}/patched_18.marker
    fi
    if [ ! -f ${BUILD_DIR}/gcc/src/gcc-${GCC_VER}/patched_19.marker ]; then
        # For building with -fstack-protector*.
        # Link libgcc to libssp statically.
        patch -p1 -i ${PATCHES_DIR}/gcc/0017-for-fstack-protector.patch >> ${LOGS_DIR}/gcc/gcc_patch.log 2>&1 || exit 1
        touch ${BUILD_DIR}/gcc/src/gcc-${GCC_VER}/patched_19.marker
    fi
    if [ ! -f ${BUILD_DIR}/gcc/src/gcc-${GCC_VER}/patched_20.marker ]; then
        # Assume that target is windows 7 or later. XP has died, and nobody uses vista.
        patch -p1 -i ${PATCHES_DIR}/gcc/0018-gcc-windows7-or-later-default.patch \
            >> ${LOGS_DIR}/gcc/gcc_patch.log 2>&1 || exit 1
        touch ${BUILD_DIR}/gcc/src/gcc-${GCC_VER}/patched_20.marker
    fi
    popd > /dev/null
    echo "done"

    return 0
}

# Create symlinks.
function symlink_gcc() {
    local _arch=${1}
    local _bitval=$(get_arch_bit ${_arch})

    pushd ${PREIN_DIR}/gcc/mingw${_bitval}/bin > /dev/null
    # Symlinking to ${_arch}-w64-mingw32-*.exe.
    find . -type f -a \( -name "cpp*.exe" -o -name "g++*.exe" -o -name "gcc*.exe" -o -name "gcov*.exe" \) -printf '%f\n' | \
        xargs -I% ln -fsr % ./${_arch}-w64-mingw32-%
    # Symlinking to *.exe added versioned suffix.
    find . -type f -a \( -name "cpp*.exe" -o -name "g++*.exe" -o -name "gcc*.exe" -o -name "gcov*.exe" \) -print0  | \
        while read -r -d '' fname
        do
            ln -fsr $fname ${fname%%-${GCC_VER/-*}.exe}.exe
        done
    # Symlinking to ${_arch}-w64-mingw32-*-${GCC_VER}.exe.
    find . -type f -a \( -name "cpp*.exe" -o -name "g++*.exe" -o -name "gcc*.exe" -o -name "gcov*.exe" \) -printf '%f\n' | \
        while read -r fname
        do
            ln -fsr $fname ${_arch}-w64-mingw32-${fname%%-${GCC_VER/-*}.exe}.exe
        done
    # c++*.exe are symlinks of g++-${GCC_VER}.exe.
    ln -fsr ./g++-${GCC_VER/-*}.exe ./c++-${GCC_VER/-*}.exe
    ln -fsr ./g++-${GCC_VER/-*}.exe ./c++.exe
    ln -fsr ./g++-${GCC_VER/-*}.exe ./${_arch}-w64-mingw32-c++-${GCC_VER/-*}.exe
    ln -fsr ./g++-${GCC_VER/-*}.exe ./${_arch}-w64-mingw32-c++.exe
    # Many packages expect this symlink.
    ln -fsr ./gcc.exe ./cc
    popd > /dev/null

    pushd ${PREIN_DIR}/gcc/mingw${_bitval}/lib/gcc/${_arch}-w64-mingw32/${GCC_VER/-*} > /dev/null
    # This is necessary for slim LTO.
    mkdir -p ${PREIN_DIR}/gcc/mingw${_bitval}/lib/bfd-plugins
    ln -fsr ./liblto_plugin-*.dll ../../../bfd-plugins
    popd > /dev/null

    return 0
}

# Cleanup.
function term_gcc() {
    local _arch=${1}
    local _bitval=$(get_arch_bit ${_arch})

    # DLLs list of gcc_libs.
    local -ra _dlllist=(
        "libgmp-*.dll"
        "libmpfr-*.dll"
        "libmpc-*.dll"
        "libisl-*.dll"
        "libcloog-isl-*.dll"
    )

    # POSIX conformance launcher scripts for c89, c99 and c11.
    cat > ${DST_DIR}/mingw${_bitval}/bin/c89 << "__EOF__"
#!/usr/bin/env bash
fl="-std=c89"
for opt;
do
    case "${opt}" in
        -ansi | -std=c89 | -std=c90 | -std=iso9899:1990 )
            fl=""
            ;;
        -std=* )
            echo "$(basename $0) called with non ANSI/ISO C option $opt" >&2
            exit 1
            ;;
    esac
done
exec gcc $fl ${1+"$@"}
__EOF__

    cat > ${DST_DIR}/mingw${_bitval}/bin/c99 << "__EOF__"
#!/usr/bin/env bash
fl="-std=c99"
for opt;
do
    case "${opt}" in
        -std=c99 | -std=iso9899:1999 )
            fl=""
            ;;
        -std=* )
            echo "$(basename $0) called with non ISO C99 option $opt" >&2
            exit 1
            ;;
    esac
done
exec gcc $fl ${1+"$@"}
__EOF__

    cat > ${DST_DIR}/mingw${_bitval}/bin/c11 << "__EOF__"
#!/usr/bin/env bash
fl="-std=c11"
for opt;
do
    case "${opt}" in
        -std=c11 | -std=iso9899:2011 )
            fl=""
            ;;
        -std=* )
            echo "$(basename $0) called with non ISO C11 option $opt" >&2
            exit 1
            ;;
    esac
done
exec gcc $fl ${1+"$@"}
__EOF__

    # Relocate DLLs to EXEC_PREFIX.
    local _dll
    for _dll in ${_dlllist[@]}
    do
        mv -f ${DST_DIR}/mingw${_bitval}/bin/$_dll ${DST_DIR}/mingw${_bitval}/lib/gcc/${_arch}-w64-mingw32/${GCC_VER/-*}
    done
    # Remove headers & libs of gcc_libs.
    # GMP
    rm -f  ${DST_DIR}/mingw${_bitval}/include/gmp.h
    rm -f  ${DST_DIR}/mingw${_bitval}/lib/libgmp.dll.a
    # MPFR
    rm -f  ${DST_DIR}/mingw${_bitval}/include/mpfr.h
    rm -f  ${DST_DIR}/mingw${_bitval}/include/mpf2mpfr.h
    rm -f  ${DST_DIR}/mingw${_bitval}/lib/libmpfr.dll.a
    # MPC
    rm -f  ${DST_DIR}/mingw${_bitval}/include/mpc.h
    rm -f  ${DST_DIR}/mingw${_bitval}/lib/libmpc.dll.a
    # ISL
    rm -fr ${DST_DIR}/mingw${_bitval}/include/isl
    rm -f  ${DST_DIR}/mingw${_bitval}/lib/libisl.dll.a
    # CLooG
    rm -fr ${DST_DIR}/mingw${_bitval}/include/cloog
    rm -f  ${DST_DIR}/mingw${_bitval}/lib/libcloog-isl.dll.a

    return 0
}

# Build and install.
function build_gcc() {
    clear; printf "Build GCC %s\n" $GCC_VER

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
                printf "build_gcc: Unknown Option: '%s'\n" $_opt
                echo "...exit"
                exit 1
                ;;
        esac
    done

    # Setup.
    if ${_rebuild}; then
        download_gcc_src
        prepare_gcc
    fi

    local _arch
    for _arch in ${TARGET_ARCH[@]}
    do
        local _bitval=$(get_arch_bit ${_arch})

        if ${_rebuild}; then
            cd ${BUILD_DIR}/gcc/build_$_arch
            # Cleanup the build dir.
            rm -fr ${BUILD_DIR}/gcc/build_${_arch}/*

            # PATH exporting.
            source cpath $_arch
            PATH=${DST_DIR}/mingw${_bitval}/bin:$PATH
            export PATH

            # For relocatable.
            mkdir -p ${BUILD_DIR}/gcc/build_${_arch}/include/../lib
            ln -fs ${DST_DIR}/mingw${_bitval}/{include,${_arch}-w64-mingw32/include}/* ${BUILD_DIR}/gcc/build_${_arch}/include
            ln -fs ${DST_DIR}/mingw${_bitval}/{lib,${_arch}-w64-mingw32/lib}/* ${BUILD_DIR}/gcc/build_${_arch}/lib

            # For building with -fstack-protector*
            local _old_gcc_ver=$(gcc -dumpversion)
            ln -fs /mingw${_bitval}/lib/gcc/${_arch}-w64-mingw32/${_old_gcc_ver}/libssp*.a ${BUILD_DIR}/gcc/build_${_arch}/lib
            local _stage1_ldflags="-static-libstdc++ -static-libgcc -fstack-protector-strong --param=ssp-buffer-size=4"

            # Arch specific config option.
            if [ "${_arch}" = "i686" ]; then
                local _ehconf="--disable-sjlj-exceptions --with-dwarf2"
            else
                local _ehconf=""
            fi

            # Don't search build toolchain include dir.
            local _nshdir="${DST_DIR}/mingw${_bitval}/${_arch}-w64-mingw32/include"

            # package version.
            local _pkgver="GCC $GCC_VER Rev.${GCC_PKGREV}, target: ${_arch}-w64-mingw32, built on ${GCC_BUILT_DATE}"

            # Don't use win native symlink during building GCC.
            unset MSYS

            # Configure.
            printf "===> Configuring GCC %s...\n" $_arch
            ../src/gcc-${GCC_VER}/configure                                       \
                --prefix=/mingw$_bitval                                           \
                --with-local-prefix=/mingw${_bitval}/local                        \
                --with-build-sysroot=${DST_DIR}/mingw$_bitval                     \
                --with-native-system-header-dir=${_nshdir}                        \
                --with-gxx-include-dir=/mingw${_bitval}/include/c++/${GCC_VER/-*} \
                --libexecdir=/mingw${_bitval}/lib                                 \
                --build=${_arch}-w64-mingw32                                      \
                --host=${_arch}-w64-mingw32                                       \
                --target=${_arch}-w64-mingw32                                     \
                --enable-shared                                                   \
                --enable-static                                                   \
                --disable-multilib                                                \
                --enable-languages=c,c++,lto                                      \
                --enable-threads=$THREAD_MODEL                                    \
                --enable-libstdcxx-time=yes                                       \
                ${_ehconf}                                                        \
                --enable-lto                                                      \
                --enable-checking=release                                         \
                --enable-version-specific-runtime-libs                            \
                --enable-fully-dynamic-string                                     \
                --disable-libgomp                                                 \
                --enable-libssp                                                   \
                --disable-libquadmath                                             \
                --enable-bootstrap                                                \
                --disable-win32-registry                                          \
                --enable-nls                                                      \
                --disable-rpath                                                   \
                --disable-werror                                                  \
                --disable-symvers                                                 \
                --disable-libstdcxx-pch                                           \
                --disable-libstdcxx-debug                                         \
                --with-{gmp,mpfr,mpc,isl,cloog}=${DST_DIR}/mingw$_bitval          \
                --disable-isl-version-check                                       \
                --disable-cloog-version-check                                     \
                --enable-cloog-backend=isl                                        \
                --enable-graphite                                                 \
                --with-lib{iconv,intl}-prefix=${DST_DIR}/mingw$_bitval            \
                --with-system-zlib                                                \
                --with-arch=${arch/_/-}                                           \
                --with-tune=generic                                               \
                --with-pkgversion="${_pkgver}"                                    \
                --with-gnu-as                                                     \
                --with-gnu-ld                                                     \
                --program-suffix=-${GCC_VER/-*}                                   \
                --with-stage1-ldflags="${_stage1_ldflags}"                        \
                > ${LOGS_DIR}/gcc/gcc_config_${_arch}.log 2>&1 || exit 1
            echo "done"

            # Make.
            printf "===> Making GCC %s...\n" $_arch
            # Setting -j$(($(nproc)+1)) sometimes makes error.
            make                                                                    \
                CPPFLAGS="${CPPFLAGS_}"                                             \
                CPPFLAGS_FOR_TARGET="${CPPFLAGS_}"                                  \
                CFLAGS="-march=${_arch/_/-} ${CFLAGS_} ${CPPFLAGS_}"                \
                CFLAGS_FOR_TARGET="-march=${_arch/_/-} ${CFLAGS_} ${CPPFLAGS_}"     \
                BOOT_CFLAGS="-march=${_arch/_/-} ${CFLAGS_} ${CPPFLAGS_}"           \
                CXXFLAGS="-march=${_arch/_/-} ${CXXFLAGS_} ${CPPFLAGS_}"            \
                CXXFLAGS_FOR_TARGET="-march=${_arch/_/-} ${CXXFLAGS_} ${CPPFLAGS_}" \
                BOOT_CXXFLAGS="-march=${_arch/_/-} ${CXXFLAGS_} ${CPPFLAGS_}"       \
                LDFLAGS="${LDFLAGS_}"                                               \
                LDFLAGS_FOR_TARGET="${LDFLAGS_}"                                    \
                BOOT_LDFLAGS="${LDFLAGS_}"                                          \
                bootstrap > ${LOGS_DIR}/gcc/gcc_make_${_arch}.log 2>&1 || exit 1
            echo "done"

            # Install.
            printf "===> Installing GCC %s...\n" $_arch
            rm -fr ${PREIN_DIR}/gcc/mingw$_bitval
            make DESTDIR=${PREIN_DIR}/gcc install > ${LOGS_DIR}/gcc/gcc_install_${_arch}.log 2>&1 || exit 1
            # Move libgcc_s.a to GCC EXEC_PREFIX.
            mv -f ${PREIN_DIR}/gcc/mingw${_bitval}/lib/gcc/${_arch}-w64-mingw32/lib/libgcc_s.a \
                ${PREIN_DIR}/gcc/mingw${_bitval}/lib/gcc/${_arch}-w64-mingw32/${GCC_VER/-*}
            # Remove unneeded files.
            rm -f  ${PREIN_DIR}/gcc/mingw${_bitval}/lib/gcc/${_arch}-w64-mingw32/${GCC_VER/-*}/*.py
            rm -fr ${PREIN_DIR}/gcc/mingw${_bitval}/share/gcc-${GCC_VER/-*}
            remove_empty_dirs ${PREIN_DIR}/gcc/mingw$_bitval
            remove_la_files   ${PREIN_DIR}/gcc/mingw$_bitval
            # Strip files.
            strip_files ${PREIN_DIR}/gcc/mingw$_bitval
            echo "done"

            # Enable win native symlink.
            MSYS=winsymlinks:nativestrict
            export MSYS

            # Create symlinks.
            printf "===> Creating symlinks %s...\n" $_arch
            symlink_gcc $_arch
            echo "done"
        fi

        # Copy to DST_DIR.
        printf "===> Copying GCC %s to %s/mingw%s...\n" $_arch $DST_DIR $_bitval
        symcopy ${PREIN_DIR}/gcc/mingw$_bitval $DST_DIR
        echo "done"
        # Relocate DLLs & cleanup.
        printf "===> Cleanup GCC %s...\n" $_arch
        term_gcc $_arch
        echo "done"
    done

    cd $ROOT_DIR
    return 0
}
