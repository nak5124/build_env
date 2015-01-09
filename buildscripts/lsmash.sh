#!/usr/bin/env bash


declare -a target_arch=(
    "x86_64"
    "i686"
)

for opt in "${@}"
do
    case "${opt}" in
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

declare -r PATCHES_DIR=${HOME}/patches/lsmash
declare -r LOGS_DIR=${HOME}/logs/lsmash
if [ ! -d $LOGS_DIR ]; then
    mkdir -p $LOGS_DIR
fi

function build_lsmash() {
    clear; echo "Build L-SMASH git-master"

    if [ ! -d ${HOME}/OSS/l-smash ]; then
        cd ${HOME}/OSS
        git clone https://github.com/l-smash/l-smash.git
    fi
    cd ${HOME}/OSS/l-smash

    git clean -fdx > /dev/null 2>&1
    git reset --hard > /dev/null 2>&1
    git pull > /dev/null 2>&1
    git_hash > ${LOGS_DIR}/lsmash.hash
    git_rev >> ${LOGS_DIR}/lsmash.hash

    local -r _LSMASH_API_VER=$(cat lsmash.h | grep "#define LSMASH_VERSION_MAJOR" | awk '{print $3}')
    local -ra _bin_list=(
        "muxer.exe"
        "remuxer.exe"
        "timelineeditor.exe"
        "boxdumper.exe"
        "liblsmash-${_LSMASH_API_VER}.dll"
    )

    patch -p1 -i ${PATCHES_DIR}/0000-build-Add-unix-version-script.patch > ${LOGS_DIR}/lsmash_patch.log 2>&1 || exit 1
    patch -p1 -i ${PATCHES_DIR}/0001-.gitignore-Add-version-script.patch >> ${LOGS_DIR}/lsmash_patch.log 2>&1 || exit 1
    patch -p1 -i ${PATCHES_DIR}/0002-configure-Check-whether-SRCDIR-is-git-repo-or-not.patch \
        >> ${LOGS_DIR}/lsmash_patch.log 2>&1 || exit 1
    patch -p1 -i ${PATCHES_DIR}/0003-configure-Add-api-version-to-mingw-shared-library-na.patch \
        >> ${LOGS_DIR}/lsmash_patch.log 2>&1 || exit 1
    patch -p1 -i ${PATCHES_DIR}/0004-build-Use-lib.exe-or-dlltool-when-available-on-mingw.patch \
        >> ${LOGS_DIR}/lsmash_patch.log 2>&1 || exit 1
    patch -p1 -i ${PATCHES_DIR}/0005-configure-If-shared-is-enabled-put-LIBS-on-Libs.priv.patch \
        >> ${LOGS_DIR}/lsmash_patch.log 2>&1 || exit 1
    patch -p1 -i ${PATCHES_DIR}/0006-Makefile-Move-.ver-from-clean-to-distclean.patch \
        >> ${LOGS_DIR}/lsmash_patch.log 2>&1 || exit 1
    patch -p1 -i ${PATCHES_DIR}/0007-build-Add-non-public-symbols-which-start-lsmash_-pre.patch \
        >> ${LOGS_DIR}/lsmash_patch.log 2>&1 || exit 1

    local _arch
    for _arch in ${target_arch[@]}
    do
        if [ "${_arch}" = "i686" ]; then
            local _LSPREFIX=/mingw32/local
            local _VCDIR=$VC32_DIR
        else
            local _LSPREFIX=/mingw64/local
            local _VCDIR=$VC64_DIR
        fi

        source cpath $_arch
        PATH=${PATH}:$_VCDIR
        export PATH

        printf "===> Configuring L-SMASH %s...\n" $_arch
        ./configure                                          \
            --prefix=$_LSPREFIX                              \
            --disable-static                                 \
            --enable-shared                                  \
            --extra-cflags="${BASE_CFLAGS} ${BASE_CPPFLAGS}" \
            --extra-ldflags="${BASE_CFLAGS} ${BASE_LDFLAGS}" \
            > ${LOGS_DIR}/lsmash_config_${_arch}.log 2>&1 || exit 1
        echo "done"

        make clean > /dev/null 2>&1
        printf "===> Making L-SMASH %s...\n" $_arch
        make -j9 -O > ${LOGS_DIR}/lsmash_make_${_arch}.log 2>&1 || exit 1
        echo "done"

        printf "===> Installing L-SMASH %s...\n" $_arch
        make install > ${LOGS_DIR}/lsmash_install_${_arch}.log 2>&1 || exit 1
        if [ "${_arch}" = "x86_64" ]; then
            local _bin
            for _bin in ${_bin_list[@]}
            do
                ln -fs ${_LSPREFIX}/bin/$_bin /d/encode/tools
            done
        fi
        echo "done"
        make distclean > /dev/null 2>&1
    done

    return 0
}

declare -r mintty_save=$MINTTY
unset MINTTY

build_lsmash

MINTTY=$mintty_save
export MINTTY

clear; echo "Everything has been successfully completed!"
