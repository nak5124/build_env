#!/usr/bin/env bash


declare -r PATCHES_DIR=${HOME}/patches/lsw
declare -r LOGS_DIR=${HOME}/logs/lsw
if [ ! -d $LOGS_DIR ]; then
    mkdir -p $LOGS_DIR
fi

# common
function build_LSW_common() {
    clear; echo "Build L-SMASH Works"

    if [ ! -d ${HOME}/OSS/lsw ]; then
        cd ${HOME}/OSS
        git clone git://github.com/VFR-maniac/L-SMASH-Works.git lsw
    fi
    cd ${HOME}/OSS/lsw

    git clean -fxd > /dev/null 2>&1
    git reset --hard > /dev/null 2>&1
    git pull > /dev/null 2>&1
    git_hash > ${LOGS_DIR}/lsw.hash
    git_rev >> ${LOGS_DIR}/lsw.hash

    patch -p1 -i ${PATCHES_DIR}/0001-vslsmashsource-Don-t-print-any-info-from-libav-ffmpe.patch \
        > ${LOGS_DIR}/lsw_patches.log 2>&1 || exit 1
    patch -p1 -i ${PATCHES_DIR}/0002-lsmashsource.diff >> ${LOGS_DIR}/lsw_patches.log 2>&1 || exit 1
    patch -p1 -i ${PATCHES_DIR}/0003-lsmash-initialize-codec-id-here.patch >> ${LOGS_DIR}/lsw_patches.log 2>&1 || exit 1

    cp -fa ${PATCHES_DIR}/build_2013.bat ./AviSynth
    cp -fa ${PATCHES_DIR}/build_2013_x64.bat ./AviSynth

    return 0
}

# AviUtl
function build_LSW_aviutl() {
    cd ${HOME}/OSS/lsw/AviUtl

    source cpath i686

    echo "===> Configuring LSW AviUtl..."
    ./configure                                          \
        --libdir=/mingw32/local/lib                      \
        --includedir=/mingw32/local/include              \
        --extra-cflags="${BASE_CFLAGS} ${BASE_CPPFLAGS}" \
        --extra-ldflags="${BASE_CFLAGS} ${BASE_LDFLAGS}" \
    > ${LOGS_DIR}/lsw_config_aviutl.log 2>&1 || exit 1
    echo "done"

    make clean > /dev/null 2>&1
    echo "===> Making LSW AviUtl..."
    make -j9 -O > ${LOGS_DIR}/lsw_make_aviutl.log 2>&1 || exit 1
    echo "done"

    echo "===> Copying LSW AviUtl..."
    cp -fa ./*.aui ./*.auf ./*.auc /d/encode/aviutl/Plugins
    ln -fs /mingw32/bin/libgcc_s_dw2-1.dll /d/encode/aviutl
    ln -fs /mingw32/bin/libwinpthread-1.dll /d/encode/aviutl
    ln -fs /mingw32/bin/libssp-0.dll /d/encode/aviutl
    ln -fs /mingw32/bin/libbz2-1.dll /d/encode/aviutl
    ln -fs /mingw32/bin/libz-1.dll /d/encode/aviutl
    ln -fs /mingw32/bin/libiconv-2.dll /d/encode/aviutl
    ln -fs /mingw32/local/bin/liblsmash-2.dll /d/encode/aviutl
    ln -fs /mingw32/local/bin/avcodec-56.dll /d/encode/aviutl
    ln -fs /mingw32/local/bin/avformat-56.dll /d/encode/aviutl
    ln -fs /mingw32/local/bin/avresample-2.dll /d/encode/aviutl
    ln -fs /mingw32/local/bin/avutil-54.dll /d/encode/aviutl
    ln -fs /mingw32/local/bin/swscale-3.dll /d/encode/aviutl
    ln -fs /mingw32/local/bin/libopencore-amrnb-0.dll /d/encode/aviutl
    ln -fs /mingw32/local/bin/libopencore-amrwb-0.dll /d/encode/aviutl
    ln -fs /mingw32/local/bin/libopenmj2-7.dll /d/encode/aviutl
    ln -fs /mingw32/local/bin/libopus-0.dll /d/encode/aviutl
    ln -fs /mingw32/local/bin/libspeex-1.dll /d/encode/aviutl
    ln -fs /mingw32/local/bin/libvorbis-0.dll /d/encode/aviutl
    ln -fs /mingw32/local/bin/libvorbisenc-2.dll /d/encode/aviutl
    ln -fs /mingw32/local/bin/libogg-0.dll /d/encode/aviutl
    ln -fs /mingw32/local/bin/libvpx-1.dll /d/encode/aviutl
    ln -fs /mingw32/local/bin/liblzma-5.dll /d/encode/aviutl
    echo "done"

    return 0
}

# AviSynth
function build_LSW_avisynth() {
    cd ${HOME}/OSS/lsw/AviSynth

    echo "===> build LSW AviSynth win32"
    cmd /c 'build_2013.bat' > ${LOGS_DIR}/lsw_avisynth_i686.log 2>&1 || exit 1
    echo "done"
    echo "===> build LSW AviSynth x64"
    cmd /c 'build_2013_x64.bat' > ${LOGS_DIR}/lsw_avisynth_x86_64.log 2>&1 || exit 1
    echo "done"

    echo "===> Copying LSW AviSynth..."
    cp -fa ./Release/LSMASHSource.dll /c/AviSynth+/plugins
    cp -fa ./x64/Release/LSMASHSource.dll /c/AviSynth+/plugins64
    ln -fs /mingw32/bin/libgcc_s_dw2-1.dll /c/AviSynth+/plugins
    ln -fs /mingw32/bin/libwinpthread-1.dll /c/AviSynth+/plugins
    ln -fs /mingw32/bin/libssp-0.dll /c/AviSynth+/plugins
    ln -fs /mingw32/bin/libbz2-1.dll /c/AviSynth+/plugins
    ln -fs /mingw32/bin/libz-1.dll /c/AviSynth+/plugins
    ln -fs /mingw32/bin/libiconv-2.dll /c/AviSynth+/plugins
    ln -fs /mingw32/local/bin/liblsmash-2.dll /c/AviSynth+/plugins
    ln -fs /mingw32/local/bin/avcodec-56.dll /c/AviSynth+/plugins
    ln -fs /mingw32/local/bin/avformat-56.dll /c/AviSynth+/plugins
    ln -fs /mingw32/local/bin/avresample-2.dll /c/AviSynth+/plugins
    ln -fs /mingw32/local/bin/avutil-54.dll /c/AviSynth+/plugins
    ln -fs /mingw32/local/bin/swscale-3.dll /c/AviSynth+/plugins
    ln -fs /mingw32/local/bin/libopencore-amrnb-0.dll /c/AviSynth+/plugins
    ln -fs /mingw32/local/bin/libopencore-amrwb-0.dll /c/AviSynth+/plugins
    ln -fs /mingw32/local/bin/libopenmj2-7.dll /c/AviSynth+/plugins
    ln -fs /mingw32/local/bin/libopus-0.dll /c/AviSynth+/plugins
    ln -fs /mingw32/local/bin/libspeex-1.dll /c/AviSynth+/plugins
    ln -fs /mingw32/local/bin/libvorbis-0.dll /c/AviSynth+/plugins
    ln -fs /mingw32/local/bin/libvorbisenc-2.dll /c/AviSynth+/plugins
    ln -fs /mingw32/local/bin/libogg-0.dll /c/AviSynth+/plugins
    ln -fs /mingw32/local/bin/libvpx-1.dll /c/AviSynth+/plugins
    ln -fs /mingw32/local/bin/liblzma-5.dll /c/AviSynth+/plugins
    ln -fs /mingw64/bin/libwinpthread-1.dll /c/AviSynth+/plugins64
    ln -fs /mingw64/bin/libssp-0.dll /c/AviSynth+/plugins64
    ln -fs /mingw64/bin/libbz2-1.dll /c/AviSynth+/plugins64
    ln -fs /mingw64/bin/libz-1.dll /c/AviSynth+/plugins64
    ln -fs /mingw64/bin/libiconv-2.dll /c/AviSynth+/plugins64
    ln -fs /mingw64/local/bin/liblsmash-2.dll /c/AviSynth+/plugins64
    ln -fs /mingw64/local/bin/avcodec-56.dll /c/AviSynth+/plugins64
    ln -fs /mingw64/local/bin/avformat-56.dll /c/AviSynth+/plugins64
    ln -fs /mingw64/local/bin/avresample-2.dll /c/AviSynth+/plugins64
    ln -fs /mingw64/local/bin/avutil-54.dll /c/AviSynth+/plugins64
    ln -fs /mingw64/local/bin/swscale-3.dll /c/AviSynth+/plugins64
    ln -fs /mingw64/local/bin/libopencore-amrnb-0.dll /c/AviSynth+/plugins64
    ln -fs /mingw64/local/bin/libopencore-amrwb-0.dll /c/AviSynth+/plugins64
    ln -fs /mingw64/local/bin/libopenmj2-7.dll /c/AviSynth+/plugins64
    ln -fs /mingw64/local/bin/libopus-0.dll /c/AviSynth+/plugins64
    ln -fs /mingw64/local/bin/libspeex-1.dll /c/AviSynth+/plugins64
    ln -fs /mingw64/local/bin/libvorbis-0.dll /c/AviSynth+/plugins64
    ln -fs /mingw64/local/bin/libvorbisenc-2.dll /c/AviSynth+/plugins64
    ln -fs /mingw64/local/bin/libogg-0.dll /c/AviSynth+/plugins64
    ln -fs /mingw64/local/bin/libvpx-1.dll /c/AviSynth+/plugins64
    ln -fs /mingw64/local/bin/liblzma-5.dll /c/AviSynth+/plugins64
    echo "done"

    return 0
}

# VapourSynth
function build_LSW_vapoursynth() {
    cd ${HOME}/OSS/lsw/VapourSynth

    local _arch
    for _arch in i686 x86_64
    do
        source cpath $_arch

        if [ "${_arch}" = "i686" ]; then
            local _LSWPREFIX=/mingw32/local
        else
            local _LSWPREFIX=/mingw64/local
        fi

        printf "===> Configuring LSW VapourSynth %s\n" $_arch
        ./configure                                          \
            --libdir=${_LSWPREFIX}/lib                       \
            --includedir=${_LSWPREFIX}/include               \
            --target-os=mingw32                              \
            --extra-cflags="${BASE_CFLAGS} ${BASE_CPPFLAGS}" \
            --extra-ldflags="${BASE_CFLAGS} ${BASE_LDFLAGS}" \
        > ${LOGS_DIR}/lsw_config_VS_${_arch}.log 2>&1 || exit 1
        echo "done"

        make clean > /dev/null 2>&1
        printf "===> Making LSW VapourSynth %s...\n" $_arch
        make -j9 -O > ${LOGS_DIR}/lsw_make_VS_${_arch}.log 2>&1 || exit 1
        echo "done"

        printf "===> Copying LSW VapourSynth %s...\n" $_arch
        if [ "${_arch}" = "i686" ]; then
            cp -fa ./vslsmashsource.dll /c/VapourSynth/plugins32
            ln -fs /mingw32/bin/libgcc_s_dw2-1.dll /c/VapourSynth/plugins32
            ln -fs /mingw32/bin/libwinpthread-1.dll /c/VapourSynth/plugins32
            ln -fs /mingw32/bin/libssp-0.dll /c/VapourSynth/plugins32
            ln -fs /mingw32/bin/libbz2-1.dll /c/VapourSynth/plugins32
            ln -fs /mingw32/bin/libz-1.dll /c/VapourSynth/plugins32
            ln -fs /mingw32/bin/libiconv-2.dll /c/VapourSynth/plugins32
            ln -fs /mingw32/local/bin/liblsmash-2.dll /c/VapourSynth/plugins32
            ln -fs /mingw32/local/bin/avcodec-56.dll /c/VapourSynth/plugins32
            ln -fs /mingw32/local/bin/avformat-56.dll /c/VapourSynth/plugins32
            ln -fs /mingw32/local/bin/avresample-2.dll /c/VapourSynth/plugins32
            ln -fs /mingw32/local/bin/avutil-54.dll /c/VapourSynth/plugins32
            ln -fs /mingw32/local/bin/swscale-3.dll /c/VapourSynth/plugins32
            ln -fs /mingw32/local/bin/libopencore-amrnb-0.dll /c/VapourSynth/plugins32
            ln -fs /mingw32/local/bin/libopencore-amrwb-0.dll /c/VapourSynth/plugins32
            ln -fs /mingw32/local/bin/libopenmj2-7.dll /c/VapourSynth/plugins32
            ln -fs /mingw32/local/bin/libopus-0.dll /c/VapourSynth/plugins32
            ln -fs /mingw32/local/bin/libspeex-1.dll /c/VapourSynth/plugins32
            ln -fs /mingw32/local/bin/libvorbis-0.dll /c/VapourSynth/plugins32
            ln -fs /mingw32/local/bin/libvorbisenc-2.dll /c/VapourSynth/plugins32
            ln -fs /mingw32/local/bin/libogg-0.dll /c/VapourSynth/plugins32
            ln -fs /mingw32/local/bin/libvpx-1.dll /c/VapourSynth/plugins32
            ln -fs /mingw32/local/bin/liblzma-5.dll /c/VapourSynth/plugins32
        else
            cp -fa ./vslsmashsource.dll  /c/VapourSynth/plugins64
            ln -fs /mingw64/bin/libwinpthread-1.dll /c/VapourSynth/plugins64
            ln -fs /mingw64/bin/libssp-0.dll /c/VapourSynth/plugins64
            ln -fs /mingw64/bin/libbz2-1.dll /c/VapourSynth/plugins64
            ln -fs /mingw64/bin/libz-1.dll /c/VapourSynth/plugins64
            ln -fs /mingw64/bin/libiconv-2.dll /c/VapourSynth/plugins64
            ln -fs /mingw64/local/bin/liblsmash-2.dll /c/VapourSynth/plugins64
            ln -fs /mingw64/local/bin/avcodec-56.dll /c/VapourSynth/plugins64
            ln -fs /mingw64/local/bin/avformat-56.dll /c/VapourSynth/plugins64
            ln -fs /mingw64/local/bin/avresample-2.dll /c/VapourSynth/plugins64
            ln -fs /mingw64/local/bin/avutil-54.dll /c/VapourSynth/plugins64
            ln -fs /mingw64/local/bin/swscale-3.dll /c/VapourSynth/plugins64
            ln -fs /mingw64/local/bin/libopencore-amrnb-0.dll /c/VapourSynth/plugins64
            ln -fs /mingw64/local/bin/libopencore-amrwb-0.dll /c/VapourSynth/plugins64
            ln -fs /mingw64/local/bin/libopenmj2-7.dll /c/VapourSynth/plugins64
            ln -fs /mingw64/local/bin/libopus-0.dll /c/VapourSynth/plugins64
            ln -fs /mingw64/local/bin/libspeex-1.dll /c/VapourSynth/plugins64
            ln -fs /mingw64/local/bin/libvorbis-0.dll /c/VapourSynth/plugins64
            ln -fs /mingw64/local/bin/libvorbisenc-2.dll /c/VapourSynth/plugins64
            ln -fs /mingw64/local/bin/libogg-0.dll /c/VapourSynth/plugins64
            ln -fs /mingw64/local/bin/libvpx-1.dll /c/VapourSynth/plugins64
            ln -fs /mingw64/local/bin/liblzma-5.dll /c/VapourSynth/plugins64
        fi
        echo "done"

        make distclean > /dev/null 2>&1
    done

    return 0
}

declare -r mintty_save=$MINTTY
unset MINTTY

build_LSW_common
build_LSW_aviutl
build_LSW_avisynth
build_LSW_vapoursynth

MINTTY=$mintty_save
export MINTTY

clear; echo "Everything has been successfully completed!"
