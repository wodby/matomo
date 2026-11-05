-include env_make

# Accept legacy build arguments during the image revision transition.
BASE_IMAGE_REVISION ?= $(BASE_IMAGE_STABILITY_TAG)
IMAGE_REVISION ?= $(STABILITY_TAG)

MATOMO_VER ?= 5.14.2
MATOMO_MINOR_VER ?= $(shell echo "${MATOMO_VER}" | grep -oE '^[0-9]+\.[0-9]+')

# VARIANT=apache builds the Wodby 2 image: Matomo served by Apache and PHP-FPM
# from the image. Without it, the PHP-FPM image that Wodby 1 uses.
VARIANT ?=

ifeq ($(VARIANT),apache)
    TAG ?= $(MATOMO_MINOR_VER)-apache
    TARGET = apache
else ifeq ($(VARIANT),)
    TAG ?= $(MATOMO_MINOR_VER)
    TARGET = fpm
else
    $(error Unsupported VARIANT: $(VARIANT))
endif

PHP_VER ?= 8.2
BASE_IMAGE_TAG = $(PHP_VER)

APACHE_PHP_VER ?= 8.4
APACHE_BASE_IMAGE_TAG = $(APACHE_PHP_VER)-apache

REPO = wodby/matomo
NAME = matomo-$(MATOMO_MINOR_VER)

ifneq ($(BASE_IMAGE_REVISION),)
    BASE_IMAGE_TAG := $(BASE_IMAGE_TAG)-$(BASE_IMAGE_REVISION)
endif

ifneq ($(APACHE_BASE_IMAGE_REVISION),)
    APACHE_BASE_IMAGE_TAG := $(APACHE_BASE_IMAGE_TAG)-$(APACHE_BASE_IMAGE_REVISION)
endif

ifneq ($(IMAGE_REVISION),)
    ifneq ($(TAG),latest)
        override TAG := $(TAG)-$(IMAGE_REVISION)
    else ifneq ($(filter r%,$(IMAGE_REVISION)),)
        override TAG := $(IMAGE_REVISION)
    endif
endif

# Architecture images of the Apache variant, combined by buildx-imagetools-create.
ifneq ($(ARCH),)
    override TAG := $(TAG)-$(ARCH)
endif

.PHONY: build test push shell run start stop logs clean release buildx-push buildx-imagetools-create

# Resolve the same pinned base image for every local and CI build target.
include base-images.mk

# The Apache variant's base, pinned in base-images.mk like BASE_IMAGE.
APACHE_BASE_IMAGE = $(BASE_IMAGE_REPOSITORY):$(APACHE_BASE_IMAGE_TAG)@$(or $(BASE_IMAGE_DIGEST_$(APACHE_BASE_IMAGE_TAG)),$(error No base image digest for $(BASE_IMAGE_REPOSITORY):$(APACHE_BASE_IMAGE_TAG); update base-images.mk))

default: build

build:
	docker build --build-arg BASE_IMAGE="$(BASE_IMAGE)" -t $(REPO):$(TAG) \
		--build-arg MATOMO_VER=$(MATOMO_VER) \
		$(if $(filter apache,$(VARIANT)),--build-arg APACHE_BASE_IMAGE="$(APACHE_BASE_IMAGE)") \
		--target $(TARGET) \
		./

test:
ifeq ($(VARIANT),apache)
	cd ./test/apache && IMAGE=$(REPO):$(TAG) NAME=$(NAME)-apache ./run.sh
else
	cd ./test && IMAGE=$(REPO):$(TAG) ./run.sh
endif

# Builds the image for both architectures and pushes it. The Apache variant is
# published this way.
PLATFORMS ?= linux/amd64,linux/arm64

buildx-push:
	docker buildx build --platform $(PLATFORMS) --push -t $(REPO):$(TAG) \
		--build-arg BASE_IMAGE="$(BASE_IMAGE)" \
		--build-arg MATOMO_VER=$(MATOMO_VER) \
		$(if $(filter apache,$(VARIANT)),--build-arg APACHE_BASE_IMAGE="$(APACHE_BASE_IMAGE)") \
		--target $(TARGET) \
		./

buildx-imagetools-create:
	docker buildx imagetools create -t $(REPO):$(IMAGETOOLS_TAG) \
				$(REPO):$(TAG)-amd64 \
				$(REPO):$(TAG)-arm64

push:
	docker push $(REPO):$(TAG)

shell:
	docker run --rm --name $(NAME) -i -t $(PORTS) $(VOLUMES) $(ENV) $(REPO):$(TAG) /bin/bash

run:
	docker run --rm --name $(NAME) $(PORTS) $(VOLUMES) $(ENV) $(REPO):$(TAG) $(CMD)

start:
	docker run -d --name $(NAME) $(PORTS) $(VOLUMES) $(ENV) $(REPO):$(TAG)

stop:
	docker stop $(NAME)

logs:
	docker logs $(NAME)

clean:
	-docker rm -f $(NAME)

release: build push
