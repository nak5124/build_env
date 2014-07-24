# Autoconf: A GNU tool for automatically configuring source code
# download src
function download_autoconf_src() {
    if [ ! -f ${BUILD_DIR}/autotools/autoconf/src/autoconf-${AUTOCONF_VER}.tar.xz ] ; then
        printf "===> downloading Autoconf %s\n" $AUTOCONF_VER
        pushd ${BUILD_DIR}/autotools/autoconf/src > /dev/null
        wget -c ftp://ftp.gnu.org/gnu/autoconf/autoconf-${AUTOCONF_VER}.tar.xz
        popd > /dev/null
        echo "done"
    fi

    if [ ! -d ${BUILD_DIR}/autotools/autoconf/src/autoconf-$AUTOCONF_VER ] ; then
        printf "===> extracting Autoconf %s\n" $AUTOCONF_VER
        pushd ${BUILD_DIR}/autotools/autoconf/src > /dev/null
        tar Jxf ${BUILD_DIR}/autotools/autoconf/src/autoconf-${AUTOCONF_VER}.tar.xz
        popd > /dev/null
        echo "done"
    fi

    return 0
}

# patch
function patch_autoconf() {
    pushd ${BUILD_DIR}/autotools/autoconf/src/autoconf-$AUTOCONF_VER > /dev/null

    if [ ! -f ${BUILD_DIR}/autotools/autoconf/src/autoconf-${AUTOCONF_VER}/patched_01.marker ] ; then
        patch -p1 < ${PATCHES_DIR}/autoconf/0001-atomic.all.patch \
            > ${LOGS_DIR}/autotools/autoconf/autoconf_patch.log 2>&1 || exit 1
        touch ${BUILD_DIR}/autotools/autoconf/src/autoconf-${AUTOCONF_VER}/patched_01.marker
    fi
    if [ ! -f ${BUILD_DIR}/autotools/autoconf/src/autoconf-${AUTOCONF_VER}/patched_02.marker ] ; then
        patch -p1 < ${PATCHES_DIR}/autoconf/0002-stricter-versioning.all.patch \
            >> ${LOGS_DIR}/autotools/autoconf/autoconf_patch.log 2>&1 || exit 1
        touch ${BUILD_DIR}/autotools/autoconf/src/autoconf-${AUTOCONF_VER}/patched_02.marker
    fi
    if [ ! -f ${BUILD_DIR}/autotools/autoconf/src/autoconf-${AUTOCONF_VER}/patched_03.marker ] ; then
        patch -p1 < ${PATCHES_DIR}/autoconf/0003-m4sh.m4.all.patch \
            >> ${LOGS_DIR}/autotools/autoconf/autoconf_patch.log 2>&1 || exit 1
        touch ${BUILD_DIR}/autotools/autoconf/src/autoconf-${AUTOCONF_VER}/patched_03.marker
    fi
    if [ ! -f ${BUILD_DIR}/autotools/autoconf/src/autoconf-${AUTOCONF_VER}/patched_04.marker ] ; then
        patch -p1 < ${PATCHES_DIR}/autoconf/0004-autoconf2.5-2.69-1.src.all.patch \
            >> ${LOGS_DIR}/autotools/autoconf/autoconf_patch.log 2>&1 || exit 1
        touch ${BUILD_DIR}/autotools/autoconf/src/autoconf-${AUTOCONF_VER}/patched_04.marker
    fi
    if [ ! -f ${BUILD_DIR}/autotools/autoconf/src/autoconf-${AUTOCONF_VER}/patched_05.marker ] ; then
        patch -p1 < ${PATCHES_DIR}/autoconf/0005-autoconf-ga357718.all.patch \
            >> ${LOGS_DIR}/autotools/autoconf/autoconf_patch.log 2>&1 || exit 1
        touch ${BUILD_DIR}/autotools/autoconf/src/autoconf-${AUTOCONF_VER}/patched_05.marker
    fi
    if [ ! -f ${BUILD_DIR}/autotools/autoconf/src/autoconf-${AUTOCONF_VER}/patched_06.marker ] ; then
        patch -p1 < ${PATCHES_DIR}/autoconf/0006-allow-lns-on-msys2.all.patch \
            >> ${LOGS_DIR}/autotools/autoconf/autoconf_patch.log 2>&1 || exit 1
        touch ${BUILD_DIR}/autotools/autoconf/src/autoconf-${AUTOCONF_VER}/patched_06.marker
    fi
    if [ ! -f ${BUILD_DIR}/autotools/autoconf/src/autoconf-${AUTOCONF_VER}/patched_07.marker ] ; then
        patch -p1 < ${PATCHES_DIR}/autoconf/0007-fix-cr-for-awk-in-configure.all.patch \
            >> ${LOGS_DIR}/autotools/autoconf/autoconf_patch.log 2>&1 || exit 1
        touch ${BUILD_DIR}/autotools/autoconf/src/autoconf-${AUTOCONF_VER}/patched_07.marker
    fi
    if [ ! -f ${BUILD_DIR}/autotools/autoconf/src/autoconf-${AUTOCONF_VER}/patched_08.marker ] ; then
        patch -p1 < ${PATCHES_DIR}/autoconf/0008-fix-cr-for-awk-in-status.all.patch \
            >> ${LOGS_DIR}/autotools/autoconf/autoconf_patch.log 2>&1 || exit 1
        touch ${BUILD_DIR}/autotools/autoconf/src/autoconf-${AUTOCONF_VER}/patched_08.marker
    fi

    popd > /dev/null

    return 0
}

# build
function build_autoconf() {
    clear; printf "Build Autoconf %s\n" $AUTOCONF_VER

    download_autoconf_src
    patch_autoconf

    for arch in ${TARGET_ARCH[@]}
    do
        cd ${BUILD_DIR}/autotools/autoconf/build_$arch
        rm -fr ${BUILD_DIR}/autotools/autoconf/build_${arch}/*

        local bitval=$(get_arch_bit ${arch})

        source cpath $arch
        PATH=${DST_DIR}/mingw${bitval}/bin:/usr/local/bin:/usr/bin:/bin
        export PATH

        printf "===> configure Autoconf %s\n" $arch
        ../src/autoconf-${AUTOCONF_VER}/configure \
            --prefix=/mingw$bitval                \
            --build=${arch}-w64-mingw32           \
            --host=${arch}-w64-mingw32            \
            > ${LOGS_DIR}/autotools/autoconf/autoconf_config_${arch}.log 2>&1 || exit 1
        echo "done"

        printf "===> building Autoconf %s\n" $arch
        make $MAKEFLAGS > ${LOGS_DIR}/autotools/autoconf/autoconf_make_${arch}.log 2>&1 || exit 1
        echo "done"

        printf "===> installing Autoconf %s\n" $arch
        make DESTDIR=${PREIN_DIR}/autotools/autoconf install \
            > ${LOGS_DIR}/autotools/autoconf/autoconf_install_${arch}.log 2>&1 || exit 1
        rm -f ${PREIN_DIR}/autotools/autoconf/mingw${bitval}/share/info/standards.info
        echo "done"

        printf "===> copying Autoconf %s to %s/mingw%s\n" $arch $DST_DIR $bitval
        cp -fra ${PREIN_DIR}/autotools/autoconf/mingw$bitval $DST_DIR
        echo "done"
    done

    cd $ROOT_DIR
    return 0
}

# copy only
function copy_only_autoconf() {
    clear; printf "Autoconf %s\n" $AUTOCONF_VER

    for arch in ${TARGET_ARCH[@]}
    do
        local bitval=$(get_arch_bit ${arch})

        printf "===> copying Autoconf %s to %s/mingw%s\n" $arch $DST_DIR $bitval
        cp -fra ${PREIN_DIR}/autotools/autoconf/mingw$bitval $DST_DIR
        echo "done"
    done

    cd $ROOT_DIR
    return 0
}

# Automake: A GNU tool for automatically creating Makefiles
# download src
function download_automake_src() {
    if [ ! -f ${BUILD_DIR}/autotools/automake/src/automake-${AUTOMAKE_VER}.tar.xz ] ; then
        printf "===> downloading Automake %s\n" $AUTOMAKE_VER
        pushd ${BUILD_DIR}/autotools/automake/src > /dev/null
        wget -c ftp://ftp.gnu.org/gnu/automake/automake-${AUTOMAKE_VER}.tar.xz
        popd > /dev/null
        echo "done"
    fi

    if [ ! -d ${BUILD_DIR}/autotools/automake/src/automake-$AUTOMAKE_VER ] ; then
        printf "===> extracting Automake %s\n" $AUTOMAKE_VER
        pushd ${BUILD_DIR}/autotools/automake/src > /dev/null
        tar Jxf ${BUILD_DIR}/autotools/automake/src/automake-${AUTOMAKE_VER}.tar.xz
        popd > /dev/null
        echo "done"
    fi

    return 0
}

# patch
function patch_automake() {
    pushd ${BUILD_DIR}/autotools/automake/src/automake-$AUTOMAKE_VER > /dev/null

    if [ ! -f ${BUILD_DIR}/autotools/automake/src/automake-${AUTOMAKE_VER}/patched_01.marker ] ; then
        patch -p1 < ${PATCHES_DIR}/automake/0001-fix-cr-for-awk-in-configure.all.patch \
            > ${LOGS_DIR}/autotools/automake/automake_patch.log 2>&1 || exit 1
        touch ${BUILD_DIR}/autotools/automake/src/automake-${AUTOMAKE_VER}/patched_01.marker
    fi

    popd > /dev/null

    return 0
}

# build
function build_automake() {
    clear; printf "Build Automake %s\n" $AUTOMAKE_VER

    download_automake_src
    patch_automake

    for arch in ${TARGET_ARCH[@]}
    do
        cd ${BUILD_DIR}/autotools/automake/build_$arch
        rm -fr ${BUILD_DIR}/autotools/automake/build_${arch}/*

        local bitval=$(get_arch_bit ${arch})

        source cpath $arch
        PATH=${DST_DIR}/mingw${bitval}/bin:/usr/local/bin:/usr/bin:/bin
        export PATH

        printf "===> configure Automake %s\n" $arch
        ../src/automake-${AUTOMAKE_VER}/configure \
            --prefix=/mingw$bitval                \
            --build=${arch}-w64-mingw32           \
            --host=${arch}-w64-mingw32            \
            > ${LOGS_DIR}/autotools/automake/automake_config_${arch}.log 2>&1 || exit 1
        echo "done"

        printf "===> building Automake %s\n" $arch
        make $MAKEFLAGS > ${LOGS_DIR}/autotools/automake/automake_make_${arch}.log 2>&1 || exit 1
        echo "done"

        printf "===> installing Automake %s\n" $arch
        make DESTDIR=${PREIN_DIR}/autotools/automake install \
            > ${LOGS_DIR}/autotools/automake/automake_install_${arch}.log 2>&1 || exit 1
        echo "done"

        printf "===> copying Automake %s to %s/mingw%s\n" $arch $DST_DIR $bitval
        cp -fra ${PREIN_DIR}/autotools/automake/mingw$bitval $DST_DIR
        echo "done"
    done

    cd $ROOT_DIR
    return 0
}

# copy only
function copy_only_automake() {
    clear; printf "Automake %s\n" $AUTOMAKE_VER

    for arch in ${TARGET_ARCH[@]}
    do
        local bitval=$(get_arch_bit ${arch})

        printf "===> copying Automake %s to %s/mingw%s\n" $arch $DST_DIR $bitval
        cp -fra ${PREIN_DIR}/autotools/automake/mingw$bitval $DST_DIR
        echo "done"
    done

    cd $ROOT_DIR
    return 0
}

# libtool: A generic library support script
# download src
function download_libtool_src() {
    if [ ! -f ${BUILD_DIR}/autotools/libtool/src/libtool-${LIBTOOL_VER}.tar.xz ] ; then
        printf "===> downloading  %s\n" $ISL_VER
        pushd ${BUILD_DIR}/autotools/libtool/src > /dev/null
        # wget -c ftp://ftp.gnu.org/gnu/libtool/libtool-${LIBTOOL_VER}.tar.xz
        wget -c ftp://alpha.gnu.org/gnu/libtool/libtool-${LIBTOOL_VER}.tar.xz
        popd > /dev/null
        echo "done"
    fi

    if [ ! -d ${BUILD_DIR}/autotools/libtool/src/libtool-$LIBTOOL_VER ] ; then
        printf "===> extracting Libtool %s\n" $LIBTOOL_VER
        pushd ${BUILD_DIR}/autotools/libtool/src > /dev/null
        tar Jxf ${BUILD_DIR}/autotools/libtool/src/libtool-${LIBTOOL_VER}.tar.xz
        popd > /dev/null
        echo "done"
    fi

    return 0
}

# patch
function patch_libtool() {
    pushd ${BUILD_DIR}/autotools/libtool/src/libtool-$LIBTOOL_VER > /dev/null

    if [ ! -f ${BUILD_DIR}/autotools/libtool/src/libtool-${LIBTOOL_VER}/patched_01.marker ] ; then
        patch -p1 < ${PATCHES_DIR}/libtool/0001-cygwin-mingw-Create-UAC-manifest-files.mingw.patch \
            > ${LOGS_DIR}/autotools/libtool/libtool_patch.log 2>&1 || exit 1
        touch ${BUILD_DIR}/autotools/libtool/src/libtool-${LIBTOOL_VER}/patched_01.marker
    fi
    if [ ! -f ${BUILD_DIR}/autotools/libtool/src/libtool-${LIBTOOL_VER}/patched_02.marker ] ; then
        patch -p1 < ${PATCHES_DIR}/libtool/0002-Pass-various-runtime-library-flags-to-GCC.mingw.patch \
            >> ${LOGS_DIR}/autotools/libtool/libtool_patch.log 2>&1 || exit 1
        touch ${BUILD_DIR}/autotools/libtool/src/libtool-${LIBTOOL_VER}/patched_02.marker
    fi
    if [ ! -f ${BUILD_DIR}/autotools/libtool/src/libtool-${LIBTOOL_VER}/patched_03.marker ] ; then
        patch -p1 < ${PATCHES_DIR}/libtool/0003-Fix-linking-with-fstack-protector.mingw.patch \
            >> ${LOGS_DIR}/autotools/libtool/libtool_patch.log 2>&1 || exit 1
        touch ${BUILD_DIR}/autotools/libtool/src/libtool-${LIBTOOL_VER}/patched_03.marker
    fi
    if [ ! -f ${BUILD_DIR}/autotools/libtool/src/libtool-${LIBTOOL_VER}/patched_04.marker ] ; then
        patch -p1 < ${PATCHES_DIR}/libtool/0004-Fix-seems-to-be-moved.patch \
            >> ${LOGS_DIR}/autotools/libtool/libtool_patch.log 2>&1 || exit 1
        touch ${BUILD_DIR}/autotools/libtool/src/libtool-${LIBTOOL_VER}/patched_04.marker
    fi
    if [ ! -f ${BUILD_DIR}/autotools/libtool/src/libtool-${LIBTOOL_VER}/patched_05.marker ] ; then
        patch -p1 < ${PATCHES_DIR}/libtool/0005-Fix-strict-ansi-vs-posix.patch \
            >> ${LOGS_DIR}/autotools/libtool/libtool_patch.log 2>&1 || exit 1
        touch ${BUILD_DIR}/autotools/libtool/src/libtool-${LIBTOOL_VER}/patched_05.marker
    fi
    if [ ! -f ${BUILD_DIR}/autotools/libtool/src/libtool-${LIBTOOL_VER}/patched_06.marker ] ; then
        patch -p1 < ${PATCHES_DIR}/libtool/0006-fix-cr-for-awk-in-configure.all.patch \
            >> ${LOGS_DIR}/autotools/libtool/libtool_patch.log 2>&1 || exit 1
        touch ${BUILD_DIR}/autotools/libtool/src/libtool-${LIBTOOL_VER}/patched_06.marker
    fi
    if [ ! -f ${BUILD_DIR}/autotools/libtool/src/libtool-${LIBTOOL_VER}/patched_07.marker ] ; then
        patch -p1 < ${PATCHES_DIR}/libtool/0007-find-external-libraries.patch \
            >> ${LOGS_DIR}/autotools/libtool/libtool_patch.log 2>&1 || exit 1
        touch ${BUILD_DIR}/autotools/libtool/src/libtool-${LIBTOOL_VER}/patched_07.marker
    fi

    popd > /dev/null

    return 0
}

# build
function build_libtool() {
    clear; printf "Build Libtool %s\n" $LIBTOOL_VER

    download_libtool_src
    patch_libtool

    for arch in ${TARGET_ARCH[@]}
    do
        cd ${BUILD_DIR}/autotools/libtool/build_$arch
        rm -fr ${BUILD_DIR}/autotools/libtool/build_${arch}/*

        local bitval=$(get_arch_bit ${arch})

        source cpath $arch
        PATH=${DST_DIR}/mingw${bitval}/bin:/usr/local/bin:/usr/bin:/bin
        export PATH

        printf "===> configure Libtool %s\n" $arch
        ../src/libtool-${LIBTOOL_VER}/configure \
            --prefix=/mingw$bitval                \
            --build=${arch}-w64-mingw32           \
            --host=${arch}-w64-mingw32            \
            > ${LOGS_DIR}/autotools/libtool/libtool_config_${arch}.log 2>&1 || exit 1
        echo "done"

        printf "===> building Libtool %s\n" $arch
        make $MAKEFLAGS > ${LOGS_DIR}/autotools/libtool/libtool_make_${arch}.log 2>&1 || exit 1
        echo "done"

        printf "===> installing Libtool %s\n" $arch
        make DESTDIR=${PREIN_DIR}/autotools/libtool install-binSCRIPTS install-man install-info install-data-local \
            > ${LOGS_DIR}/autotools/libtool/libtool_install_${arch}.log 2>&1 || exit 1
        rm -fr ${PREIN_DIR}/autotools/libtool/mingw${bitval}/share/libtool/libltdl
        echo "done"

        printf "===> copying Libtool %s to %s/mingw%s\n" $arch $DST_DIR $bitval
        cp -fra ${PREIN_DIR}/autotools/libtool/mingw$bitval $DST_DIR
        echo "done"
    done

    cd $ROOT_DIR
    return 0
}

# copy only
function copy_only_libtool() {
    clear; printf "Libtool %s\n" $LIBTOOL_VER

    for arch in ${TARGET_ARCH[@]}
    do
        local bitval=$(get_arch_bit ${arch})

        printf "===> copying Libtool %s to %s/mingw%s\n" $arch $DST_DIR $bitval
        cp -fra ${PREIN_DIR}/autotools/libtool/mingw$bitval $DST_DIR
        echo "done"
    done

    cd $ROOT_DIR
    return 0
}
