#!/bin/bash
set -e

install_ubuntu2004() {
    LB_IP1=${1}
    LB_IP2=${2}
    DEFAULT_DOMAIN=${3}


    if [ ${4} = 'kn' ] || [ ${5} = 'kn' ]; then
        INSTALL_KN="kn"
    fi

    if [ ${4} = 'go' ] || [ ${5} = 'go' ]; then
        INSTALL_GO="go"
    fi


    if [ -d tmp ]; then
        echo "tmp directory exist."
        echo "remove tmp directory and run again."
        exit 1
    else
        mkdir tmp
    fi

    cat << EOF > ./tmp/metallb-config.yaml
apiVersion: v1
kind: ConfigMap
metadata:
  namespace: metallb-system
  name: config
data:
  config: |
    address-pools:
    - name: default
      protocol: layer2
      addresses:
      - ${1}-${2}
EOF

    wget https://raw.githubusercontent.com/metallb/metallb/v0.11.0/manifests/namespace.yaml -P tmp/
    wget https://raw.githubusercontent.com/metallb/metallb/v0.11.0/manifests/metallb.yaml -P tmp/


    su $SUDO_USER -c "kubectl apply -f tmp/namespace.yaml"
    su $SUDO_USER -c "kubectl apply -f tmp/metallb.yaml"
    su $SUDO_USER -c "kubectl apply -f tmp/metallb-config.yaml"


    wget https://github.com/knative/serving/releases/download/knative-v1.0.0/serving-crds.yaml -P tmp/
    wget https://github.com/knative/serving/releases/download/knative-v1.0.0/serving-core.yaml -P tmp/
    wget https://github.com/knative/net-contour/releases/download/knative-v1.0.0/contour.yaml -P tmp/
    wget https://github.com/knative/net-contour/releases/download/knative-v1.0.0/net-contour.yaml -P tmp/


    su $SUDO_USER -c "kubectl apply -f tmp/serving-crds.yaml"
    su $SUDO_USER -c "kubectl apply -f tmp/serving-core.yaml"
    su $SUDO_USER -c "kubectl apply -f tmp/contour.yaml"
    su $SUDO_USER -c "kubectl apply -f tmp/net-contour.yaml"


    su $SUDO_USER -c "kubectl patch configmap/config-network --namespace knative-serving --type merge --patch '{\"data\":{\"ingress-class\":\"contour.ingress.networking.knative.dev\"}}'"

    wget https://github.com/knative/eventing/releases/download/knative-v1.0.0/eventing-crds.yaml -P tmp/
    wget https://github.com/knative/eventing/releases/download/knative-v1.0.0/eventing-core.yaml -P tmp/


    su $SUDO_USER -c "kubectl apply -f tmp/eventing-crds.yaml"
    su $SUDO_USER -c "kubectl apply -f tmp/eventing-core.yaml"


    cat << EOF > ./tmp/knative-domain-config.yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: config-domain
  namespace: knative-serving
data:
  # These are example settings of domain.
  # example.org will be used for routes having app=prod.
  prod.${3}: |
    selector:
      app: prod
  # Default value for domain, for routes that does not have app=prod labels.
  # Although it will match all routes, it is the least-specific rule so it
  # will only be used if no other domain matches.
  dev.${3}: ""
EOF

    su $SUDO_USER -c "kubectl apply -f tmp/knative-domain-config.yaml"


    if [ $INSTALL_GO = 'go' ]; then
        echo "Will Install Go"

        apt-get install -y gcc
        wget https://go.dev/dl/go1.17.7.linux-amd64.tar.gz -P tmp/
        cd tmp/
        tar zxvf go1.17.7.linux-amd64.tar.gz
        mv go/ /usr/local/
        SUDO_HOME=$(su $SUDO_USER -c "printenv HOME")
        su $SUDO_USER -c "echo \"export PATH=$PATH:/usr/local/go/bin\" >> $SUDO_HOME/.profile"
        cd ..

    else
        echo "Not installing Go"
    fi

    if [ $INSTALL_KN = 'kn' ]; then
        echo "Will Install kn"


        su $SUDO_USER -c "git clone https://github.com/knative/client.git"
        cd client/
        su $SUDO_USER -c "PATH=$PATH:/usr/local/go/bin/ && hack/build.sh -f"
        mv kn /usr/local/bin/
        cd ..

    else
        echo "Not installing kn"
    fi

}


if ! [ $(id -u) = 0 ]; then
   echo "The script need to be run as root." >&2
   echo "Sample sudo ./frr-install-script.sh" >&2
   exit 1
fi

if [ ${SUDO_USER} ]; then
  echo ${SUDO_USER}
else
  echo "Run from Root User? Prefer to run from normal user with sudo command" >&2
  echo "Sample sudo ./frr-install-script.sh" >&2
  exit 1
fi

if [ ${1} ]; then
  echo "LB first IP is ${1}"
else
  echo "Usage sudo ./knative-with-metallbl2-install-script.sh [LB first IP address] [LB Last IP address] [Default Domain Name] [OPTIONAL install kn] [OPTIONAL install golang]"
  echo "Sample: sudo ./knative-with-metallbl2-install-script.sh 192.168.15.97 192.168.15.99 example.com kn go" 
  exit 1
fi

if [ ${2} ]; then
  echo "LB Last IP is ${2}"
else
  echo "Usage sudo ./knative-with-metallbl2-install-script.sh [LB first IP address] [LB Last IP address] [Default Domain Name] [OPTIONAL install kn] [OPTIONAL install golang]"
  echo "Sample: sudo ./knative-with-metallbl2-install-script.sh 192.168.15.97 192.168.15.99 example.com kn go"
  exit 1
fi

if [ ${3} ]; then
  echo "Default domain is ${3}"
else
  echo "Usage sudo ./knative-with-metallbl2-install-script.sh [LB first IP address] [LB Last IP address] [Default Domain Name] [OPTIONAL install kn] [OPTIONAL install golang]"
  echo "Sample: sudo ./knative-with-metallbl2-install-script.sh 192.168.15.97 192.168.15.99 example.com kn go"
  exit 1
fi

OS=`lsb_release -i | awk -F':' '{print $2}' | sed -e "s/\s//g"`
VERSION=`lsb_release -r | awk -F':' '{print $2}' | sed -e "s/\s//g"`

echo $OS
echo $VERSION

case ${OS} in
  "Ubuntu")
    case ${VERSION} in
      "20.04")
        install_ubuntu2004 $1 $2 $3 $4 $5
        ;;
      "18.04")
        #install_ubuntu1804
        echo "1804 Not Supported Yet"
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
