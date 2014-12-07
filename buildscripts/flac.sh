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

declare -r PATCHES_DIR=${HOME}/patches/flac
declare -r LOGS_DIR=${HOME}/logs/flac
if [ ! -d $LOGS_DIR ]; then
    mkdir -p $LOGS_DIR
fi

# libogg
function build_libogg() {
    clear; echo "Build libogg svn-trunk"

    if [ ! -d ${HOME}/OSS/xiph/ogg ]; then
        cd ${HOME}/OSS/xiph
        # git clone git://git.xiph.org/mirrors/ogg.git
        svn co http://svn.xiph.org/trunk/ogg
    fi
    cd ${HOME}/OSS/xiph/ogg

    # git clean -fdx > /dev/null 2>&1
    # git reset --hard > /dev/null 2>&1
    # git pull > /dev/null 2>&1
    # git_hash > ${LOGS_DIR}/ogg.hash
    # git_rev >> ${LOGS_DIR}/ogg.hash
    svn cleanup > /dev/null
    svn revert --recursive . > /dev/null
    svn update > /dev/null
    svnversion > ${LOGS_DIR}/ogg.hash

    autoreconf -fi > /dev/null 2>&1

    local _arch
    for _arch in ${target_arch[@]}
    do
        source cpath $_arch

        if [ "${_arch}" = "i686" ]; then
            local _FLPREFIX=/mingw32/local
        else
            local _FLPREFIX=/mingw64/local
        fi

        printf "===> Configuring libogg %s...\n" $_arch
        ./configure                      \
            --prefix=$_FLPREFIX          \
            --build=${_arch}-w64-mingw32 \
            --host=${_arch}-w64-mingw32  \
            --disable-silent-rules       \
            --enable-shared              \
            --disable-static             \
            --enable-fast-install        \
            --with-gnu-ld                \
            CFLAGS="${BASE_CFLAGS}"      \
            LDFLAGS="${BASE_LDFLAGS}"    \
            CPPFLAGS="${BASE_CPPFLAGS}"  \
            > ${LOGS_DIR}/ogg_config_${_arch}.log 2>&1 || exit 1
        echo "done"

        make clean > /dev/null 2>&1
        printf "===> Making libogg %s...\n" $_arch
        make -j9 -O > ${LOGS_DIR}/ogg_make_${_arch}.log 2>&1 || exit 1
        echo "done"

        printf "===> Installing libogg %s...\n" $_arch
        make install-strip > ${LOGS_DIR}/ogg_install_${_arch}.log 2>&1 || exit 1
        rm -f ${_FLPREFIX}/lib/libogg.la
        echo "done"
        make distclean > /dev/null 2>&1
    done

    return 0
}

# FLAC
function build_flac() {
    clear; echo "Build flac git-master"

    if [ ! -d ${HOME}/OSS/xiph/flac ]; then
        cd ${HOME}/OSS/xiph
        git clone git://git.xiph.org/flac.git
    fi
    cd ${HOME}/OSS/xiph/flac

    git clean -fdx > /dev/null 2>&1
    git reset --hard > /dev/null 2>&1
    git pull > /dev/null 2>&1
    git_hash > ${LOGS_DIR}/flac.hash
    git_rev >> ${LOGS_DIR}/flac.hash

    local -ra _bin_list=(
        "flac.exe"
        "metaflac.exe"
        "libFLAC-8.dll"
        "libogg-0.dll"
    )

    touch config.rpath
    autoreconf -fi > /dev/null 2>&1

    local _arch
    for _arch in ${target_arch[@]}
    do
        source cpath $_arch

        if [ "${_arch}" = "i686" ]; then
            local _FLPREFIX=/mingw32/local
            local _MINGW_PREFIX=/mingw32
        else
            local _FLPREFIX=/mingw64/local
            local _MINGW_PREFIX=/mingw64
        fi

        printf "===> Configuring flac %s...\n" $_arch
        ./configure                               \
            --prefix=$_FLPREFIX                   \
            --build=${_arch}-w64-mingw32          \
            --host=${_arch}-w64-mingw32           \
            --disable-silent-rules                \
            --disable-static                      \
            --enable-shared                       \
            --enable-fast-install                 \
            --disable-doxygen-docs                \
            --disable-xmms-plugin                 \
            --disable-cpplibs                     \
            --disable-rpath                       \
            --with-gnu-ld                         \
            --with-ogg=$_FLPREFIX                 \
            --with-libiconv-prefix=$_MINGW_PREFIX \
            CFLAGS="${BASE_CFLAGS}"               \
            LDFLAGS="${BASE_LDFLAGS}"             \
            CPPFLAGS="${BASE_CPPFLAGS}"           \
            CXXFLAGS="${BASE_CXXFLAGS}"           \
            > ${LOGS_DIR}/flac_config_${_arch}.log 2>&1 || exit 1
        echo "done"

        make clean > /dev/null 2>&1
        printf "===> Making flac %s...\n" $_arch
        make -j9 -O > ${LOGS_DIR}/flac_make_${_arch}.log 2>&1 || exit 1
        echo "done"

        printf "===> Installing flac %s...\n" $_arch
        make install-strip > ${LOGS_DIR}/flac_install_${_arch}.log 2>&1 || exit 1
        rm -f ${_FLPREFIX}/lib/libFLAC.la
        if [ "${_arch}" = "x86_64" ]; then
            local _bin
            for _bin in ${_bin_list[@]}
            do
                ln -fs ${_FLPREFIX}/bin/$_bin /d/encode/tools
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
    build_libogg
fi
build_flac

MINTTY=$mintty_save
export MINTTY

clear; echo "Everything has been successfully completed!"
