#!/usr/bin/env bash

# Checks that init updates the files of an older Matomo 5 release. The files
# directory is marked as 5.14.2: its "14." once made init treat the update as
# one from Matomo 4 and stop on files that Matomo 5 no longer has.

set -e

if [[ -n "${DEBUG}" ]]; then
    set -x
fi

version_file="${APP_ROOT}/core/Version.php"

echo -n "Updating the files of Matomo 5.14.2... "
sed -i -E "s/(const VERSION = ')[^']+'/\15.14.2'/" "${version_file}"
make init -f /usr/local/bin/actions.mk > /dev/null
grep -q "const VERSION = '${MATOMO_VER}'" "${version_file}"
echo "OK"
