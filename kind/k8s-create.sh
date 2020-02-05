#!/bin/sh

set -eux

DIR=$(cd "$(dirname "$0")"; pwd -P)

usage() {
    cat << EOD

Usage: `basename $0` [options]

  Available options:
    -s           Create a single-master Kubernetes cluster
    -c           Create a single-master Kubernetes cluster, with canal CNI
    -h           This message

  Creates a Kubernetes cluster based on kind. Default cluster has 1 master and 2 nodes.

EOD
}

KIND_CONFIG_FILE="$DIR/kind-config.yaml"

CANAL=false

# get the options
while getopts cs c ; do
    case $c in
        s) KIND_CONFIG_FILE="$DIR/kind-config-single.yaml";;
        s) KIND_CONFIG_FILE="$DIR/kind-config-canal.yaml" ; CANAL=true ;;
        \?) usage ; exit 2 ;;
    esac
done
shift $(($OPTIND - 1))

if [ $# -ne 0 ] ; then
    usage
    exit 2
fi


KUBECTL_BIN="/usr/local/bin/kubectl"
KIND_BIN="/usr/local/bin/kind"
CLUSTER_NAME="kind"
KIND_VERSION="v0.7.0" 

. "$DIR/env.sh"

# If kind exists, compare current version to desired one: kind version | awk '{print $2}'
 if [ -e $KIND_BIN ]; then
    CURRENT_KIND_VERSION="v$(kind version -q)"
    if [ "$CURRENT_KIND_VERSION" != "$KIND_VERSION" ]; then
      sudo rm "$KIND_BIN"
    fi
fi

if [ ! -e $KIND_BIN ]; then
    curl -Lo /tmp/kind https://github.com/kubernetes-sigs/kind/releases/download/"$KIND_VERSION"/kind-linux-amd64
    chmod +x /tmp/kind
    sudo mv /tmp/kind "$KIND_BIN"
fi

# Download kubectl, which is a requirement for using kind.
# TODO If kubectl exists, compare current version to desired one: kubectl version --client --short  | awk '{print $3}'
if [ ! -e $KUBECTL_BIN ]; then
    K8S_VERSION_SHORT="1.16"
    # Retrive latest minor version related to k8s version defined above 
    K8S_VERSION_LONG=$(curl -s https://storage.googleapis.com/kubernetes-release/release/stable-$K8S_VERSION_SHORT.txt)
    curl -Lo /tmp/kubectl https://storage.googleapis.com/kubernetes-release/release/"$K8S_VERSION_LONG"/bin/linux/amd64/kubectl
    chmod +x /tmp/kubectl
    sudo mv /tmp/kubectl "$KUBECTL_BIN"
fi

if [ -n "$KIND_CONFIG_FILE" ]; then
    kind create cluster --config "$KIND_CONFIG_FILE" --name "$CLUSTER_NAME"
fi

if [ $CANAL = true ]; then
    kubectl apply -f https://docs.projectcalico.org/v3.9/manifests/canal.yaml
fi

# Wait until KIND cluster nodes are Ready
kubectl wait --timeout=100s --for=condition=Ready node --all
