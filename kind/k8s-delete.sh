#!/bin/sh

set -e
set -x

kind delete cluster --name qserv
unset KUBECONFIG