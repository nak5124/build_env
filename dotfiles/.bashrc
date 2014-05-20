# If not running interactively, don't do anything
[[ "$-" != *i* ]] && return

# show date
/usr/bin/showdate

# PATH
alias cpath='source cpath'

# language
LC_CTYPE='ja_JP.UTF-8'
export LC_CTYPE

# colors
eval "`dircolors -b /usr/etc/DIR_COLORS`"

# ls
alias ls='ls -CF -a --color=auto --show-control-chars'
alias ll='ls -AlFh --show-control-chars --color=auto'
alias la='ls -CFal'
alias sl=ls

# cat
alias cat='cat -n'

# git
alias git_diff='git diff --ignore-space-at-eol'
alias git_log='git log --date=short --pretty="format:%h%x20%x20[%cd]%x20%x20%s"'
alias git_log2='git log --date=short --pretty="format:%h%x20[%cd]%x20[%an:]%x20%s"'

# wget
#alias wget='wget -c'

# tar
alias tar_lzip='tar xf'
alias tar_bz2='tar xjf'
alias tar_gz='tar xzf'
alias tar_lzma='tar xf'
alias tar_xz='tar Jxf'

# omake
alias sanchi='cat /usr/bin/sanchi.txt'
alias nde='cat /usr/bin/nde.txt'

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

# GCC
GCC_COLORS='error=01;31;255:warning=01;35;255:note=01;36;255:caret=01;32;255:locus=01:quote=01'
export GCC_COLORS
BASE_CFLAGS="-pipe -Os -msse4 -fomit-frame-pointer -fexcess-precision=fast -march=x86-64 -mtune=generic -D__USE_MINGW_ANSI_STDIO=1"
BASE_CPPFLAGS="-D__USE_MINGW_ANSI_STDIO=1"
BASE_CXXFLAGS="$BASE_CFLAGS"
BASE_LDFLAGS="-pipe -Wl,-O1 -Wl,--as-needed -Wl,-s -Wl,--nxcompat -Wl,--dynamicbase"
export BASE_CFLAGS BASE_CPPFLAGS BASE_CXXFLAGS BASE_LDFLAGS

# proxy
#http_proxy=proxy.kuins.net:8080
#https_proxy=$http_proxy
#ftp_proxy=$fpt_proxy
#export http_proxy https_proxy ftp_proxy

