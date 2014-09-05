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

# SDL
function build_sdl() {
    clear; echo "Build SDL"

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

    for arch in i686 x86_64
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
                    --disable-shared            \
                    --enable-static             \
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

# openjpeg-1.5
function build_openjpeg() {
    clear; echo "Build OpenJPEG"

    if [ ! -d ${HOME}/OSS/openjpeg-1.5 ] ; then
        cd ${HOME}/OSS
        svn checkout http://openjpeg.googlecode.com/svn/branches/openjpeg-1.5 openjpeg-1.5
    fi
    cd ${HOME}/OSS/openjpeg-1.5

    svn cleanup > /dev/null
    svn revert --recursive . > /dev/null
    svn update > /dev/null
    svnversion > ${LOGS_DIR}/openjpeg.hash

    autoreconf -fi > /dev/null 2>&1
    dos2unix libopenjpeg/opj_malloc.h > /dev/null

    for arch in i686 x86_64
    do
        if [ "${arch}" = "i686" ] ; then
            local FFPREFIX=/mingw32/local
        else
            local FFPREFIX=/mingw64/local
        fi

        source cpath $arch
        printf "===> configure OpenJPEG %s\n" $arch
        ./configure --prefix=$FFPREFIX                       \
                    --build=${arch}-w64-mingw32              \
                    --host=${arch}-w64-mingw32               \
                    --disable-silent-rules                   \
                    --disable-shared                         \
                    --enable-static                          \
                    --disable-doc                            \
                    --with-gnu-ld                            \
                    CPPFLAGS="${BASE_CPPFLAGS} -DOPJ_STATIC" \
                    CFLAGS="${BASE_CFLAGS}"                  \
                    LDFLAGS="${BASE_LDFLAGS}"                \
            > ${LOGS_DIR}/openjpeg_config_${arch}.log 2>&1 || exit 1
        echo "done"

        make clean > /dev/null 2>&1
        printf "===> making OpenJPEG %s\n" $arch
        make -j9 -O > ${LOGS_DIR}/openjpeg_make_${arch}.log 2>&1 || exit 1
        echo "done"

        printf "===> installing OpenJPEG %s\n" $arch
        make install-strip > ${LOGS_DIR}/openjpeg_install_${arch}.log 2>&1 || exit 1
        rm -fr ${FFPREFIX}/bin/*j2k*
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

    for arch in i686 x86_64
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
        ./configure --prefix=$FFPREFIX                   \
                    --target=$_target                    \
                    --disable-install-docs               \
                    --disable-examples                   \
                    --disable-docs                       \
                    --disable-unit-tests                 \
                    --enable-runtime-cpu-detect          \
                    --enable-multi-res-encoding          \
                    --enable-webm-io                     \
                    --enable-libyuv                      \
                    --extra-cflags="-fno-tree-vectorize" \
            > ${LOGS_DIR}/vpx_config_${arch}.log 2>&1 || exit 1
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

    for arch in i686 x86_64
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
                    --disable-shared                  \
                    --enable-static                   \
                    --enable-sse                      \
                    --with-gnu-ld                     \
                    --with-ogg                        \
                    CPPFLAGS="${BASE_CPPFLAGS}"       \
                    CFLAGS="${BASE_CFLAGS}"           \
                    LDFLAGS="${BASE_LDFLAGS} -lwinmm" \
            > ${LOGS_DIR}/speex_config_${arch}.log 2>&1 || exit 1
        echo "done"

        make clean > /dev/null 2>&1
        printf "===> making libspeex %s\n" $arch
        make -j9 -O > ${LOGS_DIR}/speex_make_${arch}.log 2>&1 || exit 1
        echo "done"

        printf "===> installing libspeex %s\n" $arch
        make install-strip > ${LOGS_DIR}/speex_install_${arch}.log 2>&1 || exit 1
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

    for arch in i686 x86_64
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
                    --disable-shared            \
                    --enable-static             \
                    CFLAGS="${BASE_CFLAGS}"     \
                    CPPFLAGS="${BASE_CPPFLAGS}" \
                    CXXFLAGS="${BASE_CXXFLAGS}" \
                    LDFLAGS="${BASE_LDFLAGS}"   \
            > ${LOGS_DIR}/opencore-amr_config_${arch}.log 2>&1 || exit 1
        sed -i 's/#define HAVE_PTHREAD_H 1/#define HAVE_PTHREAD_H 0/' vpx_config.h
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

    patch_ffmpeg

    for arch in i686 x86_64
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
        PATH=${VCDIR}:$PATH
        export PATH

        printf "===> configure FFmpeg %s\n" $arch
        ./configure --prefix=$FFPREFIX                       \
                    --enable-version3                        \
                    --enable-shared                          \
                    --disable-doc                            \
                    --enable-avresample                      \
                    --disable-pthreads                       \
                    --enable-avisynth                        \
                    --enable-libopencore-amrnb               \
                    --disable-decoder=amrnb                  \
                    --enable-libopencore-amrwb               \
                    --disable-decoder=amrwb                  \
                    --enable-libopenjpeg                     \
                    --disable-decoder=jpeg2000               \
                    --enable-libopus                         \
                    --disable-decoder=opus                   \
                    --disable-parser=opus                    \
                    --enable-libspeex                        \
                    --enable-libvpx                          \
                    --disable-decoder=libvpx_vp9             \
                    --disable-decoder=libvpx_vp8             \
                    --disable-outdev=sdl                     \
                    ${_archopt}                              \
                    --disable-debug                          \
                    --extra-cflags="-fexcess-precision=fast" \
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
        echo "done"
        make distclean > /dev/null 2>&1
    done

    return 0
}

if $all_build ; then
    build_sdl
    build_openjpeg
    build_libvpx
    build_libspeex
    build_libopencore_amr
fi
build_ffmpeg

clear; echo "Everything has been successfully completed!"
