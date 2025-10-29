#!/usr/bin/env bash
#
# https://linkerd.io/2.18/getting-started/#step-5-install-the-demo-app

set -xeuo pipefail

curl --proto '=https' --tlsv1.2 -sSfL https://run.linkerd.io/emojivoto.yml \
    | linkerd inject - \
    | kubectl apply -f -

linkerd -n emojivoto check --proxy

echo "To access the app, run these:"
echo "kubectl -n emojivoto port-forward svc/web-svc 8080:80 &"
echo "open http://localhost:8080/"
