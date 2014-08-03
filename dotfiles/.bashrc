# If not running interactively, don't do anything
[[ "$-" != *i* ]] && return

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
alias more="\less '-E -P?f--More-- (%pb\%):--More--.'"

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
alias sanchi='clear; \cat /usr/local/bin/sanchi.txt'
alias nde='clear; \cat /usr/local/bin/nde.txt'

# TVTest
alias TV_T='start /d/PT2/TVTest/TVTest.exe //d BonDriver_PT-T.dll'
alias TV_BS='start /d/PT2/TVTest/TVTest.exe //d BonDriver_PT-S.dll //chspace 0 //rch 11'
alias TV_CS='start /d/PT2/TVTest/TVTest.exe //d BonDriver_PT-S.dll //chspace 1 //rch 330'
alias tv_t='TV_T'
alias tv_bs='TV_BS'
alias tv_cs='TV_CS'

# firefox
alias firefox='start /c/firefox/firefox.exe -p nightly_x64'

# mpc-hc
alias play='start /d/Program_Files_portable/mpc-hc/mpc-hc.exe "$@"'

# notepad++
alias nppp='start /c/progra~2/Notepad++/notepad++.exe "$@"'

# shell
PROMPT_COMMAND='printf "\033]0;%s: %s\007" "${MSYSTEM}" "${PWD/${HOME}/\~}"'
PS1="\n\033[1;32m\]\u@\h \[\033[1;31m\w\033[0m\]\n$ "
IGNOREEOF=2
export PROMPT_COMMAND PS1 IGNOREEOF

# GCC
GCC_COLORS='error=01;31;255:warning=01;35;255:note=01;36;255:caret=01;32;255:locus=01:quote=01'
export GCC_COLORS
BASE_CFLAGS="-pipe -Os -msse4 -fomit-frame-pointer -fexcess-precision=fast"
BASE_CPPFLAGS="-D_FORTIFY_SOURCE=2 -D__USE_MINGW_ANSI_STDIO=1"
BASE_CXXFLAGS="${BASE_CFLAGS}"
BASE_LDFLAGS="-pipe -s -Wl,-O1 -Wl,--as-needed -Wl,--nxcompat -Wl,--dynamicbase"
export BASE_CFLAGS BASE_CPPFLAGS BASE_CXXFLAGS BASE_LDFLAGS

# proxy
alias cproxy='source cproxy'
