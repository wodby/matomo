ARG BASE_IMAGE_TAG

FROM wodby/php:${BASE_IMAGE_TAG}

ARG MATOMO_VER

ENV APP_NAME="Matomo" \
    MATOMO_VER="${MATOMO_VER}" \
    MATOMO_URL="http://builds.piwik.org/piwik-"${MATOMO_VER}".tar.gz" \
    MATOMO_ASC_URL="http://builds.piwik.org/piwik-"${MATOMO_VER}".tar.gz.asc" \
    GPG_KEY="814E346FA01A20DBB04B6807B5DBD5925590A237" \
    GEOIP_DB_URL="http://geolite.maxmind.com/download/geoip/database/GeoLiteCity.dat.gz" \
    \
    PHP_ALWAYS_POPULATE_RAW_POST_DATA="1" \
    PHP_GEOIP_CUSTOM_DIR="/var/www/html/misc"

USER root

RUN set -ex; \
    \
    apk add --no-cache -t .matomo-build-deps gnupg; \
    \
    # Download and verify matomo.
    cd /tmp; \
    curl -o matomo.tar.gz -Lskj "${MATOMO_URL}"; \
    curl -o matomo.tar.gz.asc -Lskj "${MATOMO_ASC_URL}"; \
    export GNUPGHOME="$(mktemp -d)"; \
    gpg --keyserver ha.pool.sks-keyservers.net --recv-keys "${GPG_KEY}"; \
    gpg --batch --verify matomo.tar.gz.asc matomo.tar.gz; \
    mkdir -p /usr/src/matomo; \
    tar zxf matomo.tar.gz --strip-components=1 -C /usr/src/matomo; \
    \
    # Download GeoIP database.
    curl -fsSL -o /usr/src/matomo/misc/GeoIPCity.dat.gz "${GEOIP_DB_URL}"; \
    gunzip /usr/src/matomo/misc/GeoIPCity.dat.gz; \
    \
    chown -R www-data:www-data /usr/src/matomo; \
    chmod -R 775 /usr/src/matomo/tmp; \
    chown php-fpm:www-data /usr/src/matomo/config /usr/src/matomo/piwik.js; \
    \
    mv /usr/local/bin/actions.mk /usr/local/bin/php.mk; \
    \
    apk del --purge .matomo-build-deps; \
    rm -rf /tmp/*; \
    rm -rf /var/cache/apk/*

USER www-data

COPY init /docker-entrypoint-init.d/
COPY actions /usr/local/bin/