#!/usr/bin/env bash

set -e

if [[ -n "${DEBUG}" ]]; then
    set -x
fi

if [ ! -e "${APP_ROOT}/web/piwik.php" ]; then
    echo >&2 "${APP_NAME} not found in ${APP_ROOT} - copying now..."
    rsync -rlt "/usr/src/piwik/" "${APP_ROOT}/"
    ln -s "${APP_ROOT}/vendor/piwik/piwik" "${APP_ROOT}/web"
    echo >&2 "Complete! ${APP_NAME} has been successfully copied to ${APP_ROOT}"
fi
