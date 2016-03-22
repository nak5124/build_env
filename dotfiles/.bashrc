# If not running interactively, don't do anything
[[ "${-}" != *i* ]] && return

# cmd
echo '
CALL chcp 65001 > nul
exit
' | cmd > /dev/null

# language
LANG='en_US.UTF-8'
LC_CTYPE='ja_JP.UTF-8'
LC_COLLATE='C'
export LANG LC_CTYPE LC_COLLATE

# MSYS
MSYS='winsymlinks:nativestrict'
export MSYS

# colors
eval "`dircolors -b /etc/DIR_COLORS`"

# mercurial
HG="${HOME}"/winn/mercurial/hg.exe
export HG

# shell
PROMPT_COMMAND='printf "\033]0;%s: %s\007" "${MSYSTEM}" "${PWD/${HOME}/\~}"'
PS1="\n\033[1;32m\]\u@\h \[\033[1;31m\w\033[0m\]\n$ "
IGNOREEOF=2
EXECIGNORE="*.dll"
export PROMPT_COMMAND PS1 IGNOREEOF EXECIGNORE

shopt -s autocd
shopt -s cdable_vars
shopt -s cdspell
shopt -s checkhash
shopt -s completion_strip_exe
shopt -s dirspell
shopt -s dotglob
shopt -s extglob
shopt -s globstar
shopt -s lithist

set -o vi

# GCC
GCC_COLORS='error=01;31;255:warning=01;35;255:note=01;36;255:caret=01;32;255:locus=01:quote=01'
export GCC_COLORS
BASE_CPPFLAGS='-U__USE_MINGW_ANSI_STDIO -D__USE_MINGW_ANSI_STDIO=1 -D__USE_MINGW_ACCESS -U_FILE_OFFSET_BITS -D_FILE_OFFSET_BITS=64 -UWINVER -DWINVER=0x0a00 -U_WIN32_WINNT -D_WIN32_WINNT=0x0a00 -U_GNU_SOURCE -D_GNU_SOURCE=1 -U_BSD_SOURCE -D_BSD_SOURCE=1 -U_POSIX_SOURCE -D_POSIX_SOURCE=1 -U_POSIX_C_SOURCE -D_POSIX_C_SOURCE=200809L -U_XOPEN_SOURCE -D_XOPEN_SOURCE=700'
BASE_CFLAGS='"-pipe -Os -fomit-frame-pointer -foptimize-strlen -fexcess-precision=fast -fno-fast-math -fno-math-errno -fno-signed-zeros -fno-tree-vectorize -fstack-protector-strong --param=ssp-buffer-size=4 -mcrtdll=msvcr120'
BASE_CXXFLAGS="${BASE_CFLAGS}"
BASE_LDFLAGS='-Wl,-s,-O1,--sort-common,--as-needed,--no-undefined,--no-gc-sections ${BASE_CFLAGS}'
export BASE_CPPFLAGS BASE_CFLAGS BASE_CXXFLAGS BASE_LDFLAGS

# import aliases
source "${HOME}"/.bash_alias

# import function
source "${HOME}"/.bash_func
