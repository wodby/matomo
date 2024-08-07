#!/usr/bin/env bash

set -e

if [[ -n "${DEBUG}" ]]; then
    set -x
fi

docker compose up -d
docker compose exec -T nginx make check-ready -f /usr/local/bin/actions.mk
docker compose exec -T matomo make init -f /usr/local/bin/actions.mk
docker compose exec -T matomo tests.sh
docker compose down
