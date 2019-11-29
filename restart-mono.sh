#!/bin/sh

set -e
set -x

DIR=$(cd "$(dirname "$0")"; pwd -P)

docker start kind-control-plane
docker exec kind-control-plane sh -c 'mount -o remount,ro /sys; kill -USR1 1'
