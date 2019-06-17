#!/bin/sh

set -e
set -x

KUBECTL_BIN="/usr/local/bin/kubectl"
KIND_BIN="/usr/local/bin/kind"

curl -Lo /tmp/kind https://github.com/kubernetes-sigs/kind/releases/download/v0.3.0/kind-linux-amd64
chmod +x /tmp/kind
sudo mv /tmp/kind "$KIND_BIN"

# Download kubectl, which is a requirement for using kind.
K8S_VERSION="v1.13.0"
curl -Lo /tmp/kubectl https://storage.googleapis.com/kubernetes-release/release/"$K8S_VERSION"/bin/linux/amd64/kubectl
chmod +x /tmp/kubectl
sudo mv /tmp/kubectl "$KUBECTL_BIN"

DIR=$(cd "$(dirname "$0")"; pwd -P)
kind create cluster --config "$DIR/kind-config.yaml" --name qserv

export KUBECONFIG=$(kind get kubeconfig-path --name="qserv")

# this for loop waits until kubectl can access the api server that kind has created
JSONPATH='{range .items[*]}{@.metadata.name}:{range @.status.conditions[*]}{@.type}={@.status};{end}{end}'
until "$KUBECTL_BIN" get nodes -o jsonpath="$JSONPATH" 2>&1 | grep -q "Ready=True"
  do sleep 1
done
