#!/usr/bin/env bash


declare -a target_arch=(
    "x86_64"
    "i686"
)

for opt in "$@"
do
    case "${opt}" in
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

declare -r PATCHES_DIR=${HOME}/patches/lsmash
declare -r LOGS_DIR=${HOME}/logs/lsmash
if [ ! -d $LOGS_DIR ] ; then
    mkdir -p $LOGS_DIR
fi

function build_lsmash() {
    clear; echo "Build L-SMASH git-master"

    if [ ! -d ${HOME}/OSS/l-smash ] ; then
        cd ${HOME}/OSS
        git clone https://github.com/l-smash/l-smash.git
    fi
    cd ${HOME}/OSS/l-smash

    git clean -fdx > /dev/null 2>&1
    git reset --hard > /dev/null 2>&1
    git pull > /dev/null 2>&1
    git_hash > ${LOGS_DIR}/lsmash.hash
    git_rev >> ${LOGS_DIR}/lsmash.hash

    local -r LSMASH_API_VER=$(echo $(cat lsmash.h | grep "#define LSMASH_VERSION_MAJOR" | awk '{print $3}'))
    local -ra bin_list=(
        "muxer.exe"
        "remuxer.exe"
        "timelineeditor.exe"
        "boxdumper.exe"
        "liblsmash-${LSMASH_API_VER}.dll"
    )

    patch -p1 -i ${PATCHES_DIR}/0001-configure-Check-whether-SRCDIR-is-git-repo-or-not.patch \
        > ${LOGS_DIR}/lsmash_patch.log 2>&1 || exit 1
    patch -p1 -i ${PATCHES_DIR}/0002-configure-Add-api-version-to-mingw-shared-library-na.patch \
        >> ${LOGS_DIR}/lsmash_patch.log 2>&1 || exit 1
    patch -p1 -i ${PATCHES_DIR}/0003-build-Use-lib.exe-when-it-is-available-on-mingw.patch \
        >> ${LOGS_DIR}/lsmash_patch.log 2>&1 || exit 1

    for arch in ${target_arch[@]}
    do
        if [ "${arch}" = "i686" ] ; then
            local LSPREFIX=/mingw32/local
            local LIBTARGET=i386
            local VCDIR=$VC32_DIR
        else
            local LSPREFIX=/mingw64/local
            local LIBTARGET=x64
            local VCDIR=$VC64_DIR
        fi

        source cpath $arch
        PATH=${PATH}:$VCDIR
        export PATH

        printf "===> configure L-SMASH %s\n" $arch
        ./configure --prefix=$LSPREFIX             \
                    --disable-static               \
                    --enable-shared                \
                    --extra-ldflags=-static-libgcc \
            > ${LOGS_DIR}/lsmash_config_${arch}.log 2>&1 || exit 1
        echo "done"

        make clean > /dev/null 2>&1
        printf "===> making L-SMASH %s\n" $arch
        make -j9 -O > ${LOGS_DIR}/lsmash_make_${arch}.log 2>&1 || exit 1
        dos2unix lsmash-1.def > /dev/null 2>&1
        echo "done"

        printf "===> installing L-SMASH %s\n" $arch
        make install > ${LOGS_DIR}/lsmash_install_${arch}.log 2>&1 || exit 1
        if [ "${arch}" = "x86_64" ] ; then
            for bin in ${bin_list[@]}
            do
                ln -fs ${LSPREFIX}/bin/$bin /d/encode/tools
            done
        fi
        echo "done"
        make distclean > /dev/null 2>&1
    done

    return 0
}

unset MINTTY
declare -r mintty_save=$MINTTY

build_lsmash

MINTTY=$mintty_save
export MINTTY

clear; echo "Everything has been successfully completed!"
