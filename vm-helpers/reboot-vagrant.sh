#!/usr/bin/env bash

set -euo pipefail

extra_vagrant_args=()
if [ "${1-}" = "--force" ]; then
    extra_vagrant_args+=("--force")
fi

for vm in $(vagrant status --machine-readable | awk -F ',' '/,state,running/ {print $2}'); do
    printf "Rebooting %s...\n" "${vm}"
    vagrant reload "${vm}" "${extra_vagrant_args[@]}"
done

printf "Done.\n"
