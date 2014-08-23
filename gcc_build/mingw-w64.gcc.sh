#!/usr/bin/env bash


# load settings
ROOT_DIR=$(cd $(dirname $0);pwd)
SCRIPTS_DIR=${ROOT_DIR}/scripts
# order is important
source ${SCRIPTS_DIR}/misc.sh
source ${SCRIPTS_DIR}/config.sh
source ${SCRIPTS_DIR}/init.sh

# options
for opt in "$@"
do
    case "${opt}" in
        all )
            unset NO_GCC_LIBS
            unset NO_TOOLCHAIN
            unset NO_2ND_BUILD
            unset NO_NYASM
            unset NO_AUTOTOOLS
            ;;
        nolibs )
            define_rov NO_GCC_LIBS
            ;;
        libs )
            unset NO_GCC_LIBS
            ;;
        notc )
            define_rov NO_TOOLCHAIN
            ;;
        tc )
            unset NO_TOOLCHAIN
            ;;
        no2nd )
            define_rov NO_2ND_BUILD
            ;;
        2nd )
            unset NO_2ND_BUILD
            ;;
        noasm )
            define_rov NO_NYASM
            ;;
        asm )
            unset NO_NYASM
            ;;
        noat )
            define_rov NO_AUTOTOOLS
            ;;
        at )
            unset NO_AUTOTOOLS
            ;;
        * )
            printf "Unknown option %s\n" $opt
            exit 1
    esac
done
if is_defined NO_TOOLCHAIN > /dev/null ; then
    define_rov NO_2ND_BUILD
    if is_defined NO_GCC_LIBS  > /dev/null \
    && is_defined NO_NYASM     > /dev/null \
    && is_defined NO_AUTOTOOLS > /dev/null ; then
        echo "Nothing is run!"
        exit 1
    fi
fi

# init
init_dirs

# prerequisites for GCC
# http://gcc.gnu.org/install/prerequisites.html
source ${SCRIPTS_DIR}/gmp.sh
source ${SCRIPTS_DIR}/mpfr.sh
source ${SCRIPTS_DIR}/mpc.sh
source ${SCRIPTS_DIR}/isl.sh
source ${SCRIPTS_DIR}/cloog.sh
if ! is_defined NO_GCC_LIBS > /dev/null ; then
    # GMP
    if is_defined GMP_REBUILD > /dev/null ; then
        build_gmp
    else
        copy_gmp
    fi
    # MPFR
    if is_defined MPFR_REBUILD > /dev/null ; then
        build_mpfr
    else
        copy_mpfr
    fi
    # MPC
    if is_defined MPC_REBUILD > /dev/null ; then
        build_mpc
    else
        copy_mpc
    fi
    # ISL
    if is_defined ISL_REBUILD > /dev/null ; then
        build_isl
    else
        copy_isl
    fi
    # CLooG
    if is_defined CLOOG_REBUILD > /dev/null ; then
        build_cloog
    else
        copy_cloog
    fi
else
    copy_gmp
    copy_mpfr
    copy_mpc
    copy_isl
    copy_cloog
fi

# build mingw-w64 toolchain
source ${SCRIPTS_DIR}/libiconv.sh
source ${SCRIPTS_DIR}/libintl.sh
source ${SCRIPTS_DIR}/bzip2.sh
source ${SCRIPTS_DIR}/zlib.sh
source ${SCRIPTS_DIR}/mingw-w64.sh
source ${SCRIPTS_DIR}/binutils.sh
source ${SCRIPTS_DIR}/gcc.sh
if ! is_defined NO_TOOLCHAIN > /dev/null ; then
    # libiconv
    if is_defined ICONV_REBUILD > /dev/null ; then
        build_iconv
    else
        copy_iconv
    fi
    # libintl
    if is_defined INTL_REBUILD > /dev/null ; then
        build_intl
    else
        copy_intl
    fi
    # libiconv
    if is_defined ICONV2ND_REBUILD > /dev/null ; then
        build_iconv -2nd
    fi
    # bzip2
    if is_defined BZIP2_REBUILD > /dev/null ; then
        build_bzip2
    else
        copy_bzip2
    fi
    # zlib
    if is_defined ZLIB_REBUILD > /dev/null ; then
        build_zlib
    else
        copy_zlib
    fi
    # MinGW-w64 common
    if is_defined MINGW_REBUILD > /dev/null ; then
        prepare_mingw_w64
    fi
    # headers
    if is_defined HEADERS_REBUILD > /dev/null ; then
        build_headers
    else
        copy_headers
    fi
    # winpthreads
    if is_defined WINPTHREADS_REBUILD > /dev/null ; then
        build_threads
    else
        copy_threads
    fi
    # crt
    if is_defined CRT_REBUILD > /dev/null ; then
        build_crt
    else
        copy_crt
    fi
    # Binutils
    if is_defined BINUTILS_REBUILD > /dev/null ; then
        build_binutils
    else
        copy_binutils
    fi
    # GCC
    if is_defined GCC_REBUILD > /dev/null ; then
        # build_gcc_pre
        copy_gcc
        build_gcc
    else
        copy_gcc
    fi
else
    copy_iconv
    copy_intl
    copy_bzip2
    copy_zlib
    copy_headers
    copy_threads
    copy_crt
    copy_binutils
    copy_gcc
fi

# rebuild with newer GCC
if ! is_defined NO_2ND_BUILD > /dev/null ; then
    # Binutils
    if is_defined BINUTILS2ND_REBUILD > /dev/null ; then
        build_binutils
    fi
    # winpthreads
    if is_defined WINPTHREADS2ND_REBUILD > /dev/null ; then
        build_threads
    fi
    # crt
    if is_defined CRT2ND_REBUILD > /dev/null ; then
        build_crt
    fi
fi

# nyasm
source ${SCRIPTS_DIR}/nyasm.sh
if ! is_defined NO_NYASM > /dev/null ; then
    # NASM
    if is_defined NASM_REBUILD > /dev/null ; then
        build_nasm
    else
        copy_nasm
    fi
    # Yasm
    if is_defined YASM_REBUILD > /dev/null ; then
        build_yasm
    else
        copy_yasm
    fi
else
    copy_nasm
    copy_yasm
fi

# autotools
source ${SCRIPTS_DIR}/autotools.sh
if ! is_defined NO_AUTOTOOLS > /dev/null ; then
    # Autoconf
    if is_defined AUTOCONF_REBUILD > /dev/null ; then
        build_autoconf
    else
        copy_autoconf
    fi
    # Automake
    if is_defined AUTOMAKE_REBUILD > /dev/null ; then
        build_automake
    else
        copy_automake
    fi
    # Libtool
    if is_defined LIBTOOL_REBUILD > /dev/null ; then
        build_libtool
    else
        copy_libtool
    fi
else
    copy_autoconf
    copy_automake
    copy_libtool
fi

# reinstall ld
copy_ld

reset; echo "Everything has been successfully completed!"
