#!/bin/bash

set -euxo pipefail

DIR=$(cd "$(dirname "$0")"; pwd -P)

usage() {
    cat << EOD

Usage: `basename $0` [options]

  Available options:
    -p           Enable PodSecurityPolicies
    -s           Create a single-master Kubernetes cluster
    -c <cni>     Use alternate CNI, 'canal', 'calico' and 'cilium' are supported
    -n           Set name for Kubernetes cluster 
    -h           This message

  Creates a Kubernetes cluster based on kind. Default cluster has 1 master and 2 nodes.

EOD
}

KIND_CONFIG_FILE="$(mktemp)"

CNI=""
CLUSTER_NAME="kind"
POD_CIDR="10.244.0.0/16"
CALICO_FILE="calico.yaml"
CANAL_FILE="canal.yaml"
PSP=false
SINGLE=false

# get the options
while getopts c:n:sp c ; do
    case $c in
        p) PSP=true ;;
        s) SINGLE=true ;;
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
KIND_VERSION="v0.9.0" 

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
    K8S_VERSION_SHORT="1.19"
    # Retrieve latest minor version related to k8s version defined above 
    K8S_VERSION_LONG=$(curl -s https://storage.googleapis.com/kubernetes-release/release/stable-$K8S_VERSION_SHORT.txt)
    curl -Lo /tmp/kubectl https://storage.googleapis.com/kubernetes-release/release/"$K8S_VERSION_LONG"/bin/linux/amd64/kubectl
    chmod +x /tmp/kubectl
    sudo mv /tmp/kubectl "$KUBECTL_BIN"
fi
cat > "$KIND_CONFIG_FILE" <<EOF
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
EOF

if [ -n "$CNI" ]; then
cat >> "$KIND_CONFIG_FILE" <<EOF
networking:
  disableDefaultCNI: true # disable kindnet
  podSubnet: "$POD_CIDR" # set to Canal/Calico's default subnet
EOF
fi

ADMISSION_PLUGINS="enable-admission-plugins: NodeRestriction,ResourceQuota"
if [ "$PSP" = true ]; then
   ADMISSION_PLUGINS="$ADMISSION_PLUGINS,PodSecurityPolicy" 
fi

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
- role: worker
- role: worker
EOF
fi

echo "Kind configuration file ($KIND_CONFIG_FILE): "
cat "$KIND_CONFIG_FILE"

kind create cluster --config "$KIND_CONFIG_FILE" --name "$CLUSTER_NAME"

if [ "$PSP" = true ]; then
  kubectl apply -f $DIR/psp
fi

if [ "$CNI" = "canal" ]; then
  curl -LO https://docs.projectcalico.org/v3.16/manifests/"$CANAL_FILE"

  # Pull canal images from public registry to local host then load them to kind cluster nodes
  for image in $(grep "image:" "$DIR/$CANAL_FILE" | awk '{print $2}' | tr -d '"') ; do docker pull $image; kind load docker-image $image; done;

  kubectl apply -f $CANAL_FILE
elif [ "$CNI" = "cilium" ]; then
  curl -Lo cilium.yaml https://raw.githubusercontent.com/cilium/cilium/v1.8/install/kubernetes/quick-install.yaml
  for image in $(grep " image:" "$DIR/cilium.yaml" | awk '{print $2}' | tr -d '"') ; do docker pull $image; kind load docker-image $image; done;
  kubectl create -f cilium.yaml
elif [ "$CNI" = "calico" ]; then 
  curl -LO https://docs.projectcalico.org/v3.16/manifests/"$CALICO_FILE"
  sed -i -e "s?192.168.0.0/16?$POD_CIDR?g" "$CALICO_FILE"
  for container_id in $(docker ps --filter name=kind -q); do docker exec -i $container_id sysctl net.ipv4.conf.all.rp_filter=1; done;
  # Pull calico images from public registry to local host then load them to kind cluster nodes
  for image in $(grep "image:" "$DIR/$CALICO_FILE" | awk '{print $2}' | tr -d '"') ; do docker pull $image; kind load docker-image $image; done;

  kubectl apply -f $CALICO_FILE
elif [ -n "$CNI" ]; then
  >&2 echo "Incorrect CNI option: $CNI"
  usage
  exit 2
fi

# Wait until KIND cluster nodes are Ready
kubectl wait --timeout=180s --for=condition=Ready node --all
