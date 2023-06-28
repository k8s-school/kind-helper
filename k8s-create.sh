#!/bin/bash

set -euxo pipefail

DIR=$(cd "$(dirname "$0")"; pwd -P)

usage() {
    cat << EOD

Usage: `basename $0` [options]

  Available options:
    -c <cni>     Use alternate CNI, 'canal', 'calico' and 'cilium' are supported
    -n           Set name for Kubernetes cluster
    -h           This message
    -s           Create a single-node Kubernetes cluster, take precedence over -w option
    -w           Number of workers, default to 2


  Creates a Kubernetes cluster based on kind. Default cluster has 1 master and 2 nodes.

EOD
}

KIND_CONFIG_FILE="$(mktemp)"

CNI=""
CLUSTER_NAME="kind"
POD_CIDR="192.168.0.0/16"
NB_WORKER=3
SINGLE=false

# get the options
while getopts c:n:w:s c ; do
    case $c in
        s) SINGLE=true ;;
        w) NB_WORKER="$OPTARG" ;;
        c) CNI="$OPTARG" ;;
        n) CLUSTER_NAME="$OPTARG" ;;
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
KIND_VERSION="v0.15.0"

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


