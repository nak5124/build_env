#!/usr/bin/env bash


declare -r PATCHES_DIR=${HOME}/patches/lsw
declare -r LOGS_DIR=${HOME}/logs/lsw
if [ ! -d $LOGS_DIR ] ; then
    mkdir -p $LOGS_DIR
fi

# common
function build_LSW_common() {
    clear; echo "Build L-SMASH Works"

    if [ ! -d ${HOME}/OSS/lsw ] ; then
        cd ${HOME}/OSS
        git clone git://github.com/VFR-maniac/L-SMASH-Works.git lsw
    fi
    cd ${HOME}/OSS/lsw

    git clean -fxd > /dev/null 2>&1
    git reset --hard > /dev/null 2>&1
    git pull > /dev/null 2>&1
    git_hash > ${LOGS_DIR}/lsw.hash
    git_rev >> ${LOGS_DIR}/lsw.hash

    patch -p1 < ${PATCHES_DIR}/0001-vslsmashsource-Don-t-print-any-info-from-libav-ffmpe.patch \
        > ${LOGS_DIR}/lsw_patches.log 2>&1 || exit 1
    patch -p1 < ${PATCHES_DIR}/0002-lsmashsource.diff >> ${LOGS_DIR}/lsw_patches.log 2>&1 || exit 1

    cp -fa ${PATCHES_DIR}/build_2013.bat ./AviSynth
    cp -fa ${PATCHES_DIR}/build_2013_x64.bat ./AviSynth

    readonly DEST_DIR=${HOME}/local/dist/lsw/L-SMASH-Works_r$(git_rev)-g$(git_hash)

    if [[ ! -d ${DEST_DIR}/{AviUtl,AviSynth/x64,VapourSynth/x64,legal_stuff/{FFmpeg,L-SMASH,L-SMASH-Works/{AviUtl,AviSynth,VapourSynth}}} ]] ; then
        mkdir -p ${DEST_DIR}/{AviUtl,AviSynth/x64,VapourSynth/x64,legal_stuff/{FFmpeg,L-SMASH,L-SMASH-Works/{AviUtl,AviSynth,VapourSynth}}}
    fi

    cp -fa ${HOME}/OSS/videolan/ffmpeg/COPYING.LGPLv3 ${DEST_DIR}/legal_stuff/FFmpeg
    cp -fa ${DEST_DIR}/../patches ${DEST_DIR}/legal_stuff/FFmpeg/patches
    cp -fa ${HOME}/OSS/l-smash/LICENSE ${DEST_DIR}/legal_stuff/L-SMASH

    git_log > ${DEST_DIR}/../log
    python2 ${DEST_DIR}/../commitloggenerator.py ${DEST_DIR}/../log ${DEST_DIR}/../ChangeLog
    cp -fa ${DEST_DIR}/../ChangeLog $DEST_DIR

    return 0
}

# AviUtl
function build_LSW_aviutl() {
    cd ${HOME}/OSS/lsw/AviUtl

    source cpath i686
    echo "===> configure LSW AviUtl"
    ./configure --prefix=/mingw32/local        \
                --extra-ldflags=-static-libgcc \
    > ${LOGS_DIR}/lsw_config_aviutl.log 2>&1 || exit 1
    echo "done"

    make clean > /dev/null 2>&1
    echo "===> make LSW AviUtl"
    make -j9 -O > ${LOGS_DIR}/lsw_make_aviutl.log 2>&1 || exit 1
    echo "done"

    echo "===> copy LSW AviUtl"
    cp -fa ./*.aui ./*.auf ./*.auc ${DEST_DIR}/AviUtl
    cp -fa ${DEST_DIR}/AviUtl/* ${DEST_DIR}/..
    cp -fa ${DEST_DIR}/AviUtl/* /d/encode/aviutl/Plugins
    cp -fa ./README* ${DEST_DIR}/AviUtl
    cp -fa ./LICENSE ${DEST_DIR}/legal_stuff/L-SMASH-Works/AviUtl
    ln -fs /mingw32/bin/libbz2-1.dll /d/encode/aviutl
    ln -fs /mingw32/bin/libz-1.dll /d/encode/aviutl
    ln -fs /mingw32/bin/libiconv-2.dll /d/encode/aviutl
    ln -fs /mingw32/local/bin/liblsmash-1.dll /d/encode/aviutl
    ln -fs /mingw32/local/bin/avcodec-56.dll /d/encode/aviutl
    ln -fs /mingw32/local/bin/avformat-56.dll /d/encode/aviutl
    ln -fs /mingw32/local/bin/avresample-2.dll /d/encode/aviutl
    ln -fs /mingw32/local/bin/avutil-54.dll /d/encode/aviutl
    ln -fs /mingw32/local/bin/swscale-3.dll /d/encode/aviutl
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

    echo "===> copy LSW AviSynth"
    cp -fa ${DEST_DIR}/../msvcr120.dll ${DEST_DIR}/AviSynth
    cp -fa ${DEST_DIR}/../x64/msvcr120.dll ${DEST_DIR}/AviSynth/x64
    cp -fa ./Release/LSMASHSource.dll ${DEST_DIR}/Avisynth
    cp -fa ./Release/LSMASHSource.dll ${DEST_DIR}/..
    cp -fa ./Release/LSMASHSource.dll /c/AviSynth+/plugins
    cp -fa ./x64/Release/LSMASHSource.dll ${DEST_DIR}/Avisynth/x64
    cp -fa ./x64/Release/LSMASHSource.dll ${DEST_DIR}/../x64
    cp -fa ./x64/Release/LSMASHSource.dll /c/AviSynth+/plugins64
    cp -fa ./README ${DEST_DIR}/AviSynth
    cp -fa ./LICENSE ${DEST_DIR}/legal_stuff/L-SMASH-Works/AviSynth
    ln -fs /mingw32/bin/libbz2-1.dll /c/AviSynth+/plugins
    ln -fs /mingw32/bin/libz-1.dll /c/AviSynth+/plugins
    ln -fs /mingw32/bin/libiconv-2.dll /c/AviSynth+/plugins
    ln -fs /mingw32/local/bin/liblsmash-1.dll /c/AviSynth+/plugins
    ln -fs /mingw32/local/bin/avcodec-56.dll /c/AviSynth+/plugins
    ln -fs /mingw32/local/bin/avformat-56.dll /c/AviSynth+/plugins
    ln -fs /mingw32/local/bin/avresample-2.dll /c/AviSynth+/plugins
    ln -fs /mingw32/local/bin/avutil-54.dll /c/AviSynth+/plugins
    ln -fs /mingw32/local/bin/swscale-3.dll /c/AviSynth+/plugins
    ln -fs /mingw64/bin/libbz2-1.dll /c/AviSynth+/plugins64
    ln -fs /mingw64/bin/libz-1.dll /c/AviSynth+/plugins64
    ln -fs /mingw64/bin/libiconv-2.dll /c/AviSynth+/plugins64
    ln -fs /mingw64/local/bin/liblsmash-1.dll /c/AviSynth+/plugins64
    ln -fs /mingw64/local/bin/avcodec-56.dll /c/AviSynth+/plugins64
    ln -fs /mingw64/local/bin/avformat-56.dll /c/AviSynth+/plugins64
    ln -fs /mingw64/local/bin/avresample-2.dll /c/AviSynth+/plugins64
    ln -fs /mingw64/local/bin/avutil-54.dll /c/AviSynth+/plugins64
    ln -fs /mingw64/local/bin/swscale-3.dll /c/AviSynth+/plugins64
    echo "done"

    return 0
}

# VapourSynth
function build_LSW_vapoursynth() {
    cd ${HOME}/OSS/lsw/VapourSynth

    for arch in i686 x86_64
    do
        if [ "${arch}" = "i686" ] ; then
            local LSWPREFIX=/mingw32/local
        else
            local LSWPREFIX=/mingw64/local
        fi

        source cpath $arch
        printf "===> configure LSW VapourSynth %s\n" $arch
        ./configure --prefix=$LSWPREFIX            \
                    --target-os=mingw32            \
                    --extra-ldflags=-static-libgcc \
        > ${LOGS_DIR}/lsw_config_VS_${arch}.log 2>&1 || exit 1
        echo "done"

        make clean > /dev/null 2>&1
        printf "===> make LSW VapourSynth %s\n" $arch
        make -j9 -O > ${LOGS_DIR}/lsw_make_VS_${arch}.log 2>&1 || exit 1
        echo "done"

        printf "===> copy LSW VapourSynth %s\n" $arch
        if [ "${arch}" = "i686" ] ; then
            cp -fa ./vslsmashsource.dll ${DEST_DIR}/VapourSynth
            cp -fa ./vslsmashsource.dll ${DEST_DIR}/..
            cp -fa ./vslsmashsource.dll /c/VapourSynth/plugins32
            cp -fa ./README ${DEST_DIR}/VapourSynth
            cp -fa ./LICENSE ${DEST_DIR}/legal_stuff/L-SMASH-Works/VapourSynth
            ln -fs /mingw32/bin/libbz2-1.dll /c/VapourSynth/plugins32
            ln -fs /mingw32/bin/libz-1.dll /c/VapourSynth/plugins32
            ln -fs /mingw32/bin/libiconv-2.dll /c/VapourSynth/plugins32
            ln -fs /mingw32/local/bin/liblsmash-1.dll /c/VapourSynth/plugins32
            ln -fs /mingw32/local/bin/avcodec-56.dll /c/VapourSynth/plugins32
            ln -fs /mingw32/local/bin/avformat-56.dll /c/VapourSynth/plugins32
            ln -fs /mingw32/local/bin/avutil-54.dll /c/VapourSynth/plugins32
            ln -fs /mingw32/local/bin/swscale-3.dll /c/VapourSynth/plugins32
        else
            cp -fa ./vslsmashsource.dll ${DEST_DIR}/VapourSynth/x64
            cp -fa ./vslsmashsource.dll ${DEST_DIR}/../x64
            cp -fa ./vslsmashsource.dll  /c/VapourSynth/plugins64
            ln -fs /mingw64/bin/libbz2-1.dll /c/VapourSynth/plugins64
            ln -fs /mingw64/bin/libz-1.dll /c/VapourSynth/plugins64
            ln -fs /mingw64/bin/libiconv-2.dll /c/VapourSynth/plugins64
            ln -fs /mingw64/local/bin/liblsmash-1.dll /c/VapourSynth/plugins64
            ln -fs /mingw64/local/bin/avcodec-56.dll /c/VapourSynth/plugins64
            ln -fs /mingw64/local/bin/avformat-56.dll /c/VapourSynth/plugins64
            ln -fs /mingw64/local/bin/avutil-54.dll /c/VapourSynth/plugins64
            ln -fs /mingw64/local/bin/swscale-3.dll /c/VapourSynth/plugins64
        fi
        echo "done"

        make distclean > /dev/null 2>&1
    done

    return 0
}

build_LSW_common
build_LSW_aviutl
build_LSW_avisynth
build_LSW_vapoursynth

clear; echo "Everything has been successfully completed!"
