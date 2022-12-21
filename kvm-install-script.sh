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

OS=`lsb_release -i | awk -F':' '{print $2}' | sed -e "s/\s//g"`
VERSION=`lsb_release -r | awk -F':' '{print $2}' | sed -e "s/\s//g"`

echo $OS
echo $VERSION

case ${OS} in
  "Ubuntu")
    case ${VERSION} in
      "22.04")
        export DEBIAN_FRONTEND=noninteractive
        apt-get install -y qemu-kvm libvirt-clients libvirt-daemon-system bridge-utils virt-manager
        ;;
      "20.04")
        apt-get install -y qemu-kvm libvirt-clients libvirt-daemon-system bridge-utils virt-manager
        ;;
      "18.04")
        apt-get install -y qemu-kvm libvirt-bin ubuntu-vm-builder bridge-utils
        ;;
      *)
        echo "NO VERSION MATCH"
        ;;
    esac
    ;;
  *)
    echo "NO OS MATCH"
    ;;
esac

adduser ${SUDO_USER} libvirt
adduser ${SUDO_USER} libvirt-qemu
adduser ${SUDO_USER} kvm

kvm-ok

virt-host-validate qemu
