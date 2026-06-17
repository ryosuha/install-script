#!/bin/bash
set -e

#SUB ROUTINE
install_ubuntu() {
  apt-get update
  apt-get install -y apt-transport-https ca-certificates curl gnupg lsb-release

  install -m 0755 -d /etc/apt/keyrings
  curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
  chmod a+r /etc/apt/keyrings/docker.asc

tee /etc/apt/sources.list.d/docker.sources <<EOF
Types: deb
URIs: https://download.docker.com/linux/ubuntu
Suites: $(. /etc/os-release && echo "${UBUNTU_CODENAME:-$VERSION_CODENAME}")
Components: stable
Architectures: $(dpkg --print-architecture)
Signed-By: /etc/apt/keyrings/docker.asc
EOF

  apt-get update
  apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
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
      "26.04")
        export DEBIAN_FRONTEND=noninteractive
        install_ubuntu
        ;;
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
