#!/usr/bin/env bash

set -e

if [[ -n "${DEBUG}" ]]; then
    set -x
fi

docker-compose up -d
docker-compose exec nginx make check-ready -f /usr/local/bin/actions.mk
docker-compose exec matomo make init -f /usr/local/bin/actions.mk
docker-compose exec matomo tests
docker-compose down
