#!/bin/bash


PATCHES_DIR=${HOME}/patches/ffmpeg
LOGS_DIR=${HOME}/log/x264_libs
if [ ! -d $LOGS_DIR ] ; then
    mkdir -p $LOGS_DIR
fi

# FFmpeg
patch_ffmpeg() {
    echo "===> patching... FFmpeg"

    local _N=67
    for i in `seq 1 ${_N}`
    do
        local num=$(printf "%04d" $i )
        if [ "$i" == 1 ] ; then
            patch -p1 < ${PATCHES_DIR}/${num}*.patch \
                > ${LOGS_DIR}/ffmpeg_patches.log 2>&1 || exit 1
        else
            patch -p1 < ${PATCHES_DIR}/${num}*.patch \
                >> ${LOGS_DIR}/ffmpeg_patches.log 2>&1 || exit 1
        fi
    done

    echo "done"

    return 0
}

build_ffmpeg() {
    clear; echo "Build libav{codec,format,util},libswscale git-master"

    if [ ! ${HOME}/FFmpeg ] ; then
        cd $HOME
        git clone git://source.ffmpeg.org/ffmpeg.git FFmpeg
    fi
    cd ${HOME}/FFmpeg

    git clean -fdx > /dev/null 2>&1
    git reset --hard > /dev/null 2>&1
    git pull > /dev/null 2>&1
    git_hash > ${LOGS_DIR}/ffmpeg.hash
    git_rev >> ${LOGS_DIR}/ffmpeg.hash

    patch_ffmpeg

    local _EXCFLAGS="-I/usr/x264_libs/include -fexcess-precision=fast"
    local _EXLDFLAGS="-L/usr/x264_libs/lib"

    source cpath x86_64
    echo "===> configure libav{codec,format,util},libswscal"
    PKG_CONFIG_PATH=/usr/x264_libs/lib/pkgconfig        \
    ./configure --prefix=/usr/x264_libs                 \
                --enable-gpl --enable-version3          \
                --disable-programs --disable-doc        \
                --disable-avdevice --disable-swresample \
                --disable-postproc --disable-avfilter   \
                --disable-avresample --disable-network  \
                --disable-encoders                      \
                --disable-hwaccels                      \
                --disable-muxers                        \
                --disable-demuxer=matroska_haali        \
                --disable-devices --disable-filters     \
                --disable-iconv                         \
                --arch=x86_64                           \
                --disable-debug                         \
                --extra-cflags="${_EXCFLAGS}"           \
                --extra-ldflags="${_EXLDFLAGS}"         \
    > ${LOGS_DIR}/ffmpeg_config.log 2>&1 || exit 1
    echo "done"

    make clean > /dev/null 2>&1
    echo "===> make libav{codec,format,util},libswscale"
    make -j9 -O > ${LOGS_DIR}/ffmpeg_make.log 2>&1 || exit 1
    echo "done"

    echo "===> install libav{codec,format,util},libswscale ${arch}"
    make install > ${LOGS_DIR}/ffmpeg_install.log 2>&1 || exit 1
    echo "done"
    make distclean > /dev/null 2>&1

    return 0
}

# L-SMASH
build_liblsmash() {
    clear; echo "Build liblsmash git-master"

    if [ ! -d ${HOME}/L-SMASH ] ; then
        cd $HOME
        git clone https://github.com/l-smash/l-smash.git L-SMASH
    fi
    cd ${HOME}/L-SMASH

    git clean -fdx > /dev/null 2>&1
    git reset --hard > /dev/null 2>&1
    git pull > /dev/null 2>&1
    git_hash > ${LOGS_DIR}/lsmash.hash
    git_rev >> ${LOGS_DIR}/lsmash.hash

    source cpath x86_64
    echo "===> configure liblsmash"
    ./configure --prefix=/usr/x264_libs \
        > ${LOGS_DIR}/lsmash_config.log 2>&1 || exit 1
    echo "done"

    make clean > /dev/null 2>&1
    echo "===> make liblsmash"
    make lib -j5 -O > ${LOGS_DIR}/lsmash_make.log 2>&1 || exit 1
    echo "done"

    echo "===> install liblsmash"
    make install-lib > ${LOGS_DIR}/lsmash_install.log 2>&1 || exit 1
    echo "done"
    make distclean > /dev/null 2>&1

    return 0
}

build_ffmpeg
build_liblsmash

clear; echo "Everything has been successfully completed!"

