# If not running interactively, don't do anything
[[ "$-" != *i* ]] && return

# pacman
pacman -Syu
reset

# show date
/usr/local/bin/showdate

# PATH
alias cpath='source cpath'

# language
LC_CTYPE='ja_JP.UTF-8'
export LC_CTYPE

# colors
eval "`dircolors -b /etc/DIR_COLORS`"

# ps
alias ps='procps u'

# ls
alias ls='ls -CF -a --color=auto --show-control-chars'
alias ll='ls -AlFh --show-control-chars --color=auto'
alias la='ls -CFal'
alias sl=nde
alias dir='ls --color=auto --format=vertical'
alias vdir='ls --color=auto --format=long'
alias l='ls -CF'

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

# cat
alias cat='cat -n'

# wget
#alias wget='wget -c'

# tar
alias tar_lzip='tar xf'
alias tar_bz2='tar xjf'
alias tar_gz='tar xzf'
alias tar_lzma='tar xf'
alias tar_xz='tar Jxf'

# omake
alias sanchi='\cat /usr/local/bin/sanchi.txt'
alias nde='\cat /usr/local/bin/nde.txt'

# TVTest
alias TV_T='/d/PT2/TVTest/TVTest.exe //d BonDriver_PT-T.dll & '
alias TV_BS='/d/PT2/TVTest/TVTest.exe //d BonDriver_PT-S.dll //chspace 0 //rch 11 & '
alias TV_CS='/d/PT2/TVTest/TVTest.exe //d BonDriver_PT-S.dll //chspace 1 //rch 330 & '
alias tv_t='TV_T'
alias tv_bs='TV_BS'
alias tv_cs='TV_CS'

# shell
PS1='\[\033]0;$MSYSTEM:\w\007
\033[1;32m\]\u@\h \[\033[1;31m\w\033[0m\]
$ '
export PS1

# C{ARCH,HOST}
case "$MSYSTEM" in
    MINGW32)
        CARCH=i686
        CHOST=${CARCH}-w64-mingw32
        ;;
    MINGW64)
        CARCH=x86_64
        CHOST=${CARCH}-w64-mingw32
        ;;
    MSYSTEM)
        CARCH=x86_64
        CHOST=${CARCH}-pc-msys
        ;;
esac
export CARCH CHOST

# GCC
GCC_COLORS='error=01;31;255:warning=01;35;255:note=01;36;255:caret=01;32;255:locus=01:quote=01'
export GCC_COLORS
BASE_CFLAGS="-pipe -Os -msse4 -fomit-frame-pointer -fexcess-precision=fast -march=x86-64 -mtune=generic"
BASE_CPPFLAGS="-D_FORTIFY_SOURCE=2 -D__USE_MINGW_ANSI_STDIO=1"
BASE_CXXFLAGS="${BASE_CFLAGS}"
BASE_LDFLAGS="-pipe -s -Wl,-O1 -Wl,--as-needed -Wl,--nxcompat -Wl,--dynamicbase"
export BASE_CFLAGS BASE_CPPFLAGS BASE_CXXFLAGS BASE_LDFLAGS

# proxy
alias cproxy='source cproxy'
