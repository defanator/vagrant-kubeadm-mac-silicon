#!/usr/bin/env bash

set -xeuo pipefail

helm -n monitoring delete gkm

kubectl delete -f monitoring/gkm-service-account.yaml

kubectl delete -f monitoring/grafana-service.yaml --ignore-not-found=true
kubectl delete -f monitoring/grafana-deployment.yaml --ignore-not-found=true
kubectl delete -f monitoring/grafana-datasource-configmap.yaml --ignore-not-found=true
kubectl delete -f monitoring/grafana-secret.yaml --ignore-not-found=true
kubectl delete -f monitoring/loki-service.yaml --ignore-not-found=true
kubectl delete -f monitoring/loki-deployment.yaml --ignore-not-found=true
kubectl delete -f monitoring/loki-config.yaml --ignore-not-found=true
kubectl delete -f monitoring/prometheus-service.yaml --ignore-not-found=true
kubectl delete -f monitoring/prometheus-deployment.yaml --ignore-not-found=true
kubectl delete -f monitoring/prometheus-config.yaml --ignore-not-found=true

echo "Standalone monitoring stack resources were removed from namespace monitoring."
echo "Namespace monitoring was kept to avoid conflicts with other monitoring tools."
