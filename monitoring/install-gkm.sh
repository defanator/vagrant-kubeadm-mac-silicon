#!/usr/bin/env bash

set -xeuo pipefail

kubectl apply -f monitoring/gkm-service-account.yaml

helm install gkm grafana/k8s-monitoring \
  --version 4.1.7 \
  --namespace monitoring \
  --create-namespace \
  --values monitoring/gkm-values.yaml
