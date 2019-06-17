#!/bin/sh

# Create docker image containing build of current repository code

# @author  Benjamin Roziere 
# @author  Fabrice Jammes

set -e
#set -x

DIR=$(cd "$(dirname "$0")"; pwd -P)

GIT_HASH="$(git describe --dirty --always)"
TAG=${DEPLOY_VERSION:-${GIT_HASH}}

IMAGE="fjammes/kind-travis-ci:$TAG"

echo "Building image $IMAGE"

docker build --tag "$IMAGE" "$DIR"
docker push "$IMAGE"
echo "$IMAGE pushed to Docker Hub"
