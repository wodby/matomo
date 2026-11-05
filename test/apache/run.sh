#!/usr/bin/env bash

# Tests the Apache variant: installs Matomo into an empty MariaDB database with
# matomo-update, as a post-deployment action would, then checks the site, the
# tracker, archiving, an update run and the cases where matomo-update must
# refuse.

set -e

if [[ -n "${DEBUG}" ]]; then
    set -x
fi

network="${NAME}-net"
mariadb="${NAME}-mariadb"
files="${NAME}-files"
web="${NAME}-web"

cleanup() {
    local status=$?
    if [[ "${status}" -ne 0 ]]; then
        docker logs --tail 30 "${web}" 2>&1 || true
    fi
    docker rm -vf "${web}" "${mariadb}" > /dev/null 2>&1 || true
    docker volume rm -f "${files}" > /dev/null 2>&1 || true
    docker network rm "${network}" > /dev/null 2>&1 || true
    exit "${status}"
}
trap cleanup EXIT

env_args=(
    -e DB_HOST="${mariadb}"
    -e DB_PORT=3306
    -e DB_NAME=matomo
    -e DB_USERNAME=matomo
    -e 'DB_PASSWORD=matomo p@ss/w:rd#1'
    -e MATOMO_SALT=0123456789abcdef0123456789abcdef
    -e MATOMO_ADMIN_USERNAME=admin
    -e MATOMO_ADMIN_PASSWORD=Secret-Pass-123
    -e MATOMO_ADMIN_EMAIL=admin@example.com
    -e MATOMO_SITE_NAME='Example Inc.'
    -e MATOMO_SITE_URL=https://www.example.com
    -e WODBY_PRIMARY_URL=https://matomo.example.com
    -e 'WODBY_HOSTS=["matomo.example.com"]'
)

# A one-off container, as Wodby runs actions and cron jobs.
matomo_run() {
    docker run --rm --network "${network}" "${env_args[@]}" -v "${files}:/mnt/files" "${IMAGE}" "${@}"
}

sql() {
    docker exec "${mariadb}" mariadb -umatomo '-pmatomo p@ss/w:rd#1' matomo -NBe "${1}"
}

# Requests from inside the web container, as the gateway sends them, with a
# session. Matomo marks its cookies secure behind HTTPS, and curl won't keep
# secure cookies over plain HTTP, so /tmp/request keeps them itself.
request() {
    docker exec "${web}" /tmp/request "${@}"
}

install_request() {
    docker exec -i "${web}" sh -c 'cat > /tmp/request && chmod +x /tmp/request' <<'SCRIPT'
#!/bin/sh
touch /tmp/cookies
cookie=$(paste -sd ';' /tmp/cookies | sed 's/;/; /g')
set -- -H 'Host: matomo.example.com' -H 'X-Forwarded-Proto: https' -H 'X-Forwarded-For: 203.0.113.7' "$@"
if [ -n "${cookie}" ]; then
    set -- -H "Cookie: ${cookie}" "$@"
fi
curl -sS -D /tmp/headers "$@"
status=$?
tr -d '\r' < /tmp/headers | sed -n -E 's/^[Ss]et-[Cc]ookie: *([^;]*).*/\1/p' | while IFS= read -r pair; do
    grep -v "^${pair%%=*}=" /tmp/cookies > /tmp/cookies.new
    echo "${pair}" >> /tmp/cookies.new
    mv /tmp/cookies.new /tmp/cookies
done
exit "${status}"
SCRIPT
}

status() {
    request -o /dev/null -w '%{http_code}' "http://localhost$1"
}

expect() {
    local description=$1 actual=$2 expected=$3
    echo -n "${description}... "
    if [[ "${actual}" != *"${expected}"* ]]; then
        echo "Error: expected ${expected}, got: ${actual}"
        exit 1
    fi
    echo "OK"
}

docker network create "${network}" > /dev/null
docker volume create "${files}" > /dev/null
docker run -d --name "${mariadb}" --network "${network}" \
    -e MARIADB_ROOT_PASSWORD=root -e MARIADB_DATABASE=matomo -e MARIADB_USER=matomo -e 'MARIADB_PASSWORD=matomo p@ss/w:rd#1' \
    mariadb:11.8 > /dev/null
for _ in $(seq 1 60); do
    sql 'SELECT 1' > /dev/null 2>&1 && break
    sleep 2
done

expect "Refusing to start without a salt" \
    "$(docker run --rm "${IMAGE}" true 2>&1 || true)" "Set MATOMO_SALT"
expect "Refusing to install without an admin password" \
    "$(docker run --rm --network "${network}" -e DB_HOST="${mariadb}" -e DB_USERNAME=matomo -e 'DB_PASSWORD=matomo p@ss/w:rd#1' \
        -e MATOMO_SALT=x -v "${files}:/mnt/files" "${IMAGE}" matomo-update 2>&1 || true)" \
    "Set MATOMO_ADMIN_PASSWORD"

docker run -d --name "${web}" --network "${network}" "${env_args[@]}" -v "${files}:/mnt/files" "${IMAGE}" > /dev/null
docker exec "${web}" make check-ready max_try=60 -f /usr/local/bin/actions.mk > /dev/null
install_request

expect "Archiving nothing before installation" "$(matomo_run matomo-archive 2>&1)" "not installed yet"

echo -n "Installing Matomo... "
matomo_run matomo-update > /dev/null
echo "OK"
expect "Keeping the database password out of the shared settings" \
    "$(docker exec "${web}" grep -c 'p@ss' /mnt/files/config/config.ini.php || true)" "0"
expect "Recording the first website" "$(sql 'SELECT main_url FROM matomo_site WHERE idsite = 1')" "https://www.example.com"

expect "Showing the sign-in page" "$(status '/index.php?module=Login')" "200"
expect "Serving the tracker" "$(status /matomo.js)" "200"
expect "Hiding the settings" "$(status /config/config.ini.php)" "403"
expect "Hiding the code" "$(status /core/Version.php)" "403"
expect "Hiding temporary files" "$(status /tmp/)" "403"
docker exec "${web}" sh -c 'mkdir -p /mnt/files/plugins/Test && echo "<?php echo 1;" > /mnt/files/plugins/Test/x.php'
expect "Not running Marketplace plugin scripts" "$(status /marketplace-plugins/Test/x.php)" "403"

echo -n "Tracking a visit... "
request -o /dev/null -X POST 'http://localhost/matomo.php?idsite=1&rec=1&url=https%3A%2F%2Fwww.example.com%2F&action_name=Home'
visits=$(sql 'SELECT COUNT(*) FROM matomo_log_visit WHERE idsite = 1')
if [[ "${visits}" != "1" ]]; then
    echo "Error: ${visits} visits recorded"
    exit 1
fi
# Matomo masks the last two bytes of visitor addresses by default.
expect "from the forwarded client address" "$(sql 'SELECT INET6_NTOA(location_ip) FROM matomo_log_visit WHERE idsite = 1')" "203.0.0.0"

echo -n "Signing in... "
nonce=$(request 'http://localhost/index.php?module=Login' | grep -o 'id="login_form_nonce" value="[^"]*' | cut -d'"' -f4)
request -o /dev/null --data-urlencode form_login=admin --data-urlencode form_password=Secret-Pass-123 \
    --data-urlencode "form_nonce=${nonce}" 'http://localhost/index.php?module=Login'
page=$(request 'http://localhost/index.php?module=CoreHome&action=index&idSite=1&period=day&date=yesterday')
if [[ "${page}" == *'name="form_password"'* || "${page}" != *'piwik.token_auth'* ]]; then
    echo "Error: the dashboard is not available after signing in"
    exit 1
fi
echo "OK"

expect "Archiving reports" "$(matomo_run matomo-archive 2>&1)" "Done archiving"
expect "Updating an installed Matomo" "$(matomo_run matomo-update 2>&1)" "up to date"

tables=$(sql 'SHOW TABLES' | wc -l | tr -d ' ')
docker exec "${web}" mv /mnt/files/config/config.ini.php /mnt/files/config/config.ini.php.lost
expect "Refusing to install over existing tables" "$(matomo_run matomo-update 2>&1 || true)" "already has tables"
expect "Leaving the database alone" "$(sql 'SHOW TABLES' | wc -l | tr -d ' ')" "${tables}"
