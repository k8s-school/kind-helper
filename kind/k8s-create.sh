#!/bin/sh

set -e
set -x

DIR=$(cd "$(dirname "$0")"; pwd -P)

usage() {
    cat << EOD

Usage: `basename $0` [options]

  Available options:
    -s           Create a single-master Kubernetes cluster   
    -h           This message

  Creates a Kubernetes cluster based on kind. Default cluster has 1 master and 2 nodes.

EOD
}

KIND_CONFIG_FILE="$DIR/kind-config.yaml"

# get the options
while getopts s c ; do
    case $c in
        s) KIND_CONFIG_FILE="" ;;
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

if [ -z "$KIND_CONFIG_FILE" ]; then
    kind create cluster --name "$CLUSTER_NAME"
else
    kind create cluster --config "$KIND_CONFIG_FILE" --name "$CLUSTER_NAME"
fi 

export KUBECONFIG=$(kind get kubeconfig-path --name="$CLUSTER_NAME")

# Wait until KIND cluster nodes are Ready
kubectl wait --timeout=100s --for=condition=Ready node --all
