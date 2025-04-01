#!/usr/bin/env bash

# https://github.com/pyenv/pyenv

set -e


# Default pyenv root
USER="vagrant"
PYENV_ROOT="/home/$USER/.pyenv"
PYENV_GIT_TAG="2.44.2"  # You can change this to a specific tag or branch for example master
[ -n "$PYENV_DEBUG" ] && set -x

if [ -z "$PYENV_ROOT" ]; then
  if [ -z "$HOME" ]; then
    echo "$0: Either \$PYENV_ROOT or \$HOME must be set to determine the install location." >&2
    exit 1
  fi
  export PYENV_ROOT="${HOME}/.pyenv"
fi

colorize() {
  if [ -t 1 ]; then printf "\e[%sm%s\e[m" "$1" "$2"
  else echo -n "$2"
  fi
}

# Check if PYENV_ROOT already exists
if [ -d "${PYENV_ROOT}" ]; then
  { echo
    colorize 1 "WARNING"
    echo ": Cannot proceed with installation. Please remove the '${PYENV_ROOT}' directory first."
    echo
  } >&2
  exit 1
fi

failed_checkout() {
  echo "Failed to git clone $1" >&2
  exit 1
}

checkout() {
  [ -d "$2" ] || git -c advice.detachedHead=0 clone --branch "$3" --depth 1 "$1" "$2" || failed_checkout "$1"
}

# Ensure Git is installed
if ! command -v git 1>/dev/null 2>&1; then
  echo "pyenv: Git is not installed. Please install Git and try again." >&2
  exit 1
fi

# SSH configuration if USE_SSH is set
if [ -n "${USE_SSH}" ]; then
  if ! command -v ssh 1>/dev/null 2>&1; then
    echo "pyenv: configuration USE_SSH found, but ssh is not installed. Please install ssh and try again." >&2
    exit 1
  fi

  ssh -T git@github.com 1>/dev/null 2>&1 || EXIT_CODE=$?
  if [[ ${EXIT_CODE} != 1 ]]; then
    echo "pyenv: SSH authentication failed. Please set up an SSH key for GitHub access." >&2
    exit 1
  fi
fi

# Set GitHub URL
if [ -n "${USE_SSH}" ]; then
  GITHUB="git@github.com:"
else
  GITHUB="https://github.com/"
fi

# Clone pyenv and plugins
checkout "${GITHUB}pyenv/pyenv.git"            "${PYENV_ROOT}"                           "${PYENV_GIT_TAG}"
checkout "${GITHUB}pyenv/pyenv-doctor.git"     "${PYENV_ROOT}/plugins/pyenv-doctor"      "${PYENV_GIT_TAG}"
checkout "${GITHUB}pyenv/pyenv-update.git"     "${PYENV_ROOT}/plugins/pyenv-update"      "${PYENV_GIT_TAG}"
checkout "${GITHUB}pyenv/pyenv-virtualenv.git" "${PYENV_ROOT}/plugins/pyenv-virtualenv"  "${PYENV_GIT_TAG}"

echo 'export PYENV_ROOT="$HOME/.pyenv"' >> /home/$USER/.bashrc
echo 'command -v pyenv >/dev/null || export PATH="$PYENV_ROOT/bin:$PATH"' >> /home/$USER/.bashrc
echo 'eval "$(pyenv init -)"' >> /home/$USER/.bashrc


echo 'export PYENV_ROOT="$HOME/.pyenv"' >> /home/$USER/.bash_profile
echo '[[ -d $PYENV_ROOT/bin ]] && export PATH="$PYENV_ROOT/bin:$PATH"' >> /home/$USER/.bash_profile
echo 'eval "$(pyenv init -)"' >> /home/$USER/.bash_profile
