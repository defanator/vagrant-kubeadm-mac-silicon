#!/usr/bin/env bash

set -xeuo pipefail

echo "Installing linkerd ${LINKERD_HELM_VERSION}"

helm repo add linkerd-edge https://helm.linkerd.io/edge

helm install linkerd-crds \
    -n linkerd \
    --create-namespace \
    --set installGatewayAPI=true \
    --version ${LINKERD_HELM_VERSION} \
    linkerd-edge/linkerd-crds

step certificate create root.linkerd.cluster.local ca.crt ca.key \
    --profile root-ca --no-password --insecure --force

step certificate create identity.linkerd.cluster.local issuer.crt issuer.key \
    --profile intermediate-ca --not-after 8760h --no-password --insecure \
    --ca ca.crt --ca-key ca.key --force

helm install linkerd-control-plane -n linkerd \
    --set-file identityTrustAnchorsPEM=ca.crt \
    --set-file identity.issuer.tls.crtPEM=issuer.crt \
    --set-file identity.issuer.tls.keyPEM=issuer.key \
    --version ${LINKERD_HELM_VERSION} \
    linkerd-edge/linkerd-control-plane
