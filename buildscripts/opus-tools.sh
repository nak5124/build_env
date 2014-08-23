#!/usr/bin/env bash


declare all_build=false

for opt in "$@"
do
    case "${opt}" in
        all)
            all_build=true
            ;;
    esac
done

declare -r PATCHES_DIR=${HOME}/patches/opus-tools
declare -r LOGS_DIR=${HOME}/logs/opus-tools
if [ ! -d $LOGS_DIR ] ; then
    mkdir -p $LOGS_DIR
fi

# libopus
function build_libopus() {
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

    autoreconf -fi > /dev/null 2>&1

    patch -p1 < ${PATCHES_DIR}/version.patch > ${LOGS_DIR}/opus_patch.log 2>&1 || exit 1

    for arch in i686 x86_64
    do
        if [ "${arch}" = "i686" ] ; then
            local OPPREFIX=/mingw32/local
        else
            local OPPREFIX=/mingw64/local
        fi

        source cpath $arch
        printf "===> configure libopus %s\n" $arch
        ./configure --prefix=$OPPREFIX           \
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
        printf "===> making libopus %s\n" $arch
        make -j9 -O > ${LOGS_DIR}/opus_make_${arch}.log 2>&1 || exit 1
        echo "done"

        printf "===> installing libopus %s\n" $arch
        make install-strip > ${LOGS_DIR}/opus_install_${arch}.log 2>&1 || exit 1
        echo "done"
        make distclean > /dev/null 2>&1
    done

    return 0
}

# opus-tools
function build_tools() {
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

    patch -p1 < ${PATCHES_DIR}/version_tools.patch > ${LOGS_DIR}/tools_patch.log 2>&1 || exit 1

    for arch in i686 x86_64
    do
        if [ "${arch}" = "i686" ] ; then
            local OPPREFIX=/mingw32/local
        else
            local OPPREFIX=/mingw64/local
        fi

        source cpath $arch
        printf "===> configure opus-tools %s\n" $arch
        PKG_CONFIG_PATH=${OPPREFIX}/lib/pkgconfig    \
        ./configure --prefix=$OPPREFIX               \
                    --build=${arch}-w64-mingw32      \
                    --host=${arch}-w64-mingw32       \
                    --disable-shared --enable-static \
                    --enable-sse                     \
                    CFLAGS="${BASE_CFLAGS}"          \
                    CPPFLAGS="${BASE_CPPFLAGS}"      \
                    CXXFLAGS="${BASE_CXXFLAGS}"      \
                    LDFLAGS="${BASE_LDFLAGS}"        \
            > ${LOGS_DIR}/tools_config_${arch}.log 2>&1 || exit 1
        echo "done"

        make clean > /dev/null 2>&1
        printf "===> making opus-tools %s\n" $arch
        make -j9 -O > ${LOGS_DIR}/tools_make_${arch}.log 2>&1 || exit 1
        echo "done"

        printf "===> installing opus-tools %s\n" $arch
        make install-strip > ${LOGS_DIR}/tools_install_${arch}.log 2>&1 || exit 1
        echo "done"
        make distclean > /dev/null 2>&1
    done

    return 0
}

function make_package() {
    cd ${HOME}/OSS/xiph/opus-tools

    local -r DEST_DIR=${HOME}/local/dist/opus-tools/opus-tools_$(git describe --long)

    if [[ ! -d ${DEST_DIR}/{win32,x64} ]] ; then
        mkdir -p ${DEST_DIR}/{win32,x64}
    fi

    clear; echo "making package..."
    cp -fa /mingw32/local/bin/opus*.exe ${DEST_DIR}/win32
    cp -fa /mingw64/local/bin/opus*.exe ${DEST_DIR}/x64
    cp -fa ${HOME}/OSS/xiph/opus-tools/COPYING $DEST_DIR
    cp -fa ${DEST_DIR}/x64/* ${DEST_DIR}/..
    cp -fa ${DEST_DIR}/x64/* /d/encode/tools
    echo "done"

    return 0
}

if $all_build ; then
    build_libopus
fi
build_tools
make_package

clear; echo "Everything has been successfully completed!"
