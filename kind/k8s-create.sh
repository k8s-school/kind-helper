#!/bin/sh

set -eux

DIR=$(cd "$(dirname "$0")"; pwd -P)

usage() {
    cat << EOD

Usage: `basename $0` [options]

  Available options:
    -s           Create a single-master Kubernetes cluster
    -c           Create a single-master Kubernetes cluster, with canal CNI
    -n           Set name for Kubernetes cluster 
    -h           This message

  Creates a Kubernetes cluster based on kind. Default cluster has 1 master and 2 nodes.

EOD
}

KIND_CONFIG_FILE="$(mktemp)"

SINGLE=false
CANAL=false
CLUSTER_NAME="kind"
# Available node images: https://github.com/kubernetes-sigs/kind/releases
NODE_IMAGE="kindest/node:v1.18.0@sha256:0e20578828edd939d25eb98496a685c76c98d54084932f76069f886ec315d694"

# get the options
while getopts cn:s c ; do
    case $c in
        s) SINGLE=true ;;
        c) CANAL=true ;;
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
KIND_VERSION="v0.7.0" 

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
    K8S_VERSION_SHORT="1.18"
    # Retrive latest minor version related to k8s version defined above 
    K8S_VERSION_LONG=$(curl -s https://storage.googleapis.com/kubernetes-release/release/stable-$K8S_VERSION_SHORT.txt)
    curl -Lo /tmp/kubectl https://storage.googleapis.com/kubernetes-release/release/"$K8S_VERSION_LONG"/bin/linux/amd64/kubectl
    chmod +x /tmp/kubectl
    sudo mv /tmp/kubectl "$KUBECTL_BIN"
fi
cat > "$KIND_CONFIG_FILE" <<EOF
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
EOF

if [ $CANAL = true ]; then
cat >> "$KIND_CONFIG_FILE" <<EOF
networking:
  disableDefaultCNI: true # disable kindnet
  podSubnet: 10.244.0.0/16 # set to Canal's default subnet
EOF
fi

if [ $SINGLE = false ]; then
cat >> "$KIND_CONFIG_FILE" <<EOF
nodes:
- role: control-plane
- role: worker
- role: worker
EOF
fi

echo "Kind configuration file ($KIND_CONFIG_FILE): "
cat "$KIND_CONFIG_FILE"

kind create cluster --config "$KIND_CONFIG_FILE" --name "$CLUSTER_NAME" --image "$NODE_IMAGE"

if [ $CANAL = true ]; then
    kubectl apply -f https://docs.projectcalico.org/v3.9/manifests/canal.yaml
fi

# Wait until KIND cluster nodes are Ready
kubectl wait --timeout=100s --for=condition=Ready node --all
