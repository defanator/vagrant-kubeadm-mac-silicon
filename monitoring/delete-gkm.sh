#!/usr/bin/env bash

set -xeuo pipefail

helm -n monitoring delete gkm

kubectl delete -f monitoring/gkm-service-account.yaml
