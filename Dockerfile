# check=skip=InvalidDefaultArgInFrom

# The Makefile supplies the required digest-pinned BASE_IMAGE argument and, for
# the apache target, APACHE_BASE_IMAGE.

ARG BASE_IMAGE
# Unused unless the apache target is built.
ARG APACHE_BASE_IMAGE=scratch

# PHP-FPM with Matomo in /usr/src/matomo, copied to the shared codebase volume
# at startup. Wodby 1 runs this image behind its Nginx container.
FROM ${BASE_IMAGE} AS fpm

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
    curl -o /tmp/matomo.tar.gz -Ls "https://builds.matomo.org/matomo-"${MATOMO_VER}".tar.gz"; \
    curl -o /tmp/matomo.tar.gz.asc -Ls "https://builds.matomo.org/matomo-"${MATOMO_VER}".tar.gz.asc"; \
    GPG_KEYS=F529A27008477483777FC23D63BB30D0E5D2C749 gpg_verify /tmp/matomo.tar.gz.asc /tmp/matomo.tar.gz; \
    \
    mkdir -p /usr/src/matomo; \
    tar zxf /tmp/matomo.tar.gz --strip-components=1 -C /usr/src/matomo; \
    mv /tmp/geolite /usr/src/matomo/misc; \
    gunzip /usr/src/matomo/misc/geolite/GeoLite2-City.mmdb.gz; \
    mv /usr/src/matomo/misc/geolite/GeoLite2-City.mmdb /usr/src/matomo/misc/; \
    rm -rf /usr/src/matomo/misc/geolite; \
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

# Matomo served by Apache and PHP-FPM from the image itself, for Wodby 2. The
# code is the release verified above; settings, uploads and Marketplace plugins
# live in the files directory.
FROM ${APACHE_BASE_IMAGE} AS apache

ARG MATOMO_VER

ENV APP_NAME="Matomo" \
    MATOMO_VER="${MATOMO_VER}" \
    \
    # PHP-FPM runs as the owner of the code, like Matomo's console commands, so \
    # files any of them write stay writable by the others. \
    PHP_FPM_USER="wodby" \
    # Matomo reads the Marketplace plugin directories from the environment. \
    PHP_FPM_CLEAR_ENV="no" \
    PHP_ALWAYS_POPULATE_RAW_POST_DATA="1" \
    PHP_MAX_EXECUTION_TIME="300" \
    PHP_ERROR_REPORTING="E_ALL & ~E_NOTICE & ~E_STRICT & ~E_DEPRECATED" \
    \
    # Plugins installed from the Marketplace go to the files directory, so \
    # every container loads them and they outlive the image. \
    MATOMO_PLUGIN_DIRS="/var/www/html/marketplace-plugins;marketplace-plugins" \
    MATOMO_PLUGIN_COPY_DIR="/var/www/html/marketplace-plugins/"

COPY --from=fpm --chown=wodby:wodby /usr/src/matomo /var/www/html
COPY --chown=wodby:wodby apache/plugins /var/www/html/plugins/
COPY apache/matomo.conf /etc/apache2/conf.d/matomo.conf
COPY apache/init /docker-entrypoint-init.d/
COPY apache/bin /usr/local/bin/

RUN set -ex; \
    cd /var/www/html; \
    # Matomo's .htaccess files for its code directories. Matomo writes them \
    # itself during installation and updates, but quietly fails when the code \
    # isn't writable, so they are part of the image. \
    php console core:create-security-files; \
    # Links to the files directory: the settings Matomo writes, custom logos \
    # and Marketplace plugins. \
    ln -s "${FILES_DIR}/config/config.ini.php" config/config.ini.php; \
    rm -rf misc/user; \
    ln -s "${FILES_DIR}/misc-user" misc/user; \
    ln -s "${FILES_DIR}/plugins" marketplace-plugins

# Builds without a target get the PHP-FPM image.
FROM fpm
