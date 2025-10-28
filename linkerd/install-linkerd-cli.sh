#!/usr/bin/env bash

set -xeuo pipefail

export LINKERD2_VERSION="${LINKERD_CLI_VERSION}"

curl --proto '=https' --tlsv1.2 -sSfL https://run.linkerd.io/install-edge | sh
