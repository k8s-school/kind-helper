#!/bin/sh

set -e
set -x

kind delete cluster
unset KUBECONFIG
