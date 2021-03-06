#!/bin/bash -e

DEST_DIR=/usr/local/share/marelle
DEST_BIN=/usr/local/bin/marelle

function has_exec() {
  [ ! -z "$(which $1)" ]
}

function missing_exec() {
  [ -z "$(which $1)" ]
}

is_apt_updated=0
function apt_update() {
  if [ $is_apt_updated -eq 0 ]; then
    sudo apt-get update
    is_apt_updated=1
  fi
}

is_brew_updated=0
function brew_update() {
  if [ $is_brew_updated -eq 0 ]; then
    brew update
    is_brew_updated=1
  fi
}

function install_bash() {
  echo 'Trying to install bash'
  case $(uname -s) in
    Linux)
      if has_exec apt-get; then
        apt_update
        sudo apt-get install -y bash
      elif has_exec yum; then
        # XXX yum update?
        sudo yum install bash
      else
        bail "Unknown linux variant"
      fi
      ;;
    FreeBSD)
      if has_exec pkg; then
        sudo pkg install -y bash
      else
        bail "Old FreeBSD version without pkgng"
      fi
      ;;
    *)
      bail "Unknown operating system $(uname -s)"
      ;;
  esac
}

function install_git() {
  echo 'Trying to install git'
  case $(uname -s) in
    Darwin)
      if has_exec brew; then
        brew_update
        brew install git
      else
        bail "Please install Homebrew and retry"
      fi
      ;;
    Linux)
      if has_exec apt-get; then
        apt_update
        sudo apt-get install -y git
      elif has_exec yum; then
        # XXX yum update?
        sudo yum install git
      else
        bail "Unknown linux variant"
      fi
      ;;
    FreeBSD)
      if has_exec pkg; then
        sudo pkg install -y git
      else
        bail "Old FreeBSD version without pkgng"
      fi
      ;;
    *)
      bail "Unknown operating system $(uname -s)"
      ;;
  esac
}

function install_prolog() {
  echo 'Trying to install prolog'
  case $(uname -s) in
    Darwin)
      if has_exec brew; then
        brew_update
        brew install swi-prolog
      else
        bail "Please install Homebrew and retry"
      fi
      ;;
    Linux)
      if has_exec apt-get; then
        apt_update
        sudo apt-get install -y swi-prolog-nox
      elif has_exec yum; then
        sudo yum install swi-prolog
      else
        bail "Unknown linux variant"
      fi
      ;;
    FreeBSD)
      if has_exec pkg; then
        sudo pkg install -y swi-pl
      else
        bail "Old FreeBSD version without pkgng"
      fi
      ;;
    *)
      bail "Unknown operating system $(uname -s)"
      ;;
  esac
}

function bail()
{
  echo "$1 -- bailing"
  exit 1
}

function check_in_path() {
  echo $PATH | tr ':' '\n' | grep -x -c "$1";
}


function checkout_marelle() {
  echo 'Trying to check out marelle'
  sudo mkdir -p "${DEST_DIR}"
  cd "$(dirname ${DEST_DIR})"
  sudo git clone https://github.com/larsyencken/marelle
  sudo bash -c "cat > ${DEST_BIN}" <<EOF
#!/usr/bin/env bash
exec swipl -q -t main -s "${DEST_DIR}/marelle.pl" "\$@"
EOF
  sudo chmod a+x "${DEST_BIN}"
  if [ ! -d "${DEST_DIR}" -o ! -x "${DEST_BIN}" ]; then
    bail "Ran into a problem checking out marelle"
  fi
}

function main() {
  echo 'BOOTSTRAPPING MARELLE'
  if missing_exec bash; then
    install_bash
  fi
  echo 'Bash: OK'

  if missing_exec git; then
    install_git
  fi
  echo 'Git: OK'

  if missing_exec swipl; then
    install_prolog
  fi
  echo 'Prolog: OK'

  if [ ! -d "${DEST_DIR}" ]; then
    checkout_marelle
  fi
  echo 'Marelle: OK'

  hash -r
  if missing_exec marelle; then
    bail "Couldn't setup marelle in PATH"
  fi
  echo 'Marelle in PATH: OK'
  echo 'DONE'
}

main
