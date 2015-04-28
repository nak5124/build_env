# Autoconf: A GNU tool for automatically configuring source code
# Download the src and decompress it.
function download_autoconf_src() {
    # Download the src.
    if [ ! -f ${BUILD_DIR}/autotools/autoconf/src/autoconf-${AUTOCONF_VER}.tar.xz ]; then
        printf "===> Downloading Autoconf %s...\n" $AUTOCONF_VER
        pushd ${BUILD_DIR}/autotools/autoconf/src > /dev/null
        dl_files ftp ftp://ftp.gnu.org/gnu/autoconf/autoconf-${AUTOCONF_VER}.tar.xz
        popd > /dev/null
        echo "done"
    fi

    # Decompress the src archive.
    if [ ! -d ${BUILD_DIR}/autotools/autoconf/src/autoconf-$AUTOCONF_VER ]; then
        printf "===> Extracting Autoconf %s...\n" $AUTOCONF_VER
        pushd ${BUILD_DIR}/autotools/autoconf/src > /dev/null
        decomp_arch ${BUILD_DIR}/autotools/autoconf/src/autoconf-${AUTOCONF_VER}.tar.xz
        popd > /dev/null
        echo "done"
    fi

    return 0
}

# Apply patches.
function prepare_autoconf() {
    if [ "${AUTOCONF_VER}" = "git" ]; then
        # Git clone.
        if [ ! -d ${BUILD_DIR}/autotools/autoconf/src/autoconf-$AUTOCONF_VER ]; then
            echo "===> Cloning Autoconf git repo..."
            pushd ${BUILD_DIR}/autotools/autoconf/src > /dev/null
            dl_files git git://git.sv.gnu.org/autoconf.git autoconf-$AUTOCONF_VER
            popd > /dev/null
            echo "done"
        fi

        # Git pull.
        echo "===> Updating Autoconf git repo..."
        pushd ${BUILD_DIR}/autotools/autoconf/src/autoconf-$AUTOCONF_VER > /dev/null
        git clean -fdx > /dev/null 2>&1
        git reset --hard > /dev/null 2>&1
        git pull > /dev/null 2>&1
        git_hash > ${LOGS_DIR}/autotools/autoconf/autoconf.hash 2>&1
        git_rev >> ${LOGS_DIR}/autotools/autoconf/autoconf.hash 2>&1
        echo "done"

        # Apply patches.
        printf "===> Applying patches to Autoconf %s...\n" $AUTOCONF_VER
        patch -p1 -i ${PATCHES_DIR}/autoconf/0001-atomic.all.patch \
            > ${LOGS_DIR}/autotools/autoconf/autoconf_patch.log 2>&1 || exit 1
        patch -p1 -i ${PATCHES_DIR}/autoconf/0002-stricter-versioning.all.patch \
            >> ${LOGS_DIR}/autotools/autoconf/autoconf_patch.log 2>&1 || exit 1
        patch -p1 -i ${PATCHES_DIR}/autoconf/0003-m4sh.m4.all.patch \
            >> ${LOGS_DIR}/autotools/autoconf/autoconf_patch.log 2>&1 || exit 1
        patch -p1 -i ${PATCHES_DIR}/autoconf/0006-allow-lns-on-msys2.all.patch \
            >> ${LOGS_DIR}/autotools/autoconf/autoconf_patch.log 2>&1 || exit 1
        patch -p1 -i ${PATCHES_DIR}/autoconf/0008-fix-cr-for-awk-in-status.all.patch \
            >> ${LOGS_DIR}/autotools/autoconf/autoconf_patch.log 2>&1 || exit 1
        echo "done"

        # Autoreconf.
        printf "===> Autoreconfing Autoconf %s...\n" $AUTOCONF_VER
        autoreconf -fi > /dev/null 2>&1
        popd > /dev/null
        echo "done"
    else
        # Apply patches.
        printf "===> Applying patches to Autoconf %s...\n" $AUTOCONF_VER
        pushd ${BUILD_DIR}/autotools/autoconf/src/autoconf-$AUTOCONF_VER > /dev/null
        if [ ! -f ${BUILD_DIR}/autotools/autoconf/src/autoconf-${AUTOCONF_VER}/patched_01.marker ]; then
            patch -p1 -i ${PATCHES_DIR}/autoconf/0001-atomic.all.patch \
                > ${LOGS_DIR}/autotools/autoconf/autoconf_patch.log 2>&1 || exit 1
            touch ${BUILD_DIR}/autotools/autoconf/src/autoconf-${AUTOCONF_VER}/patched_01.marker
        fi
        if [ ! -f ${BUILD_DIR}/autotools/autoconf/src/autoconf-${AUTOCONF_VER}/patched_02.marker ]; then
            patch -p1 -i ${PATCHES_DIR}/autoconf/0002-stricter-versioning.all.patch \
                >> ${LOGS_DIR}/autotools/autoconf/autoconf_patch.log 2>&1 || exit 1
            touch ${BUILD_DIR}/autotools/autoconf/src/autoconf-${AUTOCONF_VER}/patched_02.marker
        fi
        if [ ! -f ${BUILD_DIR}/autotools/autoconf/src/autoconf-${AUTOCONF_VER}/patched_03.marker ]; then
            patch -p1 -i ${PATCHES_DIR}/autoconf/0003-m4sh.m4.all.patch \
                >> ${LOGS_DIR}/autotools/autoconf/autoconf_patch.log 2>&1 || exit 1
            touch ${BUILD_DIR}/autotools/autoconf/src/autoconf-${AUTOCONF_VER}/patched_03.marker
        fi
        if [ ! -f ${BUILD_DIR}/autotools/autoconf/src/autoconf-${AUTOCONF_VER}/patched_04.marker ]; then
            patch -p1 -i ${PATCHES_DIR}/autoconf/0004-autoconf2.5-2.69-1.src.all.patch \
                >> ${LOGS_DIR}/autotools/autoconf/autoconf_patch.log 2>&1 || exit 1
            touch ${BUILD_DIR}/autotools/autoconf/src/autoconf-${AUTOCONF_VER}/patched_04.marker
        fi
        if [ ! -f ${BUILD_DIR}/autotools/autoconf/src/autoconf-${AUTOCONF_VER}/patched_05.marker ]; then
            patch -p1 -i ${PATCHES_DIR}/autoconf/0005-autoconf-ga357718.all.patch \
                >> ${LOGS_DIR}/autotools/autoconf/autoconf_patch.log 2>&1 || exit 1
            touch ${BUILD_DIR}/autotools/autoconf/src/autoconf-${AUTOCONF_VER}/patched_05.marker
        fi
        if [ ! -f ${BUILD_DIR}/autotools/autoconf/src/autoconf-${AUTOCONF_VER}/patched_06.marker ]; then
            patch -p1 -i ${PATCHES_DIR}/autoconf/0006-allow-lns-on-msys2.all.patch \
                >> ${LOGS_DIR}/autotools/autoconf/autoconf_patch.log 2>&1 || exit 1
            touch ${BUILD_DIR}/autotools/autoconf/src/autoconf-${AUTOCONF_VER}/patched_06.marker
        fi
        if [ ! -f ${BUILD_DIR}/autotools/autoconf/src/autoconf-${AUTOCONF_VER}/patched_07.marker ]; then
            patch -p1 -i ${PATCHES_DIR}/autoconf/0007-fix-cr-for-awk-in-configure.all.patch \
                >> ${LOGS_DIR}/autotools/autoconf/autoconf_patch.log 2>&1 || exit 1
            touch ${BUILD_DIR}/autotools/autoconf/src/autoconf-${AUTOCONF_VER}/patched_07.marker
        fi
        if [ ! -f ${BUILD_DIR}/autotools/autoconf/src/autoconf-${AUTOCONF_VER}/patched_08.marker ]; then
            patch -p1 -i ${PATCHES_DIR}/autoconf/0008-fix-cr-for-awk-in-status.all.patch \
                >> ${LOGS_DIR}/autotools/autoconf/autoconf_patch.log 2>&1 || exit 1
            touch ${BUILD_DIR}/autotools/autoconf/src/autoconf-${AUTOCONF_VER}/patched_08.marker
        fi
        popd > /dev/null
        echo "done"
    fi

    return 0
}

# Build and install.
function build_autoconf() {
    clear; printf "Build Autoconf %s...\n" $AUTOCONF_VER

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
                printf "build_autoconf: Unknown Option: '%s'\n" $_opt
                echo "...exit"
                exit 1
                ;;
        esac
    done

    # Setup.
    if ${_rebuild}; then
        if [ "${AUTOCONF_VER}" != "git" ]; then
            download_autoconf_src
        fi
        prepare_autoconf
    fi

    local _arch
    for _arch in ${TARGET_ARCH[@]}
    do
        local _bitval=$(get_arch_bit ${_arch})

        if ${_rebuild}; then
            cd ${BUILD_DIR}/autotools/autoconf/build_$_arch
            # Cleanup the build dir.
            rm -fr ${BUILD_DIR}/autotools/autoconf/build_${_arch}/*

            # PATH exporting.
            source cpath $_arch
            PATH=${DST_DIR}/mingw${_bitval}/bin:/usr/local/bin:/usr/bin
            export PATH

            # Configure.
            printf "===> Configuring Autoconf %s...\n" $_arch
            # Setting {CPP,C,CXX,LD}FLAGS does not make any sense.
            ../src/autoconf-${AUTOCONF_VER}/configure \
                --prefix=/mingw$_bitval               \
                --build=${_arch}-w64-mingw32          \
                --host=${_arch}-w64-mingw32           \
                --disable-silent-rules                \
                > ${LOGS_DIR}/autotools/autoconf/autoconf_config_${_arch}.log 2>&1 || exit 1
            echo "done"

            # Make.
            printf "===> Making Autoconf %s...\n" $_arch
            make $MAKEFLAGS_ > ${LOGS_DIR}/autotools/autoconf/autoconf_make_${_arch}.log 2>&1 || exit 1
            echo "done"

            # Install.
            printf "===> Installing Autoconf %s...\n" $_arch
            make DESTDIR=${PREIN_DIR}/autotools/autoconf install \
                > ${LOGS_DIR}/autotools/autoconf/autoconf_install_${_arch}.log 2>&1 || exit 1
            echo "done"
        fi

        # Copy to DST_DIR.
        printf "===> Copying Autoconf %s to %s/mingw%s...\n" $_arch $DST_DIR $_bitval
        cp -fra ${PREIN_DIR}/autotools/autoconf/mingw$_bitval $DST_DIR
        echo "done"
    done

    cd $ROOT_DIR
    return 0
}

# Automake: A GNU tool for automatically creating Makefiles
# Download the src and decompress it.
function download_automake_src() {
    # Download the src.
    if [ ! -f ${BUILD_DIR}/autotools/automake/src/automake-${AUTOMAKE_VER}.tar.xz ]; then
        printf "===> Downloading Automake %s...\n" $AUTOMAKE_VER
        pushd ${BUILD_DIR}/autotools/automake/src > /dev/null
        dl_files ftp ftp://ftp.gnu.org/gnu/automake/automake-${AUTOMAKE_VER}.tar.xz
        popd > /dev/null
        echo "done"
    fi

    # Decompress the src archive.
    if [ ! -d ${BUILD_DIR}/autotools/automake/src/automake-$AUTOMAKE_VER ]; then
        printf "===> Extracting Automake %s...\n" $AUTOMAKE_VER
        pushd ${BUILD_DIR}/autotools/automake/src > /dev/null
        decomp_arch ${BUILD_DIR}/autotools/automake/src/automake-${AUTOMAKE_VER}.tar.xz
        popd > /dev/null
        echo "done"
    fi

    return 0
}

# Apply patches.
function prepare_automake() {
    if [ "${AUTOMAKE_VER}" = "git" ]; then
        # Git clone.
        if [ ! -d ${BUILD_DIR}/autotools/automake/src/automake-$AUTOMAKE_VER ]; then
            echo "===> Cloning Automake git repo..."
            pushd ${BUILD_DIR}/autotools/automake/src > /dev/null
            dl_files git git://git.sv.gnu.org/automake.git automake-$AUTOMAKE_VER
            popd > /dev/null
            echo "done"
        fi

        # Git pull.
        echo "===> Updating Automake git repo..."
        pushd ${BUILD_DIR}/autotools/automake/src/automake-$AUTOMAKE_VER > /dev/null
        git clean -fdx > /dev/null 2>&1
        git reset --hard > /dev/null 2>&1
        git pull > /dev/null 2>&1
        git_hash > ${LOGS_DIR}/autotools/automake/automake.hash 2>&1
        git_rev >> ${LOGS_DIR}/autotools/automake/automake.hash 2>&1
        echo "done"

        # Bootstrap.
        printf "===> Bootstraping Automake %s...\n" $AUTOCONF_VER
        ./bootstrap.sh > /dev/null 2>&1
        popd > /dev/null
        echo "done"
    else
        # Apply patches.
        printf "===> Applying patches to Automake %s...\n" $AUTOMAKE_VER
        pushd ${BUILD_DIR}/autotools/automake/src/automake-$AUTOMAKE_VER > /dev/null
        if [ ! -f ${BUILD_DIR}/autotools/automake/src/automake-${AUTOMAKE_VER}/patched_01.marker ]; then
            patch -p1 -i ${PATCHES_DIR}/automake/0001-fix-cr-for-awk-in-configure.all.patch \
                > ${LOGS_DIR}/autotools/automake/automake_patch.log 2>&1 || exit 1
            touch ${BUILD_DIR}/autotools/automake/src/automake-${AUTOMAKE_VER}/patched_01.marker
        fi
        popd > /dev/null
        echo "done"
    fi

    return 0
}

# Build and install.
function build_automake() {
    clear; printf "Build Automake %s...\n" $AUTOMAKE_VER

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
                printf "build_automake: Unknown Option: '%s'... exit\n" $_opt
                exit 1
                ;;
        esac
    done

    # Setup.
    if ${_rebuild}; then
        if [ "${AUTOMAKE_VER}" != "git" ]; then
            download_automake_src
        fi
        prepare_automake
    fi

    local _arch
    for _arch in ${TARGET_ARCH[@]}
    do
        local _bitval=$(get_arch_bit ${_arch})

        if ${_rebuild}; then
            cd ${BUILD_DIR}/autotools/automake/build_$_arch
            # Cleanup the build dir.
            rm -fr ${BUILD_DIR}/autotools/automake/build_${_arch}/*

            # PATH exporting.
            source cpath $_arch
            PATH=${DST_DIR}/mingw${_bitval}/bin:/usr/local/bin:/usr/bin
            export PATH

            # Configure.
            printf "===> Configuring Automake %s...\n" $_arch
            # Setting {CPP,C,CXX,LD}FLAGS does not make any sense.
            ../src/automake-${AUTOMAKE_VER}/configure \
                --prefix=/mingw$_bitval               \
                --build=${_arch}-w64-mingw32          \
                --host=${_arch}-w64-mingw32           \
                --disable-silent-rules                \
                > ${LOGS_DIR}/autotools/automake/automake_config_${_arch}.log 2>&1 || exit 1
            echo "done"

            # Make.
            printf "===> Making Automake %s...\n" $_arch
            make $MAKEFLAGS_ > ${LOGS_DIR}/autotools/automake/automake_make_${_arch}.log 2>&1 || exit 1
            echo "done"

            # Install.
            printf "===> Installing Automake %s...\n" $_arch
            rm -fr ${PREIN_DIR}/autotools/automake/mingw${_bitval}/*
            make DESTDIR=${PREIN_DIR}/autotools/automake install \
                > ${LOGS_DIR}/autotools/automake/automake_install_${_arch}.log 2>&1 || exit 1
            echo "done"
        fi

        printf "===> Copying Automake %s to %s/mingw%s...\n" $_arch $DST_DIR $_bitval
        cp -fra ${PREIN_DIR}/autotools/automake/mingw$_bitval $DST_DIR
        # Create symlinks.
        if [ "${AUTOMAKE_VER}" != "git" ]; then
            if ${create_symlinks:-false}; then
                printf "===> Creating symlinks %s...\n" $_arch
                pushd ${DST_DIR}/mingw${_bitval}/bin > /dev/null
                ln -fsr ./automake-$AUTOMAKE_VER ./automake
                ln -fsr ./aclocal-$AUTOMAKE_VER ./aclocal
                popd > /dev/null
            else
                rm -f ${DST_DIR}/mingw${_bitval}/bin/{aclocal,automake}
            fi
        fi
        echo "done"
    done

    cd $ROOT_DIR
    return 0
}

# libtool: A generic library support script
# Download the src and decompress it.
function download_libtool_src() {
    # Download the src.
    if [ ! -f ${BUILD_DIR}/autotools/libtool/src/libtool-${LIBTOOL_VER}.tar.xz ]; then
        printf "===> Downloading  %s...\n" $ISL_VER
        pushd ${BUILD_DIR}/autotools/libtool/src > /dev/null
        dl_files ftp ftp://ftp.gnu.org/gnu/libtool/libtool-${LIBTOOL_VER}.tar.xz
        # dl_files ftp ftp://alpha.gnu.org/gnu/libtool/libtool-${LIBTOOL_VER}.tar.xz
        popd > /dev/null
        echo "done"
    fi

    # Decompress the src archive.
    if [ ! -d ${BUILD_DIR}/autotools/libtool/src/libtool-$LIBTOOL_VER ]; then
        printf "===> Extracting Libtool %s...\n" $LIBTOOL_VER
        pushd ${BUILD_DIR}/autotools/libtool/src > /dev/null
        decomp_arch ${BUILD_DIR}/autotools/libtool/src/libtool-${LIBTOOL_VER}.tar.xz
        popd > /dev/null
        echo "done"
    fi

    return 0
}

# Apply patches.
function prepare_libtool() {
    if [ "${LIBTOOL_VER}" = "git" ]; then
        # Git clone.
        if [ ! -d ${BUILD_DIR}/autotools/libtool/src/libtool-$LIBTOOL_VER ]; then
            echo "===> Cloning Libtool git repo..."
            pushd ${BUILD_DIR}/autotools/libtool/src > /dev/null
            dl_files git git://git.sv.gnu.org/libtool.git libtool-$LIBTOOL_VER
            popd > /dev/null
            echo "done"
        fi

        # Git pull.
        echo "===> Updating Libtool git repo..."
        pushd ${BUILD_DIR}/autotools/libtool/src/libtool-$LIBTOOL_VER > /dev/null
        git clean -fdx > /dev/null 2>&1
        git reset --hard > /dev/null 2>&1
        git pull > /dev/null 2>&1
        git_hash > ${LOGS_DIR}/autotools/libtool/libtool.hash 2>&1
        git_rev >> ${LOGS_DIR}/autotools/libtool/libtool.hash 2>&1
        echo "done"

        # Apply patches.
        printf "===> Applying patches to Libtool %s...\n" $LIBTOOL_VER
        patch -p1 -i ${PATCHES_DIR}/libtool/0001-cygwin-mingw-Create-UAC-manifest-files.mingw.patch \
            > ${LOGS_DIR}/autotools/libtool/libtool_patch.log 2>&1 || exit 1
        patch -p1 -i ${PATCHES_DIR}/libtool/0002-Pass-various-runtime-library-flags-to-GCC.mingw.patch \
            >> ${LOGS_DIR}/autotools/libtool/libtool_patch.log 2>&1 || exit 1
        patch -p1 -i ${PATCHES_DIR}/libtool/0003-Fix-seems-to-be-moved.patch \
            >> ${LOGS_DIR}/autotools/libtool/libtool_patch.log 2>&1 || exit 1
        patch -p1 -i ${PATCHES_DIR}/libtool/0004-Fix-strict-ansi-vs-posix.patch \
            >> ${LOGS_DIR}/autotools/libtool/libtool_patch.log 2>&1 || exit 1
        echo "done"

        # Bootstrap.
        printf "===> Bootstraping Libtool %s...\n" $LIBTOOL_VER
        ./bootstrap > /dev/null 2>&1
        popd > /dev/null
        echo "done"
    else
        # Apply patches.
        printf "===> Applying patches to Libtool %s...\n" $LIBTOOL_VER
        pushd ${BUILD_DIR}/autotools/libtool/src/libtool-$LIBTOOL_VER > /dev/null
        if [ ! -f ${BUILD_DIR}/autotools/libtool/src/libtool-${LIBTOOL_VER}/patched_01.marker ]; then
            patch -p1 -i ${PATCHES_DIR}/libtool/0001-cygwin-mingw-Create-UAC-manifest-files.mingw.patch \
                > ${LOGS_DIR}/autotools/libtool/libtool_patch.log 2>&1 || exit 1
            touch ${BUILD_DIR}/autotools/libtool/src/libtool-${LIBTOOL_VER}/patched_01.marker
        fi
        if [ ! -f ${BUILD_DIR}/autotools/libtool/src/libtool-${LIBTOOL_VER}/patched_02.marker ]; then
            patch -p1 -i ${PATCHES_DIR}/libtool/0002-Pass-various-runtime-library-flags-to-GCC.mingw.patch \
                >> ${LOGS_DIR}/autotools/libtool/libtool_patch.log 2>&1 || exit 1
            touch ${BUILD_DIR}/autotools/libtool/src/libtool-${LIBTOOL_VER}/patched_02.marker
        fi
        if [ ! -f ${BUILD_DIR}/autotools/libtool/src/libtool-${LIBTOOL_VER}/patched_03.marker ]; then
            patch -p1 -i ${PATCHES_DIR}/libtool/0003-Fix-seems-to-be-moved.patch \
                >> ${LOGS_DIR}/autotools/libtool/libtool_patch.log 2>&1 || exit 1
            touch ${BUILD_DIR}/autotools/libtool/src/libtool-${LIBTOOL_VER}/patched_03.marker
        fi
        if [ ! -f ${BUILD_DIR}/autotools/libtool/src/libtool-${LIBTOOL_VER}/patched_04.marker ]; then
            patch -p1 -i ${PATCHES_DIR}/libtool/0004-Fix-strict-ansi-vs-posix.patch \
                >> ${LOGS_DIR}/autotools/libtool/libtool_patch.log 2>&1 || exit 1
            touch ${BUILD_DIR}/autotools/libtool/src/libtool-${LIBTOOL_VER}/patched_04.marker
        fi
        if [ ! -f ${BUILD_DIR}/autotools/libtool/src/libtool-${LIBTOOL_VER}/patched_05.marker ]; then
            patch -p1 -i ${PATCHES_DIR}/libtool/0005-fix-cr-for-awk-in-configure.all.patch \
                >> ${LOGS_DIR}/autotools/libtool/libtool_patch.log 2>&1 || exit 1
            touch ${BUILD_DIR}/autotools/libtool/src/libtool-${LIBTOOL_VER}/patched_05.marker
        fi
        # Disable automatic image base calculation.
        sed -i 's/enable-auto-image-base/disable-auto-image-base/g' {configure,m4/libtool.m4}
        perl -pi -e 's/_stat\n/_stat64\n/g' build-aux/ltmain.in
        popd > /dev/null
        echo "done"
    fi

    return 0
}

# Build and install.
function build_libtool() {
    clear; printf "Build Libtool %s...\n" $LIBTOOL_VER

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
                printf "build_libtool: Unknown Option: '%s'... exit\n" $_opt
                exit 1
                ;;
        esac
    done

    # Setup.
    if ${_rebuild}; then
        if [ "${LIBTOOL_VER}" != "git" ]; then
            download_libtool_src
        fi
        prepare_libtool
    fi

    local _arch
    for _arch in ${TARGET_ARCH[@]}
    do
        local _bitval=$(get_arch_bit ${_arch})

        if ${_rebuild}; then
            cd ${BUILD_DIR}/autotools/libtool/build_$_arch
            # Cleanup the build dir.
            rm -fr ${BUILD_DIR}/autotools/libtool/build_${_arch}/*

            # PATH exporting.
            source cpath $_arch
            PATH=${DST_DIR}/mingw${_bitval}/bin:/usr/local/bin:/usr/bin
            export PATH

            # Configure.
            printf "===> Configuring Libtool %s...\n" $_arch
            # Setting {CPP,C,CXX,LD}FLAGS does not make any sense.
            ../src/libtool-${LIBTOOL_VER}/configure \
                --prefix=/mingw$_bitval             \
                --build=${_arch}-w64-mingw32        \
                --host=${_arch}-w64-mingw32         \
                --disable-silent-rules              \
                --disable-ltdl-install              \
                > ${LOGS_DIR}/autotools/libtool/libtool_config_${_arch}.log 2>&1 || exit 1
            echo "done"

            # Make.
            printf "===> Making Libtool %s...\n" $_arch
            make $MAKEFLAGS > ${LOGS_DIR}/autotools/libtool/libtool_make_${_arch}.log 2>&1 || exit 1
            echo "done"

            # Install.
            printf "===> Installing Libtool %s...\n" $_arch
            # Don't install libltdl.
            make DESTDIR=${PREIN_DIR}/autotools/libtool install \
                > ${LOGS_DIR}/autotools/libtool/libtool_install_${_arch}.log 2>&1 || exit 1
            rm -fr ${PREIN_DIR}/autotools/libtool/mingw${_bitval}/share/libtool/libltdl
            # Modify hard coded file PATH.
            local _dst_dir_winpath=$(cygpath -ma ${DST_DIR})
            sed -i "s|${_dst_dir_winpath//\//\\/}||g" ${PREIN_DIR}/autotools/libtool/mingw${_bitval}/bin/libtool
            sed -i "s|${DST_DIR//\//\\/}||g" ${PREIN_DIR}/autotools/libtool/mingw${_bitval}/bin/libtool
            sed -i "s|${_dst_dir_winpath//\//\\/}||g" ${PREIN_DIR}/autotools/libtool/mingw${_bitval}/share/man/man1/libtool.1
            echo "done"
        fi

        # Copy to DST_DIR.
        printf "===> Copying Libtool %s to %s/mingw%s...\n" $_arch $DST_DIR $_bitval
        cp -fra ${PREIN_DIR}/autotools/libtool/mingw$_bitval $DST_DIR
        echo "done"
    done

    cd $ROOT_DIR
    return 0
}
