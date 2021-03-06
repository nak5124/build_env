# Binutils: A set of programs to assemble and manipulate binary and object files
# Clone git repo, git pull and apply patches.
function apply_patch_bu() {
    apply_patch "${1}" "${BUILD_DIR}"/binutils/src/binutils-$BINUTILS_VER "${LOGS_DIR}"/binutils/binutils_patch.log "${2}"
}

function prepare_binutils() {
    # Git clone.
    if [ ! -d "${BUILD_DIR}"/binutils/src/binutils-$BINUTILS_VER ]; then
        echo '===> Cloning Binutils git repo...'
        pushd "${BUILD_DIR}"/binutils/src > /dev/null
        dl_files git http://sourceware.org/git/binutils-gdb.git binutils-$BINUTILS_VER
        popd > /dev/null # "${BUILD_DIR}"/binutils/src
        echo 'done'
    fi

    # Git pull.
    echo '===> Updating Binutils git-repo...'
    pushd "${BUILD_DIR}"/binutils/src/binutils-$BINUTILS_VER > /dev/null
    git clean -fdx > /dev/null 2>&1
    git reset --hard > /dev/null 2>&1
    git pull > /dev/null 2>&1
    git log -1 --format="%h" > "${LOGS_DIR}"/binutils/binutils.hash 2>&1
    git rev-list HEAD | wc -l >> "${LOGS_DIR}"/binutils/binutils.hash 2>&1
    echo 'done'

    # Apply patches.
    printf "===> Applying patches to Binutils %s...\n" "${BINUTILS_VER}"

    # /dev/null -> nul
    apply_patch_bu "${PATCHES_DIR}"/binutils/0001-binutils-Check-harder-for-the-file-in-question-being.patch true
    # For --enable-shared.
    apply_patch_bu "${PATCHES_DIR}"/binutils/0002-Enable-shared-on-MinGW.patch                               false
    # Shut up GCC -Wformat.
    apply_patch_bu "${PATCHES_DIR}"/binutils/0003-MinGW-Use-__MINGW_PRINTF_FORMAT-for-__USE_MINGW_ANSI.patch false
    # Don't search dirs under ${prefix} but ${build_sysroot}.
    apply_patch_bu "${PATCHES_DIR}"/binutils/0004-configure-Search-dirs-under-build_sysroot-instead-of.patch false
    # Disable automatic image base calculation.
    apply_patch_bu "${PATCHES_DIR}"/binutils/0005-MinGW-Disable-automatic-image-base-calculation.patch       false
    # Don't make a lowercase backslashed path from argv[0] that then fail to strcmp with prefix(es) .. they're also ugly.
    apply_patch_bu "${PATCHES_DIR}"/binutils/0006-libiberty-lrealpath.c-Don-t-make-a-lowercase-backsla.patch false
    # Ray's patch
    apply_patch_bu "${PATCHES_DIR}"/binutils/0007-bfd-Increase-_bfd_coff_max_nscns-to-65279.patch            false
    # Fixes for NT weak external (https://sourceware.org/ml/binutils/2015-10/msg00234.html).
    apply_patch_bu "${PATCHES_DIR}"/binutils/0008-Fixes-for-NT-weak-externals.patch                          false
    # Add --enable-reloc-section (https://sourceware.org/bugzilla/show_bug.cgi?id=17321).
    apply_patch_bu "${PATCHES_DIR}"/binutils/0009-Add-enable-reloc-section-option.patch                      false
    # Assume that target is windows 10.
    apply_patch_bu "${PATCHES_DIR}"/binutils/0010-Update-default-versions.patch                              false
    # Remove #define stat _stat ...
    apply_patch_bu "${PATCHES_DIR}"/binutils/0011-ltmain.sh-Remove-useless-defines.patch                     false

    popd > /dev/null # "${BUILD_DIR}"/binutils/src/binutils-$BINUTILS_VER
    echo 'done'

    return 0
}

# Create symlinks.
function symlink_binutils() {
    local _arch=${1}
    local _bitval=$(get_arch_bit ${_arch})

    pushd "${DST_DIR}"/mingw${_bitval}/bin > /dev/null
    # ld is symlink of lb.bfd.
    ln -frs ./ld.bfd.exe ./ld.exe
    # Symlinking to ${_arch}-w64-mingw32-*.exe.
    ln -frs ./ld.bfd.exe ./${_arch}-w64-mingw32-ld.exe
    find . -type f -name "*.exe" -printf '%f\n' | xargs -I% ln -fsr % ${_arch}-w64-mingw32-%
    popd > /dev/null # "${DST_DIR}"/mingw${_bitval}/bin

    return 0
}

# Build and install.
function build_binutils() {
    clear; printf "Build Binutils %s\n" "${BINUTILS_VER}"

    # Option handling.
    local _rebuild=true
    local _2nd_build=false

    local _opt
    for _opt in "${@}"
    do
        case "${_opt}" in
            --rebuild=* )
                _rebuild=${_opt#*=}
                ;;
            --2nd )
                _2nd_build=true
                ;;
            * )
                printf "build_binutils: Unknown Option: '%s'\n" "${_opt}"
                echo '...exit'
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
            cd "${BUILD_DIR}"/binutils/build_$_arch
            # Cleanup the build dir.
            rm -fr "${BUILD_DIR}"/binutils/build_${_arch}/*

            # PATH exporting.
            if ${_2nd_build}; then
                # Use the new GCC for 2nd build.
                set_path2 $_arch
            else
                set_path $_arch
            fi

            # Arch specific config option.
            if [ "${_arch}" = 'i686' ]; then
                local _64_bit_bfd=''
            else
                local _64_bit_bfd='--enable-64-bit-bfd'
            fi

            # Temporal libpath.
            local _libpath="${DST_DIR}"/mingw${_bitval}/lib:"${DST_DIR}"/mingw${_bitval}/${_arch}-w64-mingw32/lib

            # Configure.
            printf "===> Configuring Binutils %s...\n" "${_arch}"
            ../src/binutils-${BINUTILS_VER}/configure             \
                --prefix=/mingw$_bitval                           \
                --build=${_arch}-w64-mingw32                      \
                --host=${_arch}-w64-mingw32                       \
                --target=${_arch}-w64-mingw32                     \
                --enable-ld=default                               \
                --enable-lto                                      \
                --disable-werror                                  \
                --enable-shared                                   \
                --disable-static                                  \
                --enable-fast-install                             \
                --enable-plugins                                  \
                ${_64_bit_bfd}                                    \
                --enable-secureplt                                \
                --enable-install-libbfd                           \
                --disable-nls                                     \
                --disable-rpath                                   \
                --enable-got=target                               \
                --disable-multilib                                \
                --disable-install-libiberty                       \
                --disable-gdb                                     \
                --disable-libdecnumber                            \
                --disable-readline                                \
                --disable-sim                                     \
                --with-stage1-ldflags=no                          \
                --with-build-sysroot="${DST_DIR}"/mingw$_bitval   \
                --with-gnu-ld                                     \
                --with-system-zlib                                \
                --with-libiconv-prefix="${DST_DIR}"/mingw$_bitval \
                --with-lib-path="${_libpath}"                     \
                --with-sysroot=/mingw$_bitval                     \
                CFLAGS="${CFLAGS_} ${CPPFLAGS_}"                  \
                LDFLAGS="${LDFLAGS_}"                             \
                CXXFLAGS="${CXXFLAGS_} ${CPPFLAGS_}"              \
                > "${LOGS_DIR}"/binutils/binutils_config_${_arch}.log 2>&1 || exit 1
            echo 'done'

            # Make.
            printf "===> Making Binutils %s...\n" "${_arch}"
            # Setting -j$(($(nproc)+1)) sometimes makes error.
            make LIB_PATH="${DST_DIR}"/mingw${_bitval}/lib:"${DST_DIR}"/mingw${_bitval}/${_arch}-w64-mingw32/lib \
                tooldir=/mingw$_bitval > "${LOGS_DIR}"/binutils/binutils_make_${_arch}.log 2>&1 || exit 1
            echo 'done'

            # Install.
            printf "===> Installing Binutils %s...\n" "${_arch}"
            rm -fr "${PREIN_DIR}"/binutils/mingw${_bitval}/*
            make DESTDIR="${PREIN_DIR}"/binutils prefix=/mingw$_bitval tooldir=/mingw$_bitval install \
                > "${LOGS_DIR}"/binutils/binutils_install_${_arch}.log 2>&1 || exit 1
            # Remove unneeded files.
            rm -f  "${PREIN_DIR}"/binutils/mingw${_bitval}/lib/*.a
            rm -fr "${PREIN_DIR}"/binutils/mingw${_bitval}/include
            remove_la_files "${PREIN_DIR}"/binutils/mingw$_bitval
            # Strip files.
            strip_files "${PREIN_DIR}"/binutils/mingw$_bitval
            echo 'done'

            # For modifying SEARCH_DIR.
            printf "===> Remaking ld %s...\n" "${_arch}"
            # Setting -j$(($(nproc)+1)) sometimes makes error.
            make -C ld clean > "${LOGS_DIR}"/binutils/binutils_remakeld_${_arch}.log 2>&1 || exit 1
            make -C ld LIB_PATH=/mingw${_bitval}/lib:/mingw${_bitval}/${_arch}-w64-mingw32/lib:/mingw${_bitval}/local/lib \
                tooldir=/mingw$_bitval >> "${LOGS_DIR}"/binutils/binutils_remakeld_${_arch}.log 2>&1 || exit 1
            echo 'done'

            # Reinstall ld.
            printf "===> Reinstalling ld %s...\n" "${_arch}"
            rm -fr "${PREIN_DIR}"/binutils_ld/mingw${_bitval}/*
            make -C ld DESTDIR="${PREIN_DIR}"/binutils_ld prefix=/mingw$_bitval tooldir=/mingw$_bitval install \
                > "${LOGS_DIR}"/binutils/binutils_reinstallld_${_arch}.log 2>&1 || exit 1
            # Remove unneeded files.
            rm -f  "${PREIN_DIR}"/binutils_ld/mingw${_bitval}/bin/ld.exe
            rm -fr "${PREIN_DIR}"/binutils_ld/mingw${_bitval}/share
            # Strip files.
            strip_files "${PREIN_DIR}"/binutils_ld/mingw$_bitval
            echo "done"
        fi

        if ! ( ! ${_rebuild} && ${_2nd_build} ); then
            # Copy to DST_DIR.
            printf "===> Copying Binutils %s to %s/mingw%s...\n" "${_arch}" "${DST_DIR}" "${_bitval}"
            cp -af "${PREIN_DIR}"/binutils/mingw$_bitval "${DST_DIR}"
            echo 'done'
            # Create symlinks.
            if ${create_symlinks:-false}; then
                printf "===> Creating symlinks %s...\n" "${_arch}"
                symlink_binutils $_arch
                echo 'done'
            fi

            # Copy logs
            printf "===> Copying Binutils %s logs to %s/mingw%s/logs...\n" "${_arch}" "${DST_DIR}" "${_bitval}"
            mkdir -p "${DST_DIR}"/mingw${_bitval}/logs/binutils
            cp -af "${LOGS_DIR}"/binutils/binutils_{config,install,make}_${_arch}* \
                "${DST_DIR}"/mingw${_bitval}/logs/binutils
            cp -af "${LOGS_DIR}"/binutils/binutils_patch.log "${DST_DIR}"/mingw${_bitval}/logs/binutils
            if [ "${BINUTILS_VER}" = 'git' ]; then
                cp -af "${LOGS_DIR}"/binutils/binutils.hash "${DST_DIR}"/mingw${_bitval}/logs/binutils
            fi
            echo 'done'
        fi
    done

    cd "${ROOT_DIR}"
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
        printf "===> Copying ld %s to %s/mingw%s...\n" "${_arch}" "${DST_DIR}" "${_bitval}"
        cp -af "${PREIN_DIR}"/binutils_ld/mingw$_bitval "${DST_DIR}"
        echo 'done'

        # Copy logs
        printf "===> Copying ld %s logs to %s/mingw%s/logs...\n" "${_arch}" "${DST_DIR}" "${_bitval}"
        cp -af "${LOGS_DIR}"/binutils/binutils_{reinstallld,remakeld}_${_arch}* \
            "${DST_DIR}"/mingw${_bitval}/logs/binutils
        echo 'done'
    done

    cd "${ROOT_DIR}"
    return 0
}
