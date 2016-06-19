# Target
declare -ra BUILD_TARGETS=(
    'gcc_libs gmp mpfr mpc isl'
    'libiconv'
    'zlib'
    'binutils'
    'mingw-w64 headers crt winpthreads crt libmangle tools'
    'mcfgthread'
    'gcc'
    'autotools autoconf automake libtool'
    'nyasm nasm yasm'
)

declare -ra TARGET_ARCH=(
    'x86_64'
    # 'i686'
)

# LANG
LC_ALL=en_US.UTF-8
export LC_ALL

# symlink
MSYS=winsymlinks:nativestrict
export MSYS
declare -r create_symlinks=false

# PATH
declare -r LOGS_DIR="${ROOT_DIR}"/logs
declare -r PATCHES_DIR="${ROOT_DIR}"/patches
declare -r PREIN_DIR="${ROOT_DIR}"/prein
declare -r BUILD_DIR="${ROOT_DIR}"/build
declare -r DST_DIR="${ROOT_DIR}"/dst

# BUILDFLAGS
declare -r CPPFLAGS_=' -D__USE_MINGW_ANSI_STDIO=1 -D__USE_MINGW_ACCESS -D_FILE_OFFSET_BITS=64 -DWINVER=0x0a00 -D_WIN32_WINNT=0x0a00 -D_GNU_SOURCE=1 -D_BSD_SOURCE=1 -D_POSIX_SOURCE=1 -D_POSIX_C_SOURCE=200809L -D_XOPEN_SOURCE=700 -DNDEBUG'
declare -r CFLAGS_=' -pipe -O2 -fomit-frame-pointer -fno-tree-vectorize -fno-fast-math -fno-math-errno -fno-signed-zeros -mcrtdll=msvcr120'
declare -r CXXFLAGS_=" ${CFLAGS_}"
declare -r LDFLAGS_=' -Wl,-O1,--sort-common,--as-needed,--no-undefined,--no-gc-sections -mcrtdll=msvcr120'
declare -r MAKEFLAGS_=" -j$(($(nproc)+1)) -O"
#declare -r MAKEFLAGS_=" -j$(($(nproc)/2-1)) -O"

# GCC thread model
declare -r THREAD_MODEL='mcf'

# GCC package revision
declare -r GCC_PKGREV=4
declare -r GCC_BUILT_DATE=$(date +%Y.%m.%d)

# Version
declare -r GMP_VER='6.1.0'
declare -r MPFR_VER='3.1.4'
declare -r MPC_VER='1.0.3'
declare -r ISL_VER='0.17.1'
declare -r ZLIB_VER='git'
declare -r ICONV_VER='1.14'
declare -r MINGW_VER='git'
declare -r MCFGTHREAD_VER='git'
declare -r BINUTILS_VER='2.25.1'
declare -r GCC_VER='6.1.0'
declare -r NASM_VER='2.12.02rc9'
# declare -r NASM_SS='20150118'
declare -r YASM_VER='1.3.0'
declare -r AUTOCONF_VER='2.69'
declare -r AUTOMAKE_VER='1.15'
declare -r LIBTOOL_VER='2.4.6'
declare -r use_win_iconv=true

# Comment out if you don't want to rebuild.
# prerequisites for GCC
declare gmp_rebuild=true
declare mpfr_rebuild=true
declare mpc_rebuild=true
declare isl_rebuild=true

# MinGW-w64 toolchain
declare zlib_rebuild=true
declare iconv_rebuild=true
declare headers_rebuild=true
declare threads_rebuild=true
declare crt_rebuild=true
declare mcfgthread_rebuild=true
declare binutils_rebuild=true
declare gcc_rebuild=true

# Rebuild with newer GCC.
declare binutils_2nd_rebuild=true
declare crt_2nd_rebuild=true
declare mcfgthread_2nd_rebuild=true
declare threads_2nd_rebuild=true

# MinGW-w64 additional packages
declare mangle_rebuild=true
declare tools_rebuild=true

# nyasm
declare nasm_rebuild=true
declare yasm_rebuild=true

# autotools
declare autoconf_rebuild=true
declare automake_rebuild=true
declare libtool_rebuild=true
