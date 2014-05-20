#!/bin/bash


WORK_DIR="${HOME}/FLAC"
LOGS_DIR="${HOME}/log/FLAC"

# libogg
build_libogg() {
    clear; echo "Build libogg git-master"

    if [ ! -d ${WORK_DIR}/ogg ] ; then
        cd $WORK_DIR
        git clone git://git.xiph.org/mirrors/ogg.git
    fi
    cd ${WORK_DIR}/ogg

    git clean -fdx > /dev/null 2>&1
    git reset --hard > /dev/null 2>&1
    git pull > /dev/null 2>&1
    git_hash > ${LOGS_DIR}/ogg.hash
    git_rev >> ${LOGS_DIR}/ogg.sh

    autoreconf -fiv > /dev/null 2>&1

    for arch in i686 x86_64
    do
        source cpath $arch
        echo "===> configure libogg ${arch}"
        ./configure --prefix=${WORK_DIR}/$arch  \
                    --build=${arch}-w64-mingw32 \
                    --host=${arch}-w64-mingw32  \
                    --disable-shared            \
                    --enable-static             \
                    CFLAGS="${BASE_CFLAGS}"     \
                    CPPFLAGS="${BASE_CPPFLAGS}" \
                    CXXFLAGS="${BASE_CXXFLAGS}" \
                    LDFLAGS="${BASE_LDFLAGS}"   \
        > ${LOGS_DIR}/ogg_config_${arch}.log 2>&1 || exit 1

        make clean > /dev/null 2>&1
        echo "===> make libogg ${arch}"
        make -j5 -O > ${LOGS_DIR}/ogg_make_${arch}.log 2>&1 || exit 1
        echo "===> install libogg ${arch}"
        make install-strip > ${LOGS_DIR}/ogg_install_${arch}.log 2>&1 || exit 1
        make distclean > /dev/null 2>&1
    done

    return 0
}

# FLAC
build_flac() {
    clear; echo "Build flac git-master"

    if [ ! -d ${WORK_DIR}/flac ] ; then
        cd $WORK_DIR
        git clone git://git.xiph.org/flac.git
    fi
    cd ${WORK_DIR}/flac

    git clean -fdx > /dev/null 2>&1
    git reset --hard > /dev/null 2>&1
    git pull > /dev/null 2>&1
    git_hash > ${LOGS_DIR}/flac.hash
    git_rev >> ${LOGS_DIR}/flac.hash

    cp -fa /usr/share/gettext/config.rpath ${WORK_DIR}/flac
    autoreconf -fiv > /dev/null 2>&1

    for arch in i686 x86_64
    do
        if [ "$arch" == "i686" ] ; then
            local _LAA=" -Wl,--large-address-aware"
        else
            local _LAA=""
        fi

        source cpath $arch
        echo "===> configure flac ${arch}"
        ./configure --prefix=${WORK_DIR}/$arch        \
                    --build=${arch}-w64-mingw32       \
                    --host=${arch}-w64-mingw32        \
                    --disable-shared                  \
                    --enable-static                   \
                    --enable-sse                      \
                    --disable-xmms-plugin             \
                    --disable-cpplibs                 \
                    --disable-rpath                   \
                    --with-ogg=${WORK_DIR}/$arch      \
                    CFLAGS="${BASE_CFLAGS}"           \
                    CPPFLAGS="${BASE_CPPFLAGS}"       \
                    CXXFLAGS="${BASE_CXXFLAGS}"       \
                    LDFLAGS="${BASE_LDFLAGS} ${_LAA}" \
        > ${LOGS_DIR}/flac_config_${arch}.log 2>&1 || exit 1

        make clean > /dev/null 2>&1
        echo "===> make flac ${arch}"
        make -j5 -O > ${LOGS_DIR}/flac_make_${arch}.log 2>&1 || exit 1
        echo "===> install flac ${arch}"
        make install-strip > ${LOGS_DIR}/flac_install_${arch}.log 2>&1 || exit 1
        make distclean > /dev/null 2>&1
    done

    return 0
}

make_package() {
    if [ ! -d ${WORK_DIR}/flac ] ; then
        cd $WORK_DIR
        git clone git://git.xiph.org/flac.git
    fi
    cd ${WORK_DIR}/flac

    DEST_DIR=/usr/local/FLAC/flac_`git describe`
    if [[ ! -d ${DEST_DIR}/{win32,x64} ]] ; then
        mkdir -p ${DEST_DIR}/{win32,x64}
    fi

    clear; echo "making package..."
    cp -fa ${WORK_DIR}/i686/bin/*.exe ${DEST_DIR}/win32
    cp -fa ${WORK_DIR}/x86_64/bin/*.exe ${DEST_DIR}/x64
    cp -fa ${WORK_DIR}/flac/COPYING.GPL $DEST_DIR
    cp -fa ${DEST_DIR}/x64/* /usr/local/FLAC
    cp -fa ${DEST_DIR}/x64/* /d/encode/tools

    return 0
}

build_libogg
build_flac
make_package

clear; echo "Everything has been successfully completed!"

