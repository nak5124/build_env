#!/usr/bin/env bash


declare all_build=false
declare -a target_arch=(
    "x86_64"
    "i686"
)

for opt in "$@"
do
    case "${opt}" in
        all)
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

declare -r PATCHES_DIR=${HOME}/patches/ffmpeg
declare -r LOGS_DIR=${HOME}/logs/ffmpeg
if [ ! -d $LOGS_DIR ] ; then
    mkdir -p $LOGS_DIR
fi

# SDL
function build_sdl() {
    clear; echo "Build SDL 1.2.15"

    if [ ! -f ${HOME}/OSS/SDL-1.2.15.tar.gz ] ; then
        cd ${HOME}/OSS
        curl --fail --location --max-redirs 2 --continue-at - --retry 10 --retry-delay 5 --speed-limit 1 --speed-time 30 \
            -o SDL-1.2.15.tar.gz http://libsdl.org/release/SDL-1.2.15.tar.gz
    fi

    if [ ! -d ${HOME}/OSS/SDL-1.2.15 ] ; then
        cd ${HOME}/OSS
        tar xzf SDL-1.2.15.tar.gz
    fi
    cd ${HOME}/OSS/SDL-1.2.15

    sed -i 's|-mwindows||g' ${HOME}/OSS/SDL-1.2.15/configure

    for arch in ${target_arch[@]}
    do
        if [ "${arch}" = "i686" ] ; then
            local FFPREFIX=/mingw32/local
        else
            local FFPREFIX=/mingw64/local
        fi

        source cpath $arch
        printf "===> configure SDL %s\n" $arch
        ./configure --prefix=$FFPREFIX          \
                    --build=${arch}-w64-mingw32 \
                    --host=${arch}-w64-mingw32  \
                    --enable-shared             \
                    --disable-static            \
                    --with-gnu-ld               \
                    CPPFLAGS="${BASE_CPPFLAGS}" \
                    CFLAGS="${BASE_CFLAGS}"     \
                    CXXFLAGS="${BASE_CXXFLAGS}" \
                    LDFLAGS="${BASE_LDFLAGS}"   \
            > ${LOGS_DIR}/sdl_config_${arch}.log 2>&1 || exit 1
        echo "done"

        make clean > /dev/null 2>&1
        printf "===> making SDL %s\n" $arch
        make -j9 -O > ${LOGS_DIR}/sdl_make_${arch}.log 2>&1 || exit 1
        echo "done"

        printf "===> installing SDL %s\n" $arch
        make install > ${LOGS_DIR}/sdl_install_${arch}.log 2>&1 || exit 1
        sed -i "s|-mwindows||g" ${FFPREFIX}/lib/pkgconfig/sdl.pc
        echo "done"
        make distclean > /dev/null 2>&1
    done

    return 0
}

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

    for arch in ${target_arch[@]}
    do
        if [ "${arch}" = "i686" ] ; then
            local FFPREFIX=/mingw32/local
        else
            local FFPREFIX=/mingw64/local
        fi

        source cpath $arch
        printf "===> configure libopencore-amr %s\n" $arch
        ./configure --prefix=$FFPREFIX          \
                    --build=${arch}-w64-mingw32 \
                    --host=${arch}-w64-mingw32  \
                    --disable-silent-rules      \
                    --enable-shared             \
                    --disable-static            \
                    --with-gnu-ld               \
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

# openjpeg-1.5
function build_openjpeg() {
    clear; echo "Build OpenJPEG svn openjpeg-1.5 branch"

    if [ ! -d ${HOME}/OSS/openjpeg-1.5 ] ; then
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

    for arch in ${target_arch[@]}
    do
        if [ "${arch}" = "i686" ] ; then
            local FFPREFIX=/mingw32/local
        else
            local FFPREFIX=/mingw64/local
        fi

        source cpath $arch
        printf "===> configure OpenJPEG %s\n" $arch
        ./configure --prefix=$FFPREFIX          \
                    --build=${arch}-w64-mingw32 \
                    --host=${arch}-w64-mingw32  \
                    --disable-silent-rules      \
                    --enable-shared             \
                    --disable-static            \
                    --disable-doc               \
                    --with-gnu-ld               \
                    CPPFLAGS="${BASE_CPPFLAGS}" \
                    CFLAGS="${BASE_CFLAGS}"     \
                    LDFLAGS="${BASE_LDFLAGS}"   \
            > ${LOGS_DIR}/openjpeg_config_${arch}.log 2>&1 || exit 1
        sed -i 's|-O3||g' config.status
        echo "done"

        make clean > /dev/null 2>&1
        printf "===> making OpenJPEG %s\n" $arch
        make -j9 -O > ${LOGS_DIR}/openjpeg_make_${arch}.log 2>&1 || exit 1
        echo "done"

        printf "===> installing OpenJPEG %s\n" $arch
        make install-strip > ${LOGS_DIR}/openjpeg_install_${arch}.log 2>&1 || exit 1
        rm -fr ${FFPREFIX}/bin/*j2k*.exe
        echo "done"
        make distclean > /dev/null 2>&1
    done

    return 0
}

# speex
function build_libspeex() {
    clear; echo "Build libspeex git-master"

    if [ ! -d ${HOME}/OSS/xiph/speex ] ; then
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

    for arch in ${target_arch[@]}
    do
        if [ "${arch}" = "i686" ] ; then
            local FFPREFIX=/mingw32/local
        else
            local FFPREFIX=/mingw64/local
        fi

        source cpath $arch
        printf "===> configure libspeex %s\n" $arch
        ./configure --prefix=$FFPREFIX                \
                    --build=${arch}-w64-mingw32       \
                    --host=${arch}-w64-mingw32        \
                    --disable-silent-rules            \
                    --enable-shared                   \
                    --disable-static                  \
                    --enable-sse                      \
                    --with-gnu-ld                     \
                    --with-ogg                        \
                    CPPFLAGS="${BASE_CPPFLAGS}"       \
                    CFLAGS="${BASE_CFLAGS}"           \
                    LDFLAGS="${BASE_LDFLAGS} -lwinmm" \
            > ${LOGS_DIR}/speex_config_${arch}.log 2>&1 || exit 1
        sed -i 's|-O3||g' config.status
        echo "done"

        make clean > /dev/null 2>&1
        printf "===> making libspeex %s\n" $arch
        make -j9 -O > ${LOGS_DIR}/speex_make_${arch}.log 2>&1 || exit 1
        echo "done"

        printf "===> installing libspeex %s\n" $arch
        make install-strip > ${LOGS_DIR}/speex_install_${arch}.log 2>&1 || exit 1
        rm -f ${FFPREFIX}/bin/speex*.exe
        echo "done"
        make distclean > /dev/null 2>&1
    done

    return 0
}

# vorbis
function build_libvorbis() {
    clear; echo "Build libvorbis(aoTuV b6.03)"

    if [ ! -f ${HOME}/OSS/xiph/aotuv_b6.03_2014.tar.bz2 ] ; then
        cd ${HOME}/OSS/xiph
        curl --fail --location --max-redirs 2 --continue-at - --retry 10 --retry-delay 5 --speed-limit 1 --speed-time 30 \
            -o aotuv_b6.03_2014.tar.bz2 http://www.geocities.jp/aoyoume/aotuv/source_code/libvorbis-aotuv_b6.03_2014.tar.bz2
    fi

    if [ ! -d ${HOME}/OSS/xiph/aotuv-b6.03_20110424-20140429 ] ; then
        cd ${HOME}/OSS/xiph
        tar xjf aotuv_b6.03_2014.tar.bz2
    fi
    cd ${HOME}/OSS/xiph/aotuv-b6.03_20110424-20140429

    for arch in ${target_arch[@]}
    do
        if [ "${arch}" = "i686" ] ; then
            local FFPREFIX=/mingw32/local
        else
            local FFPREFIX=/mingw64/local
        fi

        source cpath $arch
        printf "===> configure libvorbis(aoTuV) %s\n" $arch
        ./autogen.sh --prefix=$FFPREFIX           \
                     --build=${arch}-w64-mingw32  \
                     --host=${arch}-w64-mingw32   \
                     --target=${arch}-w64-mingw32 \
                     --enable-shared              \
                     --disable-static             \
                     --disable-docs               \
                     --disable-examples           \
                     --with-gnu-ld                \
                     --with-ogg=$FFPREFIX         \
                     CPPFLAGS="${BASE_CPPFLAGS}"  \
                     CFLAGS="${BASE_CFLAGS}"      \
                     LDFLAGS="${BASE_LDFLAGS}"    \
            > ${LOGS_DIR}/vorbis_config_${arch}.log 2>&1 || exit 1
        echo "done"

        make clean > /dev/null 2>&1
        printf "===> making libvorbis(aoTuV) %s\n" $arch
        make -j9 -O > ${LOGS_DIR}/vorbis_make_${arch}.log 2>&1 || exit 1
        echo "done"

        printf "===> installing libvorbis(aoTuV) %s\n" $arch
        make install-strip > ${LOGS_DIR}/vorbis_install_${arch}.log 2>&1 || exit 1
        echo "done"
        make distclean > /dev/null 2>&1
    done

    return 0
}

# vpx
function build_libvpx() {
    clear; echo "Build libvpx git-master"

    if [ ! -d ${HOME}/OSS/libvpx ] ; then
        cd ${HOME}/OSS
        git clone http://git.chromium.org/webm/libvpx.git
    fi
    cd ${HOME}/OSS/libvpx

    git clean -fdx > /dev/null 2>&1
    git reset --hard > /dev/null 2>&1
    git pull > /dev/null 2>&1
    git_hash > ${LOGS_DIR}/vpx.hash
    git_rev >> ${LOGS_DIR}/vpx.hash

    patch -p1 -i ${PATCHES_DIR}/libvpx/0001-enable-shared-on.mingw.patch > ${LOGS_DIR}/vpx_patch.log 2>&1 || exit 1
    patch -p1 -i ${PATCHES_DIR}/libvpx/0002-implib.mingw.patch >> ${LOGS_DIR}/vpx_patch.log 2>&1 || exit 1
    patch -p1 -i ${PATCHES_DIR}/libvpx/0003-fix-exports.mingw.patch >> ${LOGS_DIR}/vpx_patch.log 2>&1 || exit 1
    patch -p1 -i ${PATCHES_DIR}/libvpx/0004-instll-implib.mingw.patch >> ${LOGS_DIR}/vpx_patch.log 2>&1 || exit 1
    patch -p1 -i ${PATCHES_DIR}/libvpx/0005-fix-ln-on-install.mingw.patch >> ${LOGS_DIR}/vpx_patch.log 2>&1 || exit 1

    for arch in ${target_arch[@]}
    do
        if [ "${arch}" = "i686" ] ; then
            local FFPREFIX=/mingw32/local
            local _target=x86-win32-gcc
        else
            local FFPREFIX=/mingw64/local
            local _target=x86_64-win64-gcc
        fi

        source cpath $arch
        printf "===> configure libvpx %s\n" $arch
        CFLAGS="${BASE_CFLAGS}"                 \
        CXXFLAGS="${BASE_CXXFLAGS}"             \
        LDFLAGS="${BASE_LDFLAGS}"               \
        ./configure --prefix=$FFPREFIX          \
                    --target=$_target           \
                    --disable-install-docs      \
                    --disable-examples          \
                    --disable-docs              \
                    --disable-unit-tests        \
                    --enable-runtime-cpu-detect \
                    --enable-shared             \
                    --disable-static            \
                    --enable-multi-res-encoding \
                    --disable-vp8-decoder       \
                    --disable-vp9-decoder       \
            > ${LOGS_DIR}/vpx_config_${arch}.log 2>&1 || exit 1
        sed -i 's|-O3||g' libs-${_target}.mk
        sed -i '/extralibs/d' libs-${_target}.mk
        sed -i 's/HAVE_PTHREAD_H=yes/HAVE_PTHREAD_H=no/' libs-${_target}.mk
        sed -i 's/#define HAVE_PTHREAD_H 1/#define HAVE_PTHREAD_H 0/' vpx_config.h
        echo "done"

        make clean > /dev/null 2>&1
        printf "===> making libvpx %s\n" $arch
        make -j9 -O > ${LOGS_DIR}/vpx_make_${arch}.log 2>&1 || exit 1
        echo "done"

        printf "===> installing libvpx %s\n" $arch
        make install > ${LOGS_DIR}/vpx_install_${arch}.log 2>&1 || exit 1
        echo "done"
        make distclean > /dev/null 2>&1
    done

    return 0
}

# FFmpeg
function patch_ffmpeg() {
    echo "===> patching... FFmpeg"

    local _N=37
    for i in `seq 1 ${_N}`
    do
        local num=$( printf "%04d" $i )
        if [ "${i}" = 1 ] ; then
            patch -p1 < ${PATCHES_DIR}/${num}*.patch > ${LOGS_DIR}/ffmpeg_patches.log 2>&1 || exit 1
        else
            patch -p1 < ${PATCHES_DIR}/${num}*.patch >> ${LOGS_DIR}/ffmpeg_patches.log 2>&1 || exit 1
        fi
    done

: <<'#_CO_'
    local _M=39
    for j in `seq 1 ${_M}`
    do
        local num=$( printf "%04d" $j )
        patch -p1 < ${PATCHES_DIR}/haali/${num}*.patch >> ${LOGS_DIR}/ffmpeg_patches.log 2>&1 || exit 1
    done
#_CO_

    echo "done"

    return 0
}

function build_ffmpeg() {
    clear; echo "Build FFmpeg git-master"

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

    local -r AVCODEC_API_VER=$(echo $(cat libavcodec/version.h | grep "#define LIBAVCODEC_VERSION_MAJOR" | awk '{print $3}'))
    local -r AVDEVICE_API_VER=$(echo $(cat libavdevice/version.h | grep "#define LIBAVDEVICE_VERSION_MAJOR" | awk '{print $3}'))
    local -r AVFILTER_API_VER=$(echo $(cat libavfilter/version.h | grep "#define LIBAVFILTER_VERSION_MAJOR" | awk '{print $3}'))
    local -r AVFORMAT_API_VER=$(echo $(cat libavformat/version.h | grep "#define LIBAVFORMAT_VERSION_MAJOR" | awk '{print $3}'))
    local -r AVRESAMPLE_API_VER=$(echo $(cat libavresample/version.h | grep "#define LIBAVRESAMPLE_VERSION_MAJOR" | awk '{print $3}'))
    local -r AVUTIL_API_VER=$(echo $(cat libavutil/version.h | grep "#define LIBAVUTIL_VERSION_MAJOR" | awk '{print $3}'))
    local -r SWRESAMPLE_API_VER=$(echo $(cat libswresample/version.h | grep "#define LIBSWRESAMPLE_VERSION_MAJOR" | awk '{print $3}'))
    local -r SWSCALE_API_VER=$(echo $(cat libswscale/version.h | grep "#define LIBSWSCALE_VERSION_MAJOR" | awk '{print $3}'))
    local -ra bin_list=(
        "ffmpeg.exe"
        "ffprobe.exe"
        "ffplay.exe"
        "avcodec-${AVCODEC_API_VER}.dll"
        "avdevice-${AVDEVICE_API_VER}.dll"
        "avfilter-${AVFILTER_API_VER}.dll"
        "avformat-${AVFORMAT_API_VER}.dll"
        "avresample-${AVRESAMPLE_API_VER}.dll"
        "avutil-${AVUTIL_API_VER}.dll"
        "swresample-${SWRESAMPLE_API_VER}.dll"
        "swscale-${SWSCALE_API_VER}.dll"
        "SDL.dll"
        "libopencore-amrnb-0.dll"
        "libopencore-amrwb-0.dll"
        "libopenjpeg-1.dll"
        "libspeex-1.dll"
        "libvorbis-0.dll"
        "libvorbisenc-2.dll"
        "libvpx-1.dll"
    )

    patch_ffmpeg

    for arch in ${target_arch[@]}
    do
        if [ "${arch}" = "i686" ] ; then
            local _archopt="--arch=x86 --cpu=i686"
            local FFPREFIX=/mingw32/local
            local VCDIR=$VC32_DIR
        else
            local _archopt="--arch=x86_64"
            local FFPREFIX=/mingw64/local
            local VCDIR=$VC64_DIR
        fi

        source cpath $arch
        PATH=${PATH}:$VCDIR
        export PATH

        printf "===> configure FFmpeg %s\n" $arch
        ./configure --prefix=$FFPREFIX           \
                    --enable-version3            \
                    --disable-static             \
                    --enable-shared              \
                    --disable-doc                \
                    --enable-avresample          \
                    --disable-pthreads           \
                    --enable-avisynth            \
                    --enable-libopencore-amrnb   \
                    --disable-decoder=amrnb      \
                    --enable-libopencore-amrwb   \
                    --disable-decoder=amrwb      \
                    --enable-libopenjpeg         \
                    --disable-decoder=jpeg2000   \
                    --enable-libopus             \
                    --disable-decoder=opus       \
                    --disable-parser=opus        \
                    --enable-libspeex            \
                    --enable-libvorbis           \
                    --disable-encoder=vorbis     \
                    --disable-decoder=vorbis     \
                    --enable-libvpx              \
                    --disable-decoder=libvpx_vp9 \
                    --disable-decoder=libvpx_vp8 \
                    --disable-outdev=sdl         \
                    ${_archopt}                  \
                    --disable-debug              \
                    --optflags="${BASE_CFLAGS}"  \
            > ${LOGS_DIR}/ffmpeg_config_${arch}.log 2>&1 || exit 1
        sed -i '/HAVE_CLOCK_GETTIME/d' config.h
        sed -i '/HAVE_NANOSLEEP/d' config.h
        echo "done"

        make clean > /dev/null 2>&1
        printf "===> making FFmpeg %s\n" $arch
        make -j9 -O > ${LOGS_DIR}/ffmpeg_make_${arch}.log 2>&1 || exit 1
        echo "done"

        printf "===> installing FFmpeg %s\n" $arch
        make install > ${LOGS_DIR}/ffmpeg_install_${arch}.log 2>&1 || exit 1
        if [ "${arch}" = "x86_64" ] ; then
            for bin in ${bin_list[@]}
            do
                ln -fs ${FFPREFIX}/bin/$bin /d/encode/tools
            done
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

if $all_build ; then
    build_sdl
    build_libopencore_amr
    build_openjpeg
    build_libspeex
    build_libvorbis
    build_libvpx
fi
build_ffmpeg

MINTTY=$mintty_save
export MINTTY

clear; echo "Everything has been successfully completed!"
