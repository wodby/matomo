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

* `5.13`, `5`, `latest` [_(Dockerfile)_](https://github.com/wodby/matomo/tree/master/Dockerfile)

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
