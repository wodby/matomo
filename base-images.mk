# Base image inputs shared by local builds and CI. Updated by wodby/images.
# Each digest identifies the complete multi-platform image index.
BASE_IMAGE_REPOSITORY := wodby/php
BASE_IMAGE_VERSION_SUFFIX :=

BASE_IMAGE_DIGEST_8.2 := sha256:f3f79f5c8ace1962bbb3a4d7f2ac35d4d8c011bd483774f2669622fcc1bc4ef1
BASE_IMAGE_DIGEST_8.2-r18 := sha256:573cd79ff25e7b87945dd9be575271a4e26e0fbd74f0bbef5b4715d6a2086a81
BASE_IMAGE_DIGEST_8.4-apache := sha256:7db5c5189455cbf13a718f0c103d20efa12b358fe390909fa4911acf001262cf
BASE_IMAGE_DIGEST_8.4-apache-r18 := sha256:0ba2f0b1dde0ce69400aefb070f2551cefb0e9722a732e205c12a8d135d5b31b

# Fail before building when a version or variant has no reviewed pin.
BASE_IMAGE = $(BASE_IMAGE_REPOSITORY):$(BASE_IMAGE_TAG)@$(or $(BASE_IMAGE_DIGEST_$(BASE_IMAGE_TAG)),$(error No base image digest for $(BASE_IMAGE_REPOSITORY):$(BASE_IMAGE_TAG); update base-images.mk))
