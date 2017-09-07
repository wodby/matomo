FROM wodby/php:7.1

ENV APP_NAME="Piwik" \
    PIWIK_VERSION="3.0.4" \
    PHP_ALWAYS_POPULATE_RAW_POST_DATA="1" \
    PHP_GEOIP_CUSTOM_DIR="/var/www/html/web/misc" \
    GEOIP_DB_URL="http://geolite.maxmind.com/download/geoip/database/GeoLiteCity.dat.gz"

RUN mkdir -p /usr/src/piwik && \
    cd /usr/src/piwik && \
    chown www-data:www-data /usr/src/piwik && \
    su-exec www-data composer require piwik/piwik:${PIWIK_VERSION} && \

    curl -fsSL -o /usr/src/piwik/vendor/piwik/piwik/misc/GeoIPCity.dat.gz ${GEOIP_DB_URL} && \
    gunzip /usr/src/piwik/vendor/piwik/piwik/misc/GeoIPCity.dat.gz && \

    mv /usr/local/bin/actions.mk /usr/local/bin/php.mk

COPY init /docker-entrypoint-init.d/
COPY actions /usr/local/bin/