#!/bin/sh

set -e
set -x

abs_path() {
  # $1 : relative filename
  echo "$(cd "$(dirname "$1")" && pwd)/$(basename "$1")"
}

DIR=$(cd "$(dirname "$0")"; pwd -P)
BASE=$(abs_path "$DIR/..")

export KUBECONFIG="$(kind get kubeconfig-path --name='qserv')"

echo "Pods are up:"
kubectl get pods"

# TODO Add strong check for startup
sleep 10

