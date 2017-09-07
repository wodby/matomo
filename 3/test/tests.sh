#!/usr/bin/env bash

set -e

if [[ -n "${DEBUG}" ]]; then
    set -x
fi

echo -n "Checking Piwik homepage... "
curl -s "nginx" | grep -q "Piwik 3.0.4 &rsaquo; Installation"
echo "OK"

# TODO: test installation