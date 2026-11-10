# Matomo Docker Container Image

[![Build Status](https://github.com/wodby/matomo/workflows/Build%20docker%20image/badge.svg)](https://github.com/wodby/matomo/actions)
[![Docker Pulls](https://img.shields.io/docker/pulls/wodby/matomo.svg)](https://hub.docker.com/r/wodby/matomo)
[![Docker Stars](https://img.shields.io/docker/stars/wodby/matomo.svg)](https://hub.docker.com/r/wodby/matomo)

## Docker Images

Use image revision tags such as `wodby/matomo:5-rN` to select a Wodby image revision.
Major and minor tags use the repository release number, starting at `r0`. Full-version tags such as
`wodby/matomo:5.13.0-r0` start at `r0` for each exact upstream version.
Every published versioned revision tag has a matching annotated Git tag pointing to its release commit.
Existing tags remain available after support for their major or minor version ends.
See [release tags](https://github.com/wodby/matomo/tags) for available revisions and the [image revision policy](https://github.com/wodby/images#image-revisions) for upgrade guidance.
Previously published image tags remain available.

Overview:

- All images based on Alpine Linux
- Base image: [wodby/php](https://github.com/wodby/php)
- [GitHub actions builds](https://github.com/wodby/matomo/actions) 
- [Docker Hub](https://hub.docker.com/r/wodby/matomo)

Supported tags and respective `Dockerfile` links:

* `5.14`, `5`, `latest` [_(Dockerfile)_](https://github.com/wodby/matomo/tree/master/Dockerfile)
* `5.14-apache`, `5-apache` [_(Dockerfile)_](https://github.com/wodby/matomo/tree/master/Dockerfile), see
  [Apache variant](#apache-variant)

## Apache variant

The `-apache` images serve Matomo from the image itself: Matomo's verified release in `/var/www/html` on the Apache
variant of [wodby/php](https://github.com/wodby/php) 8.4, where Apache passes PHP to PHP-FPM in the same container.
They are built for `linux/amd64` and `linux/arm64`. The other tags are unchanged: PHP-FPM with Matomo in
`/usr/src/matomo`, copied to a shared codebase volume for a separate web server.

On every start the image writes `config/common.config.ini.php`, a layer Matomo reads but never writes, from:

| Variable                  | Default             | Description                                                                 |
|---------------------------|---------------------|-----------------------------------------------------------------------------|
| `DB_HOST`                 | `localhost`         |                                                                             |
| `DB_PORT`                 | `3306`              |                                                                             |
| `DB_NAME`                 | `matomo`            |                                                                             |
| `DB_USERNAME`             |                     |                                                                             |
| `DB_PASSWORD`             |                     |                                                                             |
| `MATOMO_DB_TABLES_PREFIX` | `matomo_`           |                                                                             |
| `MATOMO_SALT`             |                     | Required. A long random string that never changes                          |
| `MATOMO_URL`              | `WODBY_PRIMARY_URL` | Matomo's address; HTTPS here makes Matomo assume HTTPS behind the proxy     |
| `WODBY_HOSTS`             |                     | JSON array of trusted hosts                                                 |
| `MATOMO_TRUSTED_HOSTS`    |                     | More trusted hosts, separated by commas                                     |

It also turns off the web installer, Matomo's own updater and archiving triggered by viewing reports, and takes the
client address from `X-Forwarded-For`.

The files directory, `/mnt/files`, holds `config/config.ini.php` (the settings Matomo writes), custom logos
(`misc-user`, linked from `misc/user`) and plugins installed from the Marketplace (`plugins`, loaded through
`MATOMO_PLUGIN_DIRS`). Share it between all containers of an installation.

| Command          | What it does                                                                                       |
|------------------|----------------------------------------------------------------------------------------------------|
| _(default)_      | Serves Matomo on port 80                                                                           |
| `matomo-update`  | Installs Matomo into an empty database, or runs `core:update` on an installed one                 |
| `matomo-archive` | Runs `core:archive` with `--url` set to `MATOMO_URL`; run it every hour                            |

`matomo-update` installs Matomo the way the web installer does, with the `wodby:install` command of the bundled
WodbyInstall plugin. The superuser comes from `MATOMO_ADMIN_USERNAME` (default `admin`), `MATOMO_ADMIN_PASSWORD` and
`MATOMO_ADMIN_EMAIL`, and the first website from `MATOMO_SITE_URL`, named `MATOMO_SITE_NAME`. It refuses to install
without a password and email, or into a database that already has tables.

### Another Matomo release

An image built on this one can replace Matomo with another verified release of the same major version, for example
to keep Matomo's version in an application's repository:

```dockerfile
FROM wodby/matomo:5-apache
USER root
RUN apk add --no-cache -t .gpg gnupg && matomo-use-release 5.14.1 && apk del --purge .gpg
USER wodby
```

`matomo-use-release` downloads the release, checks its signature and puts it in place of the image's Matomo, keeping
the WodbyInstall plugin, the GeoLite database, Matomo's `.htaccess` files and the links to the files directory. It
refuses a version of another major and does nothing when the version is the image's own.

## Environment Variables

| Variable                            | Default Value        | Description |
|-------------------------------------|----------------------|-------------|
| `PHP_ALWAYS_POPULATE_RAW_POST_DATA` | `1`                  |             |
| `PHP_GEOIP_CUSTOM_DIR`              | `/var/www/html/misc` |             |

See [wodby/php](https://github.com/wodby/php) for all variables

## Orchestration Actions

Usage:
```
make COMMAND [params ...]
 
commands:
    init
```

See [wodby/php](https://github.com/wodby/php) for all actions

## Deployment

Deploy Matomo to your own server via [![Wodby](https://www.google.com/s2/favicons?domain=wodby.com) Wodby](https://wodby.com/stacks/matomo).

## Building with pinned base images

Build with the Makefile to use the base image digests in `base-images.mk`. Local
builds and CI resolve the same version and variant to the same multi-platform
image. A version without a pin fails before the build starts.

When adding a supported base version or variant, add its image index digest to
`base-images.mk`. For a custom build, override `BASE_IMAGE` with a complete
`repository:tag@sha256:...` reference.
