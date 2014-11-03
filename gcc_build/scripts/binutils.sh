# Binutils: A set of programs to assemble and manipulate binary and object files
# Clone git repo, git pull and apply patches.
function prepare_binutils() {
    # Git clone.
    if [ ! -d ${BUILD_DIR}/binutils/src/binutils-$BINUTILS_VER ]; then
        echo "===> Cloning Binutils git repo..."
        pushd ${BUILD_DIR}/binutils/src > /dev/null
        dl_files git http://sourceware.org/git/binutils-gdb.git binutils-$BINUTILS_VER
        popd > /dev/null
        echo "done"
    fi

    # Git pull.
    echo "===> Updating Binutils git-repo..."
    pushd ${BUILD_DIR}/binutils/src/binutils-$BINUTILS_VER > /dev/null
    git clean -fdx > /dev/null 2>&1
    git reset --hard > /dev/null 2>&1
    git pull > /dev/null 2>&1
    git_hash > ${LOGS_DIR}/binutils/binutils.hash 2>&1
    git_rev >> ${LOGS_DIR}/binutils/binutils.hash 2>&1
    echo "done"

    # Apply patches.
    printf "===> Applying patches to Binutils %s...\n" $BINUTILS_VER
    # Hack! - libiberty configure tests for header files using "$CPP $CPPFLAGS"
    sed -i "/ac_cpp=/s/\$CPPFLAGS/\$CPPFLAGS -Os/" libiberty/configure
    patch -p1 -i ${PATCHES_DIR}/binutils/0001-check-for-unusual-file-harder.patch \
        > ${LOGS_DIR}/binutils/binutils_patch.log 2>&1 || exit 1
    # For --enable-shared.
    patch -p1 -i ${PATCHES_DIR}/binutils/0002-enable-shared-bfd.all.patch \
        >> ${LOGS_DIR}/binutils/binutils_patch.log 2>&1 || exit 1
    patch -p1 -i ${PATCHES_DIR}/binutils/0003-link-to-libibtl-and-libiberty.mingw.patch \
        >> ${LOGS_DIR}/binutils/binutils_patch.log 2>&1 || exit 1
    patch -p1 -i ${PATCHES_DIR}/binutils/0004-shared-opcodes.mingw.patch \
        >> ${LOGS_DIR}/binutils/binutils_patch.log 2>&1 || exit 1
    patch -p1 -i ${PATCHES_DIR}/binutils/0005-fix-libiberty-makefile.mingw.patch \
        >> ${LOGS_DIR}/binutils/binutils_patch.log 2>&1 || exit 1
    patch -p1 -i ${PATCHES_DIR}/binutils/0006-fix-libiberty-configure.mingw.patch \
        >> ${LOGS_DIR}/binutils/binutils_patch.log 2>&1 || exit 1
    patch -p1 -i ${PATCHES_DIR}/binutils/0007-dont-link-gas-to-libiberty.mingw.patch \
        >> ${LOGS_DIR}/binutils/binutils_patch.log 2>&1 || exit 1
    patch -p1 -i ${PATCHES_DIR}/binutils/0008-dont-link-binutils-to-libiberty.mingw.patch \
        >> ${LOGS_DIR}/binutils/binutils_patch.log 2>&1 || exit 1
    patch -p1 -i ${PATCHES_DIR}/binutils/0009-dont-link-ld-to-libiberty.mingw.patch \
        >> ${LOGS_DIR}/binutils/binutils_patch.log 2>&1 || exit 1
    patch -p1 -i ${PATCHES_DIR}/binutils/0010-binutils-mingw-gnu-print.patch \
        >> ${LOGS_DIR}/binutils/binutils_patch.log 2>&1 || exit 1
    patch -p1 -i ${PATCHES_DIR}/binutils/0011-fix-iconv-linking.all.patch \
        >> ${LOGS_DIR}/binutils/binutils_patch.log 2>&1 || exit 1
    # Don't search dirs under ${prefix} but ${build_sysroot}.
    patch -p1 -i ${PATCHES_DIR}/binutils/0012-binutils-use-build-sysroot-dir.patch \
        >> ${LOGS_DIR}/binutils/binutils_patch.log 2>&1 || exit 1
    # For building with -fstack-protector*.
    patch -p1 -i ${PATCHES_DIR}/binutils/0013-update-ltmain.sh.patch \
        >> ${LOGS_DIR}/binutils/binutils_patch.log 2>&1 || exit 1
    # A newer standards.info is installed later on in the Autoconf instructions.
    rm -fv ${BUILD_DIR}/binutils/src/binutils-${BINUTILS_VER}/etc/standards.info
    sed -i.bak '/^INFO/s/standards.info //' ${BUILD_DIR}/binutils/src/binutils-${BINUTILS_VER}/etc/Makefile.in
    popd > /dev/null
    echo "done"

    return 0
}

# Create symlinks.
function symlink_binutils() {
    local _arch=${1}
    local _bitval=$(get_arch_bit ${_arch})

    pushd ${PREIN_DIR}/binutils/mingw${_bitval}/bin > /dev/null
    # ld is symlink of lb.bfd.
    ln -fsr ./ld.bfd.exe ./ld.exe
    # Symlinking to ${_arch}-w64-mingw32-*.exe.
    ln -fsr ./ld.bfd.exe ./${_arch}-w64-mingw32-ld.exe
    find . -type f -a -name "*.exe" -printf '%f\n' | xargs -I% ln -fsr % ${_arch}-w64-mingw32-%
    # Symlinking to ../$CHOST/bin/*.exe.
    ln -fsr ./ld.bfd.exe ../${_arch}-w64-mingw32/bin/ld.exe
    find . -type f -a \( -name "ar.exe" -o -name "as.exe" -o -name "dlltool.exe" -o -name "ld.bfd.exe" -o -name "nm.exe" \
        -o -name "objcopy.exe" -o -name "objdump.exe" -o -name "ranlib.exe" -o -name "strip.exe" \) -printf '%f\n' |     \
            xargs -I% ln -fsr % ../${_arch}-w64-mingw32/bin/%
    popd > /dev/null

    # New ld.
    pushd ${PREIN_DIR}/binutils_ld/mingw${_bitval}/bin > /dev/null
    ln -fsr ./ld.bfd.exe ./ld.exe
    ln -fsr ./ld.bfd.exe ./${_arch}-w64-mingw32-ld.bfd.exe
    ln -fsr ./ld.bfd.exe ./${_arch}-w64-mingw32-ld.exe
    ln -fsr ./ld.bfd.exe ../${_arch}-w64-mingw32/bin/ld.bfd.exe
    ln -fsr ./ld.bfd.exe ../${_arch}-w64-mingw32/bin/ld.exe
    popd > /dev/null

    return 0
}

# Build and install.
function build_binutils() {
    clear; printf "Build Binutils %s\n" $BINUTILS_VER

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
                printf "build_binutils: Unknown Option: '%s'\n" $_opt
                echo "...exit"
                exit 1
                ;;
        esac
    done

    # Setup.
    if ${_rebuild}; then
        prepare_binutils
    fi

    local _arch
    for _arch in ${TARGET_ARCH[@]}
    do
        local _bitval=$(get_arch_bit ${_arch})

        if ${_rebuild}; then
            cd ${BUILD_DIR}/binutils/build_$_arch
            # Cleanup the build dir.
            rm -fr ${BUILD_DIR}/binutils/build_${_arch}/*

            # PATH exporting.
            source cpath $_arch
            PATH=${DST_DIR}/mingw${_bitval}/bin:$PATH
            export PATH

            # Arch specific config option.
            if [ "${_arch}" = "i686" ]; then
                local _64_bit_bfd=""
            else
                local _64_bit_bfd="--enable-64-bit-bfd"
            fi

            # Temporal libpath.
            local _libpath="${DST_DIR}/mingw${_bitval}/lib:${DST_DIR}/mingw${_bitval}/${_arch}-w64-mingw32/lib"

            # Configure.
            printf "===> Configuring Binutils %s...\n" $_arch
            ../src/binutils-${BINUTILS_VER}/configure                    \
                --prefix=/mingw$_bitval                                  \
                --build=${_arch}-w64-mingw32                             \
                --host=${_arch}-w64-mingw32                              \
                --target=${_arch}-w64-mingw32                            \
                --enable-lto                                             \
                --disable-werror                                         \
                --enable-shared                                          \
                --disable-static                                         \
                --enable-plugins                                         \
                ${_64_bit_bfd}                                           \
                --enable-install-libbfd                                  \
                --enable-nls                                             \
                --disable-rpath                                          \
                --disable-multilib                                       \
                --disable-install-libiberty                              \
                --disable-gdb                                            \
                --disable-libdecnumber                                   \
                --disable-readline                                       \
                --disable-sim                                            \
                --with-build-sysroot=${DST_DIR}/mingw$_bitval            \
                --with-gnu-ld                                            \
                --with-zlib=yes                                          \
                --with-lib{iconv,intl}-prefix=${DST_DIR}/mingw$_bitval   \
                --with-sysroot=/mingw$_bitval                            \
                --with-lib-path=${_libpath}                              \
                CFLAGS="-march=${_arch/_/-} ${CFLAGS_} ${CPPFLAGS_}"     \
                LDFLAGS="${LDFLAGS_}"                                    \
                CXXFLAGS="-march=${_arch/_/-} ${CXXFLAGS_} ${CPPFLAGS_}" \
                > ${LOGS_DIR}/binutils/binutils_config_${_arch}.log 2>&1 || exit 1
            echo "done"

            # Make.
            printf "===> Making Binutils %s...\n" $_arch
            # Setting -j$(($(nproc)+1)) sometimes makes error.
            make > ${LOGS_DIR}/binutils/binutils_make_${_arch}.log 2>&1 || exit 1
            echo "done"

            # Install.
            printf "===> Installing Binutils %s...\n" $_arch
            rm -fr ${PREIN_DIR}/binutils/mingw${_bitval}/*
            make DESTDIR=${PREIN_DIR}/binutils install > ${LOGS_DIR}/binutils/binutils_install_${_arch}.log 2>&1 || exit 1
            # Remove unneeded files.
            rm -fr ${PREIN_DIR}/binutils/mingw${_bitval}/lib
            # Install only ansidecl.h, which is included by ieeefp.h.
            rm -f ${PREIN_DIR}/binutils/mingw${_bitval}/include/{bfd*,dis-asm,plugin-api,symcat}.h
            remove_empty_dirs ${PREIN_DIR}/binutils/mingw$_bitval
            remove_la_files   ${PREIN_DIR}/binutils/mingw$_bitval
            # Strip files.
            strip_files ${PREIN_DIR}/binutils/mingw$_bitval
            echo "done"

            # For modifying SEARCH_DIR.
            printf "===> Remaking ld %s...\n" $_arch
            # Setting -j$(($(nproc)+1)) sometimes makes error.
            make -C ld clean > ${LOGS_DIR}/binutils/binutils_remakeld_${_arch}.log 2>&1 || exit 1
            make -C ld LIB_PATH=/mingw${_bitval}/lib:/mingw${_bitval}/${_arch}-w64-mingw32/lib:/mingw${_bitval}/local/lib \
                >> ${LOGS_DIR}/binutils/binutils_remakeld_${_arch}.log 2>&1 || exit 1
            echo "done"

            # Reinstall ld.
            printf "===> Reinstalling ld %s...\n" $_arch
            make -C ld DESTDIR=${PREIN_DIR}/binutils_ld install \
                > ${LOGS_DIR}/binutils/binutils_reinstallld_${_arch}.log 2>&1 || exit 1
            strip_files ${PREIN_DIR}/binutils_ld/mingw$_bitval
            echo "done"

            # Create symlinks.
            printf "===> Creating symlinks %s...\n" $_arch
            symlink_binutils $_arch
            echo "done"
        fi

        if ! ( ! ${_rebuild} && ${_2nd_build} ); then
            # Copy to DST_DIR.
            printf "===> Copying Binutils %s to %s/mingw%s...\n" $_arch $DST_DIR $_bitval
            symcopy ${PREIN_DIR}/binutils/mingw$_bitval $DST_DIR
            echo "done"
        fi
    done

    cd $ROOT_DIR
    return 0
}

# Reinstall ld.
function copy_ld() {
    clear

    local _arch
    for _arch in ${TARGET_ARCH[@]}
    do
        local _bitval=$(get_arch_bit ${_arch})

        # Copy to DST_DIR.
        printf "===> Copying ld %s to %s/mingw%s...\n" $_arch $DST_DIR $_bitval
        symcopy ${PREIN_DIR}/binutils_ld/mingw$_bitval $DST_DIR
        echo "done"
    done

    cd $ROOT_DIR
    return 0
}
