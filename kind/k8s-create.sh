#!/bin/sh

set -e
set -x

DIR=$(cd "$(dirname "$0")"; pwd -P)
KUBECTL_BIN="/usr/local/bin/kubectl"
KIND_BIN="/usr/local/bin/kind"
CLUSTER_NAME="kind"

. "$DIR/env.sh"

if [ ! -e $KIND_BIN ]; then
    curl -Lo /tmp/kind https://github.com/kubernetes-sigs/kind/releases/download/v0.5.1/kind-linux-amd64
    chmod +x /tmp/kind
    sudo mv /tmp/kind "$KIND_BIN"
fi

# Download kubectl, which is a requirement for using kind.
if [ ! -e $KUBECTL_BIN ]; then
    K8S_VERSION_SHORT="1.15"
    # Retrive latest minor version related to k8s version defined above 
    K8S_VERSION_LONG=$(curl -s https://storage.googleapis.com/kubernetes-release/release/stable-$K8S_VERSION_SHORT.txt)
    curl -Lo /tmp/kubectl https://storage.googleapis.com/kubernetes-release/release/"$K8S_VERSION_LONG"/bin/linux/amd64/kubectl
    chmod +x /tmp/kubectl
    sudo mv /tmp/kubectl "$KUBECTL_BIN"
fi

kind create cluster --config "$DIR/kind-config.yaml" --name "$CLUSTER_NAME" 

export KUBECONFIG=$(kind get kubeconfig-path --name="$CLUSTER_NAME")

# Wait until KIND cluster nodes are Ready
kubectl wait --timeout=100s --for=condition=Ready node --all
