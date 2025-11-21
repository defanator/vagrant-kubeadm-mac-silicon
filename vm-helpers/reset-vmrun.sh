#!/usr/bin/env bash

set -euo pipefail

for vmx in $(vmrun list | grep -- "$(pwd)"); do
    printf "Resetting %s...\n" "${vmx}"
    vmrun reset "${vmx}" &
done

sleep 1

printf "Waiting for VMs to reset... "

wait

printf "done.\n"
