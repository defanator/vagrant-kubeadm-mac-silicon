#!/usr/bin/env bash

set -euo pipefail

vms=()

for vmx in $(vmrun list | grep -- "$(pwd)"); do
    vms+=("${vmx}")
done

printf "Running VMs: %s\n" "${#vms[@]}"

for vm in "${vms[@]}"; do
    printf "%s\n" "${vm}"
done
