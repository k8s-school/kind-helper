#!/bin/sh

set -e
set -x

DIR=$(cd "$(dirname "$0")"; pwd -P)

usage() {
    cat << EOD

Usage: `basename $0` [options]

  Available options:
    -n           Set name for Kubernetes cluster to delete, default to "kind"
    -h           This message

  Delete a Kubernetes cluster based on kind.

EOD
}

CLUSTER_NAME="kind"

# get the options
while getopts cn:s c ; do
    case $c in
        n) CLUSTER_NAME="$OPTARG" ;; 
        \?) usage ; exit 2 ;;
    esac
done
shift $(($OPTIND - 1))

if [ $# -ne 0 ] ; then
    usage
    exit 2
fi

kind delete cluster --name "$CLUSTER_NAME"
