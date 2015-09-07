# init directories
function init_dirs() {
    clear; echo 'init directories'

    local -i _i
    local -i _j
    local -a _target
    local    _arch

    # BUILD_DIR
    for(( _i = 0; _i < ${#BUILD_TARGETS[@]}; _i++ ))
    do
        _target=(${BUILD_TARGETS[${_i}]})
        if [ ${#_target[*]} -gt 1 ]; then
            for(( _j = 1; _j < ${#_target[*]}; _j++ ))
            do
                for _arch in ${TARGET_ARCH[@]}
                do
                    if [ ! -d "${BUILD_DIR}"/${_target[0]}/${_target[${_j}]}/build_$_arch ]; then
                        mkdir -p "${BUILD_DIR}"/${_target[0]}/${_target[${_j}]}/build_$_arch
                    fi
                done
                if [ "${_target}" != 'mingw-w64' ]; then
                    if [ ! -d "${BUILD_DIR}"/${_target[0]}/${_target[${_j}]}/src ]; then
                        mkdir -p "${BUILD_DIR}"/${_target[0]}/${_target[${_j}]}/src
                    fi
                fi
            done
            if [ "${_target}" = 'mingw-w64' ]; then
                if [ ! -d "${BUILD_DIR}"/${_target}/src ]; then
                    mkdir -p "${BUILD_DIR}"/${_target}/src
                fi
            fi
        else
            for _arch in ${TARGET_ARCH[@]}
            do
                if [ ! -d "${BUILD_DIR}"/${_target}/build_$_arch ]; then
                    mkdir -p "${BUILD_DIR}"/${_target}/build_$_arch
                fi
            done
            if [ ! -d "${BUILD_DIR}"/${_target}/src ]; then
                mkdir -p "${BUILD_DIR}"/${_target}/src
            fi
        fi
        if [ ! -d "${BUILD_DIR}"/autotools/config/src ]; then
            mkdir -p "${BUILD_DIR}"/autotools/config/src
        fi
    done

    # LOGS_DIR
    for(( _i = 0; _i < ${#BUILD_TARGETS[@]}; _i++ ))
    do
        _target=(${BUILD_TARGETS[${_i}]})
        if [ ${#_target[*]} -gt 1 ]; then
            for(( _j = 1; _j < ${#_target[*]}; _j++ ))
            do
                if [ ! -d "${LOGS_DIR}"/${_target[0]}/${_target[${_j}]} ]; then
                    mkdir -p "${LOGS_DIR}"/${_target[0]}/${_target[${_j}]}
                fi
            done
        else
            if [ ! -d "${LOGS_DIR}"/$_target ]; then
                mkdir -p "${LOGS_DIR}"/$_target
            fi
        fi
    done

    # PREIN_DIR
    for(( _i = 0; _i < ${#BUILD_TARGETS[@]}; _i++ ))
    do
        _target=(${BUILD_TARGETS[${_i}]})
        if [ ${#_target[*]} -gt 1 ]; then
            for(( _j = 1; _j < ${#_target[*]}; _j++ ))
            do
                if [ ! -d "${PREIN_DIR}"/${_target[0]}/${_target[${_j}]} ]; then
                    mkdir -p "${PREIN_DIR}"/${_target[0]}/${_target[${_j}]}
                fi
            done
        else
            if [ ! -d "${PREIN_DIR}"/$_target ]; then
                mkdir -p "${PREIN_DIR}"/$_target
            fi
            if [ "${_target}" = 'binutils' ]; then
                if [ ! -d "${PREIN_DIR}"/${_target}_ld ]; then
                    mkdir -p "${PREIN_DIR}"/${_target}_ld
                fi
            fi
        fi
    done
    if ${use_win_iconv}; then
        if [ ! -d "${PREIN_DIR}"/win-iconv ]; then
            mkdir -p "${PREIN_DIR}"/win-iconv
        fi
    fi

    # DST_DIR
    local _bitval
    for _arch in ${TARGET_ARCH[@]}
    do
        _bitval=$(get_arch_bit ${_arch})
        if [ -d "${DST_DIR}"/mingw$_bitval ]; then
            rm -fr "${DST_DIR}"/mingw$_bitval
        fi
        mkdir -p "${DST_DIR}"/mingw$_bitval
    done

    cd "${ROOT_DIR}"
    return 0
}
