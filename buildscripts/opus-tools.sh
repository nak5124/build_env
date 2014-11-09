#!/usr/bin/env bash


declare all_build=false
declare -a target_arch=(
    "x86_64"
    "i686"
)

for opt in "$@"
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

declare -r PATCHES_DIR=${HOME}/patches/opus-tools
declare -r LOGS_DIR=${HOME}/logs/opus-tools
if [ ! -d $LOGS_DIR ]; then
    mkdir -p $LOGS_DIR
fi

# libopus
function build_libopus() {
    clear; echo "Build libopus git-master"

    if [ ! -d ${HOME}/OSS/xiph/opus ]; then
        cd ${HOME}/OSS/xiph
        git clone git://git.xiph.org/opus.git
    fi
    cd ${HOME}/OSS/xiph/opus

    git clean -fdx > /dev/null 2>&1
    git reset --hard > /dev/null 2>&1
    git pull > /dev/null 2>&1
    git_hash > ${LOGS_DIR}/opus.hash
    git_rev >> ${LOGS_DIR}/opus.hash

    autoreconf -fi > /dev/null 2>&1

    patch -p1 < ${PATCHES_DIR}/0001-correctly-detect-alloca.mingw.patch > ${LOGS_DIR}/opus_patch.log 2>&1 || exit 1
    patch -p1 < ${PATCHES_DIR}/version.patch >> ${LOGS_DIR}/opus_patch.log 2>&1 || exit 1

    local _arch
    for _arch in ${target_arch[@]}
    do
        source cpath $_arch

        if [ "${_arch}" = "i686" ]; then
            local _OPPREFIX=/mingw32/local
        else
            local _OPPREFIX=/mingw64/local
        fi

        printf "===> Configuring libopus %s...\n" $_arch
        ./configure --prefix=$_OPPREFIX          \
                    --build=${_arch}-w64-mingw32 \
                    --host=${_arch}-w64-mingw32  \
                    --disable-silent-rules       \
                    --enable-shared              \
                    --disable-static             \
                    --enable-fast-install        \
                    --disable-doc                \
                    --disable-extra-programs     \
                    --with-gnu-ld                \
                    CFLAGS="${BASE_CFLAGS}"      \
                    LDFLAGS="${BASE_LDFLAGS}"    \
                    CPPFLAGS="${BASE_CPPFLAGS}"  \
            > ${LOGS_DIR}/opus_config_${_arch}.log 2>&1 || exit 1
        echo "done"

        make clean > /dev/null 2>&1
        printf "===> Making libopus %s...\n" $_arch
        make -j9 -O > ${LOGS_DIR}/opus_make_${_arch}.log 2>&1 || exit 1
        echo "done"

        printf "===> Installing libopus %s...\n" $_arch
        make install-strip > ${LOGS_DIR}/opus_install_${_arch}.log 2>&1 || exit 1
        rm -f ${_OPPREFIX}/lib/libopus.la
        echo "done"
        make distclean > /dev/null 2>&1
    done

    return 0
}

# opus-tools
function build_tools() {
    clear; echo "Build opus-tools git-master"

    if [ ! -d ${HOME}/OSS/xiph/opus-tools ]; then
        cd ${HOME}/OSS/xiph
        git clone git://git.xiph.org/opus-tools.git
    fi
    cd ${HOME}/OSS/xiph/opus-tools

    git clean -fdx > /dev/null 2>&1
    git reset --hard > /dev/null 2>&1
    git pull > /dev/null 2>&1
    git_hash > ${LOGS_DIR}/tools.hash
    git_rev >> ${LOGS_DIR}/tools.hash

    local -ra _bin_list=(
        "opusenc.exe"
        "opusdec.exe"
        "opusinfo.exe"
        "libopus-0.dll"
    )

    ./autogen.sh > /dev/null 2>&1

    patch -p1 < ${PATCHES_DIR}/version_tools.patch > ${LOGS_DIR}/tools_patch.log 2>&1 || exit 1

    local _arch
    for _arch in ${target_arch[@]}
    do
        source cpath $_arch

        if [ "${_arch}" = "i686" ]; then
            local _OPPREFIX=/mingw32/local
        else
            local _OPPREFIX=/mingw64/local
        fi

        printf "===> Configuring opus-tools %s...\n" $_arch
        ./configure --prefix=$_OPPREFIX          \
                    --build=${_arch}-w64-mingw32 \
                    --host=${_arch}-w64-mingw32  \
                    --disable-silent-rules       \
                    --enable-sse                 \
                    CFLAGS="${BASE_CFLAGS}"      \
                    LDFLAGS="${BASE_LDFLAGS}"    \
                    CPPFLAGS="${BASE_CPPFLAGS}"  \
            > ${LOGS_DIR}/tools_config_${_arch}.log 2>&1 || exit 1
        echo "done"

        make clean > /dev/null 2>&1
        printf "===> Making opus-tools %s...\n" $_arch
        make -j9 -O > ${LOGS_DIR}/tools_make_${_arch}.log 2>&1 || exit 1
        echo "done"

        printf "===> Installing opus-tools %s...\n" $_arch
        make install-strip > ${LOGS_DIR}/tools_install_${_arch}.log 2>&1 || exit 1
        if [ "${_arch}" = "x86_64" ]; then
            local _bin
            for _bin in ${_bin_list[@]}
            do
                ln -fs ${_OPPREFIX}/bin/$_bin /d/encode/tools
            done
        fi
        echo "done"
        make distclean > /dev/null 2>&1
    done

    return 0
}

declare -r mintty_save=$MINTTY
unset MINTTY

if ${all_build}; then
    build_libopus
fi
build_tools

MINTTY=$mintty_save
export MINTTY

clear; echo "Everything has been successfully completed!"
