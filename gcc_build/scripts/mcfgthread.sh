# mcfgthread: A Gthread implementation for Windows suitable for porting gcc and its libraries.
# Clone git repo and git pull
function prepare_mcfgthread() {
    # Git clone.
    if [ ! -d "${BUILD_DIR}"/mcfgthread/src/mcfgthread-$MCFGTHREAD_VER ]; then
        echo '===> Cloning mcfgthread git repo...'
        pushd "${BUILD_DIR}"/mcfgthread/src > /dev/null
        dl_files git https://github.com/lhmouse/mcfgthread.git mcfgthread-$MCFGTHREAD_VER
        popd > /dev/null # "${BUILD_DIR}"/mcfgthread/src
        echo 'done'
    fi

    # Git pull.
    echo '===> Updating mcfgthread git-repo...'
    pushd "${BUILD_DIR}"/mcfgthread/src/mcfgthread-$MCFGTHREAD_VER > /dev/null
    git clean -fdx > /dev/null 2>&1
    git reset --hard > /dev/null 2>&1
    git pull > /dev/null 2>&1
    git log -1 --format="%h" > "${LOGS_DIR}"/mcfgthread/mcfgthread.hash 2>&1
    git rev-list HEAD | wc -l >> "${LOGS_DIR}"/mcfgthread/mcfgthread.hash 2>&1
    echo 'done'

    # Use msvcr120.dll.
    sed -i 's/msvcrt/msvcr120/g' "${BUILD_DIR}"/mcfgthread/src/mcfgthread-${MCFGTHREAD_VER}/Makefile.am

    # Autoreconf.
    printf "===> Autoreconfing mcfgthread %s...\n" "${MCFGTHREAD_VER}"
    mkdir m4
    autoreconf -fis > /dev/null 2>&1
    popd > /dev/null # "${BUILD_DIR}"/mcfgthread/src/mcfgthread-$MCFGTHREAD_VER
    echo 'done'

    return 0
}

# Build and install.
function build_mcfgthread() {
    clear; printf "Build mcfgthread %s\n" "${MCFGTHREAD_VER}"

    # Option handling.
    local _rebuild=true
    local _2nd_build=false

    local _opt
    for _opt in "${@}"
    do
        case "${_opt}" in
            --rebuild=* )
                _rebuild=${_opt#*=}
                ;;
            --2nd )
                _2nd_build=true
                ;;
            * )
                printf "build_mcfgthread: Unknown Option: '%s'\n" "${_opt}"
                echo '...exit'
                exit 1
                ;;
        esac
    done

    # Setup.
    if ${_rebuild}; then
        prepare_mcfgthread
    fi

    local _arch
    for _arch in ${TARGET_ARCH[@]}
    do
        local _bitval=$(get_arch_bit ${_arch})

        if ${_rebuild}; then
            cd "${BUILD_DIR}"/mcfgthread/build_$_arch
            # Cleanup the build dir.
            rm -fr "${BUILD_DIR}"/mcfgthread/build_${_arch}/*

            # PATH exporting.
            if ${_2nd_build}; then
                # Use the new GCC for 2nd build.
                set_path2 $_arch
            else
                set_path $_arch
            fi

            # Configure.
            printf "===> Configuring mcfgthread %s...\n" "${_arch}"
            ../src/mcfgthread-${MCFGTHREAD_VER}/configure \
                --prefix=/mingw$_bitval                   \
                --build=${_arch}-w64-mingw32              \
                --host=${_arch}-w64-mingw32               \
                --enable-shared                           \
                --disable-static                          \
                --enable-fast-install                     \
                --disable-silent-rules                    \
                CFLAGS="${CFLAGS_}"                       \
                LDFLAGS="${LDFLAGS_}"                     \
                CPPFLAGS="${CPPFLAGS_}"                   \
                > "${LOGS_DIR}"/mcfgthread/mcfgthread_config_${_arch}.log 2>&1 || exit 1
            echo 'done'

            # Make.
            printf "===> Making mcfgthread %s...\n" "${_arch}"
            make $MAKEFLAGS_ > "${LOGS_DIR}"/mcfgthread/mcfgthread_make_${_arch}.log 2>&1 || exit 1
            echo 'done'

            # Install.
            printf "===> Installing mcfgthread %s...\n" "${_arch}"
            rm -fr "${PREIN_DIR}"/mcfgthread/mingw${_bitval}/*
            make DESTDIR="${PREIN_DIR}"/mcfgthread install \
                > "${LOGS_DIR}"/mcfgthread/mcfgthread_install_${_arch}.log 2>&1 || exit 1
            # Remove unneeded files.
            rm -f  "${PREIN_DIR}"/mcfgthread/mingw${_bitval}/lib/libmcfgthread.la
            remove_la_files "${PREIN_DIR}"/mcfgthread/mingw$_bitval
            # Strip files.
            strip_files "${PREIN_DIR}"/mcfgthread/mingw$_bitval
            echo 'done'
        fi

        if ! ( ! ${_rebuild} && ${_2nd_build} ); then
            # Copy to DST_DIR.
            printf "===> Copying mcfgthread %s to %s/mingw%s...\n" "${_arch}" "${DST_DIR}" "${_bitval}"
            cp -af "${PREIN_DIR}"/mcfgthread/mingw$_bitval "${DST_DIR}"
            echo 'done'
            # Create symlinks.
            if ${create_symlinks:-false}; then
                printf "===> Creating symlinks %s...\n" "${_arch}"
                pushd "${DST_DIR}"/mingw${_bitval}/lib > /dev/null
                ln -fs libmcfgthread.dll.a libmcfgthread.a
                popd > /dev/null
                echo 'done'
            fi
        fi
    done

    cd "${ROOT_DIR}"
    return 0
}
