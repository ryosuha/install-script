#!/bin/bash
set -e

install_ubuntu2004() {
    kOS=xUbuntu_20.04
    kVERSION=1.26:1.26.0
    kVERSION1=1.26
    kVERSIONLONG=1.26.0-00

    if [ ${1} ]; then
        kVERSION=${1}:${1}.0
        kVERSION1=${1}
        kVERSIONLONG=${1}.0-00
    fi
    
    apt update
    apt-get install -y apt-transport-https ca-certificates curl software-properties-common

    echo 'overlay' >> /etc/modules-load.d/crio.conf
    echo 'br_netfilter' >> /etc/modules-load.d/crio.conf
    modprobe overlay
    modprobe br_netfilter

    echo 'net.bridge.bridge-nf-call-iptables  = 1' >> /etc/sysctl.d/99-kubernetes-cri.conf
    echo 'net.ipv4.ip_forward                 = 1' >> /etc/sysctl.d/99-kubernetes-cri.conf
    echo 'net.bridge.bridge-nf-call-ip6tables = 1' >> /etc/sysctl.d/99-kubernetes-cri.conf
    sysctl --system

    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | apt-key add -
    add-apt-repository --yes "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"

    apt-get update
    apt-get install -y containerd.io

    mkdir -p /etc/containerd
    containerd config default | tee /etc/containerd/config.toml

    systemctl restart containerd

    echo 'br_netfilter' >> /etc/modules-load.d/k8s.conf

    echo 'net.bridge.bridge-nf-call-ip6tables = 1' >> /etc/sysctl.d/k8s.conf
    echo 'net.bridge.bridge-nf-call-iptables = 1' >> /etc/sysctl.d/k8s.conf

    sysctl --system

    apt update
    
    curl -fsSLo /usr/share/keyrings/kubernetes-archive-keyring.gpg https://packages.cloud.google.com/apt/doc/apt-key.gpg
    echo "deb [signed-by=/usr/share/keyrings/kubernetes-archive-keyring.gpg] https://apt.kubernetes.io/ kubernetes-xenial main" >> /etc/apt/sources.list.d/kubernetes.list
    apt update

    apt install -y kubelet=$kVERSIONLONG kubeadm=$kVERSIONLONG kubectl=$kVERSIONLONG

    apt-mark hold kubelet kubeadm kubectl

    swapoff /swap.img
    echo '#!/bin/bash' > /etc/rc.local
    echo 'swapoff /swap.img' >> /etc/rc.local
    echo 'exit 0' >> /etc/rc.local
    chmod +x /etc/rc.local

}


if ! [ $(id -u) = 0 ]; then
   echo "The script need to be run as root." >&2
   echo "Sample sudo ./k8s-install-script.sh [OPTIONAL(k8s version)]" >&2
   echo "Sample sudo ./k8s-install-script.sh [1.21]" >&2
   exit 1
fi

if [ ${SUDO_USER} ]; then
  echo ${SUDO_USER}
else
  echo "Run from Root User? Prefer to run from normal user with sudo command" >&2
  echo "Sample sudo ./k8s-install-script.sh [OPTIONAL(k8s version)]" >&2
  echo "Sample sudo ./k8s-install-script.sh [1.21]" >&2
  exit 1
fi

if [ ${1} ]; then
  echo "Will install k8s ver ${1}"
fi

OS=`lsb_release -i | awk -F':' '{print $2}' | sed -e "s/\s//g"`
VERSION=`lsb_release -r | awk -F':' '{print $2}' | sed -e "s/\s//g"`

echo $OS
echo $VERSION

case ${OS} in
  "Ubuntu")
    case ${VERSION} in
      "22.04")
        export DEBIAN_FRONTEND=noninteractives
        install_ubuntu2004 ${1}
        ;;
      "20.04")
        install_ubuntu2004 ${1}
        ;;
      "18.04")
        #install_ubuntu1804
        echo "Install Script Not Supported"
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

