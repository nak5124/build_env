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

declare -r LOGS_DIR=${HOME}/logs/flac
if [ ! -d $LOGS_DIR ] ; then
    mkdir -p $LOGS_DIR
fi

# libogg
function build_libogg() {
    clear; echo "Build libogg git-master"

    if [ ! -d ${HOME}/OSS/xiph/ogg ] ; then
        cd ${HOME}/OSS/xiph
        git clone git://git.xiph.org/mirrors/ogg.git
    fi
    cd ${HOME}/OSS/xiph/ogg

    git clean -fdx > /dev/null 2>&1
    git reset --hard > /dev/null 2>&1
    git pull > /dev/null 2>&1
    git_hash > ${LOGS_DIR}/ogg.hash
    git_rev >> ${LOGS_DIR}/ogg.hash

    autoreconf -fi > /dev/null 2>&1

    for arch in i686 x86_64
    do
        if [ "${arch}" = "i686" ] ; then
            local FLPREFIX=/mingw32
        else
            local FLPREFIX=/mingw64
        fi

        source cpath $arch
        printf "===> configure libogg %s\n" $arch
        ./configure --prefix=$FLPREFIX           \
                    --build=${arch}-w64-mingw32  \
                    --host=${arch}-w64-mingw32   \
                    --disable-shared             \
                    --enable-static              \
                    CFLAGS="${BASE_CFLAGS}"      \
                    CPPFLAGS="${BASE_CPPFLAGS}"  \
                    CXXFLAGS="${BASE_CXXFLAGS}"  \
                    LDFLAGS="${BASE_LDFLAGS}"    \
            > ${LOGS_DIR}/ogg_config_${arch}.log 2>&1 || exit 1
        echo "done"

        make clean > /dev/null 2>&1
        printf "===> making libogg %s\n" $arch
        make -j9 -O > ${LOGS_DIR}/ogg_make_${arch}.log 2>&1 || exit 1
        echo "done"

        printf "===> installing libogg %s\n" $arch
        make install-strip > ${LOGS_DIR}/ogg_install_${arch}.log 2>&1 || exit 1
        echo "done"
        make distclean > /dev/null 2>&1
    done

    return 0
}

# FLAC
function build_flac() {
    clear; echo "Build flac git-master"

    if [ ! -d ${HOME}/OSS/xiph/flac ] ; then
        cd ${HOME}/OSS/xiph
        git clone git://git.xiph.org/flac.git
    fi
    cd ${HOME}/OSS/xiph/flac

    git clean -fdx > /dev/null 2>&1
    git reset --hard > /dev/null 2>&1
    git pull > /dev/null 2>&1
    git_hash > ${LOGS_DIR}/flac.hash
    git_rev >> ${LOGS_DIR}/flac.hash

    cp -fa /usr/share/gettext/config.rpath .
    autoreconf -fi > /dev/null 2>&1

    for arch in i686 x86_64
    do
        if [ "${arch}" = "i686" ] ; then
            local FLPREFIX=/mingw32
            local _LAA=" -Wl,--large-address-aware"
        else
            local FLPREFIX=/mingw64
            local _LAA=""
        fi

        source cpath $arch
        printf "===> configure flac %s\n" $arch
        ./configure --prefix=$FLPREFIX                \
                    --build=${arch}-w64-mingw32       \
                    --host=${arch}-w64-mingw32        \
                    --disable-shared                  \
                    --enable-static                   \
                    --enable-sse                      \
                    --disable-xmms-plugin             \
                    --disable-cpplibs                 \
                    --disable-rpath                   \
                    --with-ogg=$FLPREFIX              \
                    CFLAGS="${BASE_CFLAGS}"           \
                    CPPFLAGS="${BASE_CPPFLAGS}"       \
                    CXXFLAGS="${BASE_CXXFLAGS}"       \
                    LDFLAGS="${BASE_LDFLAGS} ${_LAA}" \
            > ${LOGS_DIR}/flac_config_${arch}.log 2>&1 || exit 1
        echo "done"

        make clean > /dev/null 2>&1
        printf "===> making flac %s\n" $arch
        make -j9 -O > ${LOGS_DIR}/flac_make_${arch}.log 2>&1 || exit 1
        echo "done"

        printf "===> installing flac %s\n" $arch
        make install-strip > ${LOGS_DIR}/flac_install_${arch}.log 2>&1 || exit 1
        echo "done"
        make distclean > /dev/null 2>&1
    done

    return 0
}

function make_package() {
    cd ${HOME}/OSS/xiph/flac

    local -r DEST_DIR=${HOME}/local/dist/flac/flac_$(git describe)
    if [[ ! -d ${DEST_DIR}/{win32,x64} ]] ; then
        mkdir -p ${DEST_DIR}/{win32,x64}
    fi

    clear; echo "making package..."
    cp -fa /mingw32/bin/{flac,metaflac}.exe ${DEST_DIR}/win32
    cp -fa /mingw64/bin/{flac,metaflac}.exe ${DEST_DIR}/x64
    cp -fa ${HOME}/OSS/xiph/flac/COPYING.GPL $DEST_DIR
    cp -fa ${DEST_DIR}/x64/* ${DEST_DIR}/..
    cp -fa ${DEST_DIR}/x64/* /d/encode/tools
    echo "done"

    return 0
}

if $all_build ; then
    build_libogg
fi
build_flac
make_package

clear; echo "Everything has been successfully completed!"
