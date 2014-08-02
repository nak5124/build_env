#!/usr/bin/env bash


# load settings
ROOT_DIR=$(cd $(dirname $0);pwd)
SCRIPTS_DIR=${ROOT_DIR}/scripts
# order is important
source ${SCRIPTS_DIR}/misc.sh
source ${SCRIPTS_DIR}/config.sh
source ${SCRIPTS_DIR}/init.sh

# option
for opt in "$@"
do
    case "${opt}" in
        nolibs)
            define_rov NO_GCC_LIBS
            ;;
        libs)
            unset NO_GCC_LIBS
            ;;
        notc)
            define_rov NO_TOOLCHAIN
            ;;
        tc)
            unset NO_TOOLCHAIN
            ;;
        noasm)
            define_rov NO_NYASM
            ;;
        asm)
            unset NO_NYASM
            ;;
        no2nd)
            define_rov NO_2ND_BUILD
            ;;
        2nd)
            unset NO_2ND_BUILD
            ;;
        noat)
            define_rov NO_AUTOTOOLS
            ;;
        at)
            unset NO_AUTOTOOLS
            ;;
        *)
            printf "Unknown option %s\n" $opt
            exit 1
    esac
done
if is_defined NO_TOOLCHAIN > /dev/null ; then
    define_rov NO_2ND_BUILD
    if is_defined NO_GCC_LIBS  > /dev/null \
    && is_defined NO_AUTOTOOLS > /dev/null ; then
        echo "Nothing is run\!"
        exit 1
    fi
fi

# init
init_dirs

# prerequisites for GCC
# http://gcc.gnu.org/install/prerequisites.html
if ! is_defined NO_GCC_LIBS > /dev/null ; then
    # GMP
    if is_defined GMP_REBUILD > /dev/null ; then
        source ${SCRIPTS_DIR}/gmp.sh
        build_gmp
    fi
    # MPFR
    if is_defined MPFR_REBUILD > /dev/null ; then
        source ${SCRIPTS_DIR}/mpfr.sh
        build_mpfr
    fi
    # MPC
    if is_defined MPC_REBUILD > /dev/null ; then
        source ${SCRIPTS_DIR}/mpc.sh
        build_mpc
    fi
    # ISL
    if is_defined ISL_REBUILD > /dev/null ; then
        source ${SCRIPTS_DIR}/isl.sh
        build_isl
    fi
    # CLooG
    if is_defined CLOOG_REBUILD > /dev/null ; then
        source ${SCRIPTS_DIR}/cloog.sh
        build_cloog
    fi
    if is_defined GCC_LIBS_REBUILD > /dev/null ; then
        declare bitval
        for arch in ${TARGET_ARCH[@]}
        do
            bitval=$(get_arch_bit ${arch})
            rm -fr ${LIBS_DIR}/mingw${bitval}/{bin,share}
            del_empty_dir ${LIBS_DIR}/mingw$bitval
            strip_files ${LIBS_DIR}/mingw$bitval
        done
        unset bitval
    fi
fi

# build mingw-w64 toolchain
source ${SCRIPTS_DIR}/libiconv.sh
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
        copy_only_iconv
    fi
    # bzip2
    if is_defined BZIP2_REBUILD > /dev/null ; then
        build_bzip2
    else
        copy_only_bzip2
    fi
    # zlib
    if is_defined ZLIB_REBUILD > /dev/null ; then
        build_zlib
    else
        copy_only_zlib
    fi
    # MinGW-w64 common
    if is_defined MINGW_REBUILD > /dev/null ; then
        prepare_mingw_w64
    fi
    # headers
    if is_defined HEADERS_REBUILD > /dev/null ; then
        build_headers
    else
        copy_only_headers
    fi
    # Binutils
    if is_defined BINUTILS_REBUILD > /dev/null ; then
        build_binutils
    else
        copy_only_binutils
    fi
    # winpthreads
    if is_defined WINPTHREADS_REBUILD > /dev/null ; then
        build_threads
    else
        copy_only_threads
    fi
    # GCC 1st step
    if is_defined GCC_REBUILD > /dev/null ; then
        build_gcc1
    else
        copy_only_gcc
    fi
    # crt
    if is_defined CRT_REBUILD > /dev/null ; then
        build_crt
    else
        copy_only_crt
    fi
    # GCC 2nd step
    if is_defined GCC_REBUILD > /dev/null ; then
        build_gcc2
    fi
else
    copy_only_iconv
    copy_only_bzip2
    copy_only_zlib
    copy_only_headers
    copy_only_binutils
    copy_only_threads
    copy_only_crt
    copy_only_gcc
fi

# nyasm
source ${SCRIPTS_DIR}/nyasm.sh
if ! is_defined NO_NYASM > /dev/null ; then
    # NASM
    if is_defined NASM_REBUILD > /dev/null ; then
        build_nasm
    else
        copy_only_nasm
    fi
    # Yasm
    if is_defined YASM_REBUILD > /dev/null ; then
        build_yasm
    else
        copy_only_yasm
    fi
else
    copy_only_nasm
    copy_only_yasm
fi

# rebuild
if ! is_defined NO_2ND_BUILD > /dev/null ; then
    # Binutils
    if is_defined BINUTILS2ND_REBUILD > /dev/null ; then
        build_binutils -2nd
    fi
    # winpthreads
    if is_defined WINPTHREADS2ND_REBUILD > /dev/null ; then
        build_threads -2nd
    fi
    # crt
    if is_defined CRT2ND_REBUILD > /dev/null ; then
        build_crt -2nd
    fi
fi

# autotools
source ${SCRIPTS_DIR}/autotools.sh
if ! is_defined NO_AUTOTOOLS > /dev/null ; then
    # Autoconf
    if is_defined AUTOCONF_REBUILD > /dev/null ; then
        build_autoconf
    else
        copy_only_autoconf
    fi
    # Automake
    if is_defined AUTOMAKE_REBUILD > /dev/null ; then
        build_automake
    else
        copy_only_automake
    fi
    # Libtool
    if is_defined LIBTOOL_REBUILD > /dev/null ; then
        build_libtool
    else
        copy_only_libtool
    fi
else
    copy_only_autoconf
    copy_only_automake
    copy_only_libtool
fi

reset; echo "Everything has been successfully completed!"
