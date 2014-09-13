#!/usr/bin/env bash


declare all_build=false
declare -a target_arch=(
    "x86_64"
    "i686"
)

for opt in "$@"
do
    case "${opt}" in
        all )
            all_build=true
            ;;
        arch=* )
            optarg="${opt#*=}"
            target_arch=( $(echo $optarg | tr -s ',' ' ' ) )
            for arch in ${target_arch[@]}
            do
                if [ "${arch}" != "i686" -a "${arch}" != "x86_64" ] ; then
                    echo "${arch} is an unknown arch"
                    exit 1
                fi
            done
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

    for arch in ${target_arch[@]}
    do
        if [ "${arch}" = "i686" ] ; then
            local FLPREFIX=/mingw32/local
        else
            local FLPREFIX=/mingw64/local
        fi

        source cpath $arch
        printf "===> configure libogg %s\n" $arch
        ./configure --prefix=$FLPREFIX          \
                    --build=${arch}-w64-mingw32 \
                    --host=${arch}-w64-mingw32  \
                    --disable-silent-rules      \
                    --disable-shared            \
                    --enable-static             \
                    --with-gnu-ld               \
                    CPPFLAGS="${BASE_CPPFLAGS}" \
                    CFLAGS="${BASE_CFLAGS}"     \
                    LDFLAGS="${BASE_LDFLAGS}"   \
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

    for arch in ${target_arch[@]}
    do
        if [ "${arch}" = "i686" ] ; then
            local FLPREFIX=/mingw32/local
            local MINGW_PREFIX=/mingw32
        else
            local FLPREFIX=/mingw64/local
            local MINGW_PREFIX=/mingw64
        fi

        source cpath $arch
        printf "===> configure flac %s\n" $arch
        ./configure --prefix=$FLPREFIX                   \
                    --build=${arch}-w64-mingw32          \
                    --host=${arch}-w64-mingw32           \
                    --disable-silent-rules               \
                    --disable-shared                     \
                    --enable-static                      \
                    --disable-doxygen-docs               \
                    --disable-xmms-plugin                \
                    --disable-cpplibs                    \
                    --disable-rpath                      \
                    --with-gnu-ld                        \
                    --with-ogg=$FLPREFIX                 \
                    --with-libiconv-prefix=$MINGW_PREFIX \
                    CPPFLAGS="${BASE_CPPFLAGS}"          \
                    CFLAGS="${BASE_CFLAGS}"              \
                    CXXFLAGS="${BASE_CXXFLAGS}"          \
                    LDFLAGS="${BASE_LDFLAGS}"            \
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
    cp -fa /mingw32/local/bin/{flac,metaflac}.exe ${DEST_DIR}/win32
    cp -fa /mingw64/local/bin/{flac,metaflac}.exe ${DEST_DIR}/x64
    cp -fa ${HOME}/OSS/xiph/flac/COPYING.GPL $DEST_DIR
    cp -fa ${DEST_DIR}/x64/* ${DEST_DIR}/..
    cp -fa ${DEST_DIR}/x64/* /d/encode/tools
    echo "done"

    return 0
}

declare -r mintty_save=$MINTTY
unset MINTTY

if $all_build ; then
    build_libogg
fi
build_flac
make_package

MINTTY=$mintty_save
export MINTTY

clear; echo "Everything has been successfully completed!"
