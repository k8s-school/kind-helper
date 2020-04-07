#!/usr/bin/env bash
KIND_CLUSTER="kind"
KIND_CTX="kind-${KIND_CLUSTER}"

for container in $(kind get nodes --name ${KIND_CLUSTER}); do
      [[ $(docker inspect -f '{{.State.Running}}' $container) == "true" ]] || docker start $container
done
sleep 1
docker exec ${KIND_CLUSTER}-control-plane sh -c 'mount -o remount,ro /sys; kill -USR1 1'
kubectl config set clusters.${KIND_CTX}.server $(kind get kubeconfig --name ${KIND_CLUSTER} -q | yq read -j - | jq -r '.clusters[].cluster.server')
