#!/usr/bin/env bash


PATCHES_DIR=${HOME}/patches/opus-tools
LOGS_DIR=${HOME}/logs/opus-tools
if [ ! -d $LOGS_DIR ] ; then
    mkdir -p $LOGS_DIR
fi

# libopus
build_libopus() {
    clear; echo "Build libopus git-master"

    if [ ! -d ${HOME}/OSS/xiph/opus ] ; then
        cd ${HOME}/OSS/xiph
        git clone git://git.xiph.org/opus.git
    fi
    cd ${HOME}/OSS/xiph/opus

    git clean -fdx > /dev/null 2>&1
    git reset --hard > /dev/null 2>&1
    git pull > /dev/null 2>&1
    git_hash > ${LOGS_DIR}/opus.hash
    git_rev >> ${LOGS_DIR}/opus.hash

    autoreconf -fiv > /dev/null 2>&1

    patch -p1 < ${PATCHES_DIR}/version.patch \
        > ${LOGS_DIR}/opus_patch.log 2>&1 || exit 1

    for arch in i686 x86_64
    do
        source cpath $arch
        echo "===> configure libopus ${arch}"
        ./configure --prefix=${HOME}/local/$arch \
                    --build=${arch}-w64-mingw32  \
                    --host=${arch}-w64-mingw32   \
                    --disable-shared             \
                    --enable-static              \
                    --disable-doc                \
                    --disable-extra-programs     \
                    CFLAGS="${BASE_CFLAGS}"      \
                    CPPFLAGS="${BASE_CPPFLAGS}"  \
                    CXXFLAGS="${BASE_CXXFLAGS}"  \
                    LDFLAGS="${BASE_LDFLAGS}"    \
        > ${LOGS_DIR}/opus_config_${arch}.log 2>&1 || exit 1
        echo "done"

        make clean > /dev/null 2>&1
        echo "===> make libopus ${arch}"
        make -j5 -O > ${LOGS_DIR}/opus_make_${arch}.log 2>&1 || exit 1
        echo "done"

        echo "===> install libopus ${arch}"
        make install-strip \
            > ${LOGS_DIR}/opus_install_${arch}.log 2>&1 || exit 1
        echo "done"
        make distclean > /dev/null 2>&1
    done

    return 0
}

# opus-tools
build_tools() {
    clear; echo "Build opus-tools git-master"

    if [ ! -d ${HOME}/OSS/xiph/opus-tools ] ; then
        cd ${HOME}/OSS/xiph
        git clone git://git.xiph.org/opus-tools.git
    fi
    cd ${HOME}/OSS/xiph/opus-tools

    git clean -fdx > /dev/null 2>&1
    git reset --hard > /dev/null 2>&1
    git pull > /dev/null 2>&1
    git_hash > ${LOGS_DIR}/tools.hash
    git_rev >> ${LOGS_DIR}/tools.hash

    ./autogen.sh > /dev/null 2>&1

    patch -p1 < ${PATCHES_DIR}/version_tools.patch \
        > ${LOGS_DIR}/tools_patch.log 2>&1 || exit 1

    for arch in i686 x86_64
    do
        if [ "$arch" == "i686" ] ; then
            local _LAA=" -Wl,--large-address-aware"
        else
            local _LAA=""
        fi

        source cpath $arch
        echo "===> configure opus-tools ${arch}"
        PKG_CONFIG_PATH=${HOME}/local/${arch}/lib/pkgconfig \
        ./configure --prefix=${HOME}/local/$arch            \
                    --build=${arch}-w64-mingw32             \
                    --host=${arch}-w64-mingw32              \
                    --disable-shared --enable-static        \
                    --enable-sse                            \
                    CFLAGS="${BASE_CFLAGS}"                 \
                    CPPFLAGS="${BASE_CPPFLAGS}"             \
                    CXXFLAGS="${BASE_CXXFLAGS}"             \
                    LDFLAGS="${BASE_LDFLAGS} ${_LAA}"       \
        > ${LOGS_DIR}/tools_config_${arch}.log 2>&1 || exit 1
        echo "done"

        make clean > /dev/null 2>&1
        echo "===> make opus-tools ${arch}"
        make -j5 -O > ${LOGS_DIR}/tools_make_${arch}.log 2>&1 || exit 1
        echo "done"

        echo "===> install opus-tools ${arch}"
        make install-strip \
            > ${LOGS_DIR}/tools_install_${arch}.log 2>&1 || exit 1
        echo "done"
        make distclean > /dev/null 2>&1
    done

    return 0
}

make_package() {
    cd ${HOME}/OSS/xiph/opus-tools

    DEST_DIR=${HOME}/local/dist/opus-tools/opus-tools_$(git describe --long)

    if [[ ! -d ${DEST_DIR}/{win32,x64} ]] ; then
        mkdir -p ${DEST_DIR}/{win32,x64}
    fi

    clear; echo "making package..."
    cp -fa ${HOME}/local/i686/bin/opus*.exe ${DEST_DIR}/win32
    cp -fa ${HOME}/local/x86_64/bin/opus*.exe ${DEST_DIR}/x64
    cp -fa ${HOME}/OSS/xiph/opus-tools/COPYING $DEST_DIR
    cp -fa ${DEST_DIR}/x64/* ${DEST_DIR}/..
    cp -fa ${DEST_DIR}/x64/* /d/encode/tools
    echo "done"

    return 0
}

build_libopus
build_tools
make_package

clear; echo "Everything has been successfully completed!"

