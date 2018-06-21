#!/usr/bin/env bash

set -e

if [[ -n "${DEBUG}" ]]; then
    set -x
fi

# Automatically trigger init action when running outside Wodby.
if [[ -z "${WODBY_APP_NAME}" ]]; then
    make init -f /usr/local/bin/actions.mk
fi