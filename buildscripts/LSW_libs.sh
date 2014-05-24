#!/bin/bash


PATCHES_DIR=${HOME}/patches/ffmpeg
LOGS_DIR=${HOME}/log/LSW_libs
if [ ! -d $LOGS_DIR ] ; then
    mkdir -p $LOGS_DIR
fi

# libopencore-amr
build_libopencore_amr() {
    clear; echo "Build libopencore-amr git-master"

    if [ ! -d ${HOME}/FFmpeg_libs/opencore-amr ] ; then
        cd ${HOME}/FFmpeg_libs
        git clone git://opencore-amr.git.sourceforge.net/gitroot/opencore-amr/opencore-amr
    fi
    cd ${HOME}/FFmpeg_libs/opencore-amr

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
        ./configure --prefix=/usr/LSW_libs/$arch \
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

    for arch in i686 x86_64
    do
        source cpath $arch
        echo "===> configure libopus ${arch}"
        ./configure --prefix=/usr/LSW_libs/$arch \
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
        make install > ${LOGS_DIR}/opus_install_${arch}.log 2>&1 || exit 1
        echo "done"
        make distclean > /dev/null 2>&1
    done

    return 0
}

# FFmpeg
patch_ffmpeg() {
    echo "===> patching... FFmpeg"

    local _N=33
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
    clear; echo "Build libav{codec,format,resample,util},libswscale git-master"

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

    for arch in i686 x86_64
    do
        if [ "$arch" == "i686" ] ; then
            local _archopt="--arch=x86 --cpu=i686"
        else
            local _archopt="--arch=x86_64"
        fi
        local _EXCFLAGS="-I/usr/LSW_libs/${arch}/include -fexcess-precision=fast"
        local _EXLDFLAGS="-L/usr/LSW_libs/${arch}/lib"

        source cpath $arch
        echo "===> configure libav{codec,format,resample,util},libswscale ${arch}"
        PKG_CONFIG_PATH=/usr/LSW_libs/${arch}/lib/pkgconfig \
        ./configure --prefix=/usr/LSW_libs/$arch            \
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
        echo "===> make libav{codec,format,resample,util},libswscale ${arch}"
        make -j9 -O > ${LOGS_DIR}/ffmpeg_make_${arch}.log 2>&1 || exit 1
        echo "done"

        echo "===> install libav{codec,format,resample,util},libswscale ${arch}"
        make install > ${LOGS_DIR}/ffmpeg_install_${arch}.log 2>&1 || exit 1
        echo "done"
        make distclean > /dev/null 2>&1
    done

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

    for arch in i686 x86_64
    do
        source cpath $arch
        echo "===> configure liblsmash ${arch}"
        ./configure --prefix=/usr/LSW_libs/$arch \
        > ${LOGS_DIR}/lsmash_config_${arch}.log 2>&1 || exit 1
        echo "done"

        make clean > /dev/null 2>&1
        echo "===> make liblsmash ${arch}"
        make lib -j5 -O > ${LOGS_DIR}/lsmash_make_${arch}.log 2>&1 || exit 1
        echo "done"

        echo "===> install liblsmash ${arch}"
        make install-lib > ${LOGS_DIR}/lsmash_install_${arch}.log 2>&1 || exit 1
        echo "done"
        make distclean > /dev/null 2>&1
    done

    return 0
}

#build_libopencore_amr
#build_libopus
build_ffmpeg
build_liblsmash

clear; echo "Everything has been successfully completed!"

