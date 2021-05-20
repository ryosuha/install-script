#!/bin/bash
set -e

# ref: https://askubuntu.com/a/30157/8698
if ! [ $(id -u) = 0 ]; then
   echo "The script need to be run as root." >&2
   echo "Sample sudo ./kvm-install-script.sh" >&2
   exit 1
fi

if [ ${SUDO_USER} ]; then
  echo ${SUDO_USER}
else
  echo "Run from Root User? Prefer to run from normal user with sudo command" >&2
  echo "Sample sudo ./kvm-install-script.sh" >&2
  exit 1
fi

apt update

UBUNTU=`lsb_release -d`
echo ${UBUNTU}
if [[ ${UBUNTU} =~ "Ubuntu 20.04" ]]; then
  VERSION=${BASH_REMATCH[0]}
fi

echo ${VERSION}

case ${VERSION} in
  "Ubuntu 20.04")
    apt install -y qemu-kvm libvirt-clients libvirt-daemon-system bridge-utils virt-manager
    ;;
  "Ubuntu 18.04.4 LTS")
    apt install -y qemu-kvm libvirt-bin ubuntu-vm-builder bridge-utils
    ;;
  *)
  echo "NO MATCH"
    ;;
esac

adduser ${SUDO_USER} libvirt
adduser ${SUDO_USER} libvirt-qemu
adduser ${SUDO_USER} kvm

kvm-ok

virt-host-validate qemu
