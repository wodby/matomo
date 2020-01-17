ARG BASE_IMAGE_TAG

FROM wodby/php:${BASE_IMAGE_TAG}

ARG MATOMO_VER

ENV APP_NAME="Matomo" \
    MATOMO_VER="${MATOMO_VER}" \
    \
    PHP_ALWAYS_POPULATE_RAW_POST_DATA="1" \
    PHP_GEOIP_CUSTOM_DIR="/var/www/html/misc" \
    PHP_ERROR_REPORTING="E_ALL & ~E_NOTICE & ~E_STRICT & ~E_DEPRECATED"

USER root

COPY geolite /tmp/geolite

RUN set -ex; \
    \
    apk add --no-cache -t .matomo-build-deps gnupg; \
    \
    # Download and verify matomo.
    curl -o /tmp/matomo.tar.gz -Lskj "http://builds.piwik.org/piwik-"${MATOMO_VER}".tar.gz"; \
    curl -o /tmp/matomo.tar.gz.asc -Lskj "http://builds.piwik.org/piwik-"${MATOMO_VER}".tar.gz.asc"; \
    GPG_KEYS=814E346FA01A20DBB04B6807B5DBD5925590A237 gpg_verify /tmp/matomo.tar.gz.asc /tmp/matomo.tar.gz; \
    \
    mkdir -p /usr/src/matomo; \
    tar zxf /tmp/matomo.tar.gz --strip-components=1 -C /usr/src/matomo; \
    mv /tmp/geolite /usr/src/matomo/misc; \
    gunzip /usr/src/matomo/misc/geolite/GeoLite2-City.mmdb.gz; \
    mv /usr/src/matomo/misc/geolite/GeoLite2-City.mmdb /usr/src/matomo/misc/; \
    \
    echo "$(cat /etc/sudoers.d/wodby), /usr/local/bin/init" > /etc/sudoers.d/wodby; \
    \
    mkdir -p \
        /usr/src/matomo/tmp/assets \
        /usr/src/matomo/tmp/cache \
        /usr/src/matomo/tmp/cache/tracker \
        /usr/src/matomo/tmp/climulti \
        /usr/src/matomo/tmp/latest \
        /usr/src/matomo/tmp/logs \
        /usr/src/matomo/tmp/sessions \
        /usr/src/matomo/tmp/tcpdf \
        /usr/src/matomo/tmp/templates_c; \
    \
    chown -R wodby:wodby /usr/src/matomo; \
    \
    chown :www-data \
        /usr/src/matomo/misc/user \
        /usr/src/matomo/config \
        /usr/src/matomo/piwik.js; \
    chmod 775 \
        /usr/src/matomo/misc/user \
        /usr/src/matomo/config \
        /usr/src/matomo/piwik.js; \
    \
    chown -R :www-data \
        /usr/src/matomo/tmp \
        /usr/src/matomo/plugins; \
    chmod -R 775 \
        /usr/src/matomo/tmp \
        /usr/src/matomo/plugins; \
    \
    mv /usr/local/bin/actions.mk /usr/local/bin/php.mk; \
    \
    apk del --purge .matomo-build-deps; \
    rm -rf /tmp/*; \
    rm -rf /var/cache/apk/*

USER wodby

COPY init /docker-entrypoint-init.d/
COPY bin /usr/local/bin/