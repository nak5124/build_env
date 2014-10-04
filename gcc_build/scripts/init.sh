# init directories
function init_dirs() {
    clear; echo "init directories"

    # BUILD_DIR
    for (( i = 0; i < ${#BUILD_TARGETS[@]}; i++ ))
    do
        local -a target=(${BUILD_TARGETS[${i}]})
        if [ ${#target[*]} -gt 1 ] ; then
            for (( j = 1; j < ${#target[*]}; j++ ))
            do
                for arch in ${TARGET_ARCH[@]}
                do
                    if [ ! -d ${BUILD_DIR}/${target[0]}/${target[${j}]}/build_$arch ] ; then
                        mkdir -p ${BUILD_DIR}/${target[0]}/${target[${j}]}/build_$arch
                    fi
                done
                if [ "${target}" != "mingw-w64" ] ; then
                    if [ ! -d ${BUILD_DIR}/${target[0]}/${target[${j}]}/src ] ; then
                        mkdir -p ${BUILD_DIR}/${target[0]}/${target[${j}]}/src
                    fi
                fi
            done
            if [ "${target}" = "mingw-w64" ] ; then
                if [ ! -d ${BUILD_DIR}/${target}/src ] ; then
                    mkdir -p ${BUILD_DIR}/${target}/src
                fi
            fi
        else
            for arch in ${TARGET_ARCH[@]}
            do
                if [ ! -d ${BUILD_DIR}/${target}/build_$arch ] ; then
                    mkdir -p ${BUILD_DIR}/${target}/build_$arch
                fi
            done
            if [ ! -d ${BUILD_DIR}/${target}/src ] ; then
                mkdir -p ${BUILD_DIR}/${target}/src
            fi
        fi
    done

    # LOGS_DIR
    for (( i = 0; i < ${#BUILD_TARGETS[@]}; i++ ))
    do
        local -a target=(${BUILD_TARGETS[${i}]})
        if [ ${#target[*]} -gt 1 ] ; then
            for (( j = 1; j < ${#target[*]}; j++ ))
            do
                if [ ! -d ${LOGS_DIR}/${target[0]}/${target[${j}]} ] ; then
                    mkdir -p ${LOGS_DIR}/${target[0]}/${target[${j}]}
                fi
            done
        else
            if [ ! -d ${LOGS_DIR}/$target ] ; then
                mkdir -p ${LOGS_DIR}/$target
            fi
        fi
    done

    # PREIN_DIR
    for (( i = 0; i < ${#BUILD_TARGETS[@]}; i++ ))
    do
        local -a target=(${BUILD_TARGETS[${i}]})
        if [ ${#target[*]} -gt 1 ] ; then
            for (( j = 1; j < ${#target[*]}; j++ ))
            do
                if [ ! -d ${PREIN_DIR}/${target[0]}/${target[${j}]} ] ; then
                    mkdir -p ${PREIN_DIR}/${target[0]}/${target[${j}]}
                fi
            done
        else
            if [ ! -d ${PREIN_DIR}/$target ] ; then
                mkdir -p ${PREIN_DIR}/$target
            fi
            if [ "${target}" = "binutils" ] ; then
                if [ ! -d ${PREIN_DIR}/${target}_ld ] ; then
                    mkdir -p ${PREIN_DIR}/${target}_ld
                fi
            fi
        fi
    done

    # DST_DIR
    for arch in ${TARGET_ARCH[@]}
    do
        local bitval=$(get_arch_bit $arch)
        if [ -d ${DST_DIR}/mingw$bitval ] ; then
            rm -fr ${DST_DIR}/mingw$bitval
        fi
        mkdir -p ${DST_DIR}/mingw$bitval
    done

    cd $ROOT_DIR
    return 0
}
