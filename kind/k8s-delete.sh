#!/bin/sh

set -e
set -x

. "$DIR/env.sh"

kind delete cluster --name "$CLUSTER_NAME"
unset KUBECONFIG
