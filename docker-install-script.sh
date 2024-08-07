#!/bin/bash
set -e

#SUB ROUTINE
install_ubuntu() {
  apt-get install -y apt-transport-https ca-certificates curl gnupg lsb-release

  curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg

  echo \
  "deb [arch=amd64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" |  tee /etc/apt/sources.list.d/docker.list > /dev/null

  apt-get update
  apt-get install -y docker-ce docker-ce-cli containerd.io
}

# ref: https://askubuntu.com/a/30157/8698
if ! [ $(id -u) = 0 ]; then
   echo "The script need to be run as root." >&2
   echo "Sample sudo ./docker-install-script.sh" >&2
   exit 1
fi

if [ ${SUDO_USER} ]; then
  echo ${SUDO_USER}
else
  echo "Run from Root User? Prefer to run from normal user with sudo command" >&2
  echo "Sample sudo ./docker-install-script.sh" >&2
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
      "24.04")
        export DEBIAN_FRONTEND=noninteractive
        install_ubuntu
        ;;
      "22.04")
        export DEBIAN_FRONTEND=noninteractive
        install_ubuntu
        ;;
      "20.04")
        install_ubuntu
        ;;
      "18.04")
        install_ubuntu
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
