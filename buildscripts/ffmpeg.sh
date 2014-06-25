#!/usr/bin/env bash


PATCHES_DIR=${HOME}/patches/ffmpeg
LOGS_DIR=${HOME}/logs/ffmpeg
if [ ! -d $LOGS_DIR ] ; then
    mkdir -p $LOGS_DIR
fi

# libopencore-amr
build_libopencore_amr() {
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

    autoreconf -fiv > /dev/null 2>&1

    for arch in i686 x86_64
    do
        source cpath $arch
        echo "===> configure libopencore-amr ${arch}"
        ./configure --prefix=${HOME}/local/$arch \
                    --build=${arch}-w64-mingw32  \
                    --host=${arch}-w64-mingw32   \
                    --disable-shared             \
                    --enable-static              \
                    CFLAGS="${BASE_CFLAGS}"      \
                    CPPFLAGS="${BASE_CPPFLAGS}"  \
                    CXXFLAGS="${BASE_CXXFLAGS}"  \
                    LDFLAGS="${BASE_LDFLAGS}"    \
        > ${LOGS_DIR}/opencore-amr_config_${arch}.log 2>&1 || exit 1
        echo "done"

        make clean > /dev/null 2>&1
        echo "===> make libopencore-amr ${arch}"
        make -j5 -O > ${LOGS_DIR}/opencore-amr_make_${arch}.log 2>&1 || exit 1
        echo "done"

        echo "===> install libopencore-amr ${arch}"
        make install-strip > ${LOGS_DIR}/opencore-amr_install_${arch}.log \
            2>&1 || exit 1
        echo "done"
        make distclean > /dev/null 2>&1
    done

    return 0
}

# FFmpeg
patch_ffmpeg() {
    echo "===> patching... FFmpeg"

    local _N=34
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
        if [ "$arch" == "i686" ] ; then
            local _archopt="--arch=x86 --cpu=i686"
        else
            local _archopt="--arch=x86_64"
        fi
        local _EXCFLAGS="-I${HOME}/local/${arch}/include -fexcess-precision=fast"
        local _EXLDFLAGS="-L${HOME}/local/${arch}/lib"

        source cpath $arch
        echo "===> configure FFmpeg libraries ${arch}"
        PKG_CONFIG_PATH=${HOME}/local/${arch}/lib/pkgconfig \
        ./configure --prefix=${HOME}/local/$arch            \
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
        echo "===> make FFmpeg libraries ${arch}"
        make -j9 -O > ${LOGS_DIR}/ffmpeg_make_${arch}.log 2>&1 || exit 1
        echo "done"

        echo "===> install FFmpeg libraries ${arch}"
        make install > ${LOGS_DIR}/ffmpeg_install_${arch}.log 2>&1 || exit 1
        echo "done"
        make distclean > /dev/null 2>&1
    done

    return 0
}

build_libopencore_amr
build_ffmpeg

clear; echo "Everything has been successfully completed!"

