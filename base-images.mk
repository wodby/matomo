# Base image inputs shared by local builds and CI. Updated by wodby/images.
# Each digest identifies the complete multi-platform image index.
BASE_IMAGE_REPOSITORY := wodby/php
BASE_IMAGE_VERSION_SUFFIX :=

BASE_IMAGE_DIGEST_8.2 := sha256:6221847dabe66e26c8e477e47dfbbb5a10248cd461f32a0844f7a74df7618ad5
BASE_IMAGE_DIGEST_8.2-r13 := sha256:8162b7eb95448725cb9128e2d6db3ae0d56042d6df50ddccd54d3728187f812d
BASE_IMAGE_DIGEST_8.4-apache := sha256:c1abec79e9e438b5c788f25d91a8a3ebbd7bd1461cf212d1801c613bf946a038
BASE_IMAGE_DIGEST_8.4-apache-r13 := sha256:9ac5f59e62270b8641ec7077d9da03977bcab4000daef37cbc5a0c82f7f4fd83

# Fail before building when a version or variant has no reviewed pin.
BASE_IMAGE = $(BASE_IMAGE_REPOSITORY):$(BASE_IMAGE_TAG)@$(or $(BASE_IMAGE_DIGEST_$(BASE_IMAGE_TAG)),$(error No base image digest for $(BASE_IMAGE_REPOSITORY):$(BASE_IMAGE_TAG); update base-images.mk))
