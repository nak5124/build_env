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

declare -r PATCHES_DIR=${HOME}/patches/ffmpeg
declare -r LOGS_DIR=${HOME}/logs/ffmpeg
if [ ! -d $LOGS_DIR ] ; then
    mkdir -p $LOGS_DIR
fi

# libopencore-amr
function build_libopencore_amr() {
    clear; echo "Build libopencore-amr git-master"

    if [ ! -d ${HOME}/OSS/opencore-amr ] ; then
        cd ${HOME}/OSS
        git clone git://opencore-amr.git.sourceforge.net/gitroot/opencore-amr/opencore-amr
    fi
    cd ${HOME}/OSS/opencore-amr

    git clean -fdx > /dev/null 2>&1
    git reset --hard > /dev/null 2>&1
    git pull > /dev/null 2>&1
    git_hash > ${LOGS_DIR}/opencore-amr.hash
    git_rev >> ${LOGS_DIR}/opencore-amr.hash

    autoreconf -fi > /dev/null 2>&1

    for arch in i686 x86_64
    do
        if [ "${arch}" = "i686" ] ; then
            local FFPREFIX=/mingw32
        else
            local FFPREFIX=/mingw64
        fi

        source cpath $arch
        printf "===> configure libopencore-amr %s\n" $arch
        ./configure --prefix=$FFPREFIX          \
                    --build=${arch}-w64-mingw32 \
                    --host=${arch}-w64-mingw32  \
                    --disable-shared            \
                    --enable-static             \
                    CFLAGS="${BASE_CFLAGS}"     \
                    CPPFLAGS="${BASE_CPPFLAGS}" \
                    CXXFLAGS="${BASE_CXXFLAGS}" \
                    LDFLAGS="${BASE_LDFLAGS}"   \
            > ${LOGS_DIR}/opencore-amr_config_${arch}.log 2>&1 || exit 1
        echo "done"

        make clean > /dev/null 2>&1
        printf "===> making libopencore-amr %s\n"  $arch
        make -j9 -O > ${LOGS_DIR}/opencore-amr_make_${arch}.log 2>&1 || exit 1
        echo "done"

        printf "===> installing libopencore-amr %s\n" $arch
        make install-strip > ${LOGS_DIR}/opencore-amr_install_${arch}.log 2>&1 || exit 1
        echo "done"
        make distclean > /dev/null 2>&1
    done

    return 0
}

# FFmpeg
function patch_ffmpeg() {
    echo "===> patching... FFmpeg"

    local _N=34
    for i in `seq 1 ${_N}`
    do
        local num=$( printf "%04d" $i )
        if [ "${i}" = 1 ] ; then
            patch -p1 < ${PATCHES_DIR}/${num}*.patch > ${LOGS_DIR}/ffmpeg_patches.log 2>&1 || exit 1
        else
            patch -p1 < ${PATCHES_DIR}/${num}*.patch >> ${LOGS_DIR}/ffmpeg_patches.log 2>&1 || exit 1
        fi
    done

    echo "done"

    return 0
}

function build_ffmpeg() {
    clear; echo "Build FFmpeg libraries git-master"

    if [ ! ${HOME}/OSS/videolan/ffmpeg ] ; then
        cd ${HOME}/OSS/videolan
        git clone git://source.ffmpeg.org/ffmpeg.git
    fi
    cd ${HOME}/OSS/videolan/ffmpeg

    git clean -fdx > /dev/null 2>&1
    git reset --hard > /dev/null 2>&1
    git pull > /dev/null 2>&1
    git_hash > ${LOGS_DIR}/ffmpeg.hash
    git_rev >> ${LOGS_DIR}/ffmpeg.hash

    patch_ffmpeg

    for arch in i686 x86_64
    do
        if [ "${arch}" = "i686" ] ; then
            local _archopt="--arch=x86 --cpu=i686"
            local FFPREFIX=/mingw32
        else
            local _archopt="--arch=x86_64"
            local FFPREFIX=/mingw64
        fi
        local _EXCFLAGS="-I${FFPREFIX}/include -fexcess-precision=fast"
        local _EXLDFLAGS="-L${FFPREFIX}/lib"

        source cpath $arch
        printf "===> configure FFmpeg libraries %s\n" $arch
        PKG_CONFIG_PATH=${FFPREFIX}/lib/pkgconfig           \
        ./configure --prefix=$FFPREFIX                      \
                    --enable-version3                       \
                    --disable-programs --disable-doc        \
                    --disable-avdevice --disable-swresample \
                    --disable-postproc --disable-avfilter   \
                    --enable-avresample                     \
                    --disable-network                       \
                    --disable-encoders                      \
                    --disable-hwaccels                      \
                    --disable-muxers                        \
                    --disable-devices                       \
                    --disable-filters                       \
                    --disable-iconv                         \
                    --enable-libopencore-amrnb              \
                    --disable-decoder=amrnb                 \
                    --enable-libopencore-amrwb              \
                    --disable-decoder=amrwb                 \
                    --enable-libopus                        \
                    --disable-decoder=opus                  \
                    --disable-parser=opus                   \
                    ${_archopt}                             \
                    --disable-debug                         \
                    --extra-cflags="${_EXCFLAGS}"           \
                    --extra-ldflags="${_EXLDFLAGS}"         \
            > ${LOGS_DIR}/ffmpeg_config_${arch}.log 2>&1 || exit 1
        echo "done"

        make clean > /dev/null 2>&1
        printf "===> making FFmpeg libraries %s\n" $arch
        make -j9 -O > ${LOGS_DIR}/ffmpeg_make_${arch}.log 2>&1 || exit 1
        echo "done"

        printf "===> installing FFmpeg libraries %s\n" $arch
        make install > ${LOGS_DIR}/ffmpeg_install_${arch}.log 2>&1 || exit 1
        echo "done"
        make distclean > /dev/null 2>&1
    done

    return 0
}

if $all_build ; then
    build_libopencore_amr
fi
build_ffmpeg

clear; echo "Everything has been successfully completed!"
