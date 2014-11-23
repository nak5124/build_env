#!/usr/bin/env bash


declare all_build=false
declare -a target_arch=(
    "x86_64"
    "i686"
)

for opt in "${@}"
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
                if [ "${arch}" != "i686" -a "${arch}" != "x86_64" ]; then
                    printf "%s, Unknown arch: '%s'\n" $(basename $BASH_SOURCE) $arch
                    echo "...exit"
                    exit 1
                fi
            done
            ;;
        * )
            printf "%s, Unknown option: %s\n" $(basename $BASH_SOURCE) $opt
            echo "...exit"
            exit 1
            ;;
    esac
done

declare -r PATCHES_DIR=${HOME}/patches/ffmpeg
declare -r LOGS_DIR=${HOME}/logs/ffmpeg
if [ ! -d $LOGS_DIR ]; then
    mkdir -p $LOGS_DIR
fi

# SDL
function build_sdl() {
    clear; echo "Build SDL 1.2.15"

    if [ ! -f ${HOME}/OSS/SDL-1.2.15.tar.gz ]; then
        cd ${HOME}/OSS
        curl --fail --location --max-redirs 2 --continue-at - --retry 10 --retry-delay 5 --speed-limit 1 --speed-time 30 \
            -o SDL-1.2.15.tar.gz http://libsdl.org/release/SDL-1.2.15.tar.gz
    fi

    if [ ! -d ${HOME}/OSS/SDL-1.2.15 ]; then
        cd ${HOME}/OSS
        tar xzf SDL-1.2.15.tar.gz
    fi
    cd ${HOME}/OSS/SDL-1.2.15

    if [ ! -f ${HOME}/OSS/SDL-1.2.15/patched_01.marker ]; then
        patch -p1 -i ${PATCHES_DIR}/SDL/0001-SDL-update-ltmain.sh.patch > ${LOGS_DIR}/sdl_patch.log 2>&1 || exit 1
        touch ${HOME}/OSS/SDL-1.2.15/patched_01.marker
    fi

    sed -i 's|-mwindows||g' ${HOME}/OSS/SDL-1.2.15/configure

    local _arch
    for _arch in ${target_arch[@]}
    do
        source cpath $_arch

        if [ "${_arch}" = "i686" ]; then
            local _FFPREFIX=/mingw32/local
        else
            local _FFPREFIX=/mingw64/local
        fi

        printf "===> Configuring SDL %s...\n" $_arch
        ./configure --prefix=$_FFPREFIX                      \
                    --build=${_arch}-w64-mingw32             \
                    --host=${_arch}-w64-mingw32              \
                    --enable-shared                          \
                    --disable-static                         \
                    --enable-fast-install                    \
                    --enable-libc                            \
                    --enable-audio                           \
                    --enable-video                           \
                    --enable-events                          \
                    --enable-joystick                        \
                    --enable-cdrom                           \
                    --enable-threads                         \
                    --enable-timers                          \
                    --enable-file                            \
                    --enable-loadso                          \
                    --enable-cpuinfo                         \
                    --enable-assembly                        \
                    --enable-diskaudio                       \
                    --enable-dummyaudio                      \
                    --enable-nasm                            \
                    --enable-video-dummy                     \
                    --enable-video-opengl                    \
                    --enable-stdio-redirect                  \
                    --enable-directx                         \
                    --with-gnu-ld                            \
                    CFLAGS="${BASE_CFLAGS}"                  \
                    LDFLAGS="${BASE_CFLAGS} ${BASE_LDFLAGS}" \
                    CPPFLAGS="${BASE_CPPFLAGS}"              \
                    CXXFLAGS="${BASE_CXXFLAGS}"              \
            > ${LOGS_DIR}/sdl_config_${_arch}.log 2>&1 || exit 1
        echo "done"

        make clean > /dev/null 2>&1
        printf "===> Making SDL %s...\n" $_arch
        make -j9 -O > ${LOGS_DIR}/sdl_make_${_arch}.log 2>&1 || exit 1
        echo "done"

        printf "===> Installing SDL %s...\n" $_arch
        make install > ${LOGS_DIR}/sdl_install_${_arch}.log 2>&1 || exit 1
        sed -i "s|-mwindows||g" ${_FFPREFIX}/lib/pkgconfig/sdl.pc
        rm -f ${_FFPREFIX}/lib/libSDL*.la
        echo "done"
        make distclean > /dev/null 2>&1
    done

    return 0
}

# libopencore-amr
function build_libopencore_amr() {
    clear; echo "Build libopencore-amr git-master"

    if [ ! -d ${HOME}/OSS/opencore-amr ]; then
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

    local _arch
    for _arch in ${target_arch[@]}
    do
        source cpath $_arch

        if [ "${_arch}" = "i686" ]; then
            local _FFPREFIX=/mingw32/local
        else
            local _FFPREFIX=/mingw64/local
        fi

        printf "===> Configuring libopencore-amr %s...\n" $_arch
        ./configure --prefix=$_FFPREFIX          \
                    --build=${_arch}-w64-mingw32 \
                    --host=${_arch}-w64-mingw32  \
                    --disable-silent-rules       \
                    --enable-compile-c           \
                    --enable-amrnb-encoder       \
                    --enable-amrnb-decoder       \
                    --disable-examples           \
                    --enable-shared              \
                    --disable-static             \
                    --enable-fast-install        \
                    --with-gnu-ld                \
                    CXXFLAGS="${BASE_CXXFLAGS}"  \
                    LDFLAGS="${BASE_LDFLAGS}"    \
                    CPPFLAGS="${BASE_CPPFLAGS}"  \
                    CFLAGS="${BASE_CFLAGS}"      \
            > ${LOGS_DIR}/opencore-amr_config_${_arch}.log 2>&1 || exit 1
        echo "done"

        make clean > /dev/null 2>&1
        printf "===> Making libopencore-amr %s...\n"  $_arch
        make -j9 -O > ${LOGS_DIR}/opencore-amr_make_${_arch}.log 2>&1 || exit 1
        echo "done"

        printf "===> Installing libopencore-amr %s...\n" $_arch
        make install-strip > ${LOGS_DIR}/opencore-amr_install_${_arch}.log 2>&1 || exit 1
        rm -f ${_FFPREFIX}/lib/libopencore*.la
        echo "done"
        make distclean > /dev/null 2>&1
    done

    return 0
}

# openjpeg-1.5
function build_openjpeg() {
    clear; echo "Build OpenJPEG svn openjpeg-1.5 branch"

    if [ ! -d ${HOME}/OSS/openjpeg-1.5 ]; then
        cd ${HOME}/OSS
        svn checkout http://openjpeg.googlecode.com/svn/branches/openjpeg-1.5 openjpeg-1.5
    fi
    cd ${HOME}/OSS/openjpeg-1.5

    svn cleanup > /dev/null
    svn revert --recursive . > /dev/null
    svn update > /dev/null
    svnversion > ${LOGS_DIR}/openjpeg.hash

    patch -p1 -i ${PATCHES_DIR}/openjpeg/0001-cdecl.patch > ${LOGS_DIR}/openjpeg_patch.log 2>&1 || exit 1

    autoreconf -fi > /dev/null 2>&1
    dos2unix libopenjpeg/opj_malloc.h > /dev/null 2>&1

    local _arch
    for _arch in ${target_arch[@]}
    do
        source cpath $_arch

        if [ "${_arch}" = "i686" ]; then
            local _FFPREFIX=/mingw32/local
        else
            local _FFPREFIX=/mingw64/local
        fi

        printf "===> Configuring OpenJPEG 1.5 %s...\n" $_arch
        ./configure --prefix=$_FFPREFIX          \
                    --build=${_arch}-w64-mingw32 \
                    --host=${_arch}-w64-mingw32  \
                    --disable-silent-rules       \
                    --enable-shared              \
                    --disable-static             \
                    --enable-fast-install        \
                    --disable-doc                \
                    --with-gnu-ld                \
                    CFLAGS="${BASE_CFLAGS}"      \
                    LDFLAGS="${BASE_LDFLAGS}"    \
                    CPPFLAGS="${BASE_CPPFLAGS}"  \
            > ${LOGS_DIR}/openjpeg_config_${_arch}.log 2>&1 || exit 1
        sed -i 's|-O3||g' config.status
        echo "done"

        make clean > /dev/null 2>&1
        printf "===> Making OpenJPEG %s...\n" $_arch
        make -j9 -O > ${LOGS_DIR}/openjpeg_make_${_arch}.log 2>&1 || exit 1
        echo "done"

        printf "===> Installing OpenJPEG %s...\n" $_arch
        make install-strip > ${LOGS_DIR}/openjpeg_install_${_arch}.log 2>&1 || exit 1
        rm -fr ${_FFPREFIX}/bin/*j2k*.exe
        echo "done"
        make distclean > /dev/null 2>&1
    done

    return 0
}

# openjpeg2
function build_openjpeg2() {
    clear; echo "Build OpenJPEG svn trunk"

    if [ ! -d ${HOME}/OSS/openjpeg ]; then
        cd ${HOME}/OSS
        svn checkout http://openjpeg.googlecode.com/svn/trunk/ openjpeg
    fi
    cd ${HOME}/OSS/openjpeg

    svn cleanup > /dev/null
    svn revert --recursive . > /dev/null
    svn update > /dev/null
    svnversion > ${LOGS_DIR}/openjpeg2.hash

    patch -p1 -i ${PATCHES_DIR}/openjpeg2/0001-fix-install-for-dlls.all.patch > ${LOGS_DIR}/openjpeg2_patch.log 2>&1 || exit 1
    patch -p1 -i ${PATCHES_DIR}/openjpeg2/0002-versioned-dlls.mingw.patch >> ${LOGS_DIR}/openjpeg2_patch.log 2>&1 || exit 1
    patch -p1 -i ${PATCHES_DIR}/openjpeg2/0003-cdecl.patch >> ${LOGS_DIR}/openjpeg2_patch.log 2>&1 || exit 1

    local _arch
    for _arch in ${target_arch[@]}
    do
        source cpath $_arch

        if [ "${_arch}" = "i686" ]; then
            local _FFPREFIX=/mingw32/local
        else
            local _FFPREFIX=/mingw64/local
        fi

        printf "===> Configuring OpenJPEG %s...\n" $_arch
        cmake -G "MSYS Makefiles"                                                 \
              -DCMAKE_INSTALL_PREFIX=$_FFPREFIX                                   \
              -DCMAKE_BUILD_TYPE=Release                                          \
              -DBUILD_SHARED_LIBS:bool=ON                                         \
              -DBUILD_DOC:bool=OFF                                                \
              -DBUILD_MJ2:bool=ON                                                 \
              -DBUILD_JPWL:bool=OFF                                               \
              -DBUILD_JPIP:bool=OFF                                               \
              -DBUILD_JPIP_SERVER:bool=OFF                                        \
              -DBUILD_JP3D:bool=OFF                                               \
              -DBUILD_JAVA:bool=OFF                                               \
              -DBUILD_TESTING:BOOL=OFF                                            \
              -DCMAKE_SYSTEM_PREFIX_PATH=$(pwd -W)                                \
              -DCMAKE_C_FLAGS_RELEASE:STRING="${BASE_CFLAGS} ${BASE_CPPFLAGS}"    \
              -DCMAKE_SHARED_LINKER_FLAGS:STRING="${BASE_CFLAGS} ${BASE_LDFLAGS}" \
              -DCMAKE_VERBOSE_MAKEFILE:bool=ON                                    \
            > ${LOGS_DIR}/openjpeg2_config_${_arch}.log 2>&1 || exit 1
        echo "done"

        make clean > /dev/null 2>&1
        printf "===> Making OpenJPEG %s...\n" $_arch
        make openmj2 > ${LOGS_DIR}/openjpeg2_make_${_arch}.log 2>&1 || exit 1
        echo "done"

        printf "===> Installing OpenJPEG %s...\n" $_arch
        pushd ${HOME}/OSS/openjpeg/src/lib/openmj2 > /dev/null
        make install > ${LOGS_DIR}/openjpeg2_install_${_arch}.log 2>&1 || exit 1
        popd > /dev/null
        install -m 644 ${HOME}/OSS/openjpeg/src/lib/openmj2/openjpeg.h ${_FFPREFIX}/include
        echo "done"
        svn status | grep ^? | awk '{print $2}' | xargs rm -rf
    done

    return 0
}

# speex
function build_libspeex() {
    clear; echo "Build libspeex git-master"

    if [ ! -d ${HOME}/OSS/xiph/speex ]; then
        cd ${HOME}/OSS/xiph
        git clone git://git.xiph.org/speex.git
    fi
    cd ${HOME}/OSS/xiph/speex

    git clean -fdx > /dev/null 2>&1
    git reset --hard > /dev/null 2>&1
    git pull > /dev/null 2>&1
    git_hash > ${LOGS_DIR}/speex.hash
    git_rev >> ${LOGS_DIR}/speex.hash

    autoreconf -fi > /dev/null 2>&1

    local _arch
    for _arch in ${target_arch[@]}
    do
        source cpath $_arch

        if [ "${_arch}" = "i686" ]; then
            local _FFPREFIX=/mingw32/local
        else
            local _FFPREFIX=/mingw64/local
        fi

        printf "===> Configuring libspeex %s...\n" $_arch
        ./configure --prefix=$_FFPREFIX          \
                    --build=${_arch}-w64-mingw32 \
                    --host=${_arch}-w64-mingw32  \
                    --disable-silent-rules       \
                    --enable-shared              \
                    --disable-static             \
                    --enable-fast-install        \
                    --enable-sse                 \
                    --disable-binaries           \
                    --enable-vorbis-psy          \
                    --with-gnu-ld                \
                    CFLAGS="${BASE_CFLAGS}"      \
                    LDFLAGS="${BASE_LDFLAGS}"    \
                    LIBS="-lwinmm"               \
                    CPPFLAGS="${BASE_CPPFLAGS}"  \
            > ${LOGS_DIR}/speex_config_${_arch}.log 2>&1 || exit 1
        sed -i 's|-O3||g' config.status
        echo "done"

        make clean > /dev/null 2>&1
        printf "===> Making libspeex %s...\n" $_arch
        make -j9 -O > ${LOGS_DIR}/speex_make_${_arch}.log 2>&1 || exit 1
        echo "done"

        printf "===> Installing libspeex %s...\n" $_arch
        make install-strip > ${LOGS_DIR}/speex_install_${_arch}.log 2>&1 || exit 1
        rm -f ${_FFPREFIX}/lib/libspeex.la
        echo "done"
        make distclean > /dev/null 2>&1
    done

    return 0
}

# vorbis
function build_libvorbis() {
    clear; echo "Build libvorbis(aoTuV b6.03)"

    if [ ! -f ${HOME}/OSS/xiph/aotuv_b6.03_2014.tar.bz2 ]; then
        cd ${HOME}/OSS/xiph
        curl --fail --location --max-redirs 2 --continue-at - --retry 10 --retry-delay 5 --speed-limit 1 --speed-time 30 \
            -o aotuv_b6.03_2014.tar.bz2 http://www.geocities.jp/aoyoume/aotuv/source_code/libvorbis-aotuv_b6.03_2014.tar.bz2
    fi

    if [ ! -d ${HOME}/OSS/xiph/aotuv-b6.03_20110424-20140429 ]; then
        cd ${HOME}/OSS/xiph
        tar xjf aotuv_b6.03_2014.tar.bz2
    fi
    cd ${HOME}/OSS/xiph/aotuv-b6.03_20110424-20140429

    local _arch
    for _arch in ${target_arch[@]}
    do
        source cpath $_arch

        if [ "${_arch}" = "i686" ]; then
            local _FFPREFIX=/mingw32/local
        else
            local _FFPREFIX=/mingw64/local
        fi

        printf "===> Configuring libvorbis(aoTuV) %s...\n" $_arch
        ./autogen.sh --prefix=$_FFPREFIX           \
                     --build=${_arch}-w64-mingw32  \
                     --host=${_arch}-w64-mingw32   \
                     --target=${_arch}-w64-mingw32 \
                     --enable-shared               \
                     --disable-static              \
                     --enable-fast-install         \
                     --disable-docs                \
                     --disable-examples            \
                     --with-gnu-ld                 \
                     --with-ogg=$_FFPREFIX         \
                     CFLAGS="${BASE_CFLAGS}"       \
                     LDFLAGS="${BASE_LDFLAGS}"     \
                     CPPFLAGS="${BASE_CPPFLAGS}"   \
            > ${LOGS_DIR}/vorbis_config_${_arch}.log 2>&1 || exit 1
        echo "done"

        make clean > /dev/null 2>&1
        printf "===> Making libvorbis(aoTuV) %s...\n" $_arch
        make -j9 -O > ${LOGS_DIR}/vorbis_make_${_arch}.log 2>&1 || exit 1
        echo "done"

        printf "===> Installing libvorbis(aoTuV) %s...\n" $_arch
        make install-strip > ${LOGS_DIR}/vorbis_install_${_arch}.log 2>&1 || exit 1
        rm -f ${_FFPREFIX}/bin/libvorbisfile-*.dll
        rm -f ${_FFPREFIX}/include/vorbis/vorbisfile.h
        rm -f ${_FFPREFIX}/lib/libvorbisfile.dll.a
        rm -f ${_FFPREFIX}/lib/pkgconfig/vorbisfile.pc
        rm -f ${_FFPREFIX}/lib/libvorbis*.la
        echo "done"
        make distclean > /dev/null 2>&1
    done

    return 0
}

# vpx
function build_libvpx() {
    clear; echo "Build libvpx git-master"

    if [ ! -d ${HOME}/OSS/libvpx ]; then
        cd ${HOME}/OSS
        git clone http://git.chromium.org/webm/libvpx.git
    fi
    cd ${HOME}/OSS/libvpx

    git clean -fdx > /dev/null 2>&1
    git reset --hard > /dev/null 2>&1
    git pull > /dev/null 2>&1
    git_hash > ${LOGS_DIR}/vpx.hash
    git_rev >> ${LOGS_DIR}/vpx.hash

    patch -p1 -i ${PATCHES_DIR}/libvpx/0001-enable-shared-mingw.patch > ${LOGS_DIR}/vpx_patch.log 2>&1 || exit 1
    patch -p1 -i ${PATCHES_DIR}/libvpx/0002-fix-exports.mingw.patch >> ${LOGS_DIR}/vpx_patch.log 2>&1 || exit 1
    patch -p1 -i ${PATCHES_DIR}/libvpx/0003-give-preference-win32api-over-pthread.patch \
        >> ${LOGS_DIR}/vpx_patch.log 2>&1 || exit 1

    local _arch
    for _arch in ${target_arch[@]}
    do
        source cpath $_arch

        if [ "${_arch}" = "i686" ]; then
            local _FFPREFIX=/mingw32/local
            local _target=x86-win32-gcc
        else
            local _FFPREFIX=/mingw64/local
            local _target=x86_64-win64-gcc
        fi

        printf "===> Configuring libvpx %s...\n" $_arch
        CFLAGS="${BASE_CFLAGS} ${BASE_CPPFLAGS}" \
        LDFLAGS="${BASE_CFLAGS} ${BASE_LDFLAGS}" \
        CXXFLAGS="${BASE_CXXFLAGS}"              \
        ./configure --prefix=$_FFPREFIX          \
                    --target=$_target            \
                    --disable-werror             \
                    --enable-optimizations       \
                    --disable-debug              \
                    --disable-install-docs       \
                    --disable-install-bins       \
                    --enable-install-libs        \
                    --disable-install-srcs       \
                    --enable-libs                \
                    --disable-examples           \
                    --disable-docs               \
                    --disable-unit-tests         \
                    --as=yasm                    \
                    --disable-codec-srcs         \
                    --disable-debug-libs         \
                    --disable-vp8-decoder        \
                    --disable-vp9-decoder        \
                    --disable-postproc           \
                    --disable-vp9-postproc       \
                    --enable-multithread         \
                    --enable-spatial-resampling  \
                    --enable-runtime-cpu-detect  \
                    --enable-shared              \
                    --disable-static             \
                    --enable-multi-res-encoding  \
                    --disable-webm-io            \
                    --disable-libyuv             \
            > ${LOGS_DIR}/vpx_config_${_arch}.log 2>&1 || exit 1
        sed -i 's|-O3||g' libs-${_target}.mk
        echo "done"

        make clean > /dev/null 2>&1
        printf "===> Making libvpx %s...\n" $_arch
        make -j9 -O > ${LOGS_DIR}/vpx_make_${_arch}.log 2>&1 || exit 1
        echo "done"

        printf "===> Installing libvpx %s...\n" $_arch
        make install > ${LOGS_DIR}/vpx_install_${_arch}.log 2>&1 || exit 1
        sed -i "s|-lpthread||g" ${_FFPREFIX}/lib/pkgconfig/vpx.pc
        echo "done"
        make distclean > /dev/null 2>&1
    done

    return 0
}

# liblzma
function build_lzma() {
    clear; echo "Build liblzma git-master"

    if [ ! -d ${HOME}/OSS/xz ]; then
        cd ${HOME}/OSS
        git clone http://git.tukaani.org/xz.git
    fi
    cd ${HOME}/OSS/xz

    git clean -fdx > /dev/null 2>&1
    git reset --hard > /dev/null 2>&1
    git pull > /dev/null 2>&1
    git_hash > ${LOGS_DIR}/lzma.hash
    git_rev >> ${LOGS_DIR}/lzma.hash

    ./autogen.sh > /dev/null 2>&1

    local _arch
    for _arch in ${target_arch[@]}
    do
        source cpath $_arch

        if [ "${_arch}" = "i686" ]; then
            local _FFPREFIX=/mingw32/local
        else
            local _FFPREFIX=/mingw64/local
        fi

        printf "===> Configuring liblzma %s...\n" $_arch
        ./configure --prefix=$_FFPREFIX          \
                    --build=${_arch}-w64-mingw32 \
                    --host=${_arch}-w64-mingw32  \
                    --enable-threads=vista       \
                    --enable-assume-ram=16384    \
                    --disable-xz                 \
                    --disable-xzdec              \
                    --disable-lzmadec            \
                    --disable-lzmainfo           \
                    --disable-lzma-links         \
                    --disable-scripts            \
                    --disable-doc                \
                    --disable-silent-rules       \
                    --enable-shared              \
                    --disable-static             \
                    --enable-fast-install        \
                    --disable-nls                \
                    --disable-rpath              \
                    --enable-unaligned-access    \
                    --with-gnu-ld                \
                    CFLAGS="${BASE_CFLAGS}"      \
                    LDFLAGS="${BASE_LDFLAGS}"    \
                    CPPFLAGS="${BASE_CPPFLAGS}"  \
            > ${LOGS_DIR}/lzma_config_${_arch}.log 2>&1 || exit 1
        echo "done"

        make clean > /dev/null 2>&1
        printf "===> Making liblzma %s...\n" $_arch
        make -j9 -O > ${LOGS_DIR}/lzma_make_${_arch}.log 2>&1 || exit 1
        echo "done"

        printf "===> Installing liblzma %s...\n" $_arch
        make install-strip > ${LOGS_DIR}/lzma_install_${_arch}.log 2>&1 || exit 1
        rm -f ${_FFPREFIX}/lib/liblzma.la
        echo "done"
        make distclean > /dev/null 2>&1
    done

    return 0
}

# FFmpeg
function patch_ffmpeg() {
    echo "===> Applying patches to FFmpeg..."

    local -i _N=54
    local -i _i
    for _i in `seq 1 ${_N}`
    do
        local _num=$( printf "%04d" ${_i} )
        if [ $_i -eq 1 ]; then
            patch -p1 < ${PATCHES_DIR}/${_num}*.patch > ${LOGS_DIR}/ffmpeg_patches.log 2>&1 || exit 1
        else
            patch -p1 < ${PATCHES_DIR}/${_num}*.patch >> ${LOGS_DIR}/ffmpeg_patches.log 2>&1 || exit 1
        fi
    done

: << "#__CO__"
    local -i _M=42
    local -i _j
    for _j in `seq 1 ${_M}`
    do
        local _num=$( printf "%04d" $_j )
        patch -p1 < ${PATCHES_DIR}/haali/${_num}*.patch >> ${LOGS_DIR}/ffmpeg_patches.log 2>&1 || exit 1
    done
#__CO__

    echo "done"

    return 0
}

function build_ffmpeg() {
    clear; echo "Build FFmpeg git-master"

    if [ ! ${HOME}/OSS/videolan/ffmpeg ]; then
        cd ${HOME}/OSS/videolan
        git clone git://source.ffmpeg.org/ffmpeg.git
    fi
    cd ${HOME}/OSS/videolan/ffmpeg

    git clean -fdx > /dev/null 2>&1
    git reset --hard > /dev/null 2>&1
    git pull > /dev/null 2>&1
    git_hash > ${LOGS_DIR}/ffmpeg.hash
    git_rev >> ${LOGS_DIR}/ffmpeg.hash

    local -r _AVCODEC_API_VER=$(cat libavcodec/version.h | grep "#define LIBAVCODEC_VERSION_MAJOR" | awk '{print $3}')
    local -r _AVDEVICE_API_VER=$(cat libavdevice/version.h | grep "#define LIBAVDEVICE_VERSION_MAJOR" | awk '{print $3}')
    local -r _AVFILTER_API_VER=$(cat libavfilter/version.h | grep "#define LIBAVFILTER_VERSION_MAJOR" | awk '{print $3}')
    local -r _AVFORMAT_API_VER=$(cat libavformat/version.h | grep "#define LIBAVFORMAT_VERSION_MAJOR" | awk '{print $3}')
    local -r _AVRESAMPLE_API_VER=$(cat libavresample/version.h | grep "#define LIBAVRESAMPLE_VERSION_MAJOR" | awk '{print $3}')
    local -r _AVUTIL_API_VER=$(cat libavutil/version.h | grep "#define LIBAVUTIL_VERSION_MAJOR" | awk '{print $3}')
    local -r _SWRESAMPLE_API_VER=$(cat libswresample/version.h | grep "#define LIBSWRESAMPLE_VERSION_MAJOR" | awk '{print $3}')
    local -r _SWSCALE_API_VER=$(cat libswscale/version.h | grep "#define LIBSWSCALE_VERSION_MAJOR" | awk '{print $3}')
    local -ra _bin_list=(
        "ffmpeg.exe"
        "ffprobe.exe"
        "ffplay.exe"
        "avcodec-${_AVCODEC_API_VER}.dll"
        "avdevice-${_AVDEVICE_API_VER}.dll"
        "avfilter-${_AVFILTER_API_VER}.dll"
        "avformat-${_AVFORMAT_API_VER}.dll"
        "avresample-${_AVRESAMPLE_API_VER}.dll"
        "avutil-${_AVUTIL_API_VER}.dll"
        "swresample-${_SWRESAMPLE_API_VER}.dll"
        "swscale-${_SWSCALE_API_VER}.dll"
        "SDL.dll"
        "libopencore-amrnb-0.dll"
        "libopencore-amrwb-0.dll"
        "libopenmj2-7.dll"
        "libspeex-1.dll"
        "libvorbis-0.dll"
        "libvorbisenc-2.dll"
        "libvpx-1.dll"
        "liblzma-5.dll"
    )

    patch_ffmpeg

    local _arch
    for _arch in ${target_arch[@]}
    do
        if [ "${_arch}" = "i686" ]; then
            local _FFPREFIX=/mingw32/local
            local _VCDIR=$VC32_DIR
        else
            local _FFPREFIX=/mingw64/local
            local _VCDIR=$VC64_DIR
        fi

        source cpath $_arch
        PATH=${PATH}:$_VCDIR
        export PATH

        printf "===> Configuring FFmpeg %s...\n" $_arch
        ./configure --prefix=$_FFPREFIX                              \
                    --enable-version3                                \
                    --disable-static                                 \
                    --enable-shared                                  \
                    --disable-doc                                    \
                    --enable-avresample                              \
                    --disable-pthreads                               \
                    --disable-encoder=vorbis                         \
                    --disable-decoder=amrnb                          \
                    --disable-decoder=amrwb                          \
                    --disable-decoder=jpeg2000                       \
                    --disable-decoder=libopus                        \
                    --disable-decoder=libvpx_vp8                     \
                    --disable-decoder=libvpx_vp9                     \
                    --disable-decoder=vorbis                         \
                    --enable-avisynth                                \
                    --enable-libopencore-amrnb                       \
                    --enable-libopencore-amrwb                       \
                    --enable-libopenjpeg                             \
                    --enable-libopus                                 \
                    --enable-libspeex                                \
                    --enable-libvorbis                               \
                    --enable-libvpx                                  \
                    --enable-opengl                                  \
                    --arch=${_arch/i6/x}                             \
                    --cpu=sandybridge                                \
                    --disable-debug                                  \
                    --extra-ldflags="${BASE_CFLAGS} ${BASE_LDFLAGS}" \
                    --optflags="${BASE_CFLAGS} ${BASE_CPPFLAGS}"     \
            > ${LOGS_DIR}/ffmpeg_config_${_arch}.log 2>&1 || exit 1
        # if linking with MSVC statically, uncomment the following lines
        # sed -i '/HAVE_CLOCK_GETTIME/d' config.h
        # sed -i '/HAVE_NANOSLEEP/d' config.h
        printf "\nconfigh\n" >> ${LOGS_DIR}/ffmpeg_config_${_arch}.log
        cat config.h >> ${LOGS_DIR}/ffmpeg_config_${_arch}.log
        echo "done"

        make clean > /dev/null 2>&1
        printf "===> Making FFmpeg %s...\n" $_arch
        make -j9 -O > ${LOGS_DIR}/ffmpeg_make_${_arch}.log 2>&1 || exit 1
        echo "done"

        printf "===> Installing FFmpeg %s...\n" $_arch
        make install > ${LOGS_DIR}/ffmpeg_install_${_arch}.log 2>&1 || exit 1
        if [ "${_arch}" = "x86_64" ]; then
            local _bin
            for _bin in ${_bin_list[@]}
            do
                ln -fs ${_FFPREFIX}/bin/$_bin /d/encode/tools
            done
            ln -fs /mingw64/bin/libwinpthread-1.dll /d/encode/tools
            ln -fs /mingw64/bin/libssp-0.dll /d/encode/tools
            ln -fs /mingw64/bin/libiconv-2.dll /d/encode/tools
            ln -fs /mingw64/bin/libz-1.dll /d/encode/tools
            ln -fs /mingw64/bin/libbz2-1.dll /d/encode/tools
        fi
        echo "done"
        make distclean > /dev/null 2>&1
    done

    return 0
}

declare -r mintty_save=$MINTTY
unset MINTTY

if ${all_build}; then
    build_sdl
    build_libopencore_amr
    # build_openjpeg
    build_openjpeg2
    build_libspeex
    build_libvorbis
    build_libvpx
    build_lzma
fi
build_ffmpeg

MINTTY=$mintty_save
export MINTTY

clear; echo "Everything has been successfully completed!"
