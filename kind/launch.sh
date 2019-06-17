#!/bin/sh

set -e
set -x

abs_path() {
  # $1 : relative filename
  echo "$(cd "$(dirname "$1")" && pwd)/$(basename "$1")"
}

DIR=$(cd "$(dirname "$0")"; pwd -P)
BASE=$(abs_path "$DIR/..")

export KUBECONFIG="$(kind get kubeconfig-path)"

# Launch application to test here
"$BASE/run.sh"

echo "Pods are up:"
kubectl get pods

# Launch application integration test here
"$BASE/test.sh"

# TODO Add strong check for startup
sleep 10

