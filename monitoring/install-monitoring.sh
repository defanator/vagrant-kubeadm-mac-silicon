#!/usr/bin/env bash

set -xeuo pipefail

kubectl apply -f monitoring/namespace.yaml
kubectl apply -f monitoring/prometheus-config.yaml
kubectl apply -f monitoring/prometheus-deployment.yaml
kubectl apply -f monitoring/prometheus-service.yaml
kubectl apply -f monitoring/loki-config.yaml
kubectl apply -f monitoring/loki-deployment.yaml
kubectl apply -f monitoring/loki-service.yaml
kubectl apply -f monitoring/grafana-secret.yaml
kubectl apply -f monitoring/grafana-datasource-configmap.yaml
kubectl apply -f monitoring/grafana-deployment.yaml
kubectl apply -f monitoring/grafana-service.yaml

kubectl -n monitoring rollout status deployment/prometheus --timeout=180s
kubectl -n monitoring rollout status deployment/loki --timeout=180s
kubectl -n monitoring rollout status deployment/grafana --timeout=180s

kubectl apply -f monitoring/gkm-service-account.yaml

helm install gkm grafana/k8s-monitoring \
  --version 4.1.7 \
  --namespace monitoring \
  --create-namespace \
  --values monitoring/gkm-values.yaml

GRAFANA_NODE_PORT="$(kubectl -n monitoring get svc grafana -o jsonpath='{.spec.ports[0].nodePort}')"
FIRST_WORKER_NODE_IP="$(kubectl get nodes -l '!node-role.kubernetes.io/control-plane' -o jsonpath='{.items[0].status.addresses[?(@.type=="InternalIP")].address}')"

set +x

echo "Prometheus, Loki, and Grafana are deployed in namespace monitoring."
echo "Grafana NodePort: ${GRAFANA_NODE_PORT}"
echo "Access Grafana at: http://${FIRST_WORKER_NODE_IP}:${GRAFANA_NODE_PORT}"
echo "Anonymous Grafana access is enabled with Admin role."
