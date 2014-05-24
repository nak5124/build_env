#!/bin/bash


PATCHES_DIR=${HOME}/patches/opus-tools
LOGS_DIR=${HOME}/log/opus-tools
if [ ! -d $LOGS_DIR ] ; then
    mkdir -p $LOGS_DIR
fi

# libopus
build_libopus() {
    clear; echo "Build libopus git-master"


    if [ ! -d ${HOME}/opus-tools/opus ] ; then
        cd ${HOME}/opus-tools
        git clone git://git.xiph.org/opus.git
    fi
    cd ${HOME}/opus-tools/opus

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
        ./configure --prefix=${HOME}/opus-tools/$arch  \
                    --build=${arch}-w64-mingw32        \
                    --host=${arch}-w64-mingw32         \
                    --disable-shared                   \
                    --enable-static                    \
                    --disable-doc                      \
                    --disable-extra-programs           \
                    CFLAGS="${BASE_CFLAGS}"            \
                    CPPFLAGS="${BASE_CPPFLAGS}"        \
                    CXXFLAGS="${BASE_CXXFLAGS}"        \
                    LDFLAGS="${BASE_LDFLAGS}"          \
        > ${LOGS_DIR}/opus_config_${arch}.log 2>&1 || exit 1
        echo "done"

        make clean > /dev/null 2>&1
        echo "===> make libopus ${arch}"
        make -j5 -O > ${LOGS_DIR}/opus_make_${arch}.log 2>&1 || exit 1
        echo "done"

        echo "===> install libopus ${arch}"
        make install-strip > ${LOGS_DIR}/opus_install_${arch}.log 2>&1 || exit 1
        echo "done"
        make distclean > /dev/null 2>&1
    done

    return 0
}

# opus-tools
build_tools() {
    clear; echo "Build opus-tools git-master"

    if [ ! -d ${HOME}/opus-tools/opus-tools ] ; then
        cd ${HOME}/opus-tools
        git clone git://git.xiph.org/opus-tools.git
    fi
    cd ${HOME}/opus-tools/opus-tools

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
        ./configure --prefix=${HOME}/opus-tools/$arch                       \
                    --build=${arch}-w64-mingw32                             \
                    --host=${arch}-w64-mingw32                              \
                    --disable-shared                                        \
                    --enable-static                                         \
                    --enable-sse                                            \
                    CFLAGS="${BASE_CFLAGS}"                                 \
                    CPPFLAGS="${BASE_CPPFLAGS}"                             \
                    CXXFLAGS="${BASE_CXXFLAGS}"                             \
                    LDFLAGS="${BASE_LDFLAGS} ${_LAA}"                       \
                    OGG_CFLAGS="-I${HOME}/FLAC/${arch}/include"             \
                    OGG_LIBS="-L${HOME}/FLAC/${arch}/lib -logg"             \
                    OPUS_CFLAGS="-I${HOME}/opus-tools/${arch}/include/opus" \
                    OPUS_LIBS="-L${HOME}/opus-tools/${arch}/lib -lopus"     \
                    FLAC_CFLAGS="-I${HOME}/FLAC/${arch}/include"            \
                    FLAC_LIBS="-L${HOME}/FLAC/${arch}/lib -lFLAC"           \
        > ${LOGS_DIR}/tools_config_${arch}.log 2>&1 || exit 1
        echo "done"

        make clean > /dev/null 2>&1
        echo "===> make opus-tools ${arch}"
        make -j5 -O > ${LOGS_DIR}/tools_make_${arch}.log 2>&1 || exit 1
        echo "done"

        echo "===> install opus-tools ${arch}"
        make install-strip > ${LOGS_DIR}/tools_install_${arch}.log 2>&1 || exit 1
        echo "done"
        make distclean > /dev/null 2>&1
    done

    return 0
}

make_package() {
    if [ ! -d ${HOME}/opus-tools/opus-tools ] ; then
        cd ${HOME}/opus-tools
        git clone git://git.xiph.org/opus-tools.git
    fi
    cd ${HOME}/opus-tools/opus-tools

    DEST_DIR=/usr/local/opus-tools/opus-tools_`git describe --long`

    if [[ ! -d ${DEST_DIR}/{win32,x64} ]] ; then
        mkdir -p ${DEST_DIR}/{win32,x64}
    fi

    clear; echo "making package..."
    cp -fa ${HOME}/opus-tools/${arch}/bin/*.exe ${DEST_DIR}/win32
    cp -fa ${HOME}/opus-tools/${arch}/bin/*.exe ${DEST_DIR}/x64
    cp -fa ${HOME}/opus-tools/opus-tools/COPYING $DEST_DIR
    cp -fa ${DEST_DIR}/x64/* /usr/local/opus-tools
    cp -fa ${DEST_DIR}/x64/* /d/encode/tools
    echo "done"

    return 0
}

build_libopus
build_tools
make_package

clear; echo "Everything has been successfully completed!"

