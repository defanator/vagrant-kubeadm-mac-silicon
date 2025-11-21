#!/usr/bin/env bash

set -euo pipefail

for vm in $(vagrant status --machine-readable | awk -F ',' '/,state,running/ {print $2}'); do
    printf "Rebooting %s...\n" "${vm}"
    vagrant ssh "${vm}" -- sudo reboot
done

printf "Done.\n"
