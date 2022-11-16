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
POD_CIDR="10.244.0.0/16"
CALICO_FILE="calico.yaml"
CANAL_FILE="canal.yaml"
NB_WORKER=2
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
KUBECTL_VERSION="v1.25.0"

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
    curl -Lo /tmp/kubectl https://dl.k8s.io/release/"$KUBECTL_VERSION"/bin/linux/amd64/kubectl
    curl -Lo /tmp/kubectl.sha256 "https://dl.k8s.io/"$KUBECTL_VERSION"/bin/linux/amd64/kubectl.sha256"
    echo "$(cat /tmp/kubectl.sha256)  /tmp/kubectl" | sha256sum --check
    chmod +x /tmp/kubectl
    sudo mv /tmp/kubectl "$KUBECTL_BIN"
fi
cat > "$KIND_CONFIG_FILE" <<EOF
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
featureGates:
  "EphemeralContainers": true
EOF

if [ -n "$CNI" ]; then
cat >> "$KIND_CONFIG_FILE" <<EOF
networking:
  disableDefaultCNI: true # disable kindnet
  podSubnet: "$POD_CIDR" # set to Canal/Calico's default subnet
EOF
fi

ADMISSION_PLUGINS="enable-admission-plugins: NodeRestriction,ResourceQuota"

cat >> "$KIND_CONFIG_FILE" <<EOF
kubeadmConfigPatches:
- |
  apiVersion: kubeadm.k8s.io/v1beta2
  kind: ClusterConfiguration
  metadata:
    name: config
  apiServer:
    extraArgs:
      $ADMISSION_PLUGINS
EOF

if [ "$SINGLE" = false ]; then
cat >> "$KIND_CONFIG_FILE" <<EOF
nodes:
- role: control-plane
EOF
  i=0
  until [ $i -ge $NB_WORKER ]
  do
  cat >> "$KIND_CONFIG_FILE" <<EOF
- role: worker
EOF
    ((i=i+1))
  done
fi

echo "Kind configuration file ($KIND_CONFIG_FILE): "
cat "$KIND_CONFIG_FILE"

kind create cluster --config "$KIND_CONFIG_FILE" --name "$CLUSTER_NAME"

if [ "$CNI" = "canal" ]; then
  curl -LO https://docs.projectcalico.org/v3.16/manifests/"$CANAL_FILE"

  # Pull canal images from public registry to local host then load them to kind cluster nodes
  for image in $(grep "image:" "$DIR/$CANAL_FILE" | awk '{print $2}' | tr -d '"')
  do
    docker pull $image
    kind load docker-image $image --name "$CLUSTER_NAME"
  done

  kubectl apply -f $CANAL_FILE
elif [ "$CNI" = "cilium" ]; then
  curl -Lo cilium.yaml https://raw.githubusercontent.com/cilium/cilium/v1.8/install/kubernetes/quick-install.yaml
  for image in $(grep " image:" "$DIR/cilium.yaml" | awk '{print $2}' | tr -d '"') ; do docker pull $image; kind load docker-image $image; done;
  kubectl create -f cilium.yaml
elif [ "$CNI" = "calico" ]; then
  curl -o $DIR/$CALICO_FILE https://projectcalico.docs.tigera.io/manifests/"$CALICO_FILE"
  sed -i -e "s?192.168.0.0/16?$POD_CIDR?g" "$DIR/$CALICO_FILE"
  # Pull calico images from public registry to local host then load them to kind cluster nodes
  for image in $(grep "image:" "$DIR/$CALICO_FILE" | awk '{print $2}' | tr -d '"') ; do docker pull $image; kind load docker-image $image; done;

  kubectl apply -f $DIR/$CALICO_FILE
elif [ -n "$CNI" ]; then
  >&2 echo "Incorrect CNI option: $CNI"
  usage
  exit 2
fi

# Wait until KIND cluster nodes are Ready
kubectl wait --timeout=180s --for=condition=Ready node --all
