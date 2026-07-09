#!/usr/bin/env bash

set -x

helm -n monitoring delete gkm

kubectl delete -f gkm/service-account.yaml
