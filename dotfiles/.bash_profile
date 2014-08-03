# LANG for pacman
LANG='en_US.UTF-8'
export LANG

# pacman
pacman -Syu
reset

# show date
/usr/local/bin/showdate

# if running bash
if [ -n "${BASH_VERSION}" ]; then
  if [ -f "${HOME}/.bashrc" ]; then
    source "${HOME}/.bashrc"
  fi
fi
