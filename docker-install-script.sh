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
   echo "Sample sudo ./kvm-install-script.sh" >&2
   exit 1
fi

if [ ${SUDO_USER} ]; then
  echo ${SUDO_USER}
else
  echo "Run from Root User? Prefer to run from normal user with sudo command" >&2
  echo "Sample sudo ./kvm-install-script.sh" >&2
fi

apt update

UBUNTU=`lsb_release -d`
echo $UBUNTU
if [[ ${UBUNTU} =~ "Ubuntu 20.04" ]]; then
  VERSION=${BASH_REMATCH[0]}
fi

echo $VERSION

case ${VERSION} in
  "Ubuntu 20.04")
    install_ubuntu
    ;;
  "Ubuntu 18.04")
    install_ubuntu
    ;;
  *)
  echo "NO MATCH"
    ;;
esac

