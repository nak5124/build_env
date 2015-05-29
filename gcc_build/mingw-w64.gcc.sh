#!/usr/bin/env bash


# Load settings.
declare -r ROOT_DIR="$(cd $(dirname $BASH_SOURCE); pwd)"
declare -r SCRIPTS_DIR="${ROOT_DIR}"/scripts
# The order is important.
source "${SCRIPTS_DIR}"/misc.sh
source "${SCRIPTS_DIR}"/config.sh
source "${SCRIPTS_DIR}"/misc2.sh
source "${SCRIPTS_DIR}"/init.sh

# Handling options.
declare no_gcc_libs=false
declare no_toolchain=false
declare no_2nd_rebuild=false
declare no_map=false
declare no_nyasm=false
declare no_autotools=false
declare opt
for opt in "${@}"
do
    case "${opt}" in
        all )
            no_gcc_libs=false
            no_toolchain=false
            no_2nd_rebuild=false
            no_map=false
            no_nyasm=false
            no_autotools=false
            ;;
        noall )
            no_gcc_libs=true
            no_toolchain=true
            no_2nd_rebuild=true
            no_map=true
            no_nyasm=true
            no_autotools=true
            ;;
        nolibs )
            no_gcc_libs=true
            ;;
        libs )
            no_gcc_libs=false
            ;;
        notc )
            no_toolchain=true
            ;;
        tc )
            no_toolchain=false
            ;;
        no2nd )
            no_2nd_rebuild=true
            ;;
        2nd )
            no_2nd_rebuild=false
            ;;
        nomap )
            no_map=true
            ;;
        map )
            no_map=false
            ;;
        noasm )
            no_nyasm=true
            ;;
        asm )
            no_nyasm=false
            ;;
        noat )
            no_autotools=true
            ;;
        at )
            no_autotools=false
            ;;
        * )
            printf "%s, Unknown Option: '%s'\n" "$(basename $BASH_SOURCE)" "${opt}"
            echo '...exit'
            exit 1
            ;;
    esac
done
if ${no_toolchain}; then
    no_2nd_rebuild=true
fi

# Initialize.
check_cpath
init_dirs

# prerequisites for GCC
# See http://gcc.gnu.org/install/prerequisites.html.
source "${SCRIPTS_DIR}"/gmp.sh
source "${SCRIPTS_DIR}"/mpfr.sh
source "${SCRIPTS_DIR}"/mpc.sh
source "${SCRIPTS_DIR}"/isl.sh
if ! ${no_gcc_libs}; then
    build_gmp   --rebuild=${gmp_rebuild:-false}
    build_mpfr  --rebuild=${mpfr_rebuild:-false}
    build_mpc   --rebuild=${mpc_rebuild:-false}
    build_isl   --rebuild=${isl_rebuild:-false}
else
    build_gmp   --rebuild=false
    build_mpfr  --rebuild=false
    build_mpc   --rebuild=false
    build_isl   --rebuild=false
fi

# Build mingw-w64 toolchain.
source "${SCRIPTS_DIR}"/libiconv.sh
source "${SCRIPTS_DIR}"/libintl.sh
source "${SCRIPTS_DIR}"/bzip2.sh
source "${SCRIPTS_DIR}"/zlib.sh
source "${SCRIPTS_DIR}"/mingw-w64.sh
source "${SCRIPTS_DIR}"/binutils.sh
source "${SCRIPTS_DIR}"/gcc.sh

declare update_mingw=false
if ( ! ${no_toolchain} && ( ${headers_rebuild:-false} || ${threads_rebuild:-false} || ${crt_rebuild:-false} ) ) \
|| ( ! ${no_map}       && ( ${mangle_rebuild:-false}  || ${tools_rebuild:-false}                            ) ); then
    update_mingw=true
fi

if ! ${no_toolchain}; then
    build_iconv --rebuild=${iconv_rebuild:-false}
    build_bzip2 --rebuild=${bzip2_rebuild:-false}
    build_zlib  --rebuild=${zlib_rebuild:-false}
    if ${update_mingw}; then
        prepare_mingw_w64
        update_mingw=false
    fi
    build_headers  --rebuild=${headers_rebuild:-false}
    build_threads  --rebuild=${threads_rebuild:-false}
    build_crt      --rebuild=${crt_rebuild:-false}
    build_binutils --rebuild=${binutils_rebuild:-false}
    build_gcc      --rebuild=${gcc_rebuild:-false}
else
    build_iconv    --rebuild=false
    build_bzip2    --rebuild=false
    build_zlib     --rebuild=false
    build_headers  --rebuild=false
    build_threads  --rebuild=false
    build_crt      --rebuild=false
    build_binutils --rebuild=false
    build_gcc      --rebuild=false
fi

# Rebuild with newer GCC.
if ! ${no_2nd_rebuild}; then
    if ${binutils_2nd_rebuild:-false}; then
        build_binutils --rebuild=${binutils_2nd_rebuild:-false} --2nd
    fi
    if ${crt_2nd_rebuild:-false}; then
        build_crt --rebuild=${crt_2nd_rebuild:-false} --2nd
    fi
    if ${threads_2nd_rebuild:-false}; then
        build_threads --rebuild=${threads_2nd_rebuild:-false} --2nd
    fi
fi

# MinGW-w64 additional packages
if ! ${no_map}; then
    if ${update_mingw}; then
        prepare_mingw_w64
    fi
    build_mangle --rebuild=${mangle_rebuild:-false}
    build_tools  --rebuild=${tools_rebuild:-false}
else
    build_mangle --rebuild=false
    build_tools  --rebuild=false
fi

# nyasm
source "${SCRIPTS_DIR}"/nyasm.sh
if ! ${no_nyasm}; then
    build_nasm --rebuild=${nasm_rebuild:-false}
    build_yasm --rebuild=${yasm_rebuild:-false}
else
    build_nasm --rebuild=false
    build_yasm --rebuild=false
fi

# autotools
source "${SCRIPTS_DIR}"/autotools.sh
if ! ${no_autotools}; then
    build_autoconf --rebuild=${autoconf_rebuild:-false}
    build_automake --rebuild=${automake_rebuild:-false}
    build_libtool  --rebuild=${libtool_rebuild:-false}
else
    build_autoconf --rebuild=false
    build_automake --rebuild=false
    build_libtool  --rebuild=false
fi

# Reinstall ld.
copy_ld

# Replace configs with newer ones.
replace_config

LC_ALL=
export LC_ALL

reset; echo 'Everything has been successfully completed!'
