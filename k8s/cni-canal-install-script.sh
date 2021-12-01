#!/bin/bash
set -e

curl https://docs.projectcalico.org/manifests/canal.yaml -O
cat canal.yaml | sed -e "s/policy\/v1beta1/policy\/v1/g" >canalrev.yaml
su - $SUDO_USER -c "kubectl apply -f canalrev.yaml"

exit 0
