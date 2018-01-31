#!/usr/bin/env bash

set -e

if [[ -n "${DEBUG}" ]]; then
    set -x
fi

if [[ "${MATOMO_VER:0:1}" == "2" ]]; then
    match="Piwik &rsaquo; Installation"
else
    match="Matomo ${MATOMO_VER} &rsaquo; Installation"
fi

echo -n "Checking Matomo homepage... "
curl -s "nginx" | grep -q "${match}"
echo "OK"

# TODO: test installation