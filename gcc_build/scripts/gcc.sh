# GCC: The GNU Compiler Collection
# Download the src and decompress it.
function download_gcc_src() {
    # Download the src.
    if [ ! -f "${BUILD_DIR}"/gcc/src/gcc-${GCC_VER}.tar.bz2 ]; then
        printf "===> Downloading GCC %s...\n" "${GCC_VER}"
        pushd "${BUILD_DIR}"/gcc/src > /dev/null
        if [ $(echo $GCC_VER | grep RC) ]; then
            dl_files ftp ftp://gcc.gnu.org/pub/gcc/snapshots/${GCC_VER}/gcc-${GCC_VER}.tar.bz2
        else
            dl_files ftp ftp://gcc.gnu.org/pub/gcc/releases/gcc-${GCC_VER}/gcc-${GCC_VER}.tar.bz2
        fi
        popd > /dev/null # "${BUILD_DIR}"/gcc/src
        echo 'done'
    fi

    # Decompress the src archive.
    if [ ! -d "${BUILD_DIR}"/gcc/src/gcc-$GCC_VER ]; then
        printf "===> Extracting GCC %s...\n" "${GCC_VER}"
        pushd "${BUILD_DIR}"/gcc/src > /dev/null
        decomp_arch "${BUILD_DIR}"/gcc/src/gcc-${GCC_VER}.tar.bz2
        popd > /dev/null # "${BUILD_DIR}"/gcc/src
        echo 'done'
    fi

    return 0
}

# Apply patches.
function apply_patch_gcc() {
    apply_patch "${1}" "${BUILD_DIR}"/gcc/src/gcc-$GCC_VER "${LOGS_DIR}"/gcc/gcc_patch.log "${2}"
}

function prepare_gcc() {
    # Apply patches.
    printf "===> Applying patches to GCC %s...\n" "${GCC_VER}"

    # hack! - some configure tests for header files using "$CPP $CPPFLAGS"
    apply_patch_gcc "${PATCHES_DIR}"/gcc/0001-libiberty-gcc-configure-hack-some-configure-tests-fo.patch true
    # MinGW-w64 does not support Linux system call.
    apply_patch_gcc "${PATCHES_DIR}"/gcc/0002-libiberty-Modify-Makefile-for-mingw-w64.patch              false
    # Do not install libiberty.
    apply_patch_gcc "${PATCHES_DIR}"/gcc/0003-libiberty-Makefile.in-Don-t-install-libiberty.patch        false
    # For the consideration of whether folder "/doesnt-exist/.." is a valid.
    apply_patch_gcc "${PATCHES_DIR}"/gcc/0004-Windows-Follow-Posix-dir-exists-semantics-more-close.patch false
    # '\' => '/'
    apply_patch_gcc "${PATCHES_DIR}"/gcc/0005-Windows-Use-not-in-progpath-and-leave-case-as-is.patch     false
    # -mcrtdll
    apply_patch_gcc "${PATCHES_DIR}"/gcc/0006-Windows-New-feature-to-allow-overriding-lmsvcrt.patch      false
    # PR14940 (https://gcc.gnu.org/bugzilla/show_bug.cgi?id=14940).
    apply_patch_gcc "${PATCHES_DIR}"/gcc/0007-Fix-using-large-PCH.patch                                  false
    # Fix clone_function_name stdcall suffix handling.
    apply_patch_gcc "${PATCHES_DIR}"/gcc/0008-clone_function_name_1-Retain-any-stdcall-suffix.patch      false
    #
    apply_patch_gcc "${PATCHES_DIR}"/gcc/0009-gcc-make-xmmintrin-header-cplusplus-compatible-depre.patch false
    # Add /mingw{32,64}/local/{include,lib} to search dirs, and make relocatable perfectly.
    apply_patch_gcc "${PATCHES_DIR}"/gcc/0010-Add-mingw-32-64-local-include-lib-to-search-dirs-and.patch false
    # Don't search dirs under ${prefix} but ${build_sysroot}.
    apply_patch_gcc "${PATCHES_DIR}"/gcc/0011-configure-Search-dirs-under-build_sysroot-instead-of.patch false
    # When binutils's prefix == tooldir, gcc -print-prog-name=ld returns correct result.
    apply_patch_gcc "${PATCHES_DIR}"/gcc/0012-gcc-Add-prefix-bindir-to-exec_prefix.patch                 false
    # Dynamically linking to libiconv.
    apply_patch_gcc "${PATCHES_DIR}"/gcc/0013-mingw-Dynamically-linking-to-libiconv.patch                false
    # when building executables, not DLLs. Add --large-address-aware and --tsaware.
    apply_patch_gcc "${PATCHES_DIR}"/gcc/0014-MinGW-w64-When-building-executables-not-DLLs-add-lar.patch false
    # Enable nxcompat and (HE)ASLR by default.
    apply_patch_gcc "${PATCHES_DIR}"/gcc/0015-MinGW-w64-Enable-nxcompat-and-HE-ASLR-by-default.patch     false
    # Disable automatic image base calculation.
    apply_patch_gcc "${PATCHES_DIR}"/gcc/0016-MinGW-w64-Disable-automatic-image-base-calculation.patch   false
    # Shut up GCC -Wformat.
    apply_patch_gcc "${PATCHES_DIR}"/gcc/0017-MinGW-w64-Use-__MINGW_PRINTF_FORMAT-for-__USE_MINGW_.patch false
    # https://bugs.debian.org/cgi-bin/bugreport.cgi?bug=792909
    apply_patch_gcc "${PATCHES_DIR}"/gcc/0018-MinGW-w64-Fix-SPEC_PTHREAD2-definition.patch               false
    # Enable colorizing diagnostics.
    apply_patch_gcc "${PATCHES_DIR}"/gcc/0019-gcc-diagnostic-color.c-Enable-color-diagnostic-on-Wi.patch false
    # __MSVCRT_VERSION__
    apply_patch_gcc "${PATCHES_DIR}"/gcc/0020-MinGW-w64-Define-__MSVCRT_VERSION__.patch                  false
    # PR52991 (https://gcc.gnu.org/bugzilla/show_bug.cgi?id=52991).
    apply_patch_gcc "${PATCHES_DIR}"/gcc/0021-Fix-issue-about-record-union-attribute-packed-for-ms.patch false
    # Remove #define stat _stat ...
    apply_patch_gcc "${PATCHES_DIR}"/gcc/0022-ltmain.sh-Remove-useless-defines.patch                     false
    # Thread model: mcf
    apply_patch_gcc "${PATCHES_DIR}"/gcc/0023-Added-mcf-thread-model-support-from-mcfgthread.patch       false
    # Fix bootstrap
    apply_patch_gcc "${PATCHES_DIR}"/gcc/0024-MinGW-w64-Fix-bootstrap-when-libitm-is-disabled.patch      false
    # Hack for relocation
    apply_patch_gcc "${PATCHES_DIR}"/gcc/0025-MinGW-w64-Hack-Do-not-pass-iprefix-internally.patch        false
    #
    apply_patch_gcc "${PATCHES_DIR}"/gcc/0026-Add-defines-to-disable-optimize-for-size-changes.patch     false

    sed -i 's/msvcrt/msvcr120/g' "${BUILD_DIR}"/gcc/src/gcc-${GCC_VER}/libgcc/config/i386/t-mingw32

    echo 'done'

    echo "${GCC_VER/-*}" > "${BUILD_DIR}"/gcc/src/gcc-${GCC_VER}/gcc/BASE-VER

    return 0
}

# Create symlinks.
function symlink_gcc() {
    local _arch=${1}
    local _bitval=$(get_arch_bit ${_arch})

    pushd "${DST_DIR}"/mingw${_bitval}/bin > /dev/null
    # Symlinking to ${_arch}-w64-mingw32-*.exe.
    find . -type f -a \( -name "cpp*.exe" -o -name "g++*.exe" -o -name "gcc*.exe" -o -name "gcov*.exe" \) -printf '%f\n' | \
        xargs -I% ln -fsr % ./${_arch}-w64-mingw32-%
    # Symlinking to *.exe added versioned suffix.
    find . -type f -a \( -name "cpp*.exe" -o -name "g++*.exe" -o -name "gcc*.exe" -o -name "gcov*.exe" \) -print0  | \
        while read -r -d '' fname
        do
            ln -fsr $fname ${fname%%-${GCC_VER/-*}.exe}.exe
        done
    # Symlinking to ${_arch}-w64-mingw32-*-${GCC_VER}.exe.
    find . -type f -a \( -name "cpp*.exe" -o -name "g++*.exe" -o -name "gcc*.exe" -o -name "gcov*.exe" \) -printf '%f\n' | \
        while read -r fname
        do
            ln -fsr $fname ${_arch}-w64-mingw32-${fname%%-${GCC_VER/-*}.exe}.exe
        done
    # c++*.exe are symlinks of g++-${GCC_VER}.exe.
    ln -fsr ./g++-${GCC_VER/-*}.exe ./c++-${GCC_VER/-*}.exe
    ln -fsr ./g++-${GCC_VER/-*}.exe ./c++.exe
    ln -fsr ./g++-${GCC_VER/-*}.exe ./${_arch}-w64-mingw32-c++-${GCC_VER/-*}.exe
    ln -fsr ./g++-${GCC_VER/-*}.exe ./${_arch}-w64-mingw32-c++.exe
    # Many packages expect this symlink.
    ln -fsr ./gcc.exe ./cc
    popd > /dev/null # "${DST_DIR}"/mingw${_bitval}/bin

    pushd "${DST_DIR}"/mingw${_bitval}/lib/gcc/${_arch}-w64-mingw32/${GCC_VER/-*} > /dev/null
    # This is necessary for slim LTO.
    mkdir -p "${DST_DIR}"/mingw${_bitval}/lib/bfd-plugins
    ln -fsr ./liblto_plugin-*.dll ../../../bfd-plugins
    popd > /dev/null # "${DST_DIR}"/mingw${_bitval}/lib/gcc/${_arch}-w64-mingw32/${GCC_VER/-*}

    return 0
}

# Cleanup.
function term_gcc() {
    local _arch=${1}
    local _bitval=$(get_arch_bit ${_arch})

    # DLLs list of gcc_libs.
    local -ra _dlllist=(
        # "libgmp-*.dll" # GMP is used for FFmpeg, so don't relocate.
        "libmpfr-*.dll"
        "libmpc-*.dll"
        "libisl-*.dll"
    )

    # POSIX conformance launcher scripts for c89, c99 and c11.
    cat > "${DST_DIR}"/mingw${_bitval}/bin/c89 << "__EOF__"
#!/usr/bin/env bash
fl="-std=c89"
for opt;
do
    case "${opt}" in
        -ansi | -std=c89 | -std=c90 | -std=iso9899:1990 )
            fl=""
            ;;
        -std=* )
            echo "$(basename $0) called with non ANSI/ISO C option $opt" >&2
            exit 1
            ;;
    esac
done
exec gcc $fl ${1+"$@"}
__EOF__

    cat > "${DST_DIR}"/mingw${_bitval}/bin/c99 << "__EOF__"
#!/usr/bin/env bash
fl="-std=c99"
for opt;
do
    case "${opt}" in
        -std=c99 | -std=iso9899:1999 )
            fl=""
            ;;
        -std=* )
            echo "$(basename $0) called with non ISO C99 option $opt" >&2
            exit 1
            ;;
    esac
done
exec gcc $fl ${1+"$@"}
__EOF__

    cat > "${DST_DIR}"/mingw${_bitval}/bin/c11 << "__EOF__"
#!/usr/bin/env bash
fl="-std=c11"
for opt;
do
    case "${opt}" in
        -std=c11 | -std=iso9899:2011 )
            fl=""
            ;;
        -std=* )
            echo "$(basename $0) called with non ISO C11 option $opt" >&2
            exit 1
            ;;
    esac
done
exec gcc $fl ${1+"$@"}
__EOF__

    # Relocate DLLs to EXEC_PREFIX.
    local _dll
    for _dll in ${_dlllist[@]}
    do
        mv -f "${DST_DIR}"/mingw${_bitval}/bin/$_dll "${DST_DIR}"/mingw${_bitval}/lib/gcc/${_arch}-w64-mingw32/${GCC_VER/-*}
    done
    # Remove headers & libs of gcc_libs.
    # GMP
    # GMP is used for FFmpeg, so don't relocate.
    # rm -f  "${DST_DIR}"/mingw${_bitval}/include/gmp.h
    # rm -f  "${DST_DIR}"/mingw${_bitval}/lib/libgmp.dll.a
    # MPFR
    rm -f  "${DST_DIR}"/mingw${_bitval}/include/{mpfr,mpf2mpfr}.h
    rm -f  "${DST_DIR}"/mingw${_bitval}/lib/libmpfr.dll.a
    # MPC
    rm -f  "${DST_DIR}"/mingw${_bitval}/include/mpc.h
    rm -f  "${DST_DIR}"/mingw${_bitval}/lib/libmpc.dll.a
    # ISL
    rm -fr "${DST_DIR}"/mingw${_bitval}/include/isl
    rm -f  "${DST_DIR}"/mingw${_bitval}/lib/libisl.dll.a

    return 0
}

# Build and install.
function build_gcc() {
    clear; printf "Build GCC %s\n" "${GCC_VER}"

    # Option handling.
    local _rebuild=true

    local _opt
    for _opt in "${@}"
    do
        case "${_opt}" in
            --rebuild=* )
                _rebuild=${_opt#*=}
                ;;
            * )
                printf "build_gcc: Unknown Option: '%s'\n" "${_opt}"
                echo '...exit'
                exit 1
                ;;
        esac
    done

    # Setup.
    if ${_rebuild}; then
        download_gcc_src
        prepare_gcc
    fi

    local _arch
    for _arch in ${TARGET_ARCH[@]}
    do
        local _bitval=$(get_arch_bit ${_arch})

        if ${_rebuild}; then
            cd "${BUILD_DIR}"/gcc/build_$_arch
            # Cleanup the build dir.
            rm -fr "${BUILD_DIR}"/gcc/build_${_arch}/*

            # PATH exporting.
            set_path $_arch

            # For relocatable.
            mkdir -p "${BUILD_DIR}"/gcc/build_${_arch}/include/../lib
            ln -fs "${DST_DIR}"/mingw${_bitval}/{include,${_arch}-w64-mingw32/include}/* \
                "${BUILD_DIR}"/gcc/build_${_arch}/include
            ln -fs "${DST_DIR}"/mingw${_bitval}/{lib,${_arch}-w64-mingw32/lib}/* "${BUILD_DIR}"/gcc/build_${_arch}/lib
            ln -fs /mingw${_bitval}/lib/default-manifest.o "${BUILD_DIR}"/gcc/build_${_arch}/lib

            # Arch specific config option.
            if [ "${_arch}" = 'i686' ]; then
                local _ehconf='--disable-sjlj-exceptions --with-dwarf2'
                local _windres_cmd='windres -F pe-i386'
            else
                local _ehconf=''
                local _windres_cmd='windres -F pe-x86-64'
            fi

            # Don't search build toolchain include dir.
            local _nshdir="${DST_DIR}"/mingw${_bitval}/${_arch}-w64-mingw32/include

            # package version.
            local _pkgver="GCC $GCC_VER Rev.${GCC_PKGREV}, target: ${_arch}-w64-mingw32, built on ${GCC_BUILT_DATE}"

            # Don't use win native symlink during building GCC.
            unset MSYS

            # Force to use built-in specs
            local _old_gcc_ver=$(gcc -dumpversion)
            if [ -f /mingw${_bitval}/lib/gcc/${_arch}-w64-mingw32/${_old_gcc_ver}/specs ]; then
                mv -f /mingw${_bitval}/lib/gcc/${_arch}-w64-mingw32/${_old_gcc_ver}/specs \
                    /mingw${_bitval}/lib/gcc/${_arch}-w64-mingw32/${_old_gcc_ver}/specs.bak
            fi

            # Configure.
            printf "===> Configuring GCC %s...\n" "${_arch}"
            ../src/gcc-${GCC_VER}/configure                                       \
                --prefix=/mingw$_bitval                                           \
                --libexecdir=/mingw${_bitval}/lib                                 \
                --program-suffix=-${GCC_VER/-*}                                   \
                --build=${_arch}-w64-mingw32                                      \
                --host=${_arch}-w64-mingw32                                       \
                --target=${_arch}-w64-mingw32                                     \
                --enable-ld=default                                               \
                --disable-libatomic                                               \
                --disable-libquadmath                                             \
                --disable-libgomp                                                 \
                --enable-libssp                                                   \
                --disable-libvtv                                                  \
                --enable-bootstrap                                                \
                --disable-isl-version-check                                       \
                --enable-lto                                                      \
                --disable-werror                                                  \
                --disable-multilib                                                \
                --enable-shared                                                   \
                --enable-static                                                   \
                --enable-fast-install                                             \
                --disable-build-format-warnings                                   \
                --enable-checking=release                                         \
                --enable-threads=$THREAD_MODEL                                    \
                --enable-languages=c,c++,lto                                      \
                --disable-rpath                                                   \
                --disable-win32-registry                                          \
                --enable-version-specific-runtime-libs                            \
                --disable-nls                                                     \
                --disable-symvers                                                 \
                --disable-libstdcxx-pch                                           \
                --enable-cstdio=stdio                                             \
                --enable-clocale=generic                                          \
                --enable-libstdcxx-allocator=new                                  \
                --enable-cheaders=c_global                                        \
                --enable-long-long                                                \
                --enable-wchar_t                                                  \
                --enable-c99                                                      \
                --disable-libstdcxx-debug                                         \
                --enable-fully-dynamic-string                                     \
                --enable-extern-template                                          \
                --enable-libstdcxx-time=yes                                       \
                --enable-libstdcxx-threads                                        \
                --disable-vtable-verify                                           \
                --disable-tls                                                     \
                --with-stage1-ldflags=no                                          \
                --with-boot-ldflags=no                                            \
                --with-{mpc,mpfr,gmp,isl}="${DST_DIR}"/mingw$_bitval              \
                --with-build-sysroot="${DST_DIR}"/mingw$_bitval                   \
                --with-gnu-ld                                                     \
                --with-local-prefix=/mingw${_bitval}/local                        \
                --with-gxx-include-dir=/mingw${_bitval}/include/c++/${GCC_VER/-*} \
                --with-gnu-as                                                     \
                ${_ehconf}                                                        \
                --with-native-system-header-dir="${_nshdir}"                      \
                --with-pkgversion="${_pkgver}"                                    \
                --with-libiconv-prefix="${DST_DIR}"/mingw$_bitval                 \
                --with-plugin-ld=ld.bfd                                           \
                --with-system-zlib                                                \
                --with-diagnostics-color=auto-if-env                              \
                > "${LOGS_DIR}"/gcc/gcc_config_${_arch}.log 2>&1 || exit 1
            echo 'done'

                # --with-arch=x86-64                                                \
                # --with-tune=generic                                               \
                # --with-fpmath=sse                                                 \

            # Make.
            printf "===> Making GCC %s...\n" $_arch
            # Setting -j$(($(nproc)+1)) sometimes makes error.
            make -j2                                               \
                CPPFLAGS="${CPPFLAGS_}"                         \
                CPPFLAGS_FOR_TARGET="${CPPFLAGS_}"              \
                CFLAGS="${CFLAGS_} ${CPPFLAGS_}"                \
                CFLAGS_FOR_TARGET="${CFLAGS_} ${CPPFLAGS_}"     \
                BOOT_CFLAGS="${CFLAGS_} ${CPPFLAGS_}"           \
                CXXFLAGS="${CXXFLAGS_} ${CPPFLAGS_}"            \
                CXXFLAGS_FOR_TARGET="${CXXFLAGS_} ${CPPFLAGS_}" \
                BOOT_CXXFLAGS="${CXXFLAGS_} ${CPPFLAGS_}"       \
                LDFLAGS="${LDFLAGS_}"                           \
                LDFLAGS_FOR_TARGET="${LDFLAGS_}"                \
                BOOT_LDFLAGS="${LDFLAGS_}"                      \
                bootstrap > "${LOGS_DIR}"/gcc/gcc_make_${_arch}.log 2>&1 || exit 1
            echo 'done'

            # Install.
            printf "===> Installing GCC %s...\n" "${_arch}"
            rm -fr "${PREIN_DIR}"/gcc/mingw$_bitval
            make DESTDIR="${PREIN_DIR}"/gcc install > "${LOGS_DIR}"/gcc/gcc_install_${_arch}.log 2>&1 || exit 1
            # Move libgcc_s.a to GCC EXEC_PREFIX.
            mv -f "${PREIN_DIR}"/gcc/mingw${_bitval}/lib/gcc/${_arch}-w64-mingw32/lib/libgcc_s.a \
                "${PREIN_DIR}"/gcc/mingw${_bitval}/lib/gcc/${_arch}-w64-mingw32/${GCC_VER/-*}
            # Remove unneeded files.
            rm -f  "${PREIN_DIR}"/gcc/mingw${_bitval}/lib/gcc/${_arch}-w64-mingw32/${GCC_VER/-*}/*.py
            rm -fr "${PREIN_DIR}"/gcc/mingw${_bitval}/share/gcc-${GCC_VER/-*}
            rm -fr "${PREIN_DIR}"/gcc/mingw${_bitval}/bin/*tmp*
            remove_la_files   "${PREIN_DIR}"/gcc/mingw$_bitval
            remove_empty_dirs "${PREIN_DIR}"/gcc/mingw$_bitval
            # Strip files.
            strip_files "${PREIN_DIR}"/gcc/mingw$_bitval
            # Modify hard coded file PATH.
            sed -i "s|${DST_DIR//\//\\/}||g" \
                "${PREIN_DIR}"/gcc/mingw${_bitval}/lib/gcc/${_arch}-w64-mingw32/${GCC_VER/-*}/install-tools/mkheaders.conf
            echo 'done'

            # Make default-manifest.o.
            printf "===> Making windows-default-manifest %s...\n" "${_arch}"
            mkdir -p "${BUILD_DIR}"/gcc/build_${_arch}/build_manifest
            cd "${BUILD_DIR}"/gcc/build_${_arch}/build_manifest
            cat > "${BUILD_DIR}"/gcc/build_${_arch}/build_manifest/default-manifest.rc << "__EOF__"
LANGUAGE 0, 0

/* CREATEPROCESS_MANIFEST_RESOURCE_ID RT_MANIFEST MOVEABLE PURE DISCARDABLE */
1 24 MOVEABLE PURE DISCARDABLE
BEGIN
  "<?xml version=""1.0"" encoding=""UTF-8"" standalone=""yes""?>\n"
  "<assembly xmlns=""urn:schemas-microsoft-com:asm.v1"" manifestVersion=""1.0"">\n"
  "  <trustInfo xmlns=""urn:schemas-microsoft-com:asm.v3"">\n"
  "    <security>\n"
  "      <requestedPrivileges>\n"
  "        <requestedExecutionLevel level=""asInvoker""/>\n"
  "      </requestedPrivileges>\n"
  "    </security>\n"
  "  </trustInfo>\n"
  "  <compatibility xmlns=""urn:schemas-microsoft-com:compatibility.v1"">\n"
  "    <application>\n"
  "      <!--The ID below indicates application support for Windows 10 -->\n"
  "      <supportedOS Id=""{8e0f7a12-bfb3-4fe8-b9a5-48fd50a15a9a}""/> \n"
  "    </application>\n"
  "  </compatibility>\n"
  "</assembly>\n"
END

__EOF__
            ${_windres_cmd} default-manifest.rc -o default-manifest.o
            echo 'done'

            # Install default-manifest.o.
            printf "===> Installing windows-default-manifest %s...\n" "${_arch}"
            /usr/bin/install -m 644 default-manifest.o "${PREIN_DIR}"/gcc/mingw${_bitval}/lib
            echo 'done'

            # Enable win native symlink.
            MSYS=winsymlinks:nativestrict
            export MSYS

            # Restore specs.
            if [ -f /mingw${_bitval}/lib/gcc/${_arch}-w64-mingw32/${_old_gcc_ver}/specs.bak ]; then
                mv -f /mingw${_bitval}/lib/gcc/${_arch}-w64-mingw32/${_old_gcc_ver}/specs.bak \
                    /mingw${_bitval}/lib/gcc/${_arch}-w64-mingw32/${_old_gcc_ver}/specs
            fi
        fi

        # Copy to DST_DIR.
        printf "===> Copying GCC %s to %s/mingw%s...\n" "${_arch}" "${DST_DIR}" "${_bitval}"
        symcopy "${PREIN_DIR}"/gcc/mingw$_bitval "${DST_DIR}"
        echo 'done'
        # Create symlinks.
        if ${create_symlinks:-false}; then
            rm -f "${DST_DIR}"/mingw${_bitval}/bin/c++-${GCC_VER/-*}.exe
            printf "===> Creating symlinks %s...\n" "${_arch}"
            symlink_gcc $_arch
            echo 'done'
        fi
        # Relocate DLLs & cleanup.
        printf "===> Cleanup GCC %s...\n" "${_arch}"
        term_gcc $_arch
        echo 'done'

        # Copy logs
        printf "===> Copying GCC %s logs to %s/mingw%s/logs...\n" "${_arch}" "${DST_DIR}" "${_bitval}"
        mkdir -p "${DST_DIR}"/mingw${_bitval}/logs/gcc
        cp -af "${LOGS_DIR}"/gcc/*${_arch}*    "${DST_DIR}"/mingw${_bitval}/logs/gcc
        cp -af "${LOGS_DIR}"/gcc/gcc_patch.log "${DST_DIR}"/mingw${_bitval}/logs/gcc
        echo 'done'
    done

    cd "${ROOT_DIR}"
    return 0
}
