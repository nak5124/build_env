# Set PATH
function set_path() {
    # $1: arch

    local -r _arch=${1}

    local -r _bitval=$(get_arch_bit ${_arch})

    # PATH exporting.
    source cpath $_arch
    PATH="${DST_DIR}"/mingw${_bitval}/bin:"${PATH}"
    export PATH
}

function set_path2() {
    # $1: arch

    local -r _arch=${1}

    local -r _bitval=$(get_arch_bit ${_arch})

    # PATH exporting.
    source cpath $_arch
    PATH="${DST_DIR}"/mingw${_bitval}/bin:"${PATH}"
    export PATH

    # Use the new GCC.
    CC="${DST_DIR}"/mingw${_bitval}/bin/gcc-${GCC_VER/-*}
    CPP="${DST_DIR}"/mingw${_bitval}/bin/cpp-${GCC_VER/-*}
    CXX="${DST_DIR}"/mingw${_bitval}/bin/g++-${GCC_VER/-*}
    export CC CPP CXX
}

function set_path3() {
    # $1: arch

    local -r _arch=${1}

    local -r _bitval=$(get_arch_bit ${_arch})

    # PATH exporting.
    source cpath $_arch
    PATH="${DST_DIR}"/mingw${_bitval}/bin:/usr/local/bin:/usr/bin
    export PATH

    # Use the new GCC.
    CC="${DST_DIR}"/mingw${_bitval}/bin/gcc-${GCC_VER/-*}
    CPP="${DST_DIR}"/mingw${_bitval}/bin/cpp-${GCC_VER/-*}
    CXX="${DST_DIR}"/mingw${_bitval}/bin/g++-${GCC_VER/-*}
    export CC CPP CXX
}

# config
function replace_config() {
    clear; echo 'Replace configs with newer ones.'

    # Git clone.
    if [ ! -d "${BUILD_DIR}"/autotools/config/src/config ]; then
        echo '===> Cloning config git repo...'
        pushd "${BUILD_DIR}"/autotools/config/src > /dev/null
        dl_files git git://git.sv.gnu.org/config.git
        popd > /dev/null # "${BUILD_DIR}"/autotools/config/src
        echo 'done'
    fi

    # Git pull.
    echo '===> Updating config git repo...'
    cd "${BUILD_DIR}"/autotools/config/src/config
    git clean -fdx > /dev/null 2>&1
    git reset --hard > /dev/null 2>&1
    git pull > /dev/null 2>&1
    echo 'done'

    # Replace.
    echo '===> Copy newer configs...'
    local _arch
    for _arch in ${TARGET_ARCH[@]}
    do
        local _bitval=$(get_arch_bit ${_arch})

        cp -af "${BUILD_DIR}"/autotools/config/src/config/config.{guess,sub} \
            "${DST_DIR}"/mingw${_bitval}/share/libtool/build-aux
        cp -af "${BUILD_DIR}"/autotools/config/src/config/config.{guess,sub} \
            "${DST_DIR}"/mingw${_bitval}/share/automake-$AUTOMAKE_VER
    done
    echo 'done'

    cd "${ROOT_DIR}"
    return 0
}
