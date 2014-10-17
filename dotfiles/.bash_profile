# LANG for pacman
LANG='en_US.UTF-8'
export LANG

# pacman
pacman -Syu
/usr/bin/reset -Q

# show date
/usr/local/bin/showdate

# if running bash
if [ -n "${BASH_VERSION}" ]; then
  if [ -f "${HOME}/.bashrc" ]; then
    source "${HOME}/.bashrc"
  fi
fi
