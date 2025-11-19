#!/usr/bin/env bash
#
# https://linkerd.io/2.18/getting-started/#step-6-explore-linkerd
# https://linkerd.io/2.18/tasks/grafana/

set -xeuo pipefail

helm repo add grafana https://grafana.github.io/helm-charts

helm install grafana \
    -n grafana \
    --create-namespace \
    grafana/grafana \
    -f https://raw.githubusercontent.com/linkerd/linkerd2/main/grafana/values.yaml

linkerd viz install --set grafana.url=grafana.grafana:80 \
    | kubectl apply -f -

kubectl wait namespace/linkerd-viz --for=create

curl -sSfL https://github.com/linkerd/linkerd2/raw/refs/heads/main/grafana/authzpolicy-grafana.yaml \
    | kubectl apply -f -

echo "Run this to open dashboard:"
echo "linkerd viz dashboard &"
