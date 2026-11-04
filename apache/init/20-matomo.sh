#!/usr/bin/env bash

# Sourced by the wodby/php entrypoint before the main command. Prepares the
# files directory and writes the settings Matomo takes from the environment.

mkdir -p "${FILES_DIR}/config" "${FILES_DIR}/misc-user" "${FILES_DIR}/plugins"
matomo-common-config > "${APP_ROOT}/config/common.config.ini.php"
