#!/bin/bash

ABS_PATH=`readlink -f $0 | sed 's/\/[^\/]*$//'`

if uname -r | egrep '686-pae$' &> /dev/null; then
  LB_DISK="${ABS_PATH}/live-image-i386.img"
  RAW_DISK="${ABS_PATH}/live-image-i386.raw"
  LINUX_HEADERS="linux-headers-686-pae"
  REPO_ARCH="i386"
else
  LB_DISK="${ABS_PATH}-amd64.img"
  RAW_DISK="${ABS_PATH}/live-image-amd64.raw"
  LINUX_HEADERS="linux-headers-amd64"
  REPO_ARCH="amd64"
fi

DEPSOK="${ABS_PATH}/.depsok"

MIRROR_DIR="${ABS_PATH}/aptly"
PKGL_LB="${MIRROR_DIR}/lb_packages.list"
PKGL_DIR="${ABS_PATH}/config/package-lists"
PKGL_STR="$( cat ${PKGL_LB} ${PKGL_DIR}/* | grep -v '^#' | sed '/^$/d' | sort | paste -s -d'|' | sed 's/|/ | /g' )" FILTER="Priority (required) | Priority (important) | Priority (standard) | ${PKGL_STR}"

OPTS="(update | img | clean | purge)"

# - - - - -


err() {
  echo
  echo "  [*] Error: $1"
}


usage() {
  echo
  echo "----------------------------------------------------------------------------------------"
  echo
  echo "  Usage: $0 -o $OPTS"
  echo
  echo "  Run 'update' first if executing for the first time. Must be connected to the Internet."
  echo "  Run 'img' to build ISO/HDD file. Inbetween builds, run 'clean' or 'purge'."
  echo
  echo "----------------------------------------------------------------------------------------"
  echo
  exit 1
}


setmirror() {
  cat ${MIRROR_DIR}/aptly.conf | sed "s|\(^ *\"rootDir\": \).*|\1\"${MIRROR_DIR}\",|" > /root/.aptly.conf
}


imgbuild() {
  setmirror

  # check if repo key is in place
  if ! [ -f ${ABS_PATH}/config/archives/aptly.key ]; then
    gpg --export --armor > ${ABS_PATH}/config/archives/aptly.key
  fi

  # create and publish mirror snapshots
  aptly snapshot create stretch-main-spei from mirror stretch-main
  aptly snapshot create stretch-updates-spei from mirror stretch-updates
  aptly snapshot create stretch-security-spei from mirror stretch-security

  aptly snapshot merge -latest stretch-final-spei stretch-main-spei stretch-updates-spei stretch-security-spei
  aptly publish snapshot -distribution=stretch stretch-final-spei

  # ensure mirror is not yet running, then run it
  kill $( pgrep -f "aptly serve" ) 2> /dev/null
  aptly serve &

  # run build
  lb build

  # stop mirror and wipe snapshots
  kill $( pgrep -f "aptly serve" ) 2> /dev/null

  aptly publish drop stretch

  aptly snapshot drop stretch-final-spei
  aptly snapshot drop stretch-security-spei
  aptly snapshot drop stretch-updates-spei
  aptly snapshot drop stretch-main-spei
}


update() {
  if ! [ -d /root/.gnupg ]; then
    rngd -r /dev/urandom
    gpg --gen-key --batch ${MIRROR_DIR}/genkey.unattended
    gpg --no-default-keyring --keyring /usr/share/keyrings/debian-archive-keyring.gpg --export | gpg --no-default-keyring --keyring trustedkeys.gpg --import
    killall rngd
  fi

  setmirror

  mirrors="$( aptly mirror list | grep '^ * ' | sed 's/.*\[\([A-Za-z-]*\).*/\1/' )"

  echo "$mirrors" | grep stretch-main      &> /dev/null && aptly mirror drop stretch-main
  echo "$mirrors" | grep stretch-updates   &> /dev/null && aptly mirror drop stretch-updates
  echo "$mirrors" | grep stretch-security  &> /dev/null && aptly mirror drop stretch-security

  aptly mirror create -architectures=${REPO_ARCH} -filter="$FILTER" -filter-with-deps stretch-main http://ftp.br.debian.org/debian/ stretch main contrib non-free
  aptly mirror create -architectures=${REPO_ARCH} -filter="$FILTER" -filter-with-deps stretch-updates http://ftp.br.debian.org/debian/ stretch-updates main contrib non-free
  aptly mirror create -architectures=${REPO_ARCH} -filter="$FILTER" -filter-with-deps stretch-security http://security.debian.org/debian-security/ stretch/updates main contrib non-free

  aptly mirror update stretch-main
  aptly mirror update stretch-updates
  aptly mirror update stretch-security
}


clean () {
  rm -rf ${LB_DISK}
  [ -n "$1" ] && lb clean --purge || lb clean
}


deps() {
  # add necessary repository sections & update
  sed -i 's/\(main\) *$/\1 contrib non-free/' /etc/apt/sources.list
  apt-get update

  apt-get -y install --no-install-recommends ${LINUX_HEADERS} live-build mbr netcat-traditional syslinux aptly rng-tools dirmngr
}


# - - - - -


if [ $( id -u ) -ne 0 ]; then
  err "$0 must be run as root. Aborting..."
  exit 1
fi

if ! uname -r | egrep '686-pae$|amd64$' &> /dev/null; then
  err "Must run on '686-pae' or 'amd64' kernel archs. Aborting..."
  exit 1
fi

while getopts ":o:" opt; do
  case "$opt" in
    o)
      option=${OPTARG}
      ;;
    *)
      usage
      ;;
  esac
done

[ -z $option ] && { err "No option specified, aborting."; usage; }

# check deps
if [ ! -f ${DEPSOK} ]; then
  if [ $( which lb ) ] && [ $( which install-mbr ) ] && [ $( which nc ) ] && [ $( which syslinux ) ] && [ $( which aptly ) ] && [ $( which rngd ) ] && [ $( which dirmngr ) ]; then
    echo "All dependencies met. Continuing..."
  else
    echo "Missing dependencies. Installing..."
    deps
  fi

  touch ${DEPSOK}
fi

case ${option} in
  "img")
    mirrors="$( aptly mirror list | grep '^ * ' | sed 's/.*\[\([A-Za-z-]*\).*/\1/' )"
    ! echo "$mirrors" | grep stretch-main &> /dev/null && { err "No 'stretch-main' mirror detected, run '$0 -o update' first."; usage; }
    ! echo "$mirrors" | grep stretch-updates &> /dev/null && { err "No 'stretch-updates' mirror detected, run '$0 -oupdate' first."; usage; }
    ! echo "$mirrors" | grep stretch-security &> /dev/null && { err "No 'stretch-security' mirror detected, run '$0 -o update' first."; usage; }

    imgbuild
    ;;
  "update")
    update
    ;;
  "clean")
    clean
    ;;
  "purge")
    clean all
    ;;
  *)
    usage
    ;;
esac
