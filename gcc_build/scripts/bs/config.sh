# target
declare -ra BUILD_TARGETS=(
    "gcc_libs gmp mpfr mpc isl cloog"
    "libiconv"
    "libintl"
    "bzip2"
    "zlib"
    "binutils"
    "mingw-w64 headers crt winpthreads crt"
    "gcc"
    "autotools autoconf automake libtool"
    "nyasm nasm yasm"
)

declare -ra TARGET_ARCH=(
    "x86_64"
    # "i686"
)

# LANG
LC_ALL=en_US.UTF-8
export LC_ALL

# symlink
MSYS=winsymlinks:nativestrict
export MSYS

# PATH
declare -r LOGS_DIR=${ROOT_DIR}/logs_bs
declare -r PATCHES_DIR=${ROOT_DIR}/patches
declare -r PREIN_DIR=${ROOT_DIR}/prein_bs
declare -r BUILD_DIR=${ROOT_DIR}/build
declare -r DST_DIR=${ROOT_DIR}/dst

# flags
declare -r _CPPFLAGS="-D__USE_MINGW_ANSI_STDIO=1"
declare -r _CFLAGS="-pipe -O2"
declare -r _CXXFLAGS="-pipe -O2"
declare -r _LDFLAGS="-s"
declare -r MAKEFLAGS="-j$(($(nproc)+1)) -O"

# GCC thread model
declare -r THREAD_MODEL="posix"

# version
declare -r GMP_VER="6.0.0"
declare -r MPFR_VER="3.1.2"
declare -r MPC_VER="1.0.2"
declare -r ISL_VER="0.13"
declare -r CLOOG_VER="0.18.1"
declare -r ICONV_VER="1.14"
declare -r INTL_VER="0.19.2"
declare -r BZIP2_VER="1.0.6"
declare -r ZLIB_VER="1.2.8"
declare -r MINGW_VER="git"
declare -r BINUTILS_VER="git"
declare -r GCC_VER="4.9.1"
declare -r NASM_VER="2.11.05"
declare -r YASM_VER="1.3.0"
declare -r AUTOCONF_VER="2.69"
declare -r AUTOMAKE_VER="1.14.1"
declare -r LIBTOOL_VER="2.4.2.418"

# rebuild
# comment out if you don't want to rebuild
# prerequisites for GCC
define_rov GMP_REBUILD
define_rov MPFR_REBUILD
define_rov MPC_REBUILD
define_rov ISL_REBUILD
define_rov CLOOG_REBUILD
if is_defined GMP_REBUILD   > /dev/null \
|| is_defined MPFR_REBUILD  > /dev/null \
|| is_defined MPC_REBUILD   > /dev/null \
|| is_defined ISL_REBUILD   > /dev/null \
|| is_defined CLOOG_REBUILD > /dev/null ; then
    define_rov GCC_LIBS_REBUILD
fi

# mingw-w64 toolchain
# define_rov ICONV_REBUILD
# define_rov INTL_REBUILD
# define_rov ICONV2ND_REBUILD
# define_rov BZIP2_REBUILD
# define_rov ZLIB_REBUILD
# define_rov HEADERS_REBUILD
# define_rov WINPTHREADS_REBUILD
# define_rov CRT_REBUILD
# define_rov BINUTILS_REBUILD
define_rov GCC_REBUILD
if is_defined HEADERS_REBUILD     > /dev/null \
|| is_defined WINPTHREADS_REBUILD > /dev/null \
|| is_defined CRT_REBUILD         > /dev/null ; then
    define_rov MINGW_REBUILD
fi

# rebuild with newer GCC
define_rov BINUTILS2ND_REBUILD
define_rov CRT2ND_REBUILD
define_rov WINPTHREADS2ND_REBUILD

# nyasm
define_rov NASM_REBUILD
define_rov YASM_REBUILD

# autotools
define_rov AUTOCONF_REBUILD
define_rov AUTOMAKE_REBUILD
define_rov LIBTOOL_REBUILD
