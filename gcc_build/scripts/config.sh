# target
declare -ra GCC_LIBS=(
    "gmp"
    "mpfr"
    "mpc"
    "isl"
    "cloog"
)

declare -ra BUILD_TARGETS=(
    "libiconv"
    "bzip2"
    "zlib"
    "binutils"
    "mingw-w64 headers crt winpthreads"
    "gcc"
    "autotools autoconf automake libtool"
)

declare -ra TARGET_ARCH=(
    "i686"
    "x86_64"
)

# PATH
declare -r LOGS_DIR=${ROOT_DIR}/logs
declare -r PATCHES_DIR=${ROOT_DIR}/patches
declare -r PREIN_DIR=${ROOT_DIR}/prein
declare -r BUILD_DIR=${ROOT_DIR}/build
declare -r DST_DIR=${ROOT_DIR}/dst
declare -r LIBS_DIR=${ROOT_DIR}/libs

# flags
declare -r _CPPFLAGS="-D_FORTIFY_SOURCE=2 -D__USE_MINGW_ANSI_STDIO=1"
declare -r _CFLAGS="-pipe -Os -msse4 -fomit-frame-pointer"
declare -r _CXXFLAGS="-pipe -Os -msse4 -fomit-frame-pointer"
declare -r _LDFLAGS="-pipe -Wl,-O1 -Wl,--as-needed -Wl,--nxcompat -Wl,--dynamicbase"
declare -r MAKEFLAGS="-O -j9"

# version
declare -r GMP_VER="6.0.0"
declare -r MPFR_VER="3.1.2"
declare -r MPC_VER="1.0.2"
declare -r ISL_VER="0.13"
declare -r CLOOG_VER="0.18.1"
declare -r ICONV_VER="1.14"
declare -r BZIP2_VER="1.0.6"
declare -r ZLIB_VER="1.2.8"
declare -r MINGW_VER="git"
declare -r BINUTILS_VER="2.24"
declare -r GCC_VER="4.9.1"
declare -r AUTOCONF_VER="2.69"
declare -r AUTOMAKE_VER="1.14.1"
declare -r LIBTOOL_VER="2.4.2.418"

# rebuild
# comment out if you don't want to rebuild
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

define_rov ICONV_REBUILD
define_rov BZIP2_REBUILD
define_rov ZLIB_REBUILD
define_rov HEADERS_REBUILD
define_rov BINUTILS_REBUILD
define_rov WINPTHREADS_REBUILD
define_rov CRT_REBUILD
define_rov GCC_REBUILD
if is_defined HEADERS_REBUILD     > /dev/null \
|| is_defined WINPTHREADS_REBUILD > /dev/null \
|| is_defined CRT_REBUILD         > /dev/null ; then
    define_rov MINGW_REBUILD
fi

define_rov BINUTILS2ND_REBUILD
define_rov CRT2ND_REBUILD
define_rov WINPTHREADS2ND_REBUILD

define_rov AUTOCONF_REBUILD
define_rov AUTOMAKE_REBUILD
define_rov LIBTOOL_REBUILD
