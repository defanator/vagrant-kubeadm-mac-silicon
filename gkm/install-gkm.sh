#!/usr/bin/env bash

set -x

kubectl apply -f gkm/service-account.yaml

helm install gkm grafana/k8s-monitoring \
  --version 4.1.7 \
  --namespace monitoring \
  --create-namespace \
  --values gkm/values.yaml
