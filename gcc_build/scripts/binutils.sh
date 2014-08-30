# Binutils: A set of programs to assemble and manipulate binary and object files
# download src
function prepare_binutils() {
    if [ ! -d ${BUILD_DIR}/binutils/src/binutils-$BINUTILS_VER ] ; then
        printf "===> cloning Binutils %s\n" $BINUTILS_VER
        pushd ${BUILD_DIR}/binutils/src > /dev/null
        dl_files git http://sourceware.org/git/binutils-gdb.git binutils-$BINUTILS_VER
        popd > /dev/null
        echo "done"
    fi
    pushd ${BUILD_DIR}/binutils/src/binutils-$BINUTILS_VER > /dev/null

    git clean -fdx > /dev/null 2>&1
    git reset --hard > /dev/null 2>&1
    # git pull > /dev/null 2>&1 # Don't pull.
    git_hash > ${LOGS_DIR}/binutils/binutils.hash 2>&1
    git_rev >> ${LOGS_DIR}/binutils/binutils.hash 2>&1

    # hack! - libiberty configure tests for header files using "$CPP $CPPFLAGS"
    sed -i "/ac_cpp=/s/\$CPPFLAGS/\$CPPFLAGS -O2/" libiberty/configure
    patch -p1 < ${PATCHES_DIR}/binutils/0001-check-for-unusual-file-harder.patch \
        > ${LOGS_DIR}/binutils/binutils_patch.log 2>&1 || exit 1
    patch -p1 < ${PATCHES_DIR}/binutils/0002-enable-shared-bfd.all.patch \
        >> ${LOGS_DIR}/binutils/binutils_patch.log 2>&1 || exit 1
    patch -p1 < ${PATCHES_DIR}/binutils/0003-link-to-libibtl-and-libiberty.mingw.patch \
        >> ${LOGS_DIR}/binutils/binutils_patch.log 2>&1 || exit 1
    patch -p1 < ${PATCHES_DIR}/binutils/0004-shared-opcodes.mingw.patch \
        >> ${LOGS_DIR}/binutils/binutils_patch.log 2>&1 || exit 1
    patch -p1 < ${PATCHES_DIR}/binutils/0005-fix-libiberty-makefile.mingw.patch \
        >> ${LOGS_DIR}/binutils/binutils_patch.log 2>&1 || exit 1
    patch -p1 < ${PATCHES_DIR}/binutils/0006-fix-libiberty-configure.mingw.patch \
        >> ${LOGS_DIR}/binutils/binutils_patch.log 2>&1 || exit 1
    patch -p1 < ${PATCHES_DIR}/binutils/0007-dont-link-gas-to-libiberty.mingw.patch \
        >> ${LOGS_DIR}/binutils/binutils_patch.log 2>&1 || exit 1
    patch -p1 < ${PATCHES_DIR}/binutils/0008-dont-link-binutils-to-libiberty.mingw.patch \
        >> ${LOGS_DIR}/binutils/binutils_patch.log 2>&1 || exit 1
    patch -p1 < ${PATCHES_DIR}/binutils/0009-dont-link-ld-to-libiberty.mingw.patch \
        >> ${LOGS_DIR}/binutils/binutils_patch.log 2>&1 || exit 1
    patch -p1 < ${PATCHES_DIR}/binutils/0010-binutils-mingw-gnu-print.patch \
        >> ${LOGS_DIR}/binutils/binutils_patch.log 2>&1 || exit 1
    patch -p1 < ${PATCHES_DIR}/binutils/0011-fix-iconv-linking.all.patch \
        >> ${LOGS_DIR}/binutils/binutils_patch.log 2>&1 || exit 1
    patch -p1 < ${PATCHES_DIR}/binutils/0012-binutils-use-build-sysroot-dir.patch \
        >> ${LOGS_DIR}/binutils/binutils_patch.log 2>&1 || exit 1
    # A newer standards.info is installed later on in the Autoconf instructions.
    rm -fv ${BUILD_DIR}/binutils/src/binutils-${BINUTILS_VER}/etc/standards.info
    sed -i.bak '/^INFO/s/standards.info //' ${BUILD_DIR}/binutils/src/binutils-${BINUTILS_VER}/etc/Makefile.in

    popd > /dev/null

    return 0
}

# cleanup
function symlink_binutils() {
    local _arch=${1}
    local _bitval=$(get_arch_bit ${_arch})

    pushd ${PREIN_DIR}/binutils/mingw${_bitval}/bin > /dev/null

    ln -fsr ./ld.bfd.exe ./ld.exe
    ln -fsr ./ld.bfd.exe ./${_arch}-w64-mingw32-ld.exe
    ln -fsr ./ld.bfd.exe ../${_arch}-w64-mingw32/bin/ld.exe
    find . -type f -a -name "*.exe" -printf '%f\n' | xargs -I% ln -fsr % ${_arch}-w64-mingw32-%
    find . -type f -a \( -name "ar.exe" -o -name "as.exe" -o -name "dlltool.exe" -o -name "ld.bfd.exe" -o -name "nm.exe" \
        -o -name "objcopy.exe" -o -name "objdump.exe" -o -name "ranlib.exe" -o -name "strip.exe" \) -printf '%f\n' |     \
        xargs -I% ln -fsr % ../${_arch}-w64-mingw32/bin/%

    popd > /dev/null

    pushd ${PREIN_DIR}/binutils_ld/mingw${_bitval}/bin > /dev/null

    ln -fsr ./ld.bfd.exe ./ld.exe
    ln -fsr ./ld.bfd.exe ./${_arch}-w64-mingw32-ld.bfd.exe
    ln -fsr ./ld.bfd.exe ./${_arch}-w64-mingw32-ld.exe
    ln -fsr ./ld.bfd.exe ../${_arch}-w64-mingw32/bin/ld.bfd.exe
    ln -fsr ./ld.bfd.exe ../${_arch}-w64-mingw32/bin/ld.exe

    popd > /dev/null

    return 0
}

# build
function build_binutils() {
    clear; printf "Build Binutils %s\n" $BINUTILS_VER

    prepare_binutils

    for arch in ${TARGET_ARCH[@]}
    do
        cd ${BUILD_DIR}/binutils/build_$arch
        rm -fr ${BUILD_DIR}/binutils/build_${arch}/*

        local bitval=$(get_arch_bit ${arch})
        local _aof=$(arch_optflags ${arch})

        source cpath $arch
        PATH=${DST_DIR}/mingw${bitval}/bin:$PATH
        export PATH

        if [ "${arch}" = "i686" ] ; then
            local _64_bit_bfd=""
        else
            local _64_bit_bfd="--enable-64-bit-bfd"
        fi

        echo "int _dowildcard = -1;" > glob_enable.c
        gcc -c -o glob_enable.o glob_enable.c
        local _ldge=" -Wl,${BUILD_DIR}/binutils/build_${arch}/glob_enable.o"

        printf "===> configuring Binutils %s\n" $arch
        ../src/binutils-${BINUTILS_VER}/configure                                                           \
            --prefix=/mingw$bitval                                                                          \
            --build=${arch}-w64-mingw32                                                                     \
            --host=${arch}-w64-mingw32                                                                      \
            --target=${arch}-w64-mingw32                                                                    \
            --enable-lto                                                                                    \
            --disable-werror                                                                                \
            --enable-shared                                                                                 \
            --enable-static                                                                                 \
            --enable-plugins                                                                                \
            ${_64_bit_bfd}                                                                                  \
            --enable-install-libbfd                                                                         \
            --enable-nls                                                                                    \
            --disable-rpath                                                                                 \
            --disable-multilib                                                                              \
            --enable-install-libiberty                                                                      \
            --disable-gdb                                                                                   \
            --disable-libdecnumber                                                                          \
            --disable-readline                                                                              \
            --disable-sim                                                                                   \
            --with-build-sysroot=${DST_DIR}/mingw$bitval                                                    \
            --with-gnu-ld                                                                                   \
            --with-zlib=yes                                                                                 \
            --with-libiconv-prefix=${DST_DIR}/mingw$bitval                                                  \
            --with-libintl-prefix=${DST_DIR}/mingw$bitval                                                   \
            --with-sysroot=/mingw$bitval                                                                    \
            --with-lib-path=${DST_DIR}/mingw${bitval}/lib:${DST_DIR}/mingw${bitval}/${arch}-w64-mingw32/lib \
            CPPFLAGS="${_CPPFLAGS}"                                                                         \
            CFLAGS="${_aof} ${_CFLAGS}"                                                                     \
            CXXFLAGS="${_aof} ${_CXXFLAGS}"                                                                 \
            LDFLAGS="${_LDFLAGS} ${_ldge}"                                                                  \
            > ${LOGS_DIR}/binutils/binutils_config_${arch}.log 2>&1 || exit 1
        echo "done"

        printf "===> making Binutils %s\n" $arch
        # Setting -j$(($(nproc)+1)) sometimes makes error.
        make > ${LOGS_DIR}/binutils/binutils_make_${arch}.log 2>&1 || exit 1
        echo "done"

        printf "===> installing Binutils %s\n" $arch
        rm -fr ${PREIN_DIR}/binutils/mingw${bitval}/*
        make DESTDIR=${PREIN_DIR}/binutils install > ${LOGS_DIR}/binutils/binutils_install_${arch}.log 2>&1 || exit 1
        del_empty_dir ${PREIN_DIR}/binutils/mingw$bitval
        remove_la_files ${PREIN_DIR}/binutils/mingw$bitval
        strip_files ${PREIN_DIR}/binutils/mingw$bitval
        echo "done"

        # For modifying SEARCH_DIR.
        printf "===> remaking ld %s\n" $arch
        # Setting -j$(($(nproc)+1)) sometimes makes error.
        make -C ld clean > ${LOGS_DIR}/binutils/binutils_remakeld_${arch}.log 2>&1 || exit 1
        make -C ld LIB_PATH=/mingw${bitval}/lib:/mingw${bitval}/${arch}-w64-mingw32/lib:/mingw${bitval}/local/lib \
            >> ${LOGS_DIR}/binutils/binutils_remakeld_${arch}.log 2>&1 || exit 1
        echo "done"

        printf "===> reinstalling ld %s\n" $arch
        make -C ld DESTDIR=${PREIN_DIR}/binutils_ld install \
            > ${LOGS_DIR}/binutils/binutils_reinstallld_${arch}.log 2>&1 || exit 1
        strip_files ${PREIN_DIR}/binutils_ld/mingw$bitval
        echo "done"

        # symlink
        symlink_binutils $arch

        printf "===> copying Binutils %s to %s/mingw%s\n" $arch $DST_DIR $bitval
        symcopy ${PREIN_DIR}/binutils/mingw$bitval $DST_DIR
        echo "done"
    done

    cd $ROOT_DIR
    return 0
}

# copy only
function copy_binutils() {
    clear; printf "Binutils %s\n" $BINUTILS_VER

    for arch in ${TARGET_ARCH[@]}
    do
        local bitval=$(get_arch_bit ${arch})

        printf "===> copying Binutils %s to %s/mingw%s\n" $arch $DST_DIR $bitval
        symcopy ${PREIN_DIR}/binutils/mingw$bitval $DST_DIR
        echo "done"
    done

    cd $ROOT_DIR
    return 0
}

# reinstall ld
function copy_ld() {
    clear

    for arch in ${TARGET_ARCH[@]}
    do
        local bitval=$(get_arch_bit ${arch})

        printf "===> copying ld %s to %s/mingw%s\n" $arch $DST_DIR $bitval
        symcopy ${PREIN_DIR}/binutils_ld/mingw$bitval $DST_DIR
        echo "done"
    done

    cd $ROOT_DIR
    return 0
}
