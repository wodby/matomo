# Matomo Docker Container Image

[![Build Status](https://travis-ci.org/wodby/matomo.svg?branch=master)](https://travis-ci.org/wodby/matomo)
[![Docker Pulls](https://img.shields.io/docker/pulls/wodby/matomo.svg)](https://hub.docker.com/r/wodby/matomo)
[![Docker Stars](https://img.shields.io/docker/stars/wodby/matomo.svg)](https://hub.docker.com/r/wodby/matomo)
[![Docker Layers](https://images.microbadger.com/badges/image/wodby/matomo.svg)](https://microbadger.com/images/wodby/matomo)

## Docker Images

❗For better reliability we release images with stability tags (`wodby/matomo:3.10-X.X.X`) which correspond to [git tags](https://github.com/wodby/matomo/releases). We strongly recommend using images only with stability tags. 

Overview:

* All images are based on Alpine Linux
* Base image: [wodby/php](https://github.com/wodby/php)
* [TravisCI builds](https://travis-ci.org/wodby/matomo) 
* [Docker Hub](https://hub.docker.com/r/wodby/matomo)

Supported tags and respective `Dockerfile` links:

* `3.10`, `3`, `latest` [_(Dockerfile)_](https://github.com/wodby/matomo/tree/master/Dockerfile)

## Environment Variables

| Variable                            | Default Value        | Description |
| ----------------------------------- | -------------------- | ----------- |
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
