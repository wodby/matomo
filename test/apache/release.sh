#!/usr/bin/env bash

# Tests matomo-use-release: refuses versions it can't use, then builds an image
# with another Matomo 5 release, as a build that pins Matomo's version does,
# and runs the Apache variant's tests against it.

set -e

if [[ -n "${DEBUG}" ]]; then
    set -x
fi

# Any verified Matomo 5 release other than the image's own.
RELEASE="${RELEASE:-5.14.1}"
pinned="${NAME}-release"

cleanup() {
    local status=$?
    docker rmi -f "${pinned}" > /dev/null 2>&1 || true
    exit "${status}"
}
trap cleanup EXIT

expect() {
    local description=$1 actual=$2 expected=$3
    echo -n "${description}... "
    if [[ "${actual}" != *"${expected}"* ]]; then
        echo "Error: expected ${expected}, got: ${actual}"
        exit 1
    fi
    echo "OK"
}

use_release() {
    docker run --rm --user root --entrypoint matomo-use-release "${IMAGE}" "${1}" 2>&1 || true
}

expect "Refusing a version that is not a release" "$(use_release latest)" "Set a Matomo release version"
expect "Refusing another major version" "$(use_release 4.16.1)" "is not a 5.x release"
image_version=$(docker run --rm --entrypoint sh "${IMAGE}" -c 'echo "${MATOMO_VER}"')
expect "Keeping the image's own release" "$(use_release "${image_version}")" "already has Matomo"

echo -n "Building an image with Matomo ${RELEASE}... "
docker build -q -t "${pinned}" --build-arg IMAGE="${IMAGE}" --build-arg RELEASE="${RELEASE}" - > /dev/null <<'DOCKERFILE'
ARG IMAGE
FROM ${IMAGE}
ARG RELEASE
USER root
RUN apk add --no-cache -t .gpg gnupg && matomo-use-release "${RELEASE}" && apk del --purge .gpg
USER wodby
DOCKERFILE
echo "OK"

inspect() {
    docker run --rm --entrypoint sh "${pinned}" -c "cd /var/www/html && $1"
}
expect "Running the pinned release" "$(inspect "grep -o \"VERSION = '[^']*'\" core/Version.php")" "'${RELEASE}'"
expect "Keeping the WodbyInstall plugin" "$(inspect 'ls plugins/WodbyInstall')" "WodbyInstall.php"
expect "Keeping the GeoLite database" "$(inspect 'ls misc/GeoLite2-City.mmdb')" "GeoLite2-City.mmdb"
expect "Linking the settings to the files directory" "$(inspect 'readlink config/config.ini.php')" "/mnt/files/config/config.ini.php"
expect "Linking custom logos to the files directory" "$(inspect 'readlink misc/user')" "/mnt/files/misc-user"
expect "Linking Marketplace plugins to the files directory" "$(inspect 'readlink marketplace-plugins')" "/mnt/files/plugins"
expect "Writing Matomo's .htaccess files" "$(inspect 'ls core/.htaccess')" "core/.htaccess"
expect "Leaving everything owned by wodby" "$(inspect 'find . ! -user wodby | wc -l')" "0"

echo "Running the Apache tests with Matomo ${RELEASE}"
IMAGE="${pinned}" NAME="${NAME}-release" ./run.sh
