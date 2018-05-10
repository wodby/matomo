#!/usr/bin/env bash

set -e

if [[ -n "${DEBUG}" ]]; then
    set -x
fi

echo -n "Checking Matomo homepage... "
curl -s "nginx" | grep -q "Matomo ${MATOMO_VER} &rsaquo; Installation"
echo "OK"

# TODO: test installation