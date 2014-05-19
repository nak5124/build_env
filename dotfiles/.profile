# $LANG
LANG='en_US.UTF-8'
export LANG

# export LANG='ja_JP.UTF-8'

# if running bash
if [ -n "${BASH_VERSION}" ]; then
  if [ -f "${HOME}/.bashrc" ]; then
    source "${HOME}/.bashrc"
  fi
fi
