# If not running interactively, don't do anything
[[ "$-" != *i* ]] && return

# cmd
echo '
CALL chcp 65001 > nul
exit
' | cmd > /dev/null

# MSYS
MSYS='winsymlinks:nativestrict'
export MSYS

# PATH
alias cpath='source cpath'

# language
LANG='en_US.UTF-8'
LC_CTYPE='ja_JP.UTF-8'
LC_COLLATE='C'
export LANG LC_CTYPE LC_COLLATE

# colors
eval "`dircolors -b /etc/DIR_COLORS`"

# ps
alias ps='procps u'

# ls
alias ls='ls -CF -a --color=auto --show-control-chars'
alias ll='ls -AlFh --show-control-chars --color=auto'
alias la='ls -CFal'
alias sl='erutaso -Fa'
alias dir='ls --color=auto --format=vertical'
alias vdir='ls --color=auto --format=long'
alias l='ls -CF'

# tree
alias tree='tree -la'

# df/du
alias df='df -h'
alias du='du -h'

# misc
alias whence='type -a'
alias grep='grep --color'
alias egrep='egrep --color'
alias fgrep='fgrep --color'

# less
alias less='less -r'
LESSHISTFILE=/tmp/.lesshst
export LESSHISTFILE

# pacman
alias pacman_mingw64='pacman --root $HOME/.pacman --cachedir $HOME/.pacman/var/cache/pacman/pkg --config $HOME/.pacman/pacman.conf'

function addpkg() {
    local -r _pkgfile="${1}"

    local -r _pkgname="${_pkgfile##*/}"
    local -r _MYPKG_PATH="${HOME}"/.mypackages

    if [ -z "${_pkgfile}" ]; then
        echo 'addpkg: pkgfile is not specified!'
        return -1
    fi

    case "${_pkgname}" in
        mingw32*)
            mv -f "${_pkgfile}" "${_MYPKG_PATH}"/mingw32
            repo-add "${_MYPKG_PATH}"/mingw32/mingw32_Takuan.db.tar.xz "${_MYPKG_PATH}"/mingw32/$_pkgname
            ;;
        mingw64*)
            mv -f "${_pkgfile}" "${_MYPKG_PATH}"/mingw64
            repo-add "${_MYPKG_PATH}"/mingw64/mingw64_Takuan.db.tar.xz "${_MYPKG_PATH}"/mingw64/$_pkgname
            ;;
        *)
            mv -f "${_pkgfile}" "${_MYPKG_PATH}"/msys
            repo-add "${_MYPKG_PATH}"/msys/msys_Takuan.db.tar.xz "${_MYPKG_PATH}"/msys/$_pkgname
            ;;
    esac

    return 0
}

# makepkg
alias makepkg='makepkg --skippgpcheck --skipchecksums --nocheck'

# tar
alias tar_lzip='tar xf'
alias tar_bz2='tar xjf'
alias tar_gz='tar xzf'
alias tar_lzma='tar xf'
alias tar_xz='tar Jxf'

# omake
alias sanchi='clear; \cat /usr/local/bin/sanchi.txt'
alias nde='clear; \cat /usr/local/bin/nde.txt'

# kuins
function kuins() {
    local _ecs_id="${1}"
    local _port="${2}"

    if [ -z "${_ecs_id}" ]; then
        echo "ECS-ID is not specified!"
        return -1
    fi
    if [ -z "${_port}" ]; then
        _port=8080
    fi
    ssh -L ${_port}:proxy.kuins.net:${_port} ${_ecs_id}@forward.kuins.kyoto-u.ac.jp
}

# ldd for i686
function ldd32() {
    /usr/local/bin32/ldd "$@" | sed 's| /cygdrive| |g' | sed 's| /c/msys2| |g'
}

# TVTest
function tv_t() {
    start /d/PT2/TVTest/TVTest.exe //d BonDriver_PT-T.dll

    local _exists=false
    if [ -f /tmp/win32applist ] ; then
        local -i i=0
        local -a list
        while read line
        do
            list[i]=$line
            i=$((${i} + 1))
        done < /tmp/win32applist
        for (( i = 0; i < ${#list[*]}; i++ ))
        do
            if [ "${list[${i}]}" = "TVTest" ] ; then
                _exists=true
            fi
        done
    fi
    if ! $_exists ; then
        echo TVTest >> /tmp/win32applist
    fi
}

function tv_bs() {
    start /d/PT2/TVTest/TVTest.exe //d BonDriver_PT-S.dll //chspace 0 //rch 11

    local _exists=false
    if [ -f /tmp/win32applist ] ; then
        local -i i=0
        local -a list
        while read line
        do
            list[i]=$line
            i=$((${i} + 1))
        done < /tmp/win32applist
        for (( i = 0; i < ${#list[*]}; i++ ))
        do
            if [ "${list[${i}]}" = "TVTest" ] ; then
                _exists=true
            fi
        done
    fi
    if ! $_exists ; then
        echo TVTest >> /tmp/win32applist
    fi
}

function tv_cs() {
    start /d/PT2/TVTest/TVTest.exe //d BonDriver_PT-S.dll //chspace 1 //rch 330

    local _exists=false
    if [ -f /tmp/win32applist ] ; then
        local -i i=0
        local -a list
        while read line
        do
            list[i]=$line
            i=$((${i} + 1))
        done < /tmp/win32applist
        for (( i = 0; i < ${#list[*]}; i++ ))
        do
            if [ "${list[${i}]}" = "TVTest" ] ; then
                _exists=true
            fi
        done
    fi
    if ! $_exists ; then
        echo TVTest >> /tmp/win32applist
    fi
}

# firefox
function firefox() {
    start /c/firefox/firefox.exe -p nightly_x64

    local _exists=false
    if [ -f /tmp/win32applist ] ; then
        local -i i=0
        local -a list
        while read line
        do
            list[i]=$line
            i=$((${i} + 1))
        done < /tmp/win32applist
        for (( i = 0; i < ${#list[*]}; i++ ))
        do
            if [ "${list[${i}]}" = "firefox" ] ; then
                _exists=true
            fi
        done
    fi
    if ! $_exists ; then
        echo firefox >> /tmp/win32applist
    fi
}

# mpc-hc
function play() {
    start /d/Program_Files_portable/mpc-hc/mpc-hc.exe "$@"

    local _exists=false
    if [ -f /tmp/win32applist ] ; then
        local -i i=0
        local -a list
        while read line
        do
            list[i]=$line
            i=$((${i} + 1))
        done < /tmp/win32applist
        for (( i = 0; i < ${#list[*]}; i++ ))
        do
            if [ "${list[${i}]}" = "mpc-hc" ] ; then
                _exists=true
            fi
        done
    fi
    if ! $_exists ; then
        echo mpc-hc >> /tmp/win32applist
    fi
}

# notepad++
function nppp() {
    start /c/progra~2/Notepad++/notepad++.exe "$@"

    local _exists=false
    if [ -f /tmp/win32applist ] ; then
        local -i i=0
        local -a list
        while read line
        do
            list[i]=$line
            i=$((${i} + 1))
        done < /tmp/win32applist
        for (( i = 0; i < ${#list[*]}; i++ ))
        do
            if [ "${list[${i}]}" = "notepad++" ] ; then
                _exists=true
            fi
        done
    fi
    if ! $_exists ; then
        echo notepad++ >> /tmp/win32applist
    fi
}

# git
function git_sub_update() {
    git submodule foreach --recursive git clean -fdx
    git submodule foreach --recursive git reset --hard
    git submodule foreach --recursive git fetch --tags
    git submodule update --init --recursive
}

# mercurial
HG=${HOME}/winn/mercurial/hg.exe
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

# GCC
GCC_COLORS='error=01;31;255:warning=01;35;255:note=01;36;255:caret=01;32;255:locus=01:quote=01'
export GCC_COLORS
BASE_CFLAGS="-pipe -march=sandybridge -Os -fomit-frame-pointer -foptimize-strlen -fexcess-precision=fast -fno-fast-math -fno-math-errno -fno-signed-zeros -fno-tree-vectorize -fstack-protector-strong --param=ssp-buffer-size=4 -mcrtdll=msvcr120"
BASE_CPPFLAGS="-D__USE_MINGW_ANSI_STDIO=1 -D_FORTIFY_SOURCE=2 -DWINVER=0x0601 -D_WIN32_WINNT=0x0601 -D__MINGW_USE_VC2005_COMPAT=1 -D_FILE_OFFSET_BITS=64 -D_GNU_SOURCE=1 -D_BSD_SOURCE=1 -D_POSIX_SOURCE=1 -D_POSIX_C_SOURCE=200809L -D_XOPEN_SOURCE=700"
BASE_CXXFLAGS="${BASE_CFLAGS}"
BASE_LDFLAGS="-Wl,-s,-O1,--sort-common,--as-needed -mcrtdll=msvcr120"
export BASE_CFLAGS BASE_CPPFLAGS BASE_CXXFLAGS BASE_LDFLAGS

# proxy
alias cproxy='source cproxy'
