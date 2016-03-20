# Autoconf: A GNU tool for automatically configuring source code
# Download the src and decompress it.
function download_autoconf_src() {
    # Download the src.
    if [ ! -f "${BUILD_DIR}"/autotools/autoconf/src/autoconf-${AUTOCONF_VER}.tar.xz ]; then
        printf "===> Downloading Autoconf %s...\n" "${AUTOCONF_VER}"
        pushd "${BUILD_DIR}"/autotools/autoconf/src > /dev/null
        dl_files ftp ftp://ftp.gnu.org/gnu/autoconf/autoconf-${AUTOCONF_VER}.tar.xz
        popd > /dev/null # "${BUILD_DIR}"/autotools/autoconf/src
        echo 'done'
    fi

    # Decompress the src archive.
    if [ ! -d "${BUILD_DIR}"/autotools/autoconf/src/autoconf-$AUTOCONF_VER ]; then
        printf "===> Extracting Autoconf %s...\n" "${AUTOCONF_VER}"
        pushd "${BUILD_DIR}"/autotools/autoconf/src > /dev/null
        decomp_arch "${BUILD_DIR}"/autotools/autoconf/src/autoconf-${AUTOCONF_VER}.tar.xz
        popd > /dev/null # "${BUILD_DIR}"/autotools/autoconf/src
        echo 'done'
    fi

    return 0
}

# Apply patches.
function apply_patch_ac() {
    apply_patch "${1}" "${BUILD_DIR}"/autotools/autoconf/src/autoconf-$AUTOCONF_VER \
        "${LOGS_DIR}"/autotools/autoconf/autoconf_patch.log "${2}"
}

function prepare_autoconf() {
    # Apply patches.
    printf "===> Applying patches to Autoconf %s...\n" "${AUTOCONF_VER}"

    # http://lists.gnu.org/archive/html/autoconf-patches/2008-08/msg00032.html
    apply_patch_ac "${PATCHES_DIR}"/autoconf/0001-atomic.all.patch                             true
    # http://lists.gnu.org/archive/html/autoconf/2006-05/msg00127.html
    apply_patch_ac "${PATCHES_DIR}"/autoconf/0002-stricter-versioning.all.patch                false
    # Add space between chr and bracket.
    apply_patch_ac "${PATCHES_DIR}"/autoconf/0003-m4sh.m4.all.patch                            false
    # Fix texinfo.
    apply_patch_ac "${PATCHES_DIR}"/autoconf/0004-autoconf-ga357718.all.patch                  false
    # For MSYS=winsymlinks:nativestrict.
    apply_patch_ac "${PATCHES_DIR}"/autoconf/0005-allow-lns-on-msys2.all.patch                 false
    # Remove CR.
    apply_patch_ac "${PATCHES_DIR}"/autoconf/0006-fix-cr-for-awk-in-configure-and-status.patch false

    echo 'done'

    return 0
}

# Build and install.
function build_autoconf() {
    clear; printf "Build Autoconf %s...\n" "${AUTOCONF_VER}"

    # Option handling.
    local _rebuild=true

    local _opt
    for _opt in "${@}"
    do
        case "${_opt}" in
            --rebuild=* )
                _rebuild=${_opt#*=}
                ;;
            * )
                printf "build_autoconf: Unknown Option: '%s'\n" "${_opt}"
                echo '...exit'
                exit 1
                ;;
        esac
    done

    # Setup.
    if ${_rebuild}; then
        download_autoconf_src
        prepare_autoconf
    fi

    local _arch
    for _arch in ${TARGET_ARCH[@]}
    do
        local _bitval=$(get_arch_bit ${_arch})

        if ${_rebuild}; then
            cd "${BUILD_DIR}"/autotools/autoconf/build_$_arch
            # Cleanup the build dir.
            rm -fr "${BUILD_DIR}"/autotools/autoconf/build_${_arch}/*

            # PATH exporting.
            set_path3 $_arch

            # Configure.
            printf "===> Configuring Autoconf %s...\n" "${_arch}"
            # Setting {CPP,C,CXX,LD}FLAGS does not make any sense.
            ../src/autoconf-${AUTOCONF_VER}/configure \
                --prefix=/mingw$_bitval               \
                --build=${_arch}-w64-mingw32          \
                --host=${_arch}-w64-mingw32           \
                --disable-silent-rules                \
                > "${LOGS_DIR}"/autotools/autoconf/autoconf_config_${_arch}.log 2>&1 || exit 1
            echo 'done'

            # Make.
            printf "===> Making Autoconf %s...\n" "${_arch}"
            make $MAKEFLAGS_ > "${LOGS_DIR}"/autotools/autoconf/autoconf_make_${_arch}.log 2>&1 || exit 1
            echo 'done'

            # Install.
            printf "===> Installing Autoconf %s...\n" "${_arch}"
            make DESTDIR="${PREIN_DIR}"/autotools/autoconf install \
                > "${LOGS_DIR}"/autotools/autoconf/autoconf_install_${_arch}.log 2>&1 || exit 1
            echo 'done'
        fi

        # Copy to DST_DIR.
        printf "===> Copying Autoconf %s to %s/mingw%s...\n" "${_arch}" "${DST_DIR}" "${_bitval}"
        cp -af "${PREIN_DIR}"/autotools/autoconf/mingw$_bitval "${DST_DIR}"
        echo 'done'
    done

    cd "${ROOT_DIR}"
    return 0
}

# Automake: A GNU tool for automatically creating Makefiles
# Download the src and decompress it.
function download_automake_src() {
    # Download the src.
    if [ ! -f "${BUILD_DIR}"/autotools/automake/src/automake-${AUTOMAKE_VER}.tar.xz ]; then
        printf "===> Downloading Automake %s...\n" "${AUTOMAKE_VER}"
        pushd "${BUILD_DIR}"/autotools/automake/src > /dev/null
        dl_files ftp ftp://ftp.gnu.org/gnu/automake/automake-${AUTOMAKE_VER}.tar.xz
        popd > /dev/null # "${BUILD_DIR}"/autotools/automake/src
        echo 'done'
    fi

    # Decompress the src archive.
    if [ ! -d "${BUILD_DIR}"/autotools/automake/src/automake-$AUTOMAKE_VER ]; then
        printf "===> Extracting Automake %s...\n" "${AUTOMAKE_VER}"
        pushd "${BUILD_DIR}"/autotools/automake/src > /dev/null
        decomp_arch "${BUILD_DIR}"/autotools/automake/src/automake-${AUTOMAKE_VER}.tar.xz
        popd > /dev/null # "${BUILD_DIR}"/autotools/automake/src
        echo 'done'
    fi

    return 0
}

# Apply patches.
function apply_patch_am() {
    apply_patch "${1}" "${BUILD_DIR}"/autotools/automake/src/automake-$AUTOMAKE_VER \
        "${LOGS_DIR}"/autotools/automake/automake_patch.log "${2}"
}

function prepare_automake() {
    # Apply patches.
    printf "===> Applying patches to Automake %s...\n" "${AUTOMAKE_VER}"

    # Remove CR.
    apply_patch_am "${PATCHES_DIR}"/automake/0001-fix-cr-for-awk-in-configure.patch true

    echo 'done'

    return 0
}

# Build and install.
function build_automake() {
    clear; printf "Build Automake %s...\n" "${AUTOMAKE_VER}"

    # Option handling.
    local _rebuild=true

    local _opt
    for _opt in "${@}"
    do
        case "${_opt}" in
            --rebuild=* )
                _rebuild=${_opt#*=}
                ;;
            * )
                printf "build_automake: Unknown Option: '%s'... exit\n" "${_opt}"
                exit 1
                ;;
        esac
    done

    # Setup.
    if ${_rebuild}; then
        download_automake_src
        prepare_automake
    fi

    local _arch
    for _arch in ${TARGET_ARCH[@]}
    do
        local _bitval=$(get_arch_bit ${_arch})

        if ${_rebuild}; then
            cd "${BUILD_DIR}"/autotools/automake/build_$_arch
            # Cleanup the build dir.
            rm -fr "${BUILD_DIR}"/autotools/automake/build_${_arch}/*

            # PATH exporting.
            set_path3 $_arch

            # Configure.
            printf "===> Configuring Automake %s...\n" "${_arch}"
            # Setting {CPP,C,CXX,LD}FLAGS does not make any sense.
            ../src/automake-${AUTOMAKE_VER}/configure \
                --prefix=/mingw$_bitval               \
                --build=${_arch}-w64-mingw32          \
                --host=${_arch}-w64-mingw32           \
                --disable-silent-rules                \
                > "${LOGS_DIR}"/autotools/automake/automake_config_${_arch}.log 2>&1 || exit 1
            echo 'done'

            # Make.
            printf "===> Making Automake %s...\n" "${_arch}"
            make $MAKEFLAGS_ > "${LOGS_DIR}"/autotools/automake/automake_make_${_arch}.log 2>&1 || exit 1
            echo 'done'

            # Install.
            printf "===> Installing Automake %s...\n" "${_arch}"
            rm -fr "${PREIN_DIR}"/autotools/automake/mingw${_bitval}/*
            make DESTDIR="${PREIN_DIR}"/autotools/automake install \
                > "${LOGS_DIR}"/autotools/automake/automake_install_${_arch}.log 2>&1 || exit 1
            echo 'done'
        fi

        printf "===> Copying Automake %s to %s/mingw%s...\n" "${_arch}" "${DST_DIR}" "${_bitval}"
        cp -af "${PREIN_DIR}"/autotools/automake/mingw$_bitval "${DST_DIR}"
        # Create symlinks.
        if ${create_symlinks:-false}; then
            printf "===> Creating symlinks %s...\n" "${_arch}"
            pushd "${DST_DIR}"/mingw${_bitval}/bin > /dev/null
            ln -fsr ./automake-$AUTOMAKE_VER ./automake
            ln -fsr ./aclocal-$AUTOMAKE_VER ./aclocal
            popd > /dev/null # "${DST_DIR}"/mingw${_bitval}/bin
        else
            rm -f "${DST_DIR}"/mingw${_bitval}/bin/{aclocal,automake}
        fi
        echo 'done'
    done

    cd "${ROOT_DIR}"
    return 0
}

# libtool: A generic library support script
# Download the src and decompress it.
function download_libtool_src() {
    # Download the src.
    if [ ! -f "${BUILD_DIR}"/autotools/libtool/src/libtool-${LIBTOOL_VER}.tar.xz ]; then
        printf "===> Downloading  %s...\n" "${LIBTOOL_VER}"
        pushd "${BUILD_DIR}"/autotools/libtool/src > /dev/null
        dl_files ftp ftp://ftp.gnu.org/gnu/libtool/libtool-${LIBTOOL_VER}.tar.xz
        # dl_files ftp ftp://alpha.gnu.org/gnu/libtool/libtool-${LIBTOOL_VER}.tar.xz
        popd > /dev/null # "${BUILD_DIR}"/autotools/libtool/src
        echo 'done'
    fi

    # Decompress the src archive.
    if [ ! -d "${BUILD_DIR}"/autotools/libtool/src/libtool-$LIBTOOL_VER ]; then
        printf "===> Extracting Libtool %s...\n" "${LIBTOOL_VER}"
        pushd "${BUILD_DIR}"/autotools/libtool/src > /dev/null
        decomp_arch "${BUILD_DIR}"/autotools/libtool/src/libtool-${LIBTOOL_VER}.tar.xz
        popd > /dev/null # "${BUILD_DIR}"/autotools/libtool/src
        echo 'done'
    fi

    return 0
}

# Apply patches.
function apply_patch_lt() {
    apply_patch "${1}" "${BUILD_DIR}"/autotools/libtool/src/libtool-$LIBTOOL_VER \
        "${LOGS_DIR}"/autotools/libtool/libtool_patch.log "${2}"
}

function prepare_libtool() {
    # Apply patches.
    printf "===> Applying patches to Libtool %s...\n" "${LIBTOOL_VER}"

    # Emit Win32 UAC manifest.
    apply_patch_lt "${PATCHES_DIR}"/libtool/0001-cygwin-mingw-Create-UAC-manifest-files.patch    true
    # Pass the -shared-libgcc and -static-lib* flags along to GCC.
    apply_patch_lt "${PATCHES_DIR}"/libtool/0002-Pass-various-runtime-library-flags-to-GCC.patch false
    # Compare files by inode to fix "seems to be moved" warning.
    apply_patch_lt "${PATCHES_DIR}"/libtool/0003-Fix-seems-to-be-moved.patch                     false
    # Also check for _POSIX as well as __STRICT_ANSI__ to avoid re-definitions.
    apply_patch_lt "${PATCHES_DIR}"/libtool/0004-Fix-strict-ansi-vs-posix.patch                  false
    # Remove CR.
    apply_patch_lt "${PATCHES_DIR}"/libtool/0005-fix-cr-for-awk-in-configure.patch               false
    # Remove #define stat _stat ...
    apply_patch_lt "${PATCHES_DIR}"/libtool/0006-Remove-useless-define.patch                     false

    # Disable automatic image base calculation.
    sed -i 's/$wl--enable-auto-image-base //g' \
        "${BUILD_DIR}"/autotools/libtool/src/libtool-${LIBTOOL_VER}/{configure,m4/libtool.m4}

    echo 'done'

    return 0
}

# Build and install.
function build_libtool() {
    clear; printf "Build Libtool %s...\n" "${LIBTOOL_VER}"

    # Option handling.
    local _rebuild=true

    local _opt
    for _opt in "${@}"
    do
        case "${_opt}" in
            --rebuild=* )
                _rebuild=${_opt#*=}
                ;;
            * )
                printf "build_libtool: Unknown Option: '%s'... exit\n" "${_opt}"
                exit 1
                ;;
        esac
    done

    # Setup.
    if ${_rebuild}; then
        download_libtool_src
        prepare_libtool
    fi

    local _arch
    for _arch in ${TARGET_ARCH[@]}
    do
        local _bitval=$(get_arch_bit ${_arch})

        if ${_rebuild}; then
            cd "${BUILD_DIR}"/autotools/libtool/build_$_arch
            # Cleanup the build dir.
            rm -fr "${BUILD_DIR}"/autotools/libtool/build_${_arch}/*

            # PATH exporting.
            set_path3 $_arch

            # Configure.
            printf "===> Configuring Libtool %s...\n" "${_arch}"
            # Setting {CPP,C,CXX,LD}FLAGS does not make any sense.
            ../src/libtool-${LIBTOOL_VER}/configure \
                --prefix=/mingw$_bitval             \
                --build=${_arch}-w64-mingw32        \
                --host=${_arch}-w64-mingw32         \
                --disable-silent-rules              \
                --disable-ltdl-install              \
                > "${LOGS_DIR}"/autotools/libtool/libtool_config_${_arch}.log 2>&1 || exit 1
            echo 'done'

            # Make.
            printf "===> Making Libtool %s...\n" "${_arch}"
            make $MAKEFLAGS > "${LOGS_DIR}"/autotools/libtool/libtool_make_${_arch}.log 2>&1 || exit 1
            echo 'done'

            # Install.
            printf "===> Installing Libtool %s...\n" "${_arch}"
            # Don't install libltdl.
            make DESTDIR="${PREIN_DIR}"/autotools/libtool install \
                > "${LOGS_DIR}"/autotools/libtool/libtool_install_${_arch}.log 2>&1 || exit 1
            rm -fr "${PREIN_DIR}"/autotools/libtool/mingw${_bitval}/share/libtool/libltdl
            # Modify hard coded file PATH.
            local _dst_dir_winpath=$(cygpath -ma ${DST_DIR})
            sed -i "s|${_dst_dir_winpath//\//\\/}||g" "${PREIN_DIR}"/autotools/libtool/mingw${_bitval}/bin/libtool
            sed -i "s|${DST_DIR//\//\\/}||g" "${PREIN_DIR}"/autotools/libtool/mingw${_bitval}/bin/libtool
            sed -i "s|${_dst_dir_winpath//\//\\/}||g" "${PREIN_DIR}"/autotools/libtool/mingw${_bitval}/share/man/man1/libtool.1
            echo 'done'
        fi

        # Copy to DST_DIR.
        printf "===> Copying Libtool %s to %s/mingw%s...\n" "${_arch}" "${DST_DIR}" "${_bitval}"
        cp -af "${PREIN_DIR}"/autotools/libtool/mingw$_bitval "${DST_DIR}"
        echo 'done'
    done

    cd "${ROOT_DIR}"
    return 0
}
