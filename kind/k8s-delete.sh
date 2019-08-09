#!/bin/sh

set -e
set -x

DIR=$(cd "$(dirname "$0")"; pwd -P)
. "$DIR/env.sh"

kind delete cluster --name "$CLUSTER_NAME"
unset KUBECONFIG
