#!/bin/bash


PATCHES_DIR=${HOME}/patches/LSW
LOGS_DIR=${HOME}/log/LSW
if [ ! -d $LOGS_DIR ] ; then
    mkdir -p $LOGS_DIR
fi

# common
build_LSW_common() {
    clear; echo "Build L-SMASH Works"

    if [ ! -d ${HOME}/L-SMASH-Works ] ; then
        cd $HOME
        git clone git://github.com/VFR-maniac/L-SMASH-Works.git
    fi
    cd ${HOME}/L-SMASH-Works

    git clean -fxd > /dev/null 2>&1
    git reset --hard > /dev/null 2>&1
    git pull > /dev/null 2>&1
    git_hash > ${LOGS_DIR}/LSW.hash
    git_rev >> ${LOGS_DIR}/LSW.hash

    patch -p1 < ${PATCHES_DIR}/0001-vslsmashsource-Don-t-print-any-info-from-libav-ffmpe.patch \
        > ${LOGS_DIR}/LSW_patches.log 2>&1 || exit 1
    patch -p1 < ${PATCHES_DIR}/0002-lsmashsource.diff \
        >> ${LOGS_DIR}/LSW_patches.log 2>&1 || exit 1
    patch -p1 < ${PATCHES_DIR}/libs.diff \
        >> ${LOGS_DIR}/LSW_patches.log 2>&1 || exit 1

    cp -fa ${PATCHES_DIR}/build_2013.bat ${HOME}/L-SMASH-Works/AviSynth
    cp -fa ${PATCHES_DIR}/build_2013_x64.bat ${HOME}/L-SMASH-Works/AviSynth

    DEST_DIR=/usr/local/L-SMASH-Works/L-SMASH-Works_r`git_rev`-g`git_hash`
    if [[ ! -d ${DEST_DIR}/{AviUtl,AviSynth/x64,VapourSynth/x64,legal_stuff/{FFmpeg,L-SMASH,L-SMASH-Works/{AviUtl,AviSynth,VapourSynth}}} ]] ; then
        mkdir -p ${DEST_DIR}/{AviUtl,AviSynth/x64,VapourSynth/x64,legal_stuff/{FFmpeg,L-SMASH,L-SMASH-Works/{AviUtl,AviSynth,VapourSynth}}}
    fi

    cp -fa /usr/local/L-SMASH-Works/LGPLv3 ${DEST_DIR}/legal_stuff/FFmpeg/LGPLv3
    cp -fa /usr/local/L-SMASH-Works/patches ${DEST_DIR}/legal_stuff/FFmpeg/patches
    cp -fa /usr/local/L-SMASH-Works/LICENSE ${DEST_DIR}/legal_stuff/L-SMASH

    git_log > /usr/local/L-SMASH-Works/log
    python2 /usr/local/L-SMASH-Works/commitloggenerator.py \
            /usr/local/L-SMASH-Works/log /usr/local/L-SMASH-Works/ChangeLog
    cp -fa /usr/local/L-SMASH-Works/ChangeLog $DEST_DIR/

    return 0
}
# AviUtl
build_LSW_aviutl() {
    cd ${HOME}/L-SMASH-Works/AviUtl

    source cpath i686
    echo "===> configure LSW AviUtl"
    PKG_CONFIG_PATH=/usr/LSW_libs/i686/lib/pkgconfig        \
    ./configure --prefix=/usr/LSW_libs/i686                 \
                --extra-ldflags="-Wl,--large-address-aware" \
    > ${LOGS_DIR}/LSW_config_aviutl.log 2>&1 || exit 1
    echo "done"

    make clean > /dev/null 2>&1
    echo "===> make LSW AviUtl"
    make -j5 -O > ${LOGS_DIR}/LSW_make_aviutl.log 2>&1 || exit 1
    echo "done"

    echo "===> copy LSW AviUtl"
    cp -fa ${HOME}/L-SMASH-Works/AviUtl/*.aui \
           ${HOME}/L-SMASH-Works/AviUtl/*.auf \
           ${HOME}/L-SMASH-Works/AviUtl/*.auc \
           ${DEST_DIR}/AviUtl
    cp -fa ${DEST_DIR}/AviUtl/* /usr/local/L-SMASH-Works
    cp -fa ${DEST_DIR}/AviUtl/* /d/encode/aviutl/Plugins
    cp -fa ${HOME}/L-SMASH-Works/AviUtl/README* ${DEST_DIR}/AviUtl
    cp -fa ${HOME}/L-SMASH-Works/AviUtl/LICENSE \
           ${DEST_DIR}/legal_stuff/L-SMASH-Works/AviUtl
    echo "done"

    return 0
}

# AviSynth
build_LSW_avisynth() {
    cd ${HOME}/L-SMASH-Works/AviSynth

    echo "===> build LSW AviSynth win32"
    cmd /c 'build_2013.bat'
    echo "done"
    echo "===> build LSW AviSynth x64"
    cmd /c 'build_2013_x64.bat'
    echo "done"

    echo "===> copy LSW AviSynth"
    cp -fa /usr/local/L-SMASH-Works/msvcr120.dll ${DEST_DIR}/AviSynth
    cp -fa /usr/local/L-SMASH-Works/x64/msvcr120.dll ${DEST_DIR}/AviSynth/x64
    cp -fa ${HOME}/L-SMASH-Works/AviSynth/Release/LSMASHSource.dll \
           ${DEST_DIR}/Avisynth
    cp -fa ${HOME}/L-SMASH-Works/AviSynth/Release/LSMASHSource.dll \
           /usr/local/L-SMASH-Works
    cp -fa ${HOME}/L-SMASH-Works/AviSynth/Release/LSMASHSource.dll \
           /c/AviSynth+/plugins
    cp -fa ${HOME}/L-SMASH-Works/AviSynth/x64/Release/LSMASHSource.dll \
           ${DEST_DIR}/Avisynth/x64
    cp -fa ${HOME}/L-SMASH-Works/AviSynth/x64/Release/LSMASHSource.dll \
           /usr/local/L-SMASH-Works/x64
    cp -fa ${HOME}/L-SMASH-Works/AviSynth/x64/Release/LSMASHSource.dll \
           /c/AviSynth+/plugins64
    cp -fa ${HOME}/L-SMASH-Works/AviSynth/README ${DEST_DIR}/AviSynth
    cp -fa ${HOME}/L-SMASH-Works/AviSynth/LICENSE \
           ${DEST_DIR}/legal_stuff/L-SMASH-Works/AviSynth
    echo "done"

    return 0
}

# VapourSynth
build_LSW_vapoursynth() {
    cd ${HOME}/L-SMASH-Works/VapourSynth

    for arch in i686 x86_64
    do
        if [ "$arch" == "i686" ] ; then
            local _LAA=" -Wl,--large-address-aware"
        else
            local _LAA=""
        fi

        source cpath $arch
        echo "===> configure LSW VapourSynth ${arch}"
        PKG_CONFIG_PATH=/usr/LSW_libs/${arch}/lib/pkgconfig \
        ./configure --prefix=/usr/LSW_libs/$arch            \
                    --extra-ldflags="${_LAA}"               \
                    --target-os=mingw32                     \
        > ${LOGS_DIR}/LSW_config_VS_${arch}.log 2>&1 || exit 1
        echo "done"

        make clean > /dev/null 2>&1
        echo "===> make LSW VapourSynth ${arch}"
        make -j5 -O > ${LOGS_DIR}/LSW_make_VS_${arch}.log 2>&1 || exit 1
        echo "done"

        echo "===> copy LSW VapourSynth ${arch}"
        if [ "$arch" == "i686" ] ; then
            cp -fa ${HOME}/L-SMASH-Works/VapourSynth/vslsmashsource.dll \
                   ${DEST_DIR}/VapourSynth
            cp -fa ${HOME}/L-SMASH-Works/VapourSynth/vslsmashsource.dll \
                   /usr/local/L-SMASH-Works
            cp -fa ${HOME}/L-SMASH-Works/VapourSynth/vslsmashsource.dll \
                   /c/VapourSynth/plugins32
            cp -fa ${HOME}/L-SMASH-Works/VapourSynth/README \
                   ${DEST_DIR}/VapourSynth
            cp -fa ${HOME}/L-SMASH-Works/VapourSynth/LICENSE \
                   ${DEST_DIR}/legal_stuff/L-SMASH-Works/VapourSynth
        else
            cp -fa ${HOME}/L-SMASH-Works/VapourSynth/vslsmashsource.dll \
                   ${DEST_DIR}/VapourSynth/x64
            cp -fa ${HOME}/L-SMASH-Works/VapourSynth/vslsmashsource.dll \
                   /usr/local/L-SMASH-Works/x64
            cp -fa ${HOME}/L-SMASH-Works/VapourSynth/vslsmashsource.dll \
                   /c/VapourSynth/plugins64
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

